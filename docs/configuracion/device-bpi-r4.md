# Banana Pi BPi-R4

One unit in the lab (**bpi_r4_1**). High-performance board with 10G SFP+ ports; donated by Banana Pi. Used for LibreMesh tests requiring more capable hardware.

## Hardware

| Attribute | Detail |
|-----------|--------|
| SoC | MediaTek **MT7988A** (Filogic 880), quad-core Cortex-A73 @ 1.8 GHz |
| Architecture | ARM64 |
| RAM | 4 GB DDR4 (lab unit) |
| Storage | 8 GB eMMC + 128 MB SPI-NAND |
| Ethernet | 4 × 1 GbE + **2 × 10 GbE SFP+** |
| Wi-Fi | No on-board radio — requires miniPCIe modules |
| USB | 1 × USB 3.2 |
| Expansion | M.2 NVMe (KEY-M), M.2 KEY-B, microSD |
| OpenWrt target | `mediatek/filogic` — profile `bananapi_bpi-r4` |

## Lab placement

| Place name | VLAN (isolated) | VLAN (mesh) |
|------------|-----------------|-------------|
| `bpi_r4_1` | 103 | 200 |

Power via Arduino relay. Serial console via USB-C (UART mode).

## Firmware

```
bananapi_bpi-r4-initramfs-kernel.bin      # OpenWrt
lime-bananapi_bpi-r4-initramfs-kernel.bin    # LibreMesh
```

TFTP path: `/srv/tftp/bpi_r4_1/`

!!! note
    The BPi-R4 boots from eMMC by default. To boot via TFTP/initramfs, set the boot mode switch to **SD/TFTP** or use U-Boot environment variables. See the [BPi-R4 wiki](https://wiki.banana-pi.org/Banana_Pi_BPI-R4) for boot sequence details.

## Running tests

```bash
LG_PLACE=labgrid-fcefyn-bpi_r4_1 \
LG_IMAGE=/srv/tftp/bpi_r4_1/lime-bananapi_bpi-r4-initramfs-kernel.bin \
uv run pytest tests/test_libremesh.py -v
```

SSH shortcut:

```bash
ssh dut-bpi-r4-1
```

## CI

CI job name pattern: `test-firmware (bpi_r4_1 / RELEASE)`

Results published to: `docs/ci-results/results/physical/bpi_r4_1-RELEASE/report.xml`
