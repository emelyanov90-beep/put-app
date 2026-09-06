/// <reference path="../pb_data/types.d.ts" />

routerAdd(
  "GET",
  "/api/app/vehicles",
  (e) => require(`${__hooks}/lib/app.js`).listVehiclesHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/vehicles",
  (e) => require(`${__hooks}/lib/app.js`).createVehicleHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "PATCH",
  "/api/app/vehicles/{id}",
  (e) => require(`${__hooks}/lib/app.js`).patchVehicleHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/vehicles/{id}/submit-verification",
  (e) => require(`${__hooks}/lib/app.js`).submitVehicleHandler(e),
  $apis.requireAuth("users"),
)
