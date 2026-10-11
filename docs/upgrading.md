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

Major upgrades are not automated by this chart; Renovate pins the major version in the default image. Changing the major in `imageName` of an existing cluster is not a plain rolling update. Recent CNPG releases support in-place major upgrades through `pg_upgrade`; see the [CNPG documentation on PostgreSQL upgrades](https://cloudnative-pg.io/docs/current/postgres_upgrades/) and take a backup first. The alternative is a logical dump and restore into a new cluster, as in [migrating-from-docker-compose.md](migrating-from-docker-compose.md). TeslaMate also documents [upgrading PostgreSQL](https://docs.teslamate.org/docs/maintenance/upgrading_postgres).
