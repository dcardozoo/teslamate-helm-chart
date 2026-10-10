# Security Policy

## Supported versions

Only the latest released chart version receives fixes.

## Reporting a vulnerability

Do not open a public issue. Use GitHub's private vulnerability reporting:
https://github.com/dcardozoo/teslamate-helm-chart/security/advisories/new

Include the chart version, a description and reproduction steps. You can expect an acknowledgement within 7 days.

## Scope

In scope: the chart templates and defaults (RBAC, secrets handling, exposed services, pod security).
Out of scope: vulnerabilities in TeslaMate, Grafana, Mosquitto, PostgreSQL, CloudNativePG or the Barman Cloud plugin themselves; report those to the respective upstream projects.

## Verifying releases

Released chart artifacts are signed with cosign keyless signing:

```sh
cosign verify ghcr.io/dcardozoo/charts/teslamate:<version> \
  --certificate-identity-regexp '^https://github.com/dcardozoo/teslamate-helm-chart/\.github/workflows/release\.yaml@refs/tags/v.*$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```
