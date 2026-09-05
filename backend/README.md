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
