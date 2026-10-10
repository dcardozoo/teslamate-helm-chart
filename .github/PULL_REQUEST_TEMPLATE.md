## What and why

<!-- Short description of the change and the motivation. Link issues with "Fixes #123". -->

## Checklist

- [ ] PR title / commits follow Conventional Commits
- [ ] `version` in `Chart.yaml` bumped
- [ ] Unit tests in `tests/` added or updated (`helm unittest .`)
- [ ] `ct lint --config ct.yaml` passes
- [ ] New values documented with `# --` comments and `README.md` regenerated (`helm-docs`)
- [ ] `CHANGELOG.md` updated
- [ ] Ran `scripts/e2e.sh` for affected scenarios (if behaviour changed)
- [ ] Breaking changes (values renamed/removed, defaults changed) called out above
