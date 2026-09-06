/// <reference path="../pb_data/types.d.ts" />

const APP_PREFIX = "/api/app"

function bodyOf(e) {
  const body = {}
  e.bindBody(body)
  return body
}

function businessError(code, message, status) {
  const error = new Error(code + "|" + message)
  error.businessStatus = status || 400
  return error
}

function writeError(e, error) {
  const raw = String(error && error.message ? error.message : error)
  const separator = raw.indexOf("|")
  if (separator > 0) {
    const code = raw.slice(0, separator).replace(/^Error:\s*/, "")
    if (/^[A-Z0-9_]+$/.test(code)) {
      return e.json(error.businessStatus || 400, {
        status: error.businessStatus || 400,
        code: code,
        message: raw.slice(separator + 1),
      })
    }
  }
  e.app.logger().error("application route failed", "error", raw)
  return e.json(500, {
    status: 500,
    code: "INTERNAL_ERROR",
    message: "Внутренняя ошибка сервера.",
  })
}

function normalizedPhone(value) {
  let digits = String(value || "").replace(/\D/g, "")
  if (digits.length === 11 && (digits[0] === "7" || digits[0] === "8")) {
    digits = digits.slice(1)
  }
  if (digits.length !== 10) {
    throw businessError("INVALID_PHONE", "Некорректный номер телефона.")
  }
  return "+7" + digits
}

function firstByData(app, collection, field, value) {
  try {
    return app.findFirstRecordByData(collection, field, value)
  } catch (_) {
    return null
  }
}

function publicUserDto(record) {
  return {
    id: record.id,
    name: record.getString("name"),
    avatar: record.getString("avatar"),
    city_id: record.getString("city_id"),
    primary_role: record.getString("primary_role"),
    driver_enabled: record.getBool("driver_enabled"),
    rating_avg: record.get("rating_avg") || null,
    reviews_count: record.getInt("reviews_count"),
  }
}

function ownUserDto(record) {
  const result = publicUserDto(record)
  result.phone = record.getString("phone")
  result.booking_blocked = record.getBool("booking_blocked")
  result.profile_completed = record.getBool("profile_completed")
  return result
}

routerAdd("GET", APP_PREFIX + "/health", (e) => {
  return e.json(200, {
    status: "ok",
    service: "vput",
    pocketbase: "0.40.2",
  })
})

routerAdd(
  "GET",
  APP_PREFIX + "/config",
  (e) => require(`${__hooks}/lib/app.js`).runtimeConfigHandler(e),
  $apis.requireAuth("users"),
)

routerAdd("POST", APP_PREFIX + "/auth/request-code", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    h.normalizedPhone(h.bodyOf(e).phone)
    return e.json(200, { success: true, expiresIn: 60 })
  } catch (error) {
    return h.writeError(e, error)
  }
})

routerAdd("POST", APP_PREFIX + "/auth/verify-code", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const body = h.bodyOf(e)
    const phone = h.normalizedPhone(body.phone)
    if (String(body.code || "") !== "111111") {
      throw h.businessError("INVALID_OTP", "Неверный код подтверждения.", 400)
    }

    let user = h.firstByData(e.app, "users", "phone", phone)
    if (!user) {
      user = new Record(e.app.findCollectionByNameOrId("users"), {
        email: phone.slice(1) + "@otp.vput.invalid",
        phone: phone,
        is_active: true,
        reviews_count: 0,
        booking_blocked: false,
        profile_completed: false,
      })
      user.setRandomPassword()
      user.setVerified(true)
      e.app.save(user)
    }
    if (!user.getBool("is_active")) {
      throw h.businessError("ACCOUNT_BLOCKED", "Аккаунт заблокирован.", 403)
    }
    const record = h.ownUserDto(user)
    record.collectionId = user.collection().id
    record.collectionName = user.collection().name
    return e.json(200, { token: user.newAuthToken(), record: record })
  } catch (error) {
    return h.writeError(e, error)
  }
})

routerAdd("GET", APP_PREFIX + "/me", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  return e.json(200, { user: h.ownUserDto(e.auth) })
}, $apis.requireAuth("users"))

routerAdd("PATCH", APP_PREFIX + "/me", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const body = h.bodyOf(e)
    const user = e.app.findRecordById("users", e.auth.id)
    if (body.name !== undefined) user.set("name", String(body.name).trim())
    if (body.city_id !== undefined) user.set("city_id", String(body.city_id))
    if (body.primary_role !== undefined) user.set("primary_role", String(body.primary_role))
    if (body.driver_enabled !== undefined) user.set("driver_enabled", Boolean(body.driver_enabled))
    const complete = user.getString("name").length > 0 &&
      user.getString("city_id").length > 0 &&
      user.getString("primary_role").length > 0
    user.set("profile_completed", complete)
    e.app.save(user)
    return e.json(200, { user: h.ownUserDto(user) })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))

routerAdd("POST", APP_PREFIX + "/me/avatar", (e) => {
  const h = require(`${__hooks}/lib/app.js`)
  try {
    const files = e.findUploadedFiles("avatar")
    if (!files.length) {
      throw h.businessError("AVATAR_REQUIRED", "Файл фотографии не найден.")
    }
    const user = e.app.findRecordById("users", e.auth.id)
    user.set("avatar", files[0])
    e.app.save(user)
    return e.json(200, { user: h.ownUserDto(user) })
  } catch (error) {
    return h.writeError(e, error)
  }
}, $apis.requireAuth("users"))
