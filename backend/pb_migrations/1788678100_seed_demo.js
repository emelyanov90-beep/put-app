/// <reference path="../pb_data/types.d.ts" />

// Reproducible demo fixtures required by TZ section 32. All phones are reserved
// fictional test values and authenticate only through the fixed 111111 OTP.
migrate((app) => {
  const add = (collection, data) => {
    const record = new Record(app.findCollectionByNameOrId(collection), data)
    app.save(record)
    return record
  }
  const addUser = (phone, name, role, cityId) => {
    const user = new Record(app.findCollectionByNameOrId("users"), {
      email: phone.slice(1) + "@demo.vput.invalid",
      phone: phone,
      name: name,
      primary_role: role,
      driver_enabled: role === "driver",
      city_id: cityId,
      profile_completed: true,
      is_active: true,
      booking_blocked: false,
      reviews_count: 0,
    })
    user.setRandomPassword()
    user.setVerified(true)
    app.save(user)
    return user
  }
  const addStops = (trip, points) => {
    const records = []
    for (let index = 0; index < points.length; index++) {
      const point = points[index]
      records.push(add("trip_stops", {
        trip_id: trip.id,
        sort_order: index,
        stop_type: index === 0
          ? "origin"
          : (index === points.length - 1 ? "destination" : "intermediate"),
        address: point.address,
        city_id: point.city.id,
        latitude: point.latitude,
        longitude: point.longitude,
        planned_at: point.planned_at,
      }))
    }
    return records
  }

  const moscow = add("cities", {
    name: "Москва",
    country_code: "RU",
    latitude: 55.7558,
    longitude: 37.6176,
    is_active: true,
  })
  const tver = add("cities", {
    name: "Тверь",
    country_code: "RU",
    latitude: 56.8587,
    longitude: 35.9176,
    is_active: true,
  })
  const petersburg = add("cities", {
    name: "Санкт-Петербург",
    country_code: "RU",
    latitude: 59.9343,
    longitude: 30.3351,
    is_active: true,
  })
  const kazan = add("cities", {
    name: "Казань",
    country_code: "RU",
    latitude: 55.7961,
    longitude: 49.1064,
    is_active: true,
  })

  add("app_settings", { key: "monetization_enabled", value: true })
  add("app_settings", { key: "commission_fixed_rub", value: 50 })
  add("app_settings", {
    key: "trip_publication_limits",
    value: {
      driver_trip_limit_per_day: 2,
      driver_trip_limit_per_week: 10,
      outbound_limit_per_pair: 1,
      return_limit_per_pair: 1,
    },
  })

  const childSeat = add("extra_services", {
    code: "child_seat",
    title: "Детское кресло",
    description: "Детское удерживающее устройство",
    is_active: true,
  })
  const luggage = add("extra_services", {
    code: "luggage",
    title: "Багаж",
    description: "Дополнительное место для багажа",
    is_active: true,
  })
  const pets = add("extra_services", {
    code: "pets",
    title: "Животные",
    description: "Поездка с домашним животным",
    is_active: true,
  })
  const parcelService = add("extra_services", {
    code: "parcel",
    title: "Посылка",
    description: "Передача посылки без пассажира",
    is_active: true,
  })

  const passengerOne = addUser("+79990000001", "Анна", "passenger", moscow.id)
  const passengerTwo = addUser("+79990000002", "Илья", "passenger", tver.id)
  const passengerThree = addUser("+79990000003", "Мария", "passenger", kazan.id)
  const driverReviewed = addUser("+79990000011", "Алексей", "driver", moscow.id)
  const driverNoReviews = addUser("+79990000012", "Сергей", "driver", petersburg.id)

  const vehicleOne = add("vehicles", {
    owner_id: driverReviewed.id,
    transport_type: "car",
    brand: "Toyota",
    model: "Camry",
    plate_number: "А001АА77",
    color: "Белый",
    year: 2022,
    seat_count: 3,
    verification_status: "approved",
    verified_at: "2026-09-01 10:00:00.000Z",
  })
  const vehicleTwo = add("vehicles", {
    owner_id: driverNoReviews.id,
    transport_type: "car",
    brand: "Skoda",
    model: "Octavia",
    plate_number: "В002ВВ78",
    color: "Серый",
    year: 2021,
    seat_count: 2,
    verification_status: "approved",
    verified_at: "2026-09-01 10:00:00.000Z",
  })

  const standardTrip = add("trips", {
    driver_id: driverReviewed.id,
    vehicle_id: vehicleOne.id,
    transport_type: "car",
    status: "published",
    booking_mode: "standard",
    accepting_bookings: true,
    departure_at: "2030-10-10 07:00:00.000Z",
    arrival_at: "2030-10-10 15:00:00.000Z",
    seat_capacity: 3,
    base_price: 1200,
    minimum_boarding_price: 500,
    commission_amount: 50,
    driver_amount: 1150,
    currency: "RUB",
    segment_prices: [500, 700],
    published_at: "2026-09-01 10:00:00.000Z",
  })
  const standardStops = addStops(standardTrip, [
    { city: moscow, address: "Москва, площадь Тверская Застава", latitude: 55.7764, longitude: 37.5821, planned_at: "2030-10-10 07:00:00.000Z" },
    { city: tver, address: "Тверь, Волоколамский проспект, 3", latitude: 56.8498, longitude: 35.9118, planned_at: "2030-10-10 10:00:00.000Z" },
    { city: petersburg, address: "Санкт-Петербург, Московский вокзал", latitude: 59.9298, longitude: 30.3626, planned_at: "2030-10-10 15:00:00.000Z" },
  ])
  add("trip_extra_services", { trip_id: standardTrip.id, service_id: childSeat.id, price: 150 })
  add("trip_extra_services", { trip_id: standardTrip.id, service_id: luggage.id, price: 150 })
  add("trip_extra_services", { trip_id: standardTrip.id, service_id: pets.id, price: 150 })
  add("trip_extra_services", { trip_id: standardTrip.id, service_id: parcelService.id, price: 350 })

  const instantTrip = add("trips", {
    driver_id: driverNoReviews.id,
    vehicle_id: vehicleTwo.id,
    transport_type: "car",
    status: "published",
    booking_mode: "instant",
    accepting_bookings: true,
    departure_at: "2030-11-11 06:00:00.000Z",
    arrival_at: "2030-11-11 18:00:00.000Z",
    seat_capacity: 2,
    base_price: 1500,
    commission_amount: 50,
    driver_amount: 1450,
    currency: "RUB",
    segment_prices: [1500],
    published_at: "2026-09-01 10:00:00.000Z",
  })
  addStops(instantTrip, [
    { city: moscow, address: "Москва, Казанский вокзал", latitude: 55.7742, longitude: 37.6555, planned_at: "2030-11-11 06:00:00.000Z" },
    { city: kazan, address: "Казань, Привокзальная площадь", latitude: 55.7876, longitude: 49.1004, planned_at: "2030-11-11 18:00:00.000Z" },
  ])

  const pastTrip = add("trips", {
    driver_id: driverReviewed.id,
    vehicle_id: vehicleOne.id,
    transport_type: "car",
    status: "completed",
    booking_mode: "standard",
    accepting_bookings: false,
    departure_at: "2026-08-01 07:00:00.000Z",
    arrival_at: "2026-08-01 10:00:00.000Z",
    seat_capacity: 3,
    base_price: 700,
    commission_amount: 50,
    driver_amount: 650,
    currency: "RUB",
    segment_prices: [700],
    published_at: "2026-07-01 10:00:00.000Z",
  })
  const pastStops = addStops(pastTrip, [
    { city: moscow, address: "Москва, Речной вокзал", latitude: 55.8548, longitude: 37.4761, planned_at: "2026-08-01 07:00:00.000Z" },
    { city: tver, address: "Тверь, железнодорожный вокзал", latitude: 56.8357, longitude: 35.8933, planned_at: "2026-08-01 10:00:00.000Z" },
  ])
  const completedBooking = add("bookings", {
    trip_id: pastTrip.id,
    passenger_id: passengerOne.id,
    pickup_stop_id: pastStops[0].id,
    dropoff_stop_id: pastStops[1].id,
    booking_kind: "passenger",
    status: "completed",
    payment_status: "paid",
    seat_count: 1,
    amount: 700,
    commission_amount: 50,
    driver_amount: 650,
    currency: "RUB",
    idempotency_key: "demo_completed_booking",
  })
  add("reviews", {
    author_id: passengerOne.id,
    target_user_id: driverReviewed.id,
    trip_id: pastTrip.id,
    booking_id: completedBooking.id,
    rating: 5,
    text: "Отличная поездка, всё вовремя.",
    status: "published",
  })
  driverReviewed.set("rating_avg", 5)
  driverReviewed.set("reviews_count", 1)
  app.save(driverReviewed)

  const parcelBooking = add("bookings", {
    trip_id: standardTrip.id,
    passenger_id: passengerTwo.id,
    pickup_stop_id: standardStops[0].id,
    dropoff_stop_id: standardStops[2].id,
    booking_kind: "parcel",
    status: "pending_driver",
    payment_status: "unpaid",
    seat_count: 0,
    amount: 350,
    commission_amount: 50,
    driver_amount: 300,
    currency: "RUB",
    idempotency_key: "demo_parcel_booking",
  })
  add("parcels", {
    booking_id: parcelBooking.id,
    weight_category: "M",
    description: "Коробка с книгами",
    comment: "Не переворачивать",
    amount: 350,
  })
}, (app) => {
  const demoPhones = [
    "+79990000001",
    "+79990000002",
    "+79990000003",
    "+79990000011",
    "+79990000012",
  ]
  for (const phone of demoPhones) {
    try {
      app.delete(app.findFirstRecordByData("users", "phone", phone))
    } catch (_) {}
  }
  for (const name of ["Москва", "Тверь", "Санкт-Петербург", "Казань"]) {
    try {
      app.delete(app.findFirstRecordByData("cities", "name", name))
    } catch (_) {}
  }
})
