# Production deployment

Target: `pb.bookingtest26.ru` (`159.194.251.35`), PocketBase `0.40.2`, nginx,
systemd, and Let's Encrypt. PocketBase listens only on `127.0.0.1:8090`.

The deployment layout is:

```text
/opt/vput/pocketbase
/opt/vput/pb_hooks/
/opt/vput/pb_migrations/
/var/lib/vput/pb_data/
/etc/vput/pocketbase.env
/etc/systemd/system/vput-pocketbase.service
/etc/nginx/sites-available/pb.bookingtest26.ru
```

When creating a release archive on macOS, disable AppleDouble metadata so
PocketBase does not treat `._*.js` resource-fork files as hooks or migrations:

```sh
COPYFILE_DISABLE=1 tar -czf /tmp/vput-backend-release.tar.gz \
  -C backend pb_hooks pb_migrations deploy
```

`/etc/vput/pocketbase.env` must be owned by root with mode `0600` and contain
one generated 32-character value:

```text
PB_ENCRYPTION_KEY=replace-with-a-random-32-character-value
```

Never copy this file, `pb_data`, auth tokens, or superuser credentials into the
repository. The systemd unit runs under the unprivileged `vput` user and can
write only to `/var/lib/vput`.

Before enabling the nginx configuration, preserve any existing virtual host
and inspect the current listeners. Validate with `nginx -t`. Issue the
certificate only after the HTTP vhost serves this domain:

```sh
certbot --nginx -d pb.bookingtest26.ru --redirect
```

After deployment, verify both the local upstream and public TLS endpoint:

```sh
curl -fsS http://127.0.0.1:8090/api/app/health
curl -fsS https://pb.bookingtest26.ru/api/app/health
systemctl --no-pager --full status vput-pocketbase
```

PocketBase creates a local backup every day at 03:00 and retains seven cron
backups. Before replacing an existing database, stop the service and copy the
entire `/var/lib/vput/pb_data` directory to storage outside that directory.

Create the first superuser interactively after HTTPS works. Do not place its
password on a command line or in shell history. Then restrict superuser access
to the administrator's current IP in PocketBase settings and enable MFA if an
SMTP transport is configured.

Build the Flutter app with the public backend URL:

```sh
flutter run --dart-define=PB_BASE_URL=https://pb.bookingtest26.ru
```
