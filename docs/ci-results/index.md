# CI Test Dashboard

The FCEFyN Testbed CI Test Dashboard provides a real-time view of LibreMesh firmware test results across all physical lab devices and virtual (QEMU) targets.

## Access

**[Open Dashboard :material-open-in-new:](dashboard.html){ .md-button .md-button--primary }**

The dashboard is a static page hosted on GitHub Pages. It loads automatically and requires no login.

## What it shows

| Column | Source | Description |
|--------|--------|-------------|
| Status pill | GitHub Actions API | Latest job conclusion (Pass / Fail / Skipped) |
| Run history | GitHub Actions API | Last 10 runs as a color strip — click any bar to open that run |
| Test details | Published `report.xml` | Per-test-case breakdown once the CI publish pipeline runs |
| Duration | GitHub Actions API | Wall-clock time of the latest job |

## Device coverage

| Device | Place | Type | Release |
|--------|-------|------|---------|
| Linksys E8450 (Belkin RT3200) | `belkin_rt3200_1` | Physical | 24.10.6 |
| Linksys E8450 (Belkin RT3200) | `belkin_rt3200_2` | Physical | 24.10.6 |
| Linksys E8450 (Belkin RT3200) | `belkin_rt3200_3` | Physical | 24.10.6 |
| Bananapi BPi-R4 | `bananapi_bpi-r4` | Physical | 24.10.6 |
| OpenWrt One | `openwrt_one` | Physical | 24.10.6 |
| QEMU x86-64 | — | QEMU single | 24.10.6 / 25.12.2 |
| QEMU x86-64 | — | QEMU mesh | 24.10.6 / 25.12.2 |
