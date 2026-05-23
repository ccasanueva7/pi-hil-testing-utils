# Dashboard Maintenance

## Updating the device list

Edit `docs/ci-results/results/devices.json` and open a PR to `develop`. Changes take effect after the next Pages deploy.

See [Device Registry](devices.md) for the full field reference.

## Rotating the TESTBED_UTILS_TOKEN

The publish pipeline uses a fine-grained PAT stored in `lime-packages` repository secrets. PATs expire — when that happens the `publish-results` job will fail with a 401 error.

To rotate:

1. Go to `github.com/settings/tokens` → generate a new fine-grained token:
    - Resource owner: `fcefyn-testbed`
    - Repository: `fcefyn_testbed_utils`
    - Permission: `Contents: Read and write`
2. Go to `github.com/fcefyn-testbed/lime-packages/settings/secrets/actions`
3. Update `TESTBED_UTILS_TOKEN` with the new value

## Re-publishing results manually

If a scheduled run published incomplete results (e.g. some jobs were skipped), trigger `build-firmware.yml` via `workflow_dispatch` to republish.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Cards show "Test details not yet published" | `publish-results` job hasn't run yet | Wait for next schedule or trigger manually |
| `publish-results` fails with 401 | `TESTBED_UTILS_TOKEN` expired | Rotate the token (see above) |
| `publish-results` fails with 403 | Token lacks `Contents: write` on `fcefyn_testbed_utils` | Regenerate with correct permissions |
| Dashboard shows no cards | GitHub API rate limit hit (60 req/h) | Wait ~1 hour and reload |
| Old results not updating | CI skipped `publish-results` (non-schedule event) | Trigger `workflow_dispatch` manually |
