/// <reference path="../pb_data/types.d.ts" />

// Safe defaults for the nginx deployment. PocketBase only listens on loopback,
// so X-Real-IP can be trusted because nginx always overwrites it.
migrate((app) => {
  const settings = app.settings()
  settings.meta.appName = "В путь"
  settings.meta.appURL = "https://pb.bookingtest26.ru"
  settings.trustedProxy.headers = ["X-Real-IP"]
  settings.trustedProxy.useLeftmostIP = false
  settings.rateLimits.enabled = true
  settings.rateLimits.rules = [
    {
      label: "POST /api/app/auth/request-code",
      audience: "",
      duration: 60,
      maxRequests: 5,
    },
    {
      label: "POST /api/app/auth/verify-code",
      audience: "",
      duration: 60,
      maxRequests: 10,
    },
    {
      label: "/api/",
      audience: "",
      duration: 10,
      maxRequests: 300,
    },
  ]
  settings.backups.cron = "0 3 * * *"
  settings.backups.cronMaxKeep = 7
  app.save(settings)
}, (app) => {
  const settings = app.settings()
  settings.meta.appName = "Acme"
  settings.meta.appURL = "http://127.0.0.1:8090"
  settings.trustedProxy.headers = []
  settings.trustedProxy.useLeftmostIP = false
  settings.rateLimits.enabled = false
  settings.backups.cron = ""
  settings.backups.cronMaxKeep = 3
  app.save(settings)
})
