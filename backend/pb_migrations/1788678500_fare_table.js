/// <reference path="../pb_data/types.d.ts" />

// Fares move from a list of neighbouring legs to a price per pair of stops, and
// the commission becomes a percentage added on top of what the driver receives.
//
// The driver prices every pair by hand: a short leg is deliberately dearer per
// kilometre, so a fare must never be derived by adding shorter legs together.
migrate((app) => {
  const trips = app.findCollectionByNameOrId("trips")
  let hasFareTable = false
  for (const field of trips.fields) {
    if (field.name === "fare_table") hasFareTable = true
  }
  if (!hasFareTable) {
    trips.fields.add(new JSONField({ name: "fare_table", maxSize: 32768 }))
    app.save(trips)
  }

  const settings = app.findCollectionByNameOrId("app_settings")
  try {
    app.findFirstRecordByData("app_settings", "key", "commission_percent")
  } catch (_) {
    app.save(new Record(settings, { key: "commission_percent", value: 10 }))
  }

  // Backfill. The old list held the price of each neighbouring leg, and a
  // longer ride was sold as the sum of the legs it crossed — so that sum is
  // exactly what each pair used to cost. It is only a starting point: from now
  // on the driver prices every pair by hand.
  const records = app.findRecordsByFilter("trips", "id != ''", "", 500, 0)
  for (const trip of records) {
    // A JSON field comes back as raw bytes, so it has to be parsed before the
    // legs can be indexed.
    let legs = []
    try {
      const parsed = JSON.parse(String(trip.get("segment_prices") || "[]"))
      if (Array.isArray(parsed)) legs = parsed
    } catch (_) {
      legs = []
    }

    const stops = app.findRecordsByFilter(
      "trip_stops",
      "trip_id = {:trip}",
      "sort_order",
      100,
      0,
      { trip: trip.id },
    )
    const lastStop = stops.length - 1
    if (legs.length !== lastStop) legs = []

    const table = {}
    for (let from = 0; from < legs.length; from++) {
      let sum = 0
      for (let to = from + 1; to <= legs.length; to++) {
        const price = Number(legs[to - 1])
        if (!Number.isInteger(price) || price <= 0) break
        sum += price
        table[from + "-" + to] = sum
      }
    }

    const basePrice = trip.getInt("base_price")
    // The whole route always costs what the driver named for it.
    if (lastStop > 0 && basePrice > 0) table["0-" + lastStop] = basePrice
    trip.set("fare_table", table)

    // The stored price stays what the driver receives; the commission is now
    // charged on top of it instead of being carved out.
    trip.set("commission_amount", Math.round((basePrice * 10) / 100))
    trip.set("driver_amount", basePrice)
    app.save(trip)
  }
}, (app) => {
  try {
    app.delete(app.findFirstRecordByData("app_settings", "key", "commission_percent"))
  } catch (_) {}
  const trips = app.findCollectionByNameOrId("trips")
  for (const field of trips.fields) {
    if (field.name === "fare_table") {
      trips.fields.removeById(field.id)
      app.save(trips)
      break
    }
  }
})
