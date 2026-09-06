/// <reference path="../pb_data/types.d.ts" />

// A vehicle's verification state is decided by the server, never by the client.
// With `app_settings.vehicle_auto_approve` on it is approved as soon as it is
// saved; with the setting off, changing the vehicle data invalidates an earlier
// review and sends the record back to `draft`.
onRecordCreateRequest((e) => {
  if (e.auth && !e.auth.isSuperuser()) {
    require(`${__hooks}/lib/app.js`).applyVehicleVerification(e.app, e.record)
  }
  return e.next()
}, "vehicles")

onRecordUpdateRequest((e) => {
  if (e.auth && !e.auth.isSuperuser()) {
    const h = require(`${__hooks}/lib/app.js`)
    if (h.vehicleAutoApprove(e.app)) {
      h.applyVehicleVerification(e.app, e.record)
      return e.next()
    }
    const original = e.record.original()
    const changed = [
      "transport_type",
      "brand",
      "model",
      "plate_number",
      "color",
      "year",
      "seat_count",
      "photo",
      "registration_document",
    ].some((field) => JSON.stringify(e.record.get(field)) !== JSON.stringify(original.get(field))) ||
      e.record.getUnsavedFiles("photo").length > 0 ||
      e.record.getUnsavedFiles("registration_document").length > 0
    if (changed) {
      h.applyVehicleVerification(e.app, e.record)
    }
  }
  return e.next()
}, "vehicles")

onRecordDeleteRequest((e) => {
  if (e.auth && !e.auth.isSuperuser()) {
    const trips = e.app.findRecordsByFilter(
      "trips",
      "vehicle_id = {:vehicle} && (status = 'published' || status = 'completed')",
      "",
      1,
      0,
      { vehicle: e.record.id },
    )
    if (trips.length) {
      throw new ForbiddenError("Автомобиль используется в поездке.")
    }
  }
  return e.next()
}, "vehicles")
