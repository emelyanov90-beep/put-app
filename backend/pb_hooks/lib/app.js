function bodyOf(e) {
  return e.requestInfo().body || {}
}

function businessError(code, message, status) {
  const error = new Error(code + "|" + message)
  error.businessStatus = status || 400
  return error
}

function writeError(e, error) {
  const raw = String(error && error.message ? error.message : error)
  const separator = raw.indexOf("|")
  if (separator > 0) {
    const code = raw.slice(0, separator).replace(/^Error:\s*/, "")
    if (/^[A-Z0-9_]+$/.test(code)) {
      return e.json(error.businessStatus || 400, {
        status: error.businessStatus || 400,
        code: code,
        message: raw.slice(separator + 1),
      })
    }
  }
  e.app.logger().error("application route failed", "error", raw)
  return e.json(500, {
    status: 500,
    code: "INTERNAL_ERROR",
    message: "Внутренняя ошибка сервера.",
  })
}

function normalizedPhone(value) {
  let digits = String(value || "").replace(/\D/g, "")
  if (digits.length === 11 && (digits[0] === "7" || digits[0] === "8")) {
    digits = digits.slice(1)
  }
  if (digits.length !== 10) {
    throw businessError("INVALID_PHONE", "Некорректный номер телефона.")
  }
  return "+7" + digits
}

function firstByData(app, collection, field, value) {
  try {
    return app.findFirstRecordByData(collection, field, value)
  } catch (_) {
    return null
  }
}

function recordsByFilter(app, collection, filter, sort, limit, params) {
  return app.findRecordsByFilter(
    collection,
    filter,
    sort || "",
    limit || 500,
    0,
    params || {},
  )
}

function requireOwnRecord(record, userId, field) {
  if (!record || record.getString(field) !== userId) {
    throw businessError("FORBIDDEN", "Недостаточно прав.", 403)
  }
}

function publicUserDto(record) {
  return {
    id: record.id,
    name: record.getString("name"),
    avatar: record.getString("avatar"),
    city_id: record.getString("city_id"),
    primary_role: record.getString("primary_role"),
    driver_enabled: record.getBool("driver_enabled"),
    rating_avg: record.get("rating_avg") || null,
    reviews_count: record.getInt("reviews_count"),
  }
}

function ownUserDto(record) {
  const result = publicUserDto(record)
  result.phone = record.getString("phone")
  result.booking_blocked = record.getBool("booking_blocked")
  result.profile_completed = record.getBool("profile_completed")
  return result
}

function bookingDto(record) {
  return {
    id: record.id,
    trip_id: record.getString("trip_id"),
    passenger_id: record.getString("passenger_id"),
    booking_kind: record.getString("booking_kind"),
    status: record.getString("status"),
    payment_status: record.getString("payment_status"),
    seat_count: record.getInt("seat_count"),
    amount: record.getInt("amount"),
    commission_amount: record.getInt("commission_amount"),
    driver_amount: record.getInt("driver_amount"),
    currency: record.getString("currency"),
    created: record.getDateTime("created_at").string(),
    updated: record.getDateTime("updated_at").string(),
  }
}

function reservedSeats(app, tripId) {
  const records = recordsByFilter(
    app,
    "bookings",
    "trip_id = {:trip} && (status = 'awaiting_payment' || status = 'confirmed')",
    "",
    500,
    { trip: tripId },
  )
  let total = 0
  for (const record of records) total += record.getInt("seat_count")
  return total
}

function activeBooking(app, passengerId, tripId) {
  const records = recordsByFilter(
    app,
    "bookings",
    "passenger_id = {:passenger} && trip_id = {:trip} && (status = 'pending_driver' || status = 'awaiting_payment' || status = 'confirmed')",
    "-created_at",
    1,
    { passenger: passengerId, trip: tripId },
  )
  return records.length ? records[0] : null
}

function ensureSeats(app, trip, requested) {
  if (requested < 1 || reservedSeats(app, trip.id) + requested > trip.getInt("seat_capacity")) {
    throw businessError("NO_SEATS", "Свободных мест недостаточно.", 409)
  }
}

function notify(app, userId, type, title, message, payload) {
  const record = new Record(app.findCollectionByNameOrId("notifications"), {
    user_id: userId,
    type: type,
    title: title,
    body: message || "",
    payload: payload || {},
  })
  app.save(record)
}

function ensureChat(app, booking, trip) {
  const existing = firstByData(app, "chats", "booking_id", booking.id)
  if (existing) return existing
  const chat = new Record(app.findCollectionByNameOrId("chats"), {
    booking_id: booking.id,
    passenger_id: booking.getString("passenger_id"),
    driver_id: trip.getString("driver_id"),
  })
  app.save(chat)
  return chat
}

function driverDecisionHandler(e, approved) {
  try {
    const bookingId = e.request.pathValue("id")
    let result
    e.app.runInTransaction((tx) => {
      const booking = tx.findRecordById("bookings", bookingId)
      const trip = tx.findRecordById("trips", booking.getString("trip_id"))
      requireOwnRecord(trip, e.auth.id, "driver_id")
      if (booking.getString("status") !== "pending_driver") {
        const desired = approved ? "awaiting_payment" : "rejected_by_driver"
        if (booking.getString("status") === desired) {
          result = bookingDto(booking)
          return
        }
        throw businessError(
          "INVALID_BOOKING_STATUS",
          "Заявка уже обработана.",
          409,
        )
      }
      if (approved) ensureSeats(tx, trip, booking.getInt("seat_count"))
      booking.set("status", approved ? "awaiting_payment" : "rejected_by_driver")
      booking.set("driver_decided_at", new DateTime())
      tx.save(booking)
      notify(
        tx,
        booking.getString("passenger_id"),
        approved ? "booking_approved" : "booking_rejected",
        approved ? "Заявка одобрена" : "Заявка отклонена",
        approved ? "Теперь можно оплатить комиссию." : "Водитель отклонил заявку.",
        { booking_id: booking.id },
      )
      result = bookingDto(booking)
    })
    return e.json(200, { booking: result })
  } catch (error) {
    return writeError(e, error)
  }
}

function tripDto(app, trip) {
  const stops = recordsByFilter(
    app,
    "trip_stops",
    "trip_id = {:trip}",
    "sort_order",
    100,
    { trip: trip.id },
  ).map((stop) => {
    const cityId = stop.getString("city_id")
    let cityName = ""
    if (cityId) cityName = app.findRecordById("cities", cityId).getString("name")
    return {
      id: stop.id,
      sort_order: stop.getInt("sort_order"),
      stop_type: stop.getString("stop_type"),
      address: stop.getString("address"),
      city_id: cityId,
      city_name: cityName,
      latitude: stop.getFloat("latitude"),
      longitude: stop.getFloat("longitude"),
      planned_at: stop.getDateTime("planned_at").string(),
    }
  })
  const driver = app.findRecordById("users", trip.getString("driver_id"))
  const vehicle = app.findRecordById("vehicles", trip.getString("vehicle_id"))
  const serviceOffers = recordsByFilter(
    app,
    "trip_extra_services",
    "trip_id = {:trip}",
    "",
    100,
    { trip: trip.id },
  ).map((row) => ({
    code: app.findRecordById("extra_services", row.getString("service_id")).getString("code"),
    price: row.getInt("price"),
    details: row.get("details") || {},
  }))
  return {
    id: trip.id,
    driver: publicUserDto(driver),
    vehicle: {
      id: vehicle.id,
      transport_type: vehicle.getString("transport_type"),
      brand: vehicle.getString("brand"),
      model: vehicle.getString("model"),
      plate_number: vehicle.getString("plate_number"),
      color: vehicle.getString("color"),
      year: vehicle.getInt("year"),
      seat_count: vehicle.getInt("seat_count"),
      photo: vehicle.getString("photo"),
      verification_status: vehicle.getString("verification_status"),
    },
    transport_type: trip.getString("transport_type"),
    status: trip.getString("status"),
    booking_mode: trip.getString("booking_mode"),
    accepting_bookings: trip.getBool("accepting_bookings"),
    departure_at: trip.getDateTime("departure_at").string(),
    arrival_at: trip.getDateTime("arrival_at").string(),
    seat_capacity: trip.getInt("seat_capacity"),
    available_seats: Math.max(0, trip.getInt("seat_capacity") - reservedSeats(app, trip.id)),
    // `base_price` is what the driver receives; `passenger_price` is what the
    // passenger pays for the whole route, commission included.
    base_price: trip.getInt("base_price"),
    passenger_price: trip.getInt("base_price") + trip.getInt("commission_amount"),
    minimum_boarding_price: trip.getInt("minimum_boarding_price"),
    commission_amount: trip.getInt("commission_amount"),
    driver_amount: trip.getInt("driver_amount"),
    currency: trip.getString("currency"),
    fare_table: tripFareTable(trip),
    paired_trip_id: trip.getString("paired_trip_id"),
    published_at: trip.getDateTime("published_at").string(),
    stops: stops,
    services: serviceOffers.map((offer) => offer.code),
    service_offers: serviceOffers,
  }
}

function validatedStops(body) {
  const stops = Array.isArray(body.stops) ? body.stops : []
  if (stops.length < 2) {
    throw businessError("INVALID_ROUTE", "Маршрут должен содержать минимум две точки.")
  }
  return stops.map((stop, index) => {
    const address = String(stop.address || "").trim()
    if (address.length < 2) {
      throw businessError("INVALID_ROUTE", "Заполните адрес каждой точки.")
    }
    return {
      sort_order: index,
      stop_type: index === 0
        ? "origin"
        : (index === stops.length - 1 ? "destination" : "intermediate"),
      address: address,
      city_id: String(stop.city_id || ""),
      latitude: Number(stop.latitude || 0),
      longitude: Number(stop.longitude || 0),
      planned_at: stop.planned_at ? String(stop.planned_at) : "",
    }
  })
}

function replaceTripServices(app, trip, body) {
  const old = recordsByFilter(app, "trip_extra_services", "trip_id = {:trip}", "", 100, { trip: trip.id })
  for (const record of old) app.delete(record)
  const codes = Array.isArray(body.extra_service_codes)
    ? body.extra_service_codes.map((code) => String(code))
    : []
  if (body.parcel && body.parcel.enabled && codes.indexOf("parcel") < 0) {
    codes.push("parcel")
  }
  for (const code of codes) {
    const service = firstByData(app, "extra_services", "code", code)
    if (!service || !service.getBool("is_active")) {
      throw businessError("INVALID_EXTRA", "Выбрана недоступная дополнительная услуга.")
    }
    const prices = settingValue(app, "extra_service_prices", {
      child_seat: 150,
      luggage: 150,
      pets: 150,
    })
    let price = Number(prices[code] || 0)
    let details = {}
    if (code === "parcel") {
      const parcel = body.parcel || {}
      const sizes = Array.isArray(parcel.sizes) ? parcel.sizes : []
      const specs = settingValue(app, "parcel_size_specs", {})
      const allowed = {
        small: Number((specs.small || {}).price_rub || 150),
        medium: Number((specs.medium || {}).price_rub || 250),
        large: Number((specs.large || {}).price_rub || 350),
      }
      const priceBySize = {}
      for (const size of sizes) {
        if (allowed[size] !== undefined) priceBySize[size] = allowed[size]
      }
      if (!Object.keys(priceBySize).length) {
        throw businessError("INVALID_EXTRA", "Выберите допустимый размер посылки.")
      }
      price = Math.max(...Object.values(priceBySize))
      details = {
        price_by_size: priceBySize,
        allowed_without_passenger: parcel.allowed_without_passenger === true,
      }
    }
    app.save(new Record(app.findCollectionByNameOrId("trip_extra_services"), {
      trip_id: trip.id,
      service_id: service.id,
      price: price,
      details: details,
    }))
  }
}

function routeSignature(app, trip) {
  const stops = recordsByFilter(app, "trip_stops", "trip_id = {:trip}", "sort_order", 100, { trip: trip.id })
  return stops.map((stop) => stop.getString("address").trim().toLowerCase()).join("|")
}

function duplicateAcceptingTrip(app, trip) {
  const candidates = recordsByFilter(
    app,
    "trips",
    "id != {:id} && status = 'published' && accepting_bookings = true && departure_at = {:departure}",
    "published_at",
    100,
    { id: trip.id, departure: trip.getDateTime("departure_at").string() },
  )
  const signature = routeSignature(app, trip)
  return candidates.find((candidate) => routeSignature(app, candidate) === signature) || null
}

function promoteDuplicate(app, trip) {
  const signature = routeSignature(app, trip)
  const candidates = recordsByFilter(
    app,
    "trips",
    "id != {:id} && status = 'published' && departure_at = {:departure}",
    "published_at",
    100,
    { id: trip.id, departure: trip.getDateTime("departure_at").string() },
  ).filter((candidate) => routeSignature(app, candidate) === signature)
  if (candidates.some((candidate) => candidate.getBool("accepting_bookings"))) return
  if (candidates.length) {
    candidates[0].set("accepting_bookings", true)
    app.save(candidates[0])
  }
}

function replaceTripStops(app, trip, stops) {
  const old = recordsByFilter(app, "trip_stops", "trip_id = {:trip}", "", 100, { trip: trip.id })
  for (const record of old) app.delete(record)
  for (const stop of stops) {
    app.save(new Record(app.findCollectionByNameOrId("trip_stops"), {
      trip_id: trip.id,
      sort_order: stop.sort_order,
      stop_type: stop.stop_type,
      address: stop.address,
      city_id: stop.city_id,
      latitude: stop.latitude,
      longitude: stop.longitude,
      planned_at: stop.planned_at,
    }))
  }
}

/// Commission rate in percent, from `app_settings.commission_percent`.
function commissionPercent(app) {
  const setting = firstByData(app, "app_settings", "key", "commission_percent")
  const value = setting ? Number(setting.get("value")) : 10
  if (!Number.isFinite(value) || value < 0 || value > 100) return 10
  return value
}

/// Splits a fare the driver entered into what they keep and what is added.
///
/// The driver names the amount they receive and the commission goes on top of
/// it, so a 1000 fare at 10 % means the passenger pays 1100. The stored
/// `total_price` is the passenger amount, keeping `driver_amount =
/// total_price - commission_amount` true.
function tripAmounts(app, driverFare) {
  const fare = Math.max(0, Math.round(driverFare))
  const monetization = firstByData(app, "app_settings", "key", "monetization_enabled")
  if (monetization && monetization.get("value") === false) {
    return { commission: 0, driver: fare, total: fare }
  }
  const commission = Math.round((fare * commissionPercent(app)) / 100)
  return { commission: commission, driver: fare, total: fare + commission }
}

/// Fare of the leg between two stop positions, as the driver priced it.
///
/// Each pair carries its own price: a short leg is deliberately dearer per
/// kilometre, so a fare is never derived by adding shorter legs together. An
/// unpriced pair is not sold.
function legFare(trip, fromIndex, toIndex) {
  let table = trip.get("fare_table")
  if (typeof table !== "object" || table === null || Array.isArray(table)) {
    try {
      table = JSON.parse(String(table || "{}"))
    } catch (_) {
      table = {}
    }
  }
  const price = table[fromIndex + "-" + toIndex]
  if (price === undefined || price === null) return null
  const fare = Number(price)
  if (!Number.isInteger(fare) || fare <= 0) return null
  const minimum = trip.getInt("minimum_boarding_price")
  return minimum > fare ? minimum : fare
}

function settingValue(app, key, fallback) {
  const record = firstByData(app, "app_settings", "key", key)
  return record ? record.get("value") : fallback
}

function runtimeConfigHandler(e) {
  try {
    return e.json(200, {
      monetization_enabled: settingValue(e.app, "monetization_enabled", true),
      commission_percent: commissionPercent(e.app),
      trip_publication_limits: settingValue(e.app, "trip_publication_limits", {
        driver_trip_limit_per_day: 2,
        driver_trip_limit_per_week: 10,
        outbound_limit_per_pair: 1,
        return_limit_per_pair: 1,
      }),
      extra_service_prices: settingValue(e.app, "extra_service_prices", {
        child_seat: 150,
        luggage: 150,
        pets: 150,
      }),
      parcel_size_specs: settingValue(e.app, "parcel_size_specs", {}),
    })
  } catch (error) {
    return writeError(e, error)
  }
}

function applyTripBody(app, trip, body) {
  const vehicle = app.findRecordById("vehicles", String(body.vehicle_id || trip.getString("vehicle_id")))
  requireOwnRecord(vehicle, trip.getString("driver_id"), "owner_id")
  const departure = String(body.departure_at || trip.getDateTime("departure_at").string())
  const arrival = String(body.arrival_at || trip.getDateTime("arrival_at").string())
  if (!departure || !arrival || new DateTime(arrival).before(new DateTime(departure))) {
    throw businessError("INVALID_TRIP_TIME", "Время прибытия должно быть позже отправления.")
  }
  const capacity = Number(body.seat_capacity || trip.getInt("seat_capacity"))
  const basePrice = Number(body.base_price || trip.getInt("base_price"))
  if (!Number.isInteger(capacity) || capacity < 1 || capacity > vehicle.getInt("seat_count")) {
    throw businessError("INVALID_CAPACITY", "Некорректное количество мест.")
  }
  if (capacity < reservedSeats(app, trip.id)) {
    throw businessError("NO_SEATS", "Нельзя убрать уже забронированные места.", 409)
  }
  if (!Number.isInteger(basePrice) || basePrice < 1) {
    throw businessError("INVALID_PRICE", "Некорректная стоимость поездки.")
  }
  const amounts = tripAmounts(app, basePrice)
  trip.set("vehicle_id", vehicle.id)
  trip.set("transport_type", vehicle.getString("transport_type"))
  trip.set("booking_mode", String(body.booking_mode || trip.getString("booking_mode") || "standard"))
  trip.set("departure_at", departure)
  trip.set("arrival_at", arrival)
  trip.set("seat_capacity", capacity)
  trip.set("base_price", basePrice)
  trip.set("minimum_boarding_price", Number(body.minimum_boarding_price || 0))
  trip.set("commission_amount", amounts.commission)
  trip.set("driver_amount", amounts.driver)
  trip.set("currency", "RUB")
  // The stops of a brand-new trip are written after this call, so the incoming
  // body is the only place the route length can be read from there.
  const stopCount = Array.isArray(body.stops) && body.stops.length
    ? body.stops.length
    : stopCountOf(app, trip)
  trip.set("fare_table", normalizedFareTable(body.fare_table, basePrice, stopCount))
  if (body.paired_trip_id !== undefined) trip.set("paired_trip_id", String(body.paired_trip_id || ""))
  if (body.accepting_bookings !== undefined) {
    trip.set("accepting_bookings", body.accepting_bookings === true)
  }
  return vehicle
}

function criticalTripBodyChanged(app, trip, body) {
  if (body.vehicle_id !== undefined && String(body.vehicle_id) !== trip.getString("vehicle_id")) return true
  if (body.booking_mode !== undefined && String(body.booking_mode) !== trip.getString("booking_mode")) return true
  if (body.base_price !== undefined && Number(body.base_price) !== trip.getInt("base_price")) return true
  if (body.departure_at !== undefined && new DateTime(String(body.departure_at)).string() !== trip.getDateTime("departure_at").string()) return true
  if (body.arrival_at !== undefined && new DateTime(String(body.arrival_at)).string() !== trip.getDateTime("arrival_at").string()) return true
  if (body.stops !== undefined) {
    const incoming = validatedStops(body).map((stop) => stop.address.trim().toLowerCase()).join("|")
    if (incoming !== routeSignature(app, trip)) return true
  }
  return false
}

function createTripHandler(e) {
  try {
    const body = bodyOf(e)
    const stops = validatedStops(body)
    let result
    e.app.runInTransaction((tx) => {
      const trip = new Record(tx.findCollectionByNameOrId("trips"), {
        driver_id: e.auth.id,
        vehicle_id: String(body.vehicle_id || ""),
        transport_type: "car",
        status: "draft",
        booking_mode: String(body.booking_mode || "standard"),
        accepting_bookings: false,
        departure_at: String(body.departure_at || ""),
        arrival_at: String(body.arrival_at || ""),
        seat_capacity: Number(body.seat_capacity || 1),
        base_price: Number(body.base_price || 0),
        currency: "RUB",
      })
      applyTripBody(tx, trip, body)
      tx.save(trip)
      replaceTripStops(tx, trip, stops)
      if (body.extra_service_codes !== undefined || body.parcel !== undefined) {
        replaceTripServices(tx, trip, body)
      }
      result = tripDto(tx, trip)
    })
    return e.json(200, { trip: result })
  } catch (error) {
    return writeError(e, error)
  }
}

function patchTripHandler(e) {
  try {
    const body = bodyOf(e)
    let result
    e.app.runInTransaction((tx) => {
      const trip = tx.findRecordById("trips", e.request.pathValue("id"))
      requireOwnRecord(trip, e.auth.id, "driver_id")
      if (["draft", "published"].indexOf(trip.getString("status")) < 0) {
        throw businessError("TRIP_NOT_EDITABLE", "Поездку нельзя редактировать.", 409)
      }
      if (trip.getString("status") === "published") {
        const reserved = recordsByFilter(
          tx,
          "bookings",
          "trip_id = {:trip} && (status = 'awaiting_payment' || status = 'confirmed')",
          "",
          1,
          { trip: trip.id },
        )
        if (reserved.length && criticalTripBodyChanged(tx, trip, body)) {
          throw businessError("TRIP_HAS_BOOKINGS", "Критичные параметры поездки уже нельзя изменить.", 409)
        }
      }
      applyTripBody(tx, trip, body)
      tx.save(trip)
      if (body.stops !== undefined) replaceTripStops(tx, trip, validatedStops(body))
      if (body.extra_service_codes !== undefined || body.parcel !== undefined) {
        replaceTripServices(tx, trip, body)
      }
      result = tripDto(tx, trip)
    })
    return e.json(200, { trip: result })
  } catch (error) {
    return writeError(e, error)
  }
}

function publishTripHandler(e) {
  try {
    let result
    e.app.runInTransaction((tx) => {
      const trip = tx.findRecordById("trips", e.request.pathValue("id"))
      requireOwnRecord(trip, e.auth.id, "driver_id")
      if (trip.getString("status") === "published") {
        result = tripDto(tx, trip)
        return
      }
      if (trip.getString("status") !== "draft") {
        throw businessError("TRIP_NOT_PUBLISHABLE", "Поездку нельзя опубликовать.", 409)
      }
      const user = tx.findRecordById("users", e.auth.id)
      if (!user.getBool("profile_completed")) {
        throw businessError("PROFILE_INCOMPLETE", "Сначала заполните профиль.", 409)
      }
      const vehicle = tx.findRecordById("vehicles", trip.getString("vehicle_id"))
      requireOwnRecord(vehicle, e.auth.id, "owner_id")
      if (vehicle.getString("verification_status") !== "approved") {
        throw businessError("VEHICLE_NOT_APPROVED", "Автомобиль не подтверждён.", 409)
      }
      if (trip.getDateTime("departure_at").before(new DateTime())) {
        throw businessError("TRIP_IN_PAST", "Дата поездки уже прошла.", 409)
      }
      const stops = recordsByFilter(tx, "trip_stops", "trip_id = {:trip}", "sort_order", 100, { trip: trip.id })
      if (stops.length < 2) throw businessError("INVALID_ROUTE", "Маршрут не заполнен.")
      const now = new DateTime()
      const limits = settingValue(tx, "trip_publication_limits", {})
      const dayLimit = Number(limits.driver_trip_limit_per_day || 2)
      const weekLimit = Number(limits.driver_trip_limit_per_week || 10)
      const outboundLimit = Number(limits.outbound_limit_per_pair || 1)
      const returnLimit = Number(limits.return_limit_per_pair || 1)
      const startOfDay = now.string().slice(0, 10) + " 00:00:00.000Z"
      const dayTrips = recordsByFilter(tx, "trips", "driver_id = {:driver} && status = 'published' && published_at >= {:since}", "", 100, { driver: e.auth.id, since: startOfDay })
      const weekTrips = recordsByFilter(tx, "trips", "driver_id = {:driver} && status = 'published' && published_at >= {:since}", "", 100, { driver: e.auth.id, since: now.addDate(0, 0, -7).string() })
      const isReturn = trip.getString("paired_trip_id") !== ""
      const directionCount = dayTrips.filter((item) => (item.getString("paired_trip_id") !== "") === isReturn).length
      const directionLimit = isReturn ? returnLimit : outboundLimit
      if (dayTrips.length >= dayLimit || weekTrips.length >= weekLimit || directionCount >= directionLimit) {
        throw businessError("PUBLICATION_LIMIT", "Превышен лимит публикаций.", 409)
      }
      trip.set("status", "published")
      trip.set("accepting_bookings", !duplicateAcceptingTrip(tx, trip))
      trip.set("published_at", now)
      tx.save(trip)
      notify(tx, e.auth.id, "trip_published", "Поездка опубликована", "Поездка появилась в поиске.", { trip_id: trip.id })
      result = tripDto(tx, trip)
    })
    return e.json(200, { trip: result })
  } catch (error) {
    return writeError(e, error)
  }
}

function listOwnTripsHandler(e) {
  try {
    const trips = recordsByFilter(e.app, "trips", "driver_id = {:driver}", "-created_at", 200, { driver: e.auth.id })
    return e.json(200, {
      items: trips.map((trip) => {
        const value = tripDto(e.app, trip)
        value.passenger_bookings = recordsByFilter(
          e.app,
          "bookings",
          "trip_id = {:trip} && status != 'rejected_by_driver'",
          "created_at",
          200,
          { trip: trip.id },
        ).map((booking) => {
          const pickup = e.app.findRecordById("trip_stops", booking.getString("pickup_stop_id"))
          const dropoff = e.app.findRecordById("trip_stops", booking.getString("dropoff_stop_id"))
          return {
            booking: bookingDto(booking),
            passenger: publicUserDto(e.app.findRecordById("users", booking.getString("passenger_id"))),
            pickup_address: pickup.getString("address"),
            dropoff_address: dropoff.getString("address"),
          }
        })
        return value
      }),
    })
  } catch (error) {
    return writeError(e, error)
  }
}

function cancelTripHandler(e) {
  try {
    let result
    e.app.runInTransaction((tx) => {
      const trip = tx.findRecordById("trips", e.request.pathValue("id"))
      requireOwnRecord(trip, e.auth.id, "driver_id")
      if (trip.getString("status") === "cancelled") {
        result = tripDto(tx, trip)
        return
      }
      if (["draft", "published"].indexOf(trip.getString("status")) < 0) {
        throw businessError("TRIP_NOT_CANCELLABLE", "Поездку нельзя отменить.", 409)
      }
      trip.set("status", "cancelled")
      trip.set("accepting_bookings", false)
      tx.save(trip)
      const bookings = recordsByFilter(
        tx,
        "bookings",
        "trip_id = {:trip} && (status = 'pending_driver' || status = 'awaiting_payment' || status = 'confirmed')",
        "",
        200,
        { trip: trip.id },
      )
      for (const booking of bookings) {
        const wasPaid = booking.getString("payment_status") === "paid"
        booking.set("status", "cancelled_by_driver")
        booking.set("cancelled_at", new DateTime())
        if (wasPaid) booking.set("payment_status", "refund_requested")
        tx.save(booking)
        if (wasPaid) {
          const payment = firstByData(tx, "payments", "booking_id", booking.id)
          if (payment && !firstByData(tx, "refunds", "payment_id", payment.id)) {
            tx.save(new Record(tx.findCollectionByNameOrId("refunds"), {
              payment_id: payment.id,
              booking_id: booking.id,
              status: "requested",
              amount: payment.getInt("amount"),
              reason: "Поездка отменена водителем",
              requested_at: new DateTime(),
            }))
            payment.set("status", "refund_requested")
            tx.save(payment)
          }
        }
        notify(tx, booking.getString("passenger_id"), "trip_cancelled", "Поездка отменена", "Водитель отменил поездку.", { trip_id: trip.id })
      }
      promoteDuplicate(tx, trip)
      result = tripDto(tx, trip)
    })
    return e.json(200, { trip: result })
  } catch (error) {
    return writeError(e, error)
  }
}

function searchTripsHandler(e) {
  try {
    const query = e.requestInfo().query || {}
    const records = recordsByFilter(e.app, "trips", "status = 'published' && departure_at > @now", "departure_at", 100, {})
    let trips = records.map((trip) => tripDto(e.app, trip))
    if (query.from_city_id) {
      trips = trips.filter((trip) => trip.stops.length && trip.stops[0].city_id === query.from_city_id)
    }
    if (query.to_city_id) {
      trips = trips.filter((trip) => trip.stops.length && trip.stops[trip.stops.length - 1].city_id === query.to_city_id)
    }
    if (query.transport_type) trips = trips.filter((trip) => trip.transport_type === query.transport_type)
    return e.json(200, { items: trips, totalItems: trips.length })
  } catch (error) {
    return writeError(e, error)
  }
}

function getTripHandler(e) {
  try {
    const trip = e.app.findRecordById("trips", e.request.pathValue("id"))
    if (trip.getString("status") !== "published" && trip.getString("driver_id") !== e.auth.id) {
      throw businessError("FORBIDDEN", "Поездка недоступна.", 403)
    }
    return e.json(200, { trip: tripDto(e.app, trip) })
  } catch (error) {
    return writeError(e, error)
  }
}

function vehicleDto(record, includeDocument) {
  const result = {
    id: record.id,
    transport_type: record.getString("transport_type"),
    brand: record.getString("brand"),
    model: record.getString("model"),
    plate_number: record.getString("plate_number"),
    color: record.getString("color"),
    year: record.getInt("year"),
    seat_count: record.getInt("seat_count"),
    photo: record.getString("photo"),
    verification_status: record.getString("verification_status"),
  }
  if (includeDocument) result.registration_document = record.getString("registration_document")
  return result
}

function applyVehicleBody(record, body) {
  const fields = [
    "transport_type",
    "brand",
    "model",
    "plate_number",
    "color",
    "year",
    "seat_count",
  ]
  for (const field of fields) {
    if (body[field] !== undefined) record.set(field, body[field])
  }
}

function createVehicleHandler(e) {
  try {
    const body = bodyOf(e)
    const record = new Record(e.app.findCollectionByNameOrId("vehicles"), {
      owner_id: e.auth.id,
      verification_status: "draft",
    })
    applyVehicleBody(record, body)
    e.app.save(record)
    return e.json(200, { vehicle: vehicleDto(record, true) })
  } catch (error) {
    return writeError(e, error)
  }
}

function patchVehicleHandler(e) {
  try {
    const body = bodyOf(e)
    const record = e.app.findRecordById("vehicles", e.request.pathValue("id"))
    requireOwnRecord(record, e.auth.id, "owner_id")
    applyVehicleBody(record, body)
    if (record.getString("verification_status") !== "draft") {
      record.set("verification_status", "draft")
      record.set("verified_at", "")
      record.set("verification_comment", "")
    }
    e.app.save(record)
    return e.json(200, { vehicle: vehicleDto(record, true) })
  } catch (error) {
    return writeError(e, error)
  }
}

function submitVehicleHandler(e) {
  try {
    const record = e.app.findRecordById("vehicles", e.request.pathValue("id"))
    requireOwnRecord(record, e.auth.id, "owner_id")
    if (!record.getString("registration_document")) {
      throw businessError("DOCUMENT_REQUIRED", "Загрузите СТС перед отправкой.", 409)
    }
    if (record.getString("verification_status") === "approved") {
      return e.json(200, { vehicle: vehicleDto(record, true) })
    }
    record.set("verification_status", "pending")
    record.set("verification_comment", "")
    record.set("verified_at", "")
    e.app.save(record)
    notify(e.app, e.auth.id, "vehicle_submitted", "Автомобиль отправлен", "Документы отправлены на проверку.", { vehicle_id: record.id })
    return e.json(200, { vehicle: vehicleDto(record, true) })
  } catch (error) {
    return writeError(e, error)
  }
}

function listVehiclesHandler(e) {
  try {
    const records = recordsByFilter(e.app, "vehicles", "owner_id = {:owner}", "-created_at", 100, { owner: e.auth.id })
    return e.json(200, { items: records.map((record) => vehicleDto(record, true)) })
  } catch (error) {
    return writeError(e, error)
  }
}

function createReturnTripHandler(e) {
  try {
    const body = bodyOf(e)
    let result
    e.app.runInTransaction((tx) => {
      const source = tx.findRecordById("trips", e.request.pathValue("id"))
      requireOwnRecord(source, e.auth.id, "driver_id")
      const sourceStops = recordsByFilter(tx, "trip_stops", "trip_id = {:trip}", "-sort_order", 100, { trip: source.id })
      if (sourceStops.length < 2) throw businessError("INVALID_ROUTE", "Исходный маршрут не заполнен.")
      const departure = String(body.departure_at || "")
      const arrival = String(body.arrival_at || "")
      if (!departure || !arrival) throw businessError("INVALID_TRIP_TIME", "Укажите дату обратной поездки.")
      const trip = new Record(tx.findCollectionByNameOrId("trips"), {
        driver_id: e.auth.id,
        vehicle_id: source.getString("vehicle_id"),
        transport_type: source.getString("transport_type"),
        status: "draft",
        booking_mode: source.getString("booking_mode"),
        accepting_bookings: false,
        departure_at: departure,
        arrival_at: arrival,
        seat_capacity: source.getInt("seat_capacity"),
        base_price: source.getInt("base_price"),
        minimum_boarding_price: source.getInt("minimum_boarding_price"),
        commission_amount: source.getInt("commission_amount"),
        driver_amount: source.getInt("driver_amount"),
        currency: source.getString("currency"),
        fare_table: mirroredFareTable(source, sourceStops.length),
        paired_trip_id: source.id,
      })
      tx.save(trip)
      replaceTripStops(tx, trip, sourceStops.map((stop, index) => ({
        sort_order: index,
        stop_type: index === 0 ? "origin" : (index === sourceStops.length - 1 ? "destination" : "intermediate"),
        address: stop.getString("address"),
        city_id: stop.getString("city_id"),
        latitude: stop.getFloat("latitude"),
        longitude: stop.getFloat("longitude"),
        planned_at: "",
      })))
      const sourceServices = recordsByFilter(tx, "trip_extra_services", "trip_id = {:trip}", "", 100, { trip: source.id })
      for (const service of sourceServices) {
        tx.save(new Record(tx.findCollectionByNameOrId("trip_extra_services"), {
          trip_id: trip.id,
          service_id: service.getString("service_id"),
          price: service.getInt("price"),
          details: service.get("details") || {},
        }))
      }
      result = tripDto(tx, trip)
    })
    return e.json(200, { trip: result })
  } catch (error) {
    return writeError(e, error)
  }
}

function messageDto(record) {
  return {
    id: record.id,
    chat_id: record.getString("chat_id"),
    sender_id: record.getString("sender_id"),
    text: record.getString("text"),
    client_message_id: record.getString("client_message_id"),
    read_at: record.getDateTime("read_at").string(),
    created_at: record.getDateTime("created_at").string(),
  }
}

function sendMessageHandler(e) {
  try {
    const body = bodyOf(e)
    const chat = e.app.findRecordById("chats", e.request.pathValue("id"))
    if (chat.getString("passenger_id") !== e.auth.id &&
        chat.getString("driver_id") !== e.auth.id) {
      throw businessError("FORBIDDEN", "Чат недоступен.", 403)
    }
    const text = String(body.text || "").trim()
    const clientId = String(body.client_message_id || "")
    if (!text || text.length > 3000 || clientId.length < 8) {
      throw businessError("INVALID_MESSAGE", "Сообщение не заполнено.")
    }
    const existing = recordsByFilter(
      e.app,
      "messages",
      "sender_id = {:sender} && client_message_id = {:client}",
      "",
      1,
      { sender: e.auth.id, client: clientId },
    )
    if (existing.length) return e.json(200, { message: messageDto(existing[0]) })
    const now = new DateTime()
    const message = new Record(e.app.findCollectionByNameOrId("messages"), {
      chat_id: chat.id,
      sender_id: e.auth.id,
      text: text,
      client_message_id: clientId,
    })
    e.app.save(message)
    chat.set("last_message_at", now)
    e.app.save(chat)
    const recipient = chat.getString("passenger_id") === e.auth.id
      ? chat.getString("driver_id")
      : chat.getString("passenger_id")
    notify(e.app, recipient, "message_received", "Новое сообщение", "У вас новое сообщение.", { chat_id: chat.id })
    return e.json(200, { message: messageDto(message) })
  } catch (error) {
    return writeError(e, error)
  }
}

function listOwnBookingsHandler(e) {
  try {
    const records = recordsByFilter(
      e.app,
      "bookings",
      "passenger_id = {:passenger}",
      "-created_at",
      200,
      { passenger: e.auth.id },
    )
    return e.json(200, {
      items: records.map((booking) => ({
        booking: bookingDto(booking),
        trip: tripDto(
          e.app,
          e.app.findRecordById("trips", booking.getString("trip_id")),
        ),
      })),
    })
  } catch (error) {
    return writeError(e, error)
  }
}

function listOwnChatsHandler(e) {
  try {
    const chats = recordsByFilter(
      e.app,
      "chats",
      "passenger_id = {:user} || driver_id = {:user}",
      "-last_message_at",
      200,
      { user: e.auth.id },
    )
    return e.json(200, {
      items: chats.map((chat) => {
        const peerId = chat.getString("passenger_id") === e.auth.id
          ? chat.getString("driver_id")
          : chat.getString("passenger_id")
        const booking = e.app.findRecordById("bookings", chat.getString("booking_id"))
        const messages = recordsByFilter(e.app, "messages", "chat_id = {:chat}", "created_at,id", 500, { chat: chat.id })
        return {
          id: chat.id,
          booking_id: booking.id,
          trip_id: booking.getString("trip_id"),
          peer: publicUserDto(e.app.findRecordById("users", peerId)),
          messages: messages.map(messageDto),
        }
      }),
    })
  } catch (error) {
    return writeError(e, error)
  }
}

const PARCEL_SIZE_KEYS = { S: "small", M: "medium", L: "large" }

/// Price of a parcel of `size` on `trip`, taken from the platform catalogue.
///
/// The driver only switches the «parcel» service on for a trip; the amount
/// always comes from `app_settings.parcel_size_specs`, never from the client.
function parcelPrice(app, trip, size) {
  const offers = recordsByFilter(
    app,
    "trip_extra_services",
    "trip_id = {:trip}",
    "",
    100,
    { trip: trip.id },
  )
  let offered = false
  for (const offer of offers) {
    const service = app.findRecordById("extra_services", offer.getString("service_id"))
    if (service.getString("code") === "parcel") {
      offered = true
      break
    }
  }
  if (!offered) {
    throw businessError("PARCEL_UNAVAILABLE", "Водитель не возит посылки на этой поездке.", 409)
  }

  const setting = firstByData(app, "app_settings", "key", "parcel_size_specs")
  // A JSON field comes back as raw bytes, so it has to be parsed before the
  // sizes can be indexed; `runtimeConfigHandler` only ever passes it through.
  let specs = null
  if (setting) {
    try {
      specs = JSON.parse(String(setting.get("value")))
    } catch (_) {
      specs = null
    }
  }
  const spec = specs ? specs[PARCEL_SIZE_KEYS[size]] : null
  const price = spec ? Number(spec.price_rub) : NaN
  if (!Number.isInteger(price) || price < 0) {
    throw businessError("PARCEL_UNAVAILABLE", "Стоимость посылки не настроена.", 409)
  }
  return price
}

function complaintDto(record) {
  return {
    id: record.id,
    subject: record.getString("subject"),
    text: record.getString("text"),
    status: record.getString("status"),
    admin_comment: record.getString("admin_comment"),
    booking_id: record.getString("booking_id"),
    created: record.getDateTime("created_at").string(),
  }
}

/// Fares of a trip as a plain object, whatever shape the JSON field returns.
function tripFareTable(trip) {
  const raw = trip.get("fare_table")
  if (typeof raw === "object" && raw !== null && !Array.isArray(raw)) return raw
  try {
    return JSON.parse(String(raw || "{}"))
  } catch (_) {
    return {}
  }
}

function stopCountOf(app, trip) {
  if (!trip.id) return 0
  return recordsByFilter(app, "trip_stops", "trip_id = {:trip}", "sort_order", 100, { trip: trip.id }).length
}

/// Keeps only well-formed legs and always stores the whole route at the price
/// the driver entered, so a published trip can never lack its main fare.
function normalizedFareTable(raw, basePrice, stopCount) {
  const source = typeof raw === "object" && raw !== null && !Array.isArray(raw) ? raw : {}
  const table = {}
  for (const key of Object.keys(source)) {
    const parts = String(key).split("-")
    if (parts.length !== 2) continue
    const from = Number(parts[0])
    const to = Number(parts[1])
    const price = Number(source[key])
    if (!Number.isInteger(from) || !Number.isInteger(to) || to <= from || from < 0) continue
    if (stopCount > 0 && to >= stopCount) continue
    if (!Number.isInteger(price) || price <= 0) continue
    table[from + "-" + to] = price
  }
  if (stopCount > 1) table["0-" + (stopCount - 1)] = basePrice
  return table
}

/// Fares of a trip running the other way round: «A → C» becomes «C → A» at the
/// same price.
function mirroredFareTable(source, stopCount) {
  const table = tripFareTable(source)
  const last = stopCount - 1
  const mirrored = {}
  for (const key of Object.keys(table)) {
    const parts = String(key).split("-")
    if (parts.length !== 2) continue
    const from = Number(parts[0])
    const to = Number(parts[1])
    if (!Number.isInteger(from) || !Number.isInteger(to)) continue
    mirrored[(last - to) + "-" + (last - from)] = table[key]
  }
  return mirrored
}

module.exports = {
  activeBooking,
  bodyOf,
  bookingDto,
  businessError,
  commissionPercent,
  complaintDto,
  driverDecisionHandler,
  cancelTripHandler,
  createTripHandler,
  createReturnTripHandler,
  createVehicleHandler,
  ensureChat,
  ensureSeats,
  legFare,
  firstByData,
  getTripHandler,
  listVehiclesHandler,
  listOwnTripsHandler,
  listOwnBookingsHandler,
  listOwnChatsHandler,
  messageDto,
  normalizedPhone,
  notify,
  ownUserDto,
  parcelPrice,
  publicUserDto,
  runtimeConfigHandler,
  patchTripHandler,
  patchVehicleHandler,
  publishTripHandler,
  recordsByFilter,
  requireOwnRecord,
  reservedSeats,
  searchTripsHandler,
  sendMessageHandler,
  tripDto,
  submitVehicleHandler,
  vehicleDto,
  writeError,
}
