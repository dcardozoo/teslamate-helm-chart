# Troubleshooting

Names assume a release called `teslamate` in the namespace `teslamate`.

## Install fails immediately

- `Set teslamate.encryptionKey or teslamate.existingSecret`: generate a key with `openssl rand -base64 32`.
- `no matches for kind "Cluster" in version "postgresql.cnpg.io/v1"`: the CNPG operator is not installed. Install it first, see the README, "Prerequisites".
- `no matches for kind "ObjectStore"`: backups are enabled but the Barman Cloud plugin is not installed.
- `at '/database/cnpg/instances': minimum: got 1, want 2`: the CNPG cluster needs at least two instances.

## Pods stuck in `CreateContainerConfigError`

Normal for about 1-2 minutes on the first install: the pods reference the CNPG secrets `<fullname>-db-app` and `<fullname>-db-ca`, which exist only once CNPG has bootstrapped the cluster. If it lasts longer, check the Cluster: `kubectl -n teslamate get clusters.postgresql.cnpg.io` and `kubectl -n teslamate describe cluster teslamate-db`, and the operator logs.

## Backups not running

Backups are your responsibility and are not tested by this chart. Check the plugin installation and the [plugin documentation](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/). Useful commands:

```sh
kubectl -n teslamate get backups.postgresql.cnpg.io,scheduledbackups.postgresql.cnpg.io,objectstores.barmancloud.cnpg.io
kubectl -n teslamate logs teslamate-db-1 -c plugin-barman-cloud
```

`WAL archive check failed ... Expected empty archive`: the cluster archives into a `destinationPath`/`serverName` that already holds WAL (reinstall or restore onto the same bucket). Set a new `database.cnpg.backup.serverName`.

## TeslaMate crashes with an out-of-memory error

The BEAM VM sizes data structures by the open-file limit; with a huge `ulimit -n` it can exhaust memory. The chart handles this by running the stock image entrypoint (which caps the nofile limit) instead of overriding the command. Do not override the container command or entrypoint.

## Grafana cannot connect to the database

- With `grafana.readOnlyUser`, the Secret must be `kubernetes.io/basic-auth` and its `username` must equal `grafana.readOnlyUser.username`.
- With an external database, `sslmode` defaults to `disable`; set `grafana.databaseSslMode` if the server requires TLS.

## TeslaMate UI keeps reconnecting

With an Ingress or `teslamate.virtualHost`, the chart sets `CHECK_ORIGIN=true`: the websocket only accepts the configured host. Open the UI through that host, or list the extra origins in `teslamate.checkOrigin` (e.g. `"https://teslamate.example.com,//localhost:4000"` for `kubectl port-forward`). See the README, "Ingress".

## TeslaMate shows no live data / MQTT

`kubectl -n teslamate exec -it deploy/teslamate-mosquitto -- mosquitto_sub -h localhost -t 'teslamate/#' -v`

or run `helm test teslamate -n teslamate --logs`.

## Uninstall left the database behind

By design with `database.cnpg.keepOnUninstall: true` (default). See the README, "Uninstall".
