# Upgrading

Always read `CHANGELOG.md` first.

## Chart

```sh
helm upgrade teslamate oci://ghcr.io/dcardozoo/charts/teslamate -n teslamate -f values.yaml --wait
```

Do not forget your values; use `--reuse-values` only if you know what you are doing, since new chart versions add values.

## CNPG operator and Barman Cloud plugin

They are not part of this chart: upgrade them on their own, following the [CNPG upgrade guide](https://cloudnative-pg.io/docs/current/installation_upgrade/) and the [CNPG release notes](https://github.com/cloudnative-pg/cloudnative-pg/releases). The operator and its CRDs are cluster-wide and affect every CNPG cluster.

## TeslaMate

Set `teslamate.image.tag` and `grafana.image.tag` (both default to the chart `appVersion`) and keep them on the same version, or just upgrade the chart. Migrations run automatically when TeslaMate starts.

Read the [TeslaMate release notes](https://github.com/teslamate-org/teslamate/releases) before major jumps; some releases need manual steps. Take a backup first (see [backups.md](backups.md)). The Deployment uses the `Recreate` strategy, so expect a short downtime and a gap in data collection.

## PostgreSQL

Minor updates: bump `database.cnpg.imageName` to a newer tag of the same major; CNPG performs a rolling update with a switchover.

Major upgrades are not automated by this chart; Renovate pins the major version in the default image. Changing the major in `imageName` of an existing cluster is not a plain rolling update. Recent CNPG releases support in-place major upgrades through `pg_upgrade`; see the [CNPG documentation on PostgreSQL upgrades](https://cloudnative-pg.io/docs/current/postgres_upgrades/) and take a backup first. The alternative is a logical dump and restore into a new cluster (see below). TeslaMate also documents [upgrading PostgreSQL](https://docs.teslamate.org/docs/maintenance/upgrading_postgres).

## Migrating from docker-compose

1. On the old host, create a dump as described in the [upstream backup guide](https://docs.teslamate.org/docs/maintenance/backup):

   ```sh
   docker compose exec -T database pg_dump -U teslamate teslamate > teslamate.bck
   ```

2. Install this chart with the **same `ENCRYPTION_KEY`** as the old installation, otherwise the stored Tesla tokens are unreadable (or sign in to Tesla again after the import).

3. Stop TeslaMate so it does not write during the restore:

   ```sh
   kubectl -n teslamate scale deploy/teslamate --replicas=0
   ```

4. Restore. The [upstream restore steps](https://docs.teslamate.org/docs/maintenance/restore) drop and recreate the schema and extensions, which needs a superuser. Run them as `postgres` through `kubectl exec` on the primary (the pod names are `<fullname>-db-1`, `-2`; check which one is primary with `kubectl -n teslamate get cluster`):

   ```sh
   PRIMARY=$(kubectl -n teslamate get cluster.postgresql.cnpg.io teslamate-db -o jsonpath='{.status.currentPrimary}')

   kubectl -n teslamate exec -i $PRIMARY -c postgres -- psql -U postgres -d teslamate <<'SQL'
   SET ROLE teslamate;
   DROP SCHEMA IF EXISTS public CASCADE;
   DROP SCHEMA IF EXISTS private CASCADE;
   CREATE SCHEMA public;
   CREATE EXTENSION cube WITH SCHEMA public;
   CREATE EXTENSION earthdistance WITH SCHEMA public;
   SQL

   kubectl -n teslamate exec -i $PRIMARY -c postgres -- psql -U postgres -d teslamate -c 'SET ROLE teslamate' -f - < teslamate.bck
   ```

   Inside the CNPG pod, `postgres` connects over the local socket without a password. `SET ROLE teslamate` makes `teslamate` the owner of everything created, as on a fresh install.

5. Start TeslaMate again; migrations for newer versions run on start:

   ```sh
   kubectl -n teslamate scale deploy/teslamate --replicas=1
   ```

Note: edit the pod/cluster names if you changed `fullnameOverride`.
