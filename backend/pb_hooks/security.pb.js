/// <reference path="../pb_data/types.d.ts" />

onRecordUpdateRequest((e) => {
  if (e.auth && !e.auth.isSuperuser()) {
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
      e.record.set("verification_status", "draft")
      e.record.set("verification_comment", "")
      e.record.set("verified_at", "")
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
