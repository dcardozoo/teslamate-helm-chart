# Changelog

All notable changes to this chart are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the chart adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-09

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

[Unreleased]: https://github.com/dcardozoo/teslamate-helm-chart/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dcardozoo/teslamate-helm-chart/releases/tag/v0.1.0
