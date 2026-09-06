/// <reference path="../pb_data/types.d.ts" />

// Reading a notification is a state change, so it goes through an action
// instead of a client-side update: `notifications.updateRule` stays null.
routerAdd("POST", "/api/app/notifications/read", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const body = h.bodyOf(e)
    const ids = Array.isArray(body.ids) ? body.ids : []
    let updated = 0
    e.app.runInTransaction((tx) => {
      const records = ids.length
        ? ids.map((id) => tx.findRecordById("notifications", String(id)))
        : h.recordsByFilter(
            tx,
            "notifications",
            "user_id = {:user} && read_at = ''",
            "-created_at",
            500,
            { user: e.auth.id },
          )
      for (const record of records) {
        h.requireOwnRecord(record, e.auth.id, "user_id")
        // An unset date field reads back as an empty string, not as null.
        if (String(record.get("read_at") || "") !== "") continue
        record.set("read_at", new DateTime())
        tx.save(record)
        updated++
      }
    })
    return e.json(200, { updated: updated })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))
