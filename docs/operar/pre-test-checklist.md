# Pre-test sanity check

A 60-second walkthrough to confirm the lab is healthy before triggering a CI run. Save yourself a failed run (and a notified Slack channel) by going through this when something feels off — e.g. after a power outage, a reboot, or a long idle period.

All commands run on the lab host (`laryc@labgrid-fcefyn`) over SSH.

---

## 1. Core services

```sh
systemctl status \
  labgrid-coordinator \
  labgrid-exporter \
  pdudaemon \
  ser2net \
  dnsmasq \
  arduino-relay-daemon \
  prometheus \
  grafana-server
```

All eight should be `active (running)`. Quick fix for any single failed unit:

```sh
sudo systemctl restart <unit>
sudo journalctl -u <unit> -n 50 --no-pager
```

## 2. Labgrid sees the places

```sh
uv run labgrid-client places
```

Expected: every active place (`labgrid-fcefyn-belkin_rt3200_1`, `_2`, `_3`, `bananapi_bpi-r4`, `openwrt_one`, etc.) is listed. If the list is shorter than usual, check `labgrid-exporter` logs.

Confirm none is stuck-locked from a previous failed run:

```sh
uv run labgrid-client who
```

Stale locks: `uv run labgrid-client -p <place> unlock --kick`.

## 3. DUT exporters reachable

Prometheus scrape status:

```sh
curl -s http://127.0.0.1:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

Every target should be `up`. A `down` target usually means the autossh tunnel for that DUT died:

```sh
sudo systemctl status dut-metrics-tunnel-<name>
sudo systemctl restart dut-metrics-tunnel-<name>
```

## 4. TFTP server has space and is responding

```sh
df -h /srv/tftp
ls /srv/tftp/firmwares/ci/ 2>/dev/null | head
```

If `/srv/tftp` is more than ~80 % full, trigger the cleanup manually (it normally runs daily via the [`tftp_cleanup`](../../ansible/roles/tftp_cleanup/README.md) role):

```sh
sudo systemctl start tftp-cleanup.service
journalctl -u tftp-cleanup.service -n 50
```

## 5. WireGuard tunnel is up (only if running upstream `openwrt-tests` jobs)

```sh
sudo wg show wg0
```

Expected: `latest handshake` within the last few minutes. If the handshake is stale:

```sh
sudo systemctl restart wg-quick@wg0
```

## 6. CI dashboard publishing pipeline (smoke test)

If you suspect the dashboard is stale, manually trigger one collection:

```sh
gh workflow run collect-lime-results.yml -R fcefyn-testbed/fcefyn_testbed_utils --ref develop
gh run watch -R fcefyn-testbed/fcefyn_testbed_utils
```

A green run with `Collected N new report.xml file(s)` confirms `LIME_PACKAGES_TOKEN` and `BOT_PR_TOKEN` are still valid.

## Quick "everything looks fine" one-liner

```sh
systemctl is-active labgrid-coordinator labgrid-exporter pdudaemon ser2net dnsmasq arduino-relay-daemon prometheus grafana-server
```

Should print eight lines of `active`. Any other state - drill down per section above.

## When something does break

[Debugging FAQ](debugging-faq.md) lists the common failure modes (Labgrid lock stuck, DUT not booting via TFTP, `wlan0-mesh` NO-CARRIER, dashboard 404, etc.) with the fix for each.
