/// <reference path="../pb_data/types.d.ts" />

// Initial schema for the PocketBase 0.40.2 backend. Critical business
// transitions are locked here and exposed only by pb_hooks custom routes.
migrate((app) => {
  const makeCollection = (data) => {
    const fields = data.fields || []
    const indexes = data.indexes || []
    delete data.fields
    delete data.indexes
    const collection = new Collection(data)
    collection.fields.add(...fields)
    collection.indexes = indexes
    return collection
  }
  const save = (collection) => {
    try {
      app.save(collection)
    } catch (error) {
      throw new Error(`failed to save collection ${collection.name}: ${error}`)
    }
    return collection
  }
  const relation = (name, collection, required = true, cascadeDelete = false) =>
    new RelationField({
      name,
      collectionId: collection.id,
      required,
      minSelect: required ? 1 : 0,
      maxSelect: 1,
      cascadeDelete,
    })
  const created = () => new AutodateField({ name: "created_at", onCreate: true })
  const updated = () => new AutodateField({ name: "updated_at", onCreate: true, onUpdate: true })

  const cities = save(makeCollection({
    type: "base",
    name: "cities",
    listRule: "is_active = true",
    viewRule: "is_active = true",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      new TextField({ name: "name", required: true, min: 2, max: 120, presentable: true }),
      new TextField({ name: "country_code", required: true, min: 2, max: 2 }),
      new NumberField({ name: "latitude", min: -90, max: 90 }),
      new NumberField({ name: "longitude", min: -180, max: 180 }),
      new BoolField({ name: "is_active" }),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_cities_name_country ON cities (name, country_code)"],
  }))

  // PocketBase creates the default users auth collection on first boot. Extend
  // it instead of replacing it so fresh installations and upgrades behave the
  // same way. Email/password stay internal implementation details of the fixed
  // test-OTP route and are never returned through record APIs.
  const users = app.findCollectionByNameOrId("users")
  users.authRule = "is_active = true"
  users.listRule = '@request.auth.id != ""'
  users.viewRule = '@request.auth.id != ""'
  users.createRule = null
  users.updateRule = null
  users.deleteRule = null
  users.manageRule = null
  users.passwordAuth.enabled = false
  users.otp.enabled = false
  users.fields.getByName("email").hidden = true
  users.fields.getByName("name").max = 100
  users.fields.getByName("name").presentable = true
  users.fields.getByName("avatar").maxSize = 10485760
  users.fields.getByName("avatar").mimeTypes = ["image/jpeg", "image/png", "image/webp"]
  users.fields.getByName("avatar").thumbs = ["160x160"]
  const userFields = [
    new TextField({ name: "phone", required: true, min: 12, max: 12, pattern: "^\\+7[0-9]{10}$", hidden: true }),
    relation("city_id", cities, false),
    new SelectField({ name: "primary_role", values: ["passenger", "driver"], maxSelect: 1 }),
    new BoolField({ name: "driver_enabled" }),
    new BoolField({ name: "booking_blocked" }),
    new TextField({ name: "booking_block_reason", max: 500, hidden: true }),
    new NumberField({ name: "rating_avg", min: 1, max: 5 }),
    new NumberField({ name: "reviews_count", min: 0, onlyInt: true }),
    new BoolField({ name: "is_active", required: true }),
    new BoolField({ name: "profile_completed" }),
  ]
  for (const field of userFields) users.fields.add(field)
  users.indexes.push("CREATE UNIQUE INDEX idx_users_phone ON users (phone)")
  app.save(users)

  const vehicles = save(makeCollection({
    type: "base",
    name: "vehicles",
    listRule: "owner_id = @request.auth.id",
    viewRule: "owner_id = @request.auth.id",
    createRule: 'owner_id = @request.auth.id && verification_status = "draft"',
    updateRule: 'owner_id = @request.auth.id && @request.body.owner_id:changed = false && @request.body.verification_status:changed = false && @request.body.verified_at:changed = false && @request.body.verification_comment:changed = false',
    deleteRule: "owner_id = @request.auth.id",
    fields: [
      relation("owner_id", users),
      new SelectField({ name: "transport_type", values: ["car", "bus"], maxSelect: 1, required: true }),
      new TextField({ name: "brand", required: true, min: 1, max: 80, presentable: true }),
      new TextField({ name: "model", required: true, min: 1, max: 80 }),
      new TextField({ name: "plate_number", max: 20 }),
      new TextField({ name: "color", max: 40 }),
      new NumberField({ name: "year", min: 1950, max: 2100, onlyInt: true }),
      new NumberField({ name: "seat_count", required: true, min: 1, max: 50, onlyInt: true }),
      new FileField({ name: "photo", maxSelect: 1, maxSize: 10485760, mimeTypes: ["image/jpeg", "image/png", "image/webp"], thumbs: ["800x600f"] }),
      new FileField({ name: "registration_document", maxSelect: 1, maxSize: 10485760, mimeTypes: ["image/jpeg", "image/png", "image/webp", "application/pdf"], protected: true }),
      new SelectField({ name: "verification_status", values: ["draft", "pending", "approved", "rejected"], maxSelect: 1, required: true }),
      new TextField({ name: "verification_comment", max: 1000, hidden: true }),
      new DateField({ name: "verified_at" }),
      created(),
      updated(),
    ],
    indexes: ["CREATE INDEX idx_vehicles_owner ON vehicles (owner_id)"],
  }))

  const trips = save(makeCollection({
    type: "base",
    name: "trips",
    listRule: '(@request.auth.id != "" && status = "published" && departure_at > @now) || driver_id = @request.auth.id',
    viewRule: '(@request.auth.id != "" && status = "published") || driver_id = @request.auth.id',
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("driver_id", users),
      relation("vehicle_id", vehicles),
      new SelectField({ name: "transport_type", values: ["car", "bus"], maxSelect: 1, required: true }),
      new SelectField({ name: "status", values: ["draft", "published", "cancelled", "completed"], maxSelect: 1, required: true }),
      new SelectField({ name: "booking_mode", values: ["standard", "instant"], maxSelect: 1, required: true }),
      new BoolField({ name: "accepting_bookings" }),
      new DateField({ name: "departure_at", required: true }),
      new DateField({ name: "arrival_at", required: true }),
      new NumberField({ name: "seat_capacity", required: true, min: 1, max: 50, onlyInt: true }),
      new NumberField({ name: "base_price", required: true, min: 0, onlyInt: true }),
      new NumberField({ name: "minimum_boarding_price", min: 0, onlyInt: true }),
      new NumberField({ name: "commission_amount", min: 0, onlyInt: true }),
      new NumberField({ name: "driver_amount", min: 0, onlyInt: true }),
      new TextField({ name: "currency", required: true, min: 3, max: 3 }),
      new JSONField({ name: "segment_prices", maxSize: 32768 }),
      new DateField({ name: "published_at" }),
      created(),
      updated(),
    ],
    indexes: [
      "CREATE INDEX idx_trips_driver ON trips (driver_id)",
      "CREATE INDEX idx_trips_status_departure ON trips (status, departure_at)",
      "CREATE INDEX idx_trips_transport_departure ON trips (transport_type, departure_at)",
    ],
  }))
  trips.fields.add(relation("paired_trip_id", trips, false))
  app.save(trips)

  const tripStops = save(makeCollection({
    type: "base",
    name: "trip_stops",
    listRule: 'trip_id.status = "published" || trip_id.driver_id = @request.auth.id',
    viewRule: 'trip_id.status = "published" || trip_id.driver_id = @request.auth.id',
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("trip_id", trips, true, true),
      new NumberField({ name: "sort_order", min: 0, max: 100, onlyInt: true }),
      new SelectField({ name: "stop_type", values: ["origin", "intermediate", "destination"], maxSelect: 1, required: true }),
      new TextField({ name: "address", required: true, min: 2, max: 500, presentable: true }),
      relation("city_id", cities, false),
      new NumberField({ name: "latitude", min: -90, max: 90 }),
      new NumberField({ name: "longitude", min: -180, max: 180 }),
      new DateField({ name: "planned_at" }),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_trip_stops_order ON trip_stops (trip_id, sort_order)"],
  }))

  const extraServices = save(makeCollection({
    type: "base",
    name: "extra_services",
    listRule: "is_active = true",
    viewRule: "is_active = true",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      new TextField({ name: "code", required: true, min: 2, max: 40, presentable: true }),
      new TextField({ name: "title", required: true, min: 2, max: 100 }),
      new TextField({ name: "description", max: 500 }),
      new BoolField({ name: "is_active", required: true }),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_extra_services_code ON extra_services (code)"],
  }))

  const tripExtraServices = save(makeCollection({
    type: "base",
    name: "trip_extra_services",
    listRule: 'trip_id.status = "published" || trip_id.driver_id = @request.auth.id',
    viewRule: 'trip_id.status = "published" || trip_id.driver_id = @request.auth.id',
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("trip_id", trips, true, true),
      relation("service_id", extraServices),
      new NumberField({ name: "price", min: 0, onlyInt: true }),
      new JSONField({ name: "details", maxSize: 32768 }),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_trip_extra_service ON trip_extra_services (trip_id, service_id)"],
  }))

  const bookings = save(makeCollection({
    type: "base",
    name: "bookings",
    listRule: "passenger_id = @request.auth.id || trip_id.driver_id = @request.auth.id",
    viewRule: "passenger_id = @request.auth.id || trip_id.driver_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("trip_id", trips),
      relation("passenger_id", users),
      relation("pickup_stop_id", tripStops),
      relation("dropoff_stop_id", tripStops),
      new SelectField({ name: "booking_kind", values: ["passenger", "parcel"], maxSelect: 1, required: true }),
      new SelectField({ name: "status", values: ["draft", "pending_driver", "rejected_by_driver", "awaiting_payment", "confirmed", "cancelled_by_passenger", "cancelled_by_driver", "completed", "expired"], maxSelect: 1, required: true }),
      new SelectField({ name: "payment_status", values: ["not_required", "unpaid", "paid", "refund_requested", "refunded"], maxSelect: 1, required: true }),
      new NumberField({ name: "seat_count", min: 0, max: 50, onlyInt: true }),
      new NumberField({ name: "amount", min: 0, onlyInt: true }),
      new NumberField({ name: "commission_amount", min: 0, onlyInt: true }),
      new NumberField({ name: "driver_amount", min: 0, onlyInt: true }),
      new TextField({ name: "currency", required: true, min: 3, max: 3 }),
      new TextField({ name: "idempotency_key", required: true, min: 8, max: 100, hidden: true }),
      new DateField({ name: "driver_decided_at" }),
      new DateField({ name: "cancelled_at" }),
      new TextField({ name: "cancel_reason", max: 500 }),
      created(),
      updated(),
    ],
    indexes: [
      "CREATE INDEX idx_bookings_trip_status ON bookings (trip_id, status)",
      "CREATE INDEX idx_bookings_passenger_status ON bookings (passenger_id, status)",
      "CREATE UNIQUE INDEX idx_bookings_idempotency ON bookings (passenger_id, idempotency_key)",
    ],
  }))

  const bookingExtras = save(makeCollection({
    type: "base",
    name: "booking_extras",
    listRule: "booking_id.passenger_id = @request.auth.id || booking_id.trip_id.driver_id = @request.auth.id",
    viewRule: "booking_id.passenger_id = @request.auth.id || booking_id.trip_id.driver_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("booking_id", bookings, true, true),
      relation("service_id", extraServices),
      new NumberField({ name: "quantity", required: true, min: 1, max: 50, onlyInt: true }),
      new NumberField({ name: "amount", min: 0, onlyInt: true }),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_booking_extra ON booking_extras (booking_id, service_id)"],
  }))

  const parcels = save(makeCollection({
    type: "base",
    name: "parcels",
    listRule: "booking_id.passenger_id = @request.auth.id || booking_id.trip_id.driver_id = @request.auth.id",
    viewRule: "booking_id.passenger_id = @request.auth.id || booking_id.trip_id.driver_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("booking_id", bookings, true, true),
      new SelectField({ name: "weight_category", values: ["S", "M", "L"], maxSelect: 1, required: true }),
      new TextField({ name: "description", max: 1000 }),
      new TextField({ name: "comment", max: 1000 }),
      new NumberField({ name: "amount", min: 0, onlyInt: true }),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_parcels_booking ON parcels (booking_id)"],
  }))

  const payments = save(makeCollection({
    type: "base",
    name: "payments",
    listRule: "payer_id = @request.auth.id || booking_id.trip_id.driver_id = @request.auth.id",
    viewRule: "payer_id = @request.auth.id || booking_id.trip_id.driver_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("booking_id", bookings),
      relation("payer_id", users),
      new SelectField({ name: "provider", values: ["mock"], maxSelect: 1, required: true }),
      new SelectField({ name: "status", values: ["pending", "paid", "failed", "refund_requested", "refunded"], maxSelect: 1, required: true }),
      new NumberField({ name: "amount", min: 0, onlyInt: true }),
      new TextField({ name: "currency", required: true, min: 3, max: 3 }),
      new TextField({ name: "mock_transaction_id", required: true, min: 12, max: 100 }),
      new DateField({ name: "paid_at" }),
      created(),
      updated(),
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_payments_booking ON payments (booking_id)",
      "CREATE UNIQUE INDEX idx_payments_transaction ON payments (mock_transaction_id)",
    ],
  }))

  const refunds = save(makeCollection({
    type: "base",
    name: "refunds",
    listRule: "booking_id.passenger_id = @request.auth.id",
    viewRule: "booking_id.passenger_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("payment_id", payments),
      relation("booking_id", bookings),
      new SelectField({ name: "status", values: ["requested", "approved", "refunded", "rejected"], maxSelect: 1, required: true }),
      new NumberField({ name: "amount", min: 0, onlyInt: true }),
      new TextField({ name: "reason", max: 500 }),
      new DateField({ name: "requested_at", required: true }),
      new DateField({ name: "resolved_at" }),
      created(),
      updated(),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_refunds_payment ON refunds (payment_id)"],
  }))

  const reviews = save(makeCollection({
    type: "base",
    name: "reviews",
    listRule: 'status = "published"',
    viewRule: 'status = "published"',
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("author_id", users),
      relation("target_user_id", users),
      relation("trip_id", trips),
      relation("booking_id", bookings),
      new NumberField({ name: "rating", required: true, min: 1, max: 5, onlyInt: true }),
      new TextField({ name: "text", max: 3000 }),
      new SelectField({ name: "status", values: ["pending", "published", "rejected"], maxSelect: 1, required: true }),
      created(),
      updated(),
    ],
    indexes: [
      "CREATE INDEX idx_reviews_target_status ON reviews (target_user_id, status)",
      "CREATE UNIQUE INDEX idx_reviews_unique ON reviews (booking_id, author_id, target_user_id)",
    ],
  }))

  const chats = save(makeCollection({
    type: "base",
    name: "chats",
    listRule: "passenger_id = @request.auth.id || driver_id = @request.auth.id",
    viewRule: "passenger_id = @request.auth.id || driver_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("booking_id", bookings),
      relation("passenger_id", users),
      relation("driver_id", users),
      new DateField({ name: "last_message_at" }),
      created(),
      updated(),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_chats_booking ON chats (booking_id)"],
  }))

  save(makeCollection({
    type: "base",
    name: "messages",
    listRule: "chat_id.passenger_id = @request.auth.id || chat_id.driver_id = @request.auth.id",
    viewRule: "chat_id.passenger_id = @request.auth.id || chat_id.driver_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("chat_id", chats, true, true),
      relation("sender_id", users),
      new TextField({ name: "text", required: true, min: 1, max: 3000 }),
      new TextField({ name: "client_message_id", required: true, min: 8, max: 100, hidden: true }),
      new DateField({ name: "read_at" }),
      created(),
    ],
    indexes: [
      "CREATE INDEX idx_messages_chat_created ON messages (chat_id, created_at)",
      "CREATE UNIQUE INDEX idx_messages_client_id ON messages (sender_id, client_message_id)",
    ],
  }))

  save(makeCollection({
    type: "base",
    name: "notifications",
    listRule: "user_id = @request.auth.id",
    viewRule: "user_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      relation("user_id", users, true, true),
      new TextField({ name: "type", required: true, min: 2, max: 80 }),
      new TextField({ name: "title", required: true, min: 1, max: 200 }),
      new TextField({ name: "body", max: 1000 }),
      new JSONField({ name: "payload", maxSize: 32768 }),
      new DateField({ name: "read_at" }),
      created(),
    ],
    indexes: ["CREATE INDEX idx_notifications_user_created ON notifications (user_id, created_at)"],
  }))

  save(makeCollection({
    type: "base",
    name: "app_settings",
    listRule: null,
    viewRule: null,
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      new TextField({ name: "key", required: true, min: 2, max: 100, presentable: true }),
      new JSONField({ name: "value", required: true, maxSize: 32768 }),
      created(),
      updated(),
    ],
    indexes: ["CREATE UNIQUE INDEX idx_app_settings_key ON app_settings (key)"],
  }))
}, (app) => {
  const names = [
    "app_settings", "notifications", "messages", "chats", "reviews",
    "refunds", "payments", "parcels", "booking_extras", "bookings",
    "trip_extra_services", "extra_services", "trip_stops", "trips",
    "vehicles", "cities",
  ]
  for (const name of names) {
    try { app.delete(app.findCollectionByNameOrId(name)) } catch (_) {}
  }
})
