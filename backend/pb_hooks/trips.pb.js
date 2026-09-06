/// <reference path="../pb_data/types.d.ts" />

routerAdd(
  "GET",
  "/api/app/trips/search",
  (e) => require(`${__hooks}/lib/app.js`).searchTripsHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "GET",
  "/api/app/trips/mine",
  (e) => require(`${__hooks}/lib/app.js`).listOwnTripsHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "GET",
  "/api/app/trips/{id}",
  (e) => require(`${__hooks}/lib/app.js`).getTripHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/trips",
  (e) => require(`${__hooks}/lib/app.js`).createTripHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "PATCH",
  "/api/app/trips/{id}",
  (e) => require(`${__hooks}/lib/app.js`).patchTripHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/trips/{id}/publish",
  (e) => require(`${__hooks}/lib/app.js`).publishTripHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/trips/{id}/create-return",
  (e) => require(`${__hooks}/lib/app.js`).createReturnTripHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/trips/{id}/cancel",
  (e) => require(`${__hooks}/lib/app.js`).cancelTripHandler(e),
  $apis.requireAuth("users"),
)
