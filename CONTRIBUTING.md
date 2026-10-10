# Contributing

Thanks for helping improve the TeslaMate Helm chart. By contributing you agree that your work is licensed under Apache-2.0.

## Development setup

Required tools:

- [Helm](https://helm.sh/docs/intro/install/) >= 3.14 (Helm 4 works too)
- [helm-unittest](https://github.com/helm-unittest/helm-unittest): `helm plugin install https://github.com/helm-unittest/helm-unittest`
- [chart-testing (ct)](https://github.com/helm/chart-testing)
- [helm-docs](https://github.com/norwoodj/helm-docs)
- [kind](https://kind.sigs.k8s.io/) and kubectl, for end-to-end tests
- optional: [pre-commit](https://pre-commit.com/) (`pre-commit install`)

## Checks

The chart lives at the repository root.

```sh
helm lint . --set teslamate.encryptionKey=x   # static lint
helm unittest .                                # unit tests in tests/
ct lint --config ct.yaml                       # chart-testing lint (version bump, yamllint, schema)
helm-docs                                      # regenerate README.md from README.md.gotmpl and values.yaml
```

Run an end-to-end install against a throwaway cluster:

```sh
kind create cluster
helm install cnpg cloudnative-pg --repo https://cloudnative-pg.github.io/charts -n cnpg-system --create-namespace --wait
scripts/e2e.sh ci/<scenario>-values.yaml       # install, `helm test`, uninstall (release and namespace "teslamate")
```

The CNPG operator is a test prerequisite, not part of the chart. The operator, the Barman Cloud plugin and backups/restores are out of scope for the chart's tests. CI runs `ct lint` plus `scripts/e2e.sh`, not `ct install`.

## Pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`, ...). Mark breaking changes with `!` or a `BREAKING CHANGE:` footer.
- Bump `version` in `Chart.yaml` for every change that affects the packaged chart (semver: patch for fixes, minor for features, major for breaking value changes). CI enforces this.
- Add or update unit tests in `tests/` and, for behaviour changes, a scenario in `ci/`.
- Document every new value with a `# --` comment in `values.yaml`, then run `helm-docs` and commit the regenerated `README.md`. CI fails on drift.
- Add an entry under `[Unreleased]` in `CHANGELOG.md`.
- Never commit secrets or real credentials.

## Releases (maintainers)

Update `version` in `Chart.yaml` and `CHANGELOG.md`, merge to `main`, then push a tag `vX.Y.Z` matching the chart version. The release workflow publishes to GHCR and creates the GitHub Release.

## Conduct

Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately, see [SECURITY.md](SECURITY.md).
