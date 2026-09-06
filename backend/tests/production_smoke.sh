#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://pb.bookingtest26.ru}"
WRITE_TEST="${WRITE_TEST:-0}"

fail() {
  echo "FAIL: $*" >&2
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
  curl -fsS "${BASE_URL}/api/app/auth/verify-code" \
    -H 'Content-Type: application/json' \
    -d "{\"phone\":\"${phone}\",\"code\":\"111111\"}" | jq -er '.token'
}

health="$(curl -fsS "${BASE_URL}/api/app/health")"
assert_json "${health}" '.status == "ok" and .pocketbase == "0.40.2"' \
  "public health endpoint failed"

request="$(curl -fsS "${BASE_URL}/api/app/auth/request-code" \
  -H 'Content-Type: application/json' \
  -d '{"phone":"+79990000003"}')"
assert_json "${request}" '.success == true' "request-code failed"

passenger="$(auth_token '+79990000003')"
config="$(curl -fsS "${BASE_URL}/api/app/config" \
  -H "Authorization: Bearer ${passenger}")"
assert_json "${config}" \
  '.commission_fixed_rub == 50 and .trip_publication_limits.driver_trip_limit_per_day == 2 and .extra_service_prices.child_seat == 150 and .parcel_size_specs.large.price_rub == 350' \
  "runtime application settings are incomplete"

search="$(curl -fsS "${BASE_URL}/api/app/trips/search?transport_type=car" \
  -H "Authorization: Bearer ${passenger}")"
assert_json "${search}" \
  '.totalItems == 2 and ([.. | objects | has("phone")] | any) == false' \
  "trip search data or privacy contract is wrong"

suffix=""
if [[ "${WRITE_TEST}" == "1" ]]; then
  driver="$(auth_token '+79990000011')"
  trip_id="$(jq -er '.items[] | select(.booking_mode == "standard") | .id' <<<"${search}")"
  last_index="$(jq -er '.items[] | select(.id == $id) | (.stops | length) - 1' --arg id "${trip_id}" <<<"${search}")"
  created="$(curl -fsS "${BASE_URL}/api/app/bookings" \
    -H "Authorization: Bearer ${passenger}" \
    -H 'Content-Type: application/json' \
    -d "{\"trip_id\":\"${trip_id}\",\"pickup_index\":0,\"dropoff_index\":${last_index},\"seat_count\":1}")"
  assert_json "${created}" '.booking.status == "pending_driver"' \
    "production booking creation failed"
  booking_id="$(jq -er '.booking.id' <<<"${created}")"
  rejected="$(curl -fsS \
    "${BASE_URL}/api/app/bookings/${booking_id}/reject" \
    -H "Authorization: Bearer ${driver}" -X POST)"
  assert_json "${rejected}" '.booking.status == "rejected_by_driver"' \
    "production driver decision failed"
  suffix=", and write route"
fi

echo "PASS: public HTTPS health, OTP, runtime config, privacy-safe trip search${suffix}"
