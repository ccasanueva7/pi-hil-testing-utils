# CI Test Dashboard

The FCEFyN Testbed CI Test Dashboard provides a real-time view of LibreMesh firmware test results across all physical lab devices and virtual (QEMU) targets.

## Access

**[Open Dashboard :material-open-in-new:](dashboard.html){ .md-button .md-button--primary }**

The dashboard is a static page hosted on GitHub Pages. It loads automatically and requires no login.

## What it shows

### Per-card information

| Element | Source | Description |
|---------|--------|-------------|
| Status pill | GitHub Actions API | Latest job conclusion (Pass / Fail / Skipped) |
| Run history strip | GitHub Actions API | Last 10 runs as colored bars — click any bar to open that run in GitHub |
| Test details | Published `report.xml` | Per-test-case breakdown once the CI publish pipeline runs |
| Duration | GitHub Actions API | Wall-clock time of the latest job |
| Report link | GitHub Pages | Direct link to the published `report.xml` for that device |
| CI run link | GitHub Actions API | Direct link to the GitHub Actions job log |

### Stats bar

The summary bar at the top shows aggregate counts across all tracked jobs:

| Stat | Description |
|------|-------------|
| Jobs tracked | Total number of device/release combinations in the registry |
| Passing | Jobs where the latest run concluded with `success` |
| Failing | Jobs where the latest run concluded with `failure` |
| Skipped | Jobs where the latest run was skipped or cancelled |
| No data | Jobs with no runs found in the last 10 workflow executions |
| Pass rate | `passing / (passing + failing + skipped)` as a percentage |
| Avg duration | Average wall-clock duration across the latest run of each job |
| Test cases | Total individual test cases across all loaded `report.xml` files |

## Device coverage

| Device | Place | Type | Releases |
|--------|-------|------|---------|
| Linksys E8450 (Belkin RT3200) | `belkin_rt3200_1` | Physical | 24.10.6, 25.12.2 |
| Linksys E8450 (Belkin RT3200) | `belkin_rt3200_2` | Physical | 24.10.6, 25.12.2 |
| Linksys E8450 (Belkin RT3200) | `belkin_rt3200_3` | Physical | 24.10.6, 25.12.2 |
| Banana Pi BPi-R4 | `bpi_r4_1` | Physical | 24.10.6, 25.12.2 |
| OpenWrt One | `openwrt_one_1` | Physical | 24.10.6, 25.12.2 |
| QEMU x86-64 | — | QEMU single | 24.10.6, 25.12.2 |
| QEMU x86-64 | — | QEMU mesh | 24.10.6, 25.12.2 |
