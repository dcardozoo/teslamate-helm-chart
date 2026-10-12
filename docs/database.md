# Database

## Default cluster

With `database.type: cnpg` (default) the chart creates a CloudNativePG `Cluster` named `<fullname>-db`. The [CNPG operator](https://cloudnative-pg.io/docs/current/installation_upgrade/) must already be installed in the cluster; this chart does not install it.

- 2 instances (1 primary, 1 streaming replica); the values schema enforces `instances >= 2`
- PostgreSQL 18 (`database.cnpg.imageName`, CNPG's `standard` image)
- `initdb` with data checksums, database and owner `teslamate`
- preferred pod anti-affinity on `kubernetes.io/hostname` (`required` needs at least `instances` nodes)
- TeslaMate connects through `<fullname>-db-rw` with `DATABASE_SSL=true` and verifies the CNPG CA (`<fullname>-db-ca`); Grafana uses `sslmode=require`

Tune it through `database.cnpg.*`: `instances`, `storage`, `walStorage`, `resources`, `parameters` (PostgreSQL settings), `affinity`, `monitoring.enablePodMonitor`, `annotations`. Anything else goes into `database.cnpg.extraSpec`, which is merged into the generated `spec` with Helm's `mergeOverwrite`. A `bootstrap` in `extraSpec` replaces the default `initdb` (see [backups.md](backups.md#how-restore-works)).

## SUPERUSER

**The database owner (`teslamate`) is a PostgreSQL SUPERUSER**, declared through CNPG `managed.roles`. TeslaMate's migrations require it:

- Migration `20240929084639_recreate_geo_extensions` runs `DROP EXTENSION cube CASCADE` and `CREATE EXTENSION earthdistance`. `earthdistance` is not a trusted extension, so only a superuser can create it.
- Future TeslaMate releases may add more migrations like this.

This matches the upstream docker-compose setup, where `POSTGRES_USER=teslamate` makes the TeslaMate user the superuser.

**Because of this, use this database only for TeslaMate. Do not host other applications' databases in the same cluster.**

## Read-only Grafana role

Grafana editors can run arbitrary SQL through the datasource. Use a dedicated role:

```sh
kubectl -n teslamate create secret generic grafana-db --type=kubernetes.io/basic-auth \
  --from-literal=username=grafana --from-literal=password=$(openssl rand -base64 24)
```

```yaml
grafana:
  readOnlyUser:
    enabled: true
    username: grafana          # must match the secret's "username"
    existingSecret: grafana-db
```

The chart declares the role through CNPG `managed.roles` (login, member of `pg_read_all_data`, password from the secret) and Grafana connects with it. Only available with `database.type: cnpg`; `helm test` verifies the membership.

## Uninstall

`database.cnpg.keepOnUninstall: true` (default) annotates the Cluster (and the ObjectStore, if backups are enabled) with `helm.sh/resource-policy: keep`, so `helm uninstall` leaves the database and its PVCs in place. Set it to `false` to delete them with the release. See the README, "Uninstall".

## External PostgreSQL

```yaml
database:
  type: external
  external:
    host: postgres.example.com
    port: 5432
    database: teslamate
    username: teslamate
    existingSecret: teslamate-db
    existingSecretPasswordKey: password
    ssl: "true"                  # false | true | noverify
```

The chart creates no roles for external databases, and backups (`database.cnpg.backup`) are rejected. The user must be able to run TeslaMate's migrations, including `CREATE EXTENSION earthdistance` (see above), so grant it SUPERUSER yourself. Grafana's `sslmode` defaults to `disable` for external databases; set `grafana.databaseSslMode` if your server uses TLS.

## Embedded database (test only)

> [!WARNING]
> - **The embedded database is not supported.** The intended and recommended setups for this chart are a CNPG cluster (`cnpg`, default) or an external PostgreSQL server (`external`). Issues that only affect the embedded database will not be addressed.
> - **This chart treats the embedded database as a test setup.** The CNPG cluster is the robust option, with replication, TLS, scheduled backups, automated upgrades and restores. The embedded database has none of these.

It is meant for a quick start without installing the CNPG operator or providing a PostgreSQL server:

```yaml
database:
  type: embedded
  embedded:
    persistence:
      size: 5Gi
    existingSecret: ""           # optional, key "password"; otherwise a random password is generated
```

- A single-replica StatefulSet `<fullname>-postgresql` with the official `postgres` image (`database.embedded.image`), a Service of the same name and one PVC (`data-<fullname>-postgresql-0`).
- The owner (`database.embedded.username`, default `teslamate`) is the image's `POSTGRES_USER` and therefore a SUPERUSER, as with CNPG.
- No TLS: TeslaMate uses `DATABASE_SSL=false` and Grafana `sslmode=disable`.
- `grafana.readOnlyUser` and `database.cnpg.backup` are rejected.
- The generated password Secret and the PVC are kept on `helm uninstall`. The password is only applied when the data directory is first initialised, so do not delete the Secret while you keep the PVC.
- The PVC comes from `volumeClaimTemplates`: changing `persistence` after the install fails the upgrade.
- **Never change the PostgreSQL major version of the image.** PostgreSQL 18 images keep their data in a version-specific directory, so a different major starts with an empty database. Move to a new major with a dump and restore.

### Moving to CNPG

Dump the embedded database, then install the chart with `database.type: cnpg` (in a new namespace or release) and restore it as described in [migrating-from-docker-compose.md](migrating-from-docker-compose.md), starting at step 2:

```sh
kubectl -n teslamate scale deploy/teslamate --replicas=0
kubectl -n teslamate exec teslamate-postgresql-0 -- pg_dump -U teslamate teslamate > teslamate.bck
```

## Importing existing data

See [migrating-from-docker-compose.md](migrating-from-docker-compose.md).
