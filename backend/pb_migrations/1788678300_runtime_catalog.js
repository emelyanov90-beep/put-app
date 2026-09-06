/// <reference path="../pb_data/types.d.ts" />

migrate((app) => {
  const collection = app.findCollectionByNameOrId("app_settings")
  const addIfMissing = (key, value) => {
    try {
      app.findFirstRecordByData("app_settings", "key", key)
    } catch (_) {
      app.save(new Record(collection, { key: key, value: value }))
    }
  }
  addIfMissing("extra_service_prices", {
    child_seat: 150,
    luggage: 150,
    pets: 150,
  })
  addIfMissing("parcel_size_specs", {
    small: {
      title: "Маленькая",
      dimensions: "до 30 × 20 × 15 см",
      max_weight_kg: 5,
      price_rub: 150,
    },
    medium: {
      title: "Средняя",
      dimensions: "до 50 × 40 × 30 см",
      max_weight_kg: 15,
      price_rub: 250,
    },
    large: {
      title: "Большая",
      dimensions: "до 80 × 60 × 50 см",
      max_weight_kg: 30,
      price_rub: 350,
    },
  })
}, (app) => {
  for (const key of ["extra_service_prices", "parcel_size_specs"]) {
    try {
      app.delete(app.findFirstRecordByData("app_settings", "key", key))
    } catch (_) {}
  }
})
