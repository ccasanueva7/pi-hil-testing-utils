# Using the Dashboard

## Accessing the dashboard

Open **[https://fcefyn-testbed.github.io/fcefyn_testbed_utils/ci-results/dashboard.html](https://fcefyn-testbed.github.io/fcefyn_testbed_utils/ci-results/dashboard.html)** in any browser. No login required.

## Reading a device card

```
┌─────────────────────────────────────────────┐
│ Belkin RT3200 #1                   PHYSICAL │
│ belkin_rt3200_1 · OpenWrt 24.10.6      Pass │
├─────────────────────────────────────────────┤
│ ██ ██ ██ ██ ██ ██  last 6                  │
│                                             │
│ ✓ 12 passed  · 14 total  · 38.2s           │
│ ████████████████░░░░                        │
│ ▾ Test cases                                │
│                                             │
│ May 23, 10:26 AM · 5m 52s  Report ↗  CI ↗  │
└─────────────────────────────────────────────┘
```

| Element | Description |
|---------|-------------|
| **Status pill** | `Pass` / `Fail` / `Skipped` — result of the latest run |
| **Run history strip** | Each bar = one run (green=pass, red=fail, orange=skipped). Hover to see date and duration. Click to open that run in GitHub Actions |
| **Test summary** | Pass/fail/skip counts and total duration from the latest `report.xml` |
| **Progress bar** | Visual proportion of pass/fail/skip across all test cases |
| **Test cases** | Expandable list of individual test names with their result and duration |
| **Report ↗** | Direct link to the published `report.xml` on GitHub Pages |
| **CI ↗** | Direct link to the GitHub Actions job log |

## Filtering and searching

### By test type

Use the filter tabs to show only a specific category of jobs:

| Tab | Shows |
|-----|-------|
| All | Every tracked job |
| Physical | Physical lab devices |
| Mesh | Physical mesh tests |
| Mesh pairs | Paired physical device tests |
| QEMU single | Single-node QEMU tests |
| QEMU mesh | Multi-node QEMU mesh tests |
| Unit | Unit tests |

### By release version

Use the **release dropdown** to filter cards by OpenWrt release (e.g. `24.10.6`, `25.12.2`). The options are populated dynamically from the jobs found in the last 10 runs.

### By name

The **search box** filters by device name or place as you type (e.g. `belkin`, `bpi`, `qemu`, `25.12`).

All three filters (type tab, release dropdown, search) apply simultaneously.

## Dark mode

Click the **🌙 / ☀️ button** in the top-right corner to toggle between light and dark mode. The preference is saved in `localStorage` and restored on the next visit. The dashboard also respects the OS-level `prefers-color-scheme` setting on first load.

## Refreshing data

Click the **Refresh** button in the header (or press **`R`** on the keyboard) to reload all data from the GitHub API without a full page reload. The button spins while the request is in flight.

The dashboard fetches live data on every load. Hard-refresh (`Ctrl+Shift+R`) also works if needed.

!!! note "API rate limit"
    The GitHub API allows 60 unauthenticated requests per hour per IP. The dashboard uses roughly 11 requests per load (1 workflow runs + 10 jobs). If you hit the rate limit, the dashboard shows an error with a retry button.

## Expanding test cases

Each card with published results has a **Test cases** toggle to show the individual test names and their outcomes. Use **Expand all / Collapse all** in the toolbar to open or close all cards at once.

## Status colors

| Color | Meaning |
|-------|---------|
| 🟢 Green | All tests passed |
| 🔴 Red | One or more tests failed |
| 🟡 Orange | Job was skipped or cancelled |
| ⚪ Grey | No runs found in the last 10 workflow executions |
