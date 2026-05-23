# Using the Dashboard

## Accessing the dashboard

Open **[https://fcefyn-testbed.github.io/fcefyn_testbed_utils/ci-results/dashboard.html](https://fcefyn-testbed.github.io/fcefyn_testbed_utils/ci-results/dashboard.html)** in any browser. No login required.

## Reading a device card

```
┌─────────────────────────────────────────┐
│ Belkin RT3200 #1              PHYSICAL  │
│ belkin_rt3200_1 · OpenWrt 24.10.6  Pass │
├─────────────────────────────────────────┤
│ ██ ██ ██ ██ ██ ██  last 6              │
│                                         │
│ Test details not yet published          │
│                                         │
│ May 13, 10:26 AM · 5m 52s    View run ↗│
└─────────────────────────────────────────┘
```

| Element | Description |
|---------|-------------|
| **Status pill** | `Pass` / `Fail` / `Skipped` — result of the latest run |
| **Run history strip** | Each bar = one run (green=pass, red=fail, orange=skipped). Click a bar to open that run in GitHub Actions |
| **Test details** | Pass/fail/skip counts + individual test names once `report.xml` is published |
| **Duration** | Wall-clock time of the latest test job |
| **View run ↗** | Direct link to the GitHub Actions job log |

## Filters and search

- **All / Physical / QEMU single / QEMU mesh** — filter cards by test type
- **Search box** — filter by device name or place (e.g. `belkin`, `qemu`, `24.10`)

## Status indicator colors

| Color | Meaning |
|-------|---------|
| 🟢 Green | All tests passed |
| 🔴 Red | One or more tests failed |
| 🟡 Orange | Job was skipped or cancelled |
| ⚪ Grey | No runs found |

## Refreshing data

The dashboard fetches live data from the GitHub API on every page load. Hard-refresh (`Ctrl+Shift+R`) to force a reload.
