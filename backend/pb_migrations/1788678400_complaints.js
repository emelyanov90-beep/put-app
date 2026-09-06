/// <reference path="../pb_data/types.d.ts" />

// Complaints raised by users from «Профиль → Жалобы». Only the author may read
// their own; creation goes through the custom route so the status and the
// author cannot be set by the client.
migrate((app) => {
  const users = app.findCollectionByNameOrId("users")
  const bookings = app.findCollectionByNameOrId("bookings")

  const collection = new Collection({
    type: "base",
    name: "complaints",
    listRule: "author_id = @request.auth.id",
    viewRule: "author_id = @request.auth.id",
    createRule: null,
    updateRule: null,
    deleteRule: null,
  })
  collection.fields.add(
    new RelationField({
      name: "author_id",
      collectionId: users.id,
      required: true,
      minSelect: 1,
      maxSelect: 1,
      cascadeDelete: true,
    }),
    new RelationField({
      name: "booking_id",
      collectionId: bookings.id,
      required: false,
      minSelect: 0,
      maxSelect: 1,
    }),
    new SelectField({
      name: "subject",
      values: ["trip", "driver", "passenger", "payment", "app", "other"],
      maxSelect: 1,
      required: true,
    }),
    new TextField({ name: "text", required: true, min: 10, max: 2000 }),
    new SelectField({
      name: "status",
      values: ["new", "in_review", "resolved", "rejected"],
      maxSelect: 1,
      required: true,
    }),
    new TextField({ name: "admin_comment", max: 2000 }),
    new AutodateField({ name: "created_at", onCreate: true }),
    new AutodateField({ name: "updated_at", onCreate: true, onUpdate: true }),
  )
  collection.indexes = [
    "CREATE INDEX idx_complaints_author_created ON complaints (author_id, created_at)",
  ]
  app.save(collection)
}, (app) => {
  try { app.delete(app.findCollectionByNameOrId("complaints")) } catch (_) {}
})
