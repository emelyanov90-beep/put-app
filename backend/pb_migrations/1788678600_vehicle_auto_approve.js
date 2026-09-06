/// <reference path="../pb_data/types.d.ts" />

// Vehicles are usable as soon as the driver saves them: the administrator
// review is switched off for now. The switch lives in `app_settings`, so
// moderation can be turned back on without a redeploy, and the transition
// stays server-side — a client still cannot set `verification_status`.
migrate((app) => {
  const settings = app.findCollectionByNameOrId("app_settings")
  try {
    app.findFirstRecordByData("app_settings", "key", "vehicle_auto_approve")
  } catch (_) {
    app.save(new Record(settings, { key: "vehicle_auto_approve", value: true }))
  }

  // Vehicles already waiting for a review would stay stuck otherwise.
  const waiting = app.findRecordsByFilter(
    "vehicles",
    "verification_status != 'approved'",
    "",
    500,
    0,
  )
  for (const vehicle of waiting) {
    vehicle.set("verification_status", "approved")
    vehicle.set("verification_comment", "")
    vehicle.set("verified_at", new DateTime())
    app.save(vehicle)
  }
}, (app) => {
  try {
    app.delete(app.findFirstRecordByData("app_settings", "key", "vehicle_auto_approve"))
  } catch (_) {}
})
