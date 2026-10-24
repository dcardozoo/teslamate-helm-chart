# Changelog

All notable changes to this chart are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the chart adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.3.0] - 2026-10-24

### Changed

- TeslaMate and its Grafana image updated to 4.4.0 (chart `appVersion` 4.4.0). It runs database migrations on startup and changes how missing values are published over MQTT, see the [TeslaMate 4.4.0 release notes](https://github.com/teslamate-org/teslamate/releases/tag/v4.4.0).
- `helm test` curl image updated to 8.23.0.

## [0.2.0] - 2026-10-12

### Added

- `database.type: embedded`: a single-replica PostgreSQL StatefulSet for a quick start without the CNPG operator or an external server. Test setup only and not supported; use `cnpg` or `external` for real use.
- `helm install`/`upgrade` fails with a clear message when the CNPG operator, or the Barman Cloud plugin with backups enabled, is not installed. Offline rendering (`helm template`, ArgoCD) skips the check.

### Changed

- Database templates moved to `templates/database/cnpg/` and `templates/database/embedded/`.

### Removed

- The `minimal` CI scenario.

## [0.1.1] - 2026-10-11

### Fixed

- Chart `home` and `sources` now link to this chart's repository, so Artifact Hub shows it.

## [0.1.0] - 2026-10-11

### Added

- Initial release, packaging TeslaMate 4.3.0.
- TeslaMate Deployment with Service, optional Ingress and PVC, and a Secret for the encryption key.
- TeslaMate Grafana (dashboards preinstalled) with Service, optional Ingress and PVC.
- Eclipse Mosquitto MQTT broker with ConfigMap, Service and PVC.
- Highly available PostgreSQL via a CloudNativePG `Cluster`, with optional scheduled backups through the Barman Cloud plugin. The CNPG operator and the plugin are prerequisites and are not installed by this chart.
- The database owner is a PostgreSQL SUPERUSER, as TeslaMate's migrations require.
- `database.cnpg.keepOnUninstall` (default `true`) keeps the database on `helm uninstall`.
- `CHECK_ORIGIN=true` by default when a virtual host is known (Ingress or `teslamate.virtualHost`).
- Helm test hooks, helm-unittest suites and CI scenario values.

[Unreleased]: https://github.com/dcardozoo/teslamate-helm-chart/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/dcardozoo/teslamate-helm-chart/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/dcardozoo/teslamate-helm-chart/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/dcardozoo/teslamate-helm-chart/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/dcardozoo/teslamate-helm-chart/releases/tag/v0.1.0
