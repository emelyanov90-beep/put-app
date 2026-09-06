# PocketBase backend

The local executable is pinned to PocketBase `0.40.2`. It is downloaded into
`backend/bin/` and intentionally ignored by Git. Business schema belongs in
`pb_migrations`, server-only transitions belong in `pb_hooks`, and reproducible
demo data belongs in `seed`.

Bootstrap and start locally from the repository root:

```sh
./tool/bootstrap_pocketbase.sh
./tool/run_pocketbase.sh
```

The local Admin UI is then available at `http://127.0.0.1:8090/_/` and the API
at `http://127.0.0.1:8090/api/`. Local HTTP is only for development. A mobile
release must use a publicly reachable HTTPS URL as required by the TZ.

Never commit `pb_data/` or superuser credentials.

Run the isolated API acceptance test with:

```sh
backend/tests/smoke.sh
```

It creates a temporary database, applies every migration, starts PocketBase on
loopback, verifies authentication and privacy-safe DTOs, and exercises booking,
driver approval, mock payment/refund, parcel bookings, complaints, notification
read state, access rules, and a concurrent last-seat race. The temporary
database is removed when the test ends.

Hook files run each request in a fresh JS VM, so a constant declared at module
level in a `*.pb.js` file is not visible inside a route handler — declare such
values inside the handler.

Production systemd/nginx templates and the server checklist are in
`backend/deploy/`. The configured public endpoint is
`https://pb.bookingtest26.ru`; Flutter receives it through `PB_BASE_URL`.
