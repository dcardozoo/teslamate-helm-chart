# Backups and restore

**Backups and restores are your responsibility.** This chart can configure scheduled backups through the CNPG [Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/), but it does not install the plugin and does not test or manage the backup and restore process. Always verify that you can restore your backups.

## Prerequisites

- The [CloudNativePG operator](https://cloudnative-pg.io/docs/current/installation_upgrade/).
- The [Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/docs/installation/), installed in the operator's namespace (it requires cert-manager).
- Only for `database.type: cnpg`.

## How scheduled backups work

With `database.cnpg.backup.enabled: true` the chart renders three things:

- An `ObjectStore` (`<fullname>-db`) whose `spec.configuration` is `database.cnpg.backup.objectStore`: where backups go and which credentials to use.
- The plugin entry in the `Cluster` spec with `isWALArchiver: true`: every WAL segment is archived continuously to the object store.
- A `ScheduledBackup` (`database.cnpg.backup.schedule`, six-field cron with seconds first) that takes a base backup through the plugin.

A base backup plus the archived WAL lets CNPG restore to any point in time inside the retention window (`retentionPolicy`).

```yaml
database:
  cnpg:
    backup:
      enabled: true
      schedule: "0 0 3 * * *"
      retentionPolicy: 30d
      objectStore:
        destinationPath: s3://my-bucket/teslamate/
        s3Credentials:
          accessKeyId:     {name: s3-credentials, key: ACCESS_KEY_ID}
          secretAccessKey: {name: s3-credentials, key: ACCESS_SECRET_KEY}
```

The credentials Secret must exist in the release namespace. Azure, GCS, S3-compatible stores, compression and all other `ObjectStore` fields: see the [plugin's object store documentation](https://cloudnative-pg.io/plugin-barman-cloud/docs/object_stores/).

## How restore works

CNPG never restores into an existing cluster. A restore **bootstraps a new Cluster** from the object store (base backup + WAL replay, optionally up to a point in time). With this chart:

1. Create an `ObjectStore` that points to the existing backups. Do not name it `<fullname>-db`: the chart uses that name for its own `ObjectStore` when backups are enabled.
2. Install the chart with a `bootstrap` in `database.cnpg.extraSpec`. It replaces the chart's default `initdb`:

   ```yaml
   teslamate:
     existingSecret: teslamate-encryption   # the ORIGINAL encryption key
   database:
     cnpg:
       extraSpec:
         bootstrap:
           recovery:
             source: origin
             database: teslamate
             owner: teslamate
         externalClusters:
           - name: origin
             plugin:
               name: barman-cloud.cloudnative-pg.io
               parameters:
                 barmanObjectName: <objectstore-from-step-1>
                 serverName: <old-cluster-name>   # e.g. teslamate-db
   ```

3. If the restored cluster also archives to the same bucket, set a new `database.cnpg.backup.serverName`: a non-empty WAL archive is refused.

Use the same TeslaMate encryption key as before, otherwise the stored Tesla tokens are unreadable.

## Official documentation

- [Barman Cloud plugin: usage, backups and restore](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/)
- [CloudNativePG: backup](https://cloudnative-pg.io/docs/current/backup/)
- [CloudNativePG: recovery](https://cloudnative-pg.io/docs/current/recovery/)
- [TeslaMate: backup and restore (logical dumps)](https://docs.teslamate.org/docs/maintenance/backup)
