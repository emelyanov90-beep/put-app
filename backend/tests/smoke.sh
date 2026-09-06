#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PB_BIN="${PB_BIN:-${PROJECT_ROOT}/backend/bin/pocketbase}"
PB_HTTP="${PB_HTTP:-127.0.0.1:18093}"
BASE_URL="http://${PB_HTTP}"
DATA_DIR="$(mktemp -d /tmp/vput-pb-smoke.XXXXXX)"
LOG_FILE="${DATA_DIR}/pocketbase.log"

cleanup() {
  if [[ -n "${PB_PID:-}" ]]; then
    kill "${PB_PID}" 2>/dev/null || true
    wait "${PB_PID}" 2>/dev/null || true
  fi
  rm -rf "${DATA_DIR}"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  echo "PocketBase log: ${LOG_FILE}" >&2
  exit 1
}

assert_json() {
  local json="$1"
  local expression="$2"
  local message="$3"
  jq -e "${expression}" >/dev/null <<<"${json}" || fail "${message}"
}

auth_token() {
  local phone="$1"
  local response
  response="$(curl -fsS "${BASE_URL}/api/app/auth/verify-code" \
    -H 'Content-Type: application/json' \
    -d "{\"phone\":\"${phone}\",\"code\":\"111111\"}")"
  jq -e --arg phone "${phone}" \
    '.record.email == null and .record.phone == $phone' \
    >/dev/null <<<"${response}" || \
    fail "auth response must contain only the caller phone and no internal email"
  jq -er '.token' <<<"${response}"
}

if [[ ! -x "${PB_BIN}" ]]; then
  fail "PocketBase executable is missing; run ./tool/bootstrap_pocketbase.sh"
fi
command -v curl >/dev/null || fail "curl is required"
command -v jq >/dev/null || fail "jq is required"

"${PB_BIN}" serve \
  --dir="${DATA_DIR}" \
  --migrationsDir="${PROJECT_ROOT}/backend/pb_migrations" \
  --hooksDir="${PROJECT_ROOT}/backend/pb_hooks" \
  --http="${PB_HTTP}" >"${LOG_FILE}" 2>&1 &
PB_PID=$!

for _ in {1..50}; do
  if curl -fsS "${BASE_URL}/api/app/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done
health="$(curl -fsS "${BASE_URL}/api/app/health")" || fail "health endpoint did not start"
assert_json "${health}" '.status == "ok" and .pocketbase == "0.40.2"' \
  "unexpected health response"

request_code="$(curl -fsS "${BASE_URL}/api/app/auth/request-code" \
  -H 'Content-Type: application/json' \
  -d '{"phone":"+79990000001"}')"
assert_json "${request_code}" '.success == true and .expiresIn == 60' \
  "request-code failed"

invalid_status="$(curl -sS -o "${DATA_DIR}/invalid.json" -w '%{http_code}' \
  "${BASE_URL}/api/app/auth/verify-code" \
  -H 'Content-Type: application/json' \
  -d '{"phone":"+79990000001","code":"000000"}')"
[[ "${invalid_status}" == "400" ]] || fail "invalid OTP returned HTTP ${invalid_status}"
assert_json "$(cat "${DATA_DIR}/invalid.json")" '.code == "INVALID_OTP"' \
  "invalid OTP error code is wrong"

passenger_one="$(auth_token '+79990000001')"
passenger_three="$(auth_token '+79990000003')"
driver_one="$(auth_token '+79990000011')"
driver_two="$(auth_token '+79990000012')"

passenger_vehicles="$(curl -fsS "${BASE_URL}/api/app/vehicles" \
  -H "Authorization: Bearer ${passenger_one}")"
assert_json "${passenger_vehicles}" '.items | length == 0' \
  "an account without vehicles received another owner's garage"

config="$(curl -fsS "${BASE_URL}/api/app/config" \
  -H "Authorization: Bearer ${passenger_one}")"
assert_json "${config}" \
  '.commission_percent == 10 and .trip_publication_limits.driver_trip_limit_per_day == 2 and .extra_service_prices.child_seat == 150 and .parcel_size_specs.large.price_rub == 350' \
  "runtime application settings are incomplete"

search="$(curl -fsS "${BASE_URL}/api/app/trips/search?transport_type=car" \
  -H "Authorization: Bearer ${passenger_one}")"
assert_json "${search}" '.totalItems == 2' "seeded trip search did not return two trips"
assert_json "${search}" \
  '[.items[] | select(.driver.reviews_count == 0)] | length == 1 and .[0].driver.rating_avg == null' \
  "zero-review driver must not have a fake rating"
standard_trip="$(jq -er '.items[] | select(.booking_mode == "standard") | .id' <<<"${search}")"
instant_trip="$(jq -er '.items[] | select(.booking_mode == "instant") | .id' <<<"${search}")"
driver_vehicle="$(jq -er '.items[] | select(.booking_mode == "standard") | .vehicle.id' <<<"${search}")"

vehicle_update="$(curl -fsS \
  "${BASE_URL}/api/collections/vehicles/records/${driver_vehicle}" \
  -X PATCH -H "Authorization: Bearer ${driver_one}" \
  -H 'Content-Type: application/json' -d '{"plate_number":"А002АА77"}')"
assert_json "${vehicle_update}" \
  '.plate_number == "А002АА77" and .verification_status == "draft"' \
  "vehicle update did not reset verification status"

created="$(curl -fsS "${BASE_URL}/api/app/bookings" \
  -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' \
  -d "{\"trip_id\":\"${standard_trip}\",\"pickup_index\":0,\"dropoff_index\":2,\"seat_count\":1,\"extra_service_codes\":[\"child_seat\"]}")"
assert_json "${created}" \
  '.booking.status == "pending_driver" and .booking.driver_amount == 1350 and .booking.commission_amount == 135 and .booking.amount == 1485' \
  "commission must be added on top of the fare the driver receives"
booking_id="$(jq -er '.booking.id' <<<"${created}")"

# A leg is charged at the price set for that exact pair, never at the sum of
# the shorter legs inside it: a short leg is dearer per kilometre on purpose.
leg="$(curl -fsS "${BASE_URL}/api/app/bookings" \
  -H "Authorization: Bearer ${passenger_three}" \
  -H 'Content-Type: application/json' \
  -d "{\"trip_id\":\"${standard_trip}\",\"pickup_index\":0,\"dropoff_index\":1,\"seat_count\":1}")"
assert_json "${leg}" \
  '.booking.driver_amount == 500 and .booking.commission_amount == 50 and .booking.amount == 550' \
  "a partial leg must be charged at its own fare"
leg_id="$(jq -er '.booking.id' <<<"${leg}")"
curl -fsS "${BASE_URL}/api/app/bookings/${leg_id}/cancel" \
  -H "Authorization: Bearer ${passenger_three}" \
  -H 'Content-Type: application/json' -d '{"reason":"smoke"}' >/dev/null

unpriced_status="$(curl -sS -o "${DATA_DIR}/unpriced.json" -w '%{http_code}' \
  "${BASE_URL}/api/app/bookings" \
  -H "Authorization: Bearer ${passenger_three}" \
  -H 'Content-Type: application/json' \
  -d "{\"trip_id\":\"${instant_trip}\",\"pickup_index\":0,\"dropoff_index\":1,\"seat_count\":99}")"
[[ "${unpriced_status}" == "409" ]] || fail "oversized booking returned HTTP ${unpriced_status}"

approved="$(curl -fsS "${BASE_URL}/api/app/bookings/${booking_id}/approve" \
  -H "Authorization: Bearer ${driver_one}" -X POST)"
assert_json "${approved}" '.booking.status == "awaiting_payment"' \
  "driver approval failed"

paid="$(curl -fsS "${BASE_URL}/api/app/bookings/${booking_id}/pay" \
  -H "Authorization: Bearer ${passenger_one}" -X POST)"
paid_again="$(curl -fsS "${BASE_URL}/api/app/bookings/${booking_id}/pay" \
  -H "Authorization: Bearer ${passenger_one}" -X POST)"
assert_json "${paid}" '.booking.status == "confirmed" and .booking.payment_status == "paid"' \
  "mock payment failed"
[[ "$(jq -r '.mock_transaction_id' <<<"${paid}")" == \
   "$(jq -r '.mock_transaction_id' <<<"${paid_again}")" ]] || \
  fail "mock payment is not idempotent"

patch_status="$(curl -sS -o /dev/null -w '%{http_code}' \
  "${BASE_URL}/api/collections/bookings/records/${booking_id}" \
  -X PATCH -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' -d '{"status":"completed"}')"
[[ "${patch_status}" == "403" ]] || fail "direct booking mutation returned HTTP ${patch_status}"

cancelled="$(curl -fsS "${BASE_URL}/api/app/bookings/${booking_id}/cancel" \
  -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' -d '{"reason":"smoke"}')"
cancelled_again="$(curl -fsS "${BASE_URL}/api/app/bookings/${booking_id}/cancel" \
  -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' -d '{"reason":"smoke"}')"
assert_json "${cancelled}" \
  '.booking.status == "cancelled_by_passenger" and .booking.payment_status == "refund_requested" and .refund_amount == 135' \
  "paid cancellation did not request the mock refund"
jq -e --arg id "${booking_id}" \
  '.booking.id == $id and .booking.status == "cancelled_by_passenger" and .booking.payment_status == "refund_requested" and .refund_amount == 135' \
  >/dev/null <<<"${cancelled_again}" || \
  fail "cancellation retry changed the business result"

# A parcel books no seat and is priced by the platform catalogue, not the fare.
parcel="$(curl -fsS "${BASE_URL}/api/app/bookings" \
  -H "Authorization: Bearer ${passenger_three}" \
  -H 'Content-Type: application/json' \
  -d "{\"trip_id\":\"${standard_trip}\",\"booking_kind\":\"parcel\",\"pickup_index\":0,\"dropoff_index\":2,\"parcel_size\":\"M\",\"parcel_comment\":\"smoke\"}")"
assert_json "${parcel}" \
  '.booking.booking_kind == "parcel" and .booking.status == "pending_driver" and .booking.seat_count == 0 and .booking.driver_amount == 250 and .booking.amount == 275' \
  "parcel booking price, kind or seat count is wrong"
parcel_id="$(jq -er '.booking.id' <<<"${parcel}")"

parcel_record="$(curl -fsS \
  "${BASE_URL}/api/collections/parcels/records?filter=$(printf 'booking_id="%s"' "${parcel_id}" | jq -sRr @uri)" \
  -H "Authorization: Bearer ${passenger_three}")"
assert_json "${parcel_record}" \
  '.totalItems == 1 and .items[0].weight_category == "M" and .items[0].amount == 250' \
  "parcel record was not stored next to the booking"

bad_size_status="$(curl -sS -o "${DATA_DIR}/bad_parcel.json" -w '%{http_code}' \
  "${BASE_URL}/api/app/bookings" \
  -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' \
  -d "{\"trip_id\":\"${standard_trip}\",\"booking_kind\":\"parcel\",\"pickup_index\":0,\"dropoff_index\":2,\"parcel_size\":\"XL\"}")"
[[ "${bad_size_status}" == "400" ]] || fail "unknown parcel size returned HTTP ${bad_size_status}"
assert_json "$(cat "${DATA_DIR}/bad_parcel.json")" '.code == "INVALID_PARCEL_SIZE"' \
  "unknown parcel size error code is wrong"

curl -sS -o "${DATA_DIR}/race_one.json" -w '%{http_code}' \
  "${BASE_URL}/api/app/bookings" \
  -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' \
  -d "{\"trip_id\":\"${instant_trip}\",\"pickup_index\":0,\"dropoff_index\":1,\"seat_count\":2}" \
  >"${DATA_DIR}/race_one.status" &
race_one_pid=$!
curl -sS -o "${DATA_DIR}/race_two.json" -w '%{http_code}' \
  "${BASE_URL}/api/app/bookings" \
  -H "Authorization: Bearer ${passenger_three}" \
  -H 'Content-Type: application/json' \
  -d "{\"trip_id\":\"${instant_trip}\",\"pickup_index\":0,\"dropoff_index\":1,\"seat_count\":1}" \
  >"${DATA_DIR}/race_two.status" &
race_two_pid=$!
wait "${race_one_pid}"
wait "${race_two_pid}"
race_statuses="$(sort "${DATA_DIR}/race_one.status" "${DATA_DIR}/race_two.status" | tr '\n' ' ')"
[[ "${race_statuses}" == "200 409 " ]] || fail "last-seat race returned ${race_statuses}"

complaint="$(curl -fsS "${BASE_URL}/api/app/complaints" \
  -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' \
  -X POST -d '{"subject":"trip","text":"Водитель опоздал на час и не отвечал."}')"
assert_json "${complaint}" '.complaint.status == "new" and .complaint.subject == "trip"' \
  "complaint was not created"

complaints="$(curl -fsS "${BASE_URL}/api/app/complaints" \
  -H "Authorization: Bearer ${passenger_one}")"
assert_json "${complaints}" '.items | length == 1' "own complaints list is wrong"

others_complaints="$(curl -fsS "${BASE_URL}/api/app/complaints" \
  -H "Authorization: Bearer ${driver_two}")"
assert_json "${others_complaints}" '.items | length == 0' \
  "complaints leaked to another user"

short_status="$(curl -sS -o /dev/null -w '%{http_code}' \
  "${BASE_URL}/api/app/complaints" \
  -H "Authorization: Bearer ${passenger_one}" \
  -H 'Content-Type: application/json' \
  -X POST -d '{"subject":"trip","text":"коротко"}')"
[[ "${short_status}" == "400" ]] || fail "short complaint returned HTTP ${short_status}"

notifications_read="$(curl -fsS "${BASE_URL}/api/app/notifications/read" \
  -H "Authorization: Bearer ${driver_one}" \
  -H 'Content-Type: application/json' -X POST -d '{"ids":[]}')"
assert_json "${notifications_read}" '.updated >= 1' \
  "marking notifications read did not update anything"
notifications_again="$(curl -fsS "${BASE_URL}/api/app/notifications/read" \
  -H "Authorization: Bearer ${driver_one}" \
  -H 'Content-Type: application/json' -X POST -d '{"ids":[]}')"
assert_json "${notifications_again}" '.updated == 0' \
  "marking notifications read is not idempotent"

driver_trips="$(curl -fsS "${BASE_URL}/api/app/trips/mine" \
  -H "Authorization: Bearer ${driver_two}")"
assert_json "${driver_trips}" \
  '.items | length == 1 and ([.. | objects | has("phone")] | any) == false' \
  "driver trip list is incomplete or exposes a passenger phone"

cancelled_trip="$(curl -fsS "${BASE_URL}/api/app/trips/${instant_trip}/cancel" \
  -H "Authorization: Bearer ${driver_two}" -X POST)"
cancelled_trip_again="$(curl -fsS "${BASE_URL}/api/app/trips/${instant_trip}/cancel" \
  -H "Authorization: Bearer ${driver_two}" -X POST)"
assert_json "${cancelled_trip}" '.trip.status == "cancelled" and .trip.accepting_bookings == false' \
  "driver trip cancellation failed"
assert_json "${cancelled_trip_again}" '.trip.status == "cancelled"' \
  "driver trip cancellation retry failed"

echo "PASS: migrations, auth, safe DTOs, trips, booking, payment, refund, access rules, parcels, complaints, notifications, and seat race"
