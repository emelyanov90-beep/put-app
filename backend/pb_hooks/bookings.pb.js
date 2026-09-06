/// <reference path="../pb_data/types.d.ts" />

routerAdd(
  "GET",
  "/api/app/bookings/mine",
  (e) => require(`${__hooks}/lib/app.js`).listOwnBookingsHandler(e),
  $apis.requireAuth("users"),
)

routerAdd("POST", "/api/app/bookings", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const body = h.bodyOf(e)
    const passengerId = e.auth.id
    const tripId = String(body.trip_id || "")
    if (e.auth.getBool("booking_blocked")) {
      throw h.businessError("BOOKING_BLOCKED", "Новые бронирования заблокированы.", 403)
    }

    let result
    e.app.runInTransaction((tx) => {
      const trip = tx.findRecordById("trips", tripId)
      if (trip.getString("status") !== "published" ||
          !trip.getBool("accepting_bookings") ||
          trip.getDateTime("departure_at").before(new DateTime())) {
        throw h.businessError("TRIP_UNAVAILABLE", "Поездка недоступна.", 409)
      }
      if (trip.getString("driver_id") === passengerId) {
        throw h.businessError("OWN_TRIP", "Нельзя забронировать собственную поездку.", 409)
      }
      if (h.activeBooking(tx, passengerId, tripId)) {
        throw h.businessError("BOOKING_EXISTS", "Активная заявка уже существует.", 409)
      }

      const bookingKind = String(body.booking_kind || "passenger")
      if (bookingKind !== "passenger" && bookingKind !== "parcel") {
        throw h.businessError("INVALID_BOOKING", "Неизвестный тип заявки.")
      }
      const isParcel = bookingKind === "parcel"

      // A parcel travels without its sender, so it reserves no seat.
      const seatCount = isParcel ? 0 : Number(body.seat_count || 1)
      if (!isParcel && (!Number.isInteger(seatCount) || seatCount < 1)) {
        throw h.businessError("INVALID_BOOKING", "Некорректное количество мест.")
      }

      const parcelSize = isParcel ? String(body.parcel_size || "") : ""
      if (isParcel && ["S", "M", "L"].indexOf(parcelSize) < 0) {
        throw h.businessError("INVALID_PARCEL_SIZE", "Некорректный размер посылки.")
      }
      const stops = h.recordsByFilter(
        tx,
        "trip_stops",
        "trip_id = {:trip}",
        "sort_order",
        100,
        { trip: tripId },
      )
      const pickupIndex = Number(body.pickup_index)
      const dropoffIndex = Number(body.dropoff_index)
      if (!Number.isInteger(pickupIndex) || !Number.isInteger(dropoffIndex) ||
          pickupIndex < 0 || dropoffIndex <= pickupIndex || dropoffIndex >= stops.length) {
        throw h.businessError("INVALID_ROUTE", "Некорректные точки посадки и высадки.")
      }
      if (!isParcel && trip.getString("booking_mode") === "instant") {
        h.ensureSeats(tx, trip, seatCount)
      }

      // A parcel is priced by its size from the platform catalogue; a seat is
      // priced by the fare the driver set for exactly this pair of stops.
      // The driver never prices a parcel himself.
      let fare
      if (isParcel) {
        fare = h.parcelPrice(tx, trip, parcelSize)
      } else {
        const legPrice = h.legFare(trip, pickupIndex, dropoffIndex)
        if (legPrice === null) {
          throw h.businessError(
            "LEG_NOT_SOLD",
            "Водитель не назначил цену за этот участок.",
            409,
          )
        }
        fare = legPrice * seatCount
      }
      const selectedCodes = isParcel || !Array.isArray(body.extra_service_codes)
        ? []
        : body.extra_service_codes
      const selected = {}
      for (const code of selectedCodes) selected[String(code)] = true
      const enabledExtras = h.recordsByFilter(
        tx,
        "trip_extra_services",
        "trip_id = {:trip}",
        "",
        100,
        { trip: tripId },
      )
      const extraRows = []
      for (const enabled of enabledExtras) {
        const service = tx.findRecordById(
          "extra_services",
          enabled.getString("service_id"),
        )
        const code = service.getString("code")
        if (selected[code]) {
          const amount = enabled.getInt("price")
          fare += amount
          extraRows.push({ service_id: service.id, amount: amount })
          delete selected[code]
        }
      }
      if (Object.keys(selected).length) {
        throw h.businessError(
          "INVALID_EXTRA",
          "Выбрана недоступная дополнительная услуга.",
        )
      }

      // The fare is what the driver receives; the commission is added on top of
      // it, so the passenger total is fare + commission.
      let commission = 0
      const monetizationSetting = h.firstByData(
        tx,
        "app_settings",
        "key",
        "monetization_enabled",
      )
      if (!monetizationSetting || monetizationSetting.get("value") !== false) {
        commission = Math.round((fare * h.commissionPercent(tx)) / 100)
      }
      const total = fare + commission

      const status = trip.getString("booking_mode") === "instant"
        ? "awaiting_payment"
        : "pending_driver"
      const paymentStatus = commission > 0 ? "unpaid" : "not_required"
      const booking = new Record(tx.findCollectionByNameOrId("bookings"), {
        trip_id: tripId,
        passenger_id: passengerId,
        pickup_stop_id: stops[pickupIndex].id,
        dropoff_stop_id: stops[dropoffIndex].id,
        booking_kind: bookingKind,
        status: status,
        payment_status: paymentStatus,
        seat_count: seatCount,
        amount: total,
        commission_amount: commission,
        driver_amount: fare,
        currency: trip.getString("currency"),
        idempotency_key: $security.randomString(24),
      })
      tx.save(booking)
      if (isParcel) {
        tx.save(new Record(tx.findCollectionByNameOrId("parcels"), {
          booking_id: booking.id,
          weight_category: parcelSize,
          description: String(body.parcel_description || ""),
          comment: String(body.parcel_comment || ""),
          amount: fare,
        }))
      }
      for (const row of extraRows) {
        tx.save(new Record(tx.findCollectionByNameOrId("booking_extras"), {
          booking_id: booking.id,
          service_id: row.service_id,
          quantity: 1,
          amount: row.amount,
        }))
      }
      h.ensureChat(tx, booking, trip)
      h.notify(
        tx,
        trip.getString("driver_id"),
        "booking_created",
        isParcel ? "Новая посылка" : "Новая заявка",
        isParcel
          ? "Пассажир отправил заявку на перевозку посылки."
          : "Пассажир отправил заявку на поездку.",
        { booking_id: booking.id },
      )
      result = h.bookingDto(booking)
    })
    return e.json(200, { booking: result })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))

function driverDecisionHandler(e, approved) {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const bookingId = e.request.pathValue("id")
    let result
    e.app.runInTransaction((tx) => {
      const booking = tx.findRecordById("bookings", bookingId)
      const trip = tx.findRecordById("trips", booking.getString("trip_id"))
      h.requireOwnRecord(trip, e.auth.id, "driver_id")
      if (booking.getString("status") !== "pending_driver") {
        const desired = approved ? "awaiting_payment" : "rejected_by_driver"
        if (booking.getString("status") === desired) {
          result = h.bookingDto(booking)
          return
        }
        throw h.businessError(
          "INVALID_BOOKING_STATUS",
          "Заявка уже обработана.",
          409,
        )
      }
      if (approved) h.ensureSeats(tx, trip, booking.getInt("seat_count"))
      booking.set("status", approved ? "awaiting_payment" : "rejected_by_driver")
      booking.set("driver_decided_at", new DateTime())
      tx.save(booking)
      h.notify(
        tx,
        booking.getString("passenger_id"),
        approved ? "booking_approved" : "booking_rejected",
        approved ? "Заявка одобрена" : "Заявка отклонена",
        approved ? "Теперь можно оплатить комиссию." : "Водитель отклонил заявку.",
        { booking_id: booking.id },
      )
      result = h.bookingDto(booking)
    })
    return e.json(200, { booking: result })
  } catch (error) {
    return h.writeError(e, error)
  }
}

routerAdd(
  "POST",
  "/api/app/bookings/{id}/approve",
  (e) => require(`${__hooks}/lib/app.js`).driverDecisionHandler(e, true),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/bookings/{id}/reject",
  (e) => require(`${__hooks}/lib/app.js`).driverDecisionHandler(e, false),
  $apis.requireAuth("users"),
)

routerAdd("POST", "/api/app/bookings/{id}/pay", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const bookingId = e.request.pathValue("id")
    let result
    let transactionId = ""
    e.app.runInTransaction((tx) => {
      const booking = tx.findRecordById("bookings", bookingId)
      h.requireOwnRecord(booking, e.auth.id, "passenger_id")
      const existing = h.firstByData(tx, "payments", "booking_id", booking.id)
      if (booking.getString("status") === "confirmed" &&
          booking.getString("payment_status") === "paid" && existing) {
        result = h.bookingDto(booking)
        transactionId = existing.getString("mock_transaction_id")
        return
      }
      if (booking.getString("status") !== "awaiting_payment" ||
          booking.getString("payment_status") !== "unpaid") {
        throw h.businessError(
          "PAYMENT_NOT_ALLOWED",
          "Оплата недоступна для этой заявки.",
          409,
        )
      }
      const now = new DateTime()
      const payment = new Record(tx.findCollectionByNameOrId("payments"), {
        booking_id: booking.id,
        payer_id: e.auth.id,
        provider: "mock",
        status: "paid",
        amount: booking.getInt("commission_amount"),
        currency: booking.getString("currency"),
        mock_transaction_id: "mock_" + $security.randomString(32),
        paid_at: now,
      })
      tx.save(payment)
      booking.set("status", "confirmed")
      booking.set("payment_status", "paid")
      tx.save(booking)
      const trip = tx.findRecordById("trips", booking.getString("trip_id"))
      h.notify(
        tx,
        trip.getString("driver_id"),
        "booking_paid",
        "Бронь оплачена",
        "Пассажир оплатил комиссию.",
        { booking_id: booking.id },
      )
      result = h.bookingDto(booking)
      transactionId = payment.getString("mock_transaction_id")
    })
    return e.json(200, {
      booking: result,
      mock_transaction_id: transactionId,
    })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))

routerAdd("POST", "/api/app/bookings/{id}/cancel", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const body = h.bodyOf(e)
    const bookingId = e.request.pathValue("id")
    let result
    let blocked = false
    let refundAmount = 0
    e.app.runInTransaction((tx) => {
      const booking = tx.findRecordById("bookings", bookingId)
      h.requireOwnRecord(booking, e.auth.id, "passenger_id")
      if (booking.getString("status") === "cancelled_by_passenger") {
        const user = tx.findRecordById("users", e.auth.id)
        result = h.bookingDto(booking)
        blocked = user.getBool("booking_blocked")
        const payment = h.firstByData(tx, "payments", "booking_id", booking.id)
        refundAmount = payment ? payment.getInt("amount") : 0
        return
      }
      if (["pending_driver", "awaiting_payment", "confirmed"].indexOf(
        booking.getString("status"),
      ) < 0) {
        throw h.businessError(
          "CANCELLATION_NOT_ALLOWED",
          "Эту заявку нельзя отменить.",
          409,
        )
      }
      const now = new DateTime()
      const wasPaid = booking.getString("payment_status") === "paid"
      booking.set("status", "cancelled_by_passenger")
      booking.set("cancelled_at", now)
      booking.set("cancel_reason", String(body.reason || "").slice(0, 500))
      if (wasPaid) booking.set("payment_status", "refund_requested")
      tx.save(booking)

      if (wasPaid) {
        const payment = h.firstByData(tx, "payments", "booking_id", booking.id)
        if (payment) {
          refundAmount = payment.getInt("amount")
          if (!h.firstByData(tx, "refunds", "payment_id", payment.id)) {
            tx.save(new Record(tx.findCollectionByNameOrId("refunds"), {
              payment_id: payment.id,
              booking_id: booking.id,
              status: "requested",
              amount: refundAmount,
              reason: booking.getString("cancel_reason"),
              requested_at: now,
            }))
          }
          payment.set("status", "refund_requested")
          tx.save(payment)
        }
      }

      const since = now.addDate(0, 0, -30).string()
      const cancellations = h.recordsByFilter(
        tx,
        "bookings",
        "passenger_id = {:passenger} && status = 'cancelled_by_passenger' && cancelled_at >= {:since}",
        "",
        10,
        { passenger: e.auth.id, since: since },
      )
      const user = tx.findRecordById("users", e.auth.id)
      if (cancellations.length >= 2) {
        user.set("booking_blocked", true)
        user.set(
          "booking_block_reason",
          "Две отмены бронирования за последние 30 дней",
        )
        tx.save(user)
      }
      blocked = user.getBool("booking_blocked")
      const trip = tx.findRecordById("trips", booking.getString("trip_id"))
      h.notify(
        tx,
        trip.getString("driver_id"),
        "booking_cancelled",
        "Бронь отменена",
        "Пассажир отменил бронирование.",
        { booking_id: booking.id },
      )
      result = h.bookingDto(booking)
    })
    return e.json(200, {
      booking: result,
      booking_blocked: blocked,
      refund_amount: refundAmount,
    })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))
