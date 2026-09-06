/// <reference path="../pb_data/types.d.ts" />

routerAdd(
  "GET",
  "/api/app/chats/mine",
  (e) => require(`${__hooks}/lib/app.js`).listOwnChatsHandler(e),
  $apis.requireAuth("users"),
)

routerAdd(
  "POST",
  "/api/app/chats/{id}/messages",
  (e) => require(`${__hooks}/lib/app.js`).sendMessageHandler(e),
  $apis.requireAuth("users"),
)
