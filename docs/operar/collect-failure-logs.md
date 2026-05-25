# Collecting logs from a failed CI run

How to grab everything you need to debug a failed `test-firmware` / `test-mesh*` job after it ran, without having to redo the run.

---

## 1. From GitHub Actions

Every test job uploads a `test-results-<scope>` artifact (retention: 14 days). Pieces inside:

| File | What it is |
|---|---|
| `report.xml` | JUnit XML pytest generates. Per-test-case pass/fail and stderr/stdout for failures. |
| `pytest.log` / labgrid `--lg-log` files | Console output of every Labgrid driver: console buffer, SSH I/O, power events, lock events. |
| `LG_PLACE-<sha>.log` | The most useful single file — full timeline of the run from lock to unlock. |

Download from the run's "Summary" page → "Artifacts", or via CLI:

```sh
gh run download <run-id> -R fcefyn-testbed/lime-packages -n test-results-<place>-<release>
unzip test-results-*.zip
less LG_PLACE-*.log
```

## 2. From the lab host

If the run was recent (within the last few hours), more context is available locally:

### Coordinator side

```sh
sudo journalctl -u labgrid-coordinator --since "2 hours ago" --no-pager
```

Look for lock/unlock events around the failed run's window. A stuck lock that was never released usually means a stage step crashed before the `unlock` step in the workflow.

### Exporter / driver side

```sh
sudo journalctl -u labgrid-exporter --since "2 hours ago" --no-pager
```

USB serial disconnects, `ser2net` resets, USB power events appear here.

### Power-control history

`pdudaemon` does not log to journald by default; check its log file:

```sh
sudo tail -200 /var/log/pdudaemon/pdudaemon.log
```

### TFTP serving

```sh
sudo journalctl -u dnsmasq --since "2 hours ago" --no-pager | grep -i 'sent\|denied'
```

A `denied` line for the run's image path usually means a permissions issue under `/srv/tftp/firmwares/ci/<run_id>/...`.

### DUT serial console (for live re-runs)

If the DUT is still in the failed state and reachable:

```sh
uv run labgrid-client -p labgrid-fcefyn-<place> console
```

Read the boot output. `<ctrl> + ]` quits.

## 3. From the CI dashboard

The [CI dashboard](https://fcefyn-testbed.github.io/fcefyn_testbed_utils/ci-results/dashboard.html) surfaces:

- **Run history strip** — last 10 runs per device with date/duration and a direct link to the Actions job.
- **Test cases** expander — per-test pass/fail/skip with timing.
- **Report ↗** — opens `report.xml` directly from GitHub Pages.

Useful to spot patterns ("this device fails every Sunday after the cron run").

## 4. From the auto-created healthcheck issue

On `schedule` runs, `test-firmware` opens a `CI healthcheck: <place> (<release>)` issue when it fails. The issue body has:

- Metadata table (place, device, release, run link, date).
- `lime-report.sh` output from the DUT (configs, dmesg, network, mesh tables) inside a `<details>` block.

The issue reopens on subsequent failures and adds a comment with each new failure. Once the device passes again, the issue auto-closes with a "passed" comment.

List them:

```sh
gh issue list -R fcefyn-testbed/lime-packages --label healthcheck --state all
```

## 5. Putting it together

For a typical failed run:

1. Open the run on GitHub, find the failing job, scroll the log to the first `FAILED` line — usually points to which test case.
2. Download the `test-results-*` artifact, open `LG_PLACE-*.log` to see what the DUT was doing at that moment.
3. If it looks like a hardware or power issue, jump to `labgrid-exporter` / `pdudaemon` logs on the lab host.
4. If it looks like a LibreMesh issue, open the healthcheck issue for the `lime-report` snapshot.

See also: [Debugging FAQ](debugging-faq.md) for a flat list of "this symptom → this fix".
