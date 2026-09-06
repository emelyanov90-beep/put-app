/// <reference path="../pb_data/types.d.ts" />

routerAdd("GET", "/api/app/complaints", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const records = h.recordsByFilter(
      e.app,
      "complaints",
      "author_id = {:user}",
      "-created_at",
      200,
      { user: e.auth.id },
    )
    return e.json(200, { items: records.map(h.complaintDto) })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))

routerAdd("POST", "/api/app/complaints", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    // Declared inside the handler: each hook call runs in a fresh VM, so
    // module-level bindings are not visible here.
    const subjects = ["trip", "driver", "passenger", "payment", "app", "other"]
    const body = h.bodyOf(e)
    const subject = String(body.subject || "other")
    if (subjects.indexOf(subject) < 0) {
      throw h.businessError("INVALID_COMPLAINT", "Неизвестная тема обращения.")
    }
    const text = String(body.text || "").trim()
    if (text.length < 10 || text.length > 2000) {
      throw h.businessError(
        "INVALID_COMPLAINT",
        "Опишите проблему подробнее: от 10 до 2000 символов.",
      )
    }

    const bookingId = String(body.booking_id || "")
    if (bookingId) {
      // A complaint may only point at a booking the author took part in.
      const booking = e.app.findRecordById("bookings", bookingId)
      const trip = e.app.findRecordById("trips", booking.getString("trip_id"))
      if (booking.getString("passenger_id") !== e.auth.id &&
          trip.getString("driver_id") !== e.auth.id) {
        throw h.businessError("FORBIDDEN", "Нет доступа к этому бронированию.", 403)
      }
    }

    const record = new Record(e.app.findCollectionByNameOrId("complaints"), {
      author_id: e.auth.id,
      booking_id: bookingId || null,
      subject: subject,
      text: text,
      status: "new",
      admin_comment: "",
    })
    e.app.save(record)
    return e.json(200, { complaint: h.complaintDto(record) })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))
