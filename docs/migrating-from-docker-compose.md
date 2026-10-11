# Migrating from docker-compose

Move an existing [upstream docker-compose installation](https://docs.teslamate.org/docs/installation/docker) to this chart with a logical dump and restore.

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
