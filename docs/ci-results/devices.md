# Device Registry

The dashboard device list is defined in `docs/ci-results/results/devices.json`. This file serves two purposes:

1. Provides display names and metadata for devices that appear in CI job names
2. Registers device/release combinations that the dashboard should always show, even if no recent CI run exists for them

## File format

```json
{
  "last_updated": "2026-05-23T00:00:00Z",
  "devices": [
    {
      "id": "physical-belkin_rt3200_1-24.10.6",
      "device": "linksys_e8450",
      "display_name": "Belkin RT3200 #1",
      "place": "belkin_rt3200_1",
      "release": "24.10.6",
      "type": "physical",
      "results_path": "physical/belkin_rt3200_1-24.10.6/report.xml"
    }
  ]
}
```

### Fields

| Field | Description |
|-------|-------------|
| `id` | Unique identifier. Must match the ID derived by the dashboard from the CI job name. Format depends on `type` — see below |
| `device` | OpenWrt device profile name (e.g. `linksys_e8450`, `bananapi_bpi-r4`) |
| `display_name` | Human-readable label shown in the card title |
| `place` | Labgrid place name for physical devices; `null` for QEMU |
| `release` | OpenWrt release string (e.g. `24.10.6`, `25.12.2`) |
| `type` | Job category — see [Job types](#job-types) |
| `results_path` | Path to `report.xml` relative to `docs/ci-results/results/` |

### ID format by type

| Type | ID format | Example |
|------|-----------|---------|
| `physical` | `physical-{place}-{release}` | `physical-belkin_rt3200_1-24.10.6` |
| `qemu-single` | `qemu-single-{device}-{release}` | `qemu-single-qemu_x86_64-24.10.6` |
| `qemu-mesh` | `qemu-mesh-{device}-{release}` | `qemu-mesh-qemu_x86_64-25.12.2` |
| `mesh` | `physical-mesh-{release}` | `physical-mesh-24.10.6` |
| `mesh-pair` | `mesh-pair-{index}-{release}` | `mesh-pair-1-24.10.6` |
| `unit` | `unit-{variant}` | `unit-default` |

## Job types

The dashboard recognises the following CI job name patterns and maps them to types:

| Type | CI job name pattern | Filter tab |
|------|--------------------|----|
| `physical` | `test-firmware (place / release)` | Physical |
| `mesh` | `test-mesh (N=n / release)` or `test-mesh (release)` | Mesh |
| `mesh-pair` | `test-mesh-pairs (#n devA+devB / release)` | Mesh pairs |
| `qemu-single` | `test-firmware-qemu-single (device / release)` | QEMU single |
| `qemu-mesh` | `test-mesh-qemu (device / release)` | QEMU mesh |
| `unit` | `test-unit` or `test-unit (variant)` | Unit |

## Registered devices

### Physical

| ID | Device | Place | Release |
|----|--------|-------|---------|
| `physical-belkin_rt3200_1-24.10.6` | `linksys_e8450` | `belkin_rt3200_1` | 24.10.6 |
| `physical-belkin_rt3200_2-24.10.6` | `linksys_e8450` | `belkin_rt3200_2` | 24.10.6 |
| `physical-belkin_rt3200_3-24.10.6` | `linksys_e8450` | `belkin_rt3200_3` | 24.10.6 |
| `physical-bpi_r4_1-24.10.6` | `bananapi_bpi-r4` | `bpi_r4_1` | 24.10.6 |
| `physical-openwrt_one_1-24.10.6` | `openwrt_one` | `openwrt_one_1` | 24.10.6 |
| `physical-belkin_rt3200_1-25.12.2` | `linksys_e8450` | `belkin_rt3200_1` | 25.12.2 |
| `physical-belkin_rt3200_2-25.12.2` | `linksys_e8450` | `belkin_rt3200_2` | 25.12.2 |
| `physical-belkin_rt3200_3-25.12.2` | `linksys_e8450` | `belkin_rt3200_3` | 25.12.2 |
| `physical-bpi_r4_1-25.12.2` | `bananapi_bpi-r4` | `bpi_r4_1` | 25.12.2 |
| `physical-openwrt_one_1-25.12.2` | `openwrt_one` | `openwrt_one_1` | 25.12.2 |

### QEMU

| ID | Device | Type | Release |
|----|--------|------|---------|
| `qemu-single-qemu_x86_64-24.10.6` | `qemu_x86_64` | single | 24.10.6 |
| `qemu-single-qemu_x86_64-25.12.2` | `qemu_x86_64` | single | 25.12.2 |
| `qemu-mesh-qemu_x86_64-24.10.6` | `qemu_x86_64` | mesh | 24.10.6 |
| `qemu-mesh-qemu_x86_64-25.12.2` | `qemu_x86_64` | mesh | 25.12.2 |

## Adding a new device

1. Add the device to `targets.yml` in `lime-packages` with `test_firmware: true` and the corresponding `test_places` entry
2. Add an entry to `devices.json` with the correct `id`, `place`, `release`, and `results_path`
3. The CI publish pipeline will start populating `report.xml` after the next scheduled run
