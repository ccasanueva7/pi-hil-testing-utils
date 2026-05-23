# OpenWrt One

One unit in the lab (**openwrt_one_1**). Official OpenWrt community board co-designed with Banana Pi; donated by Banana Pi. Reference platform for OpenWrt development.

## Hardware

| Attribute | Detail |
|-----------|--------|
| SoC | MediaTek **MT7981B** (Filogic 820), dual-core Cortex-A53 @ 1.3 GHz |
| Architecture | ARM64 |
| RAM | 1 GB DDR4 |
| Storage | 256 MB SPI-NAND + **16 MB SPI-NOR** (dedicated recovery partition) |
| Ethernet | 1 × 2.5 GbE (WAN) + 1 × 1 GbE (LAN) |
| Wi-Fi | Wi-Fi 6, MT7976C: 2.4 GHz 2×2 + 5 GHz 3×3 |
| PoE | 802.3af/at input on WAN port |
| USB | 1 × USB 2.0 type-A + USB-C (power/console) |
| Expansion | M.2 2242/2230 NVMe (PCIe Gen2 ×1) |
| OpenWrt target | `mediatek/filogic` — profile `openwrt_one` |

The dual-flash design (NAND + NOR) means the device can always recover from a bad NAND flash by booting from NOR. This makes it particularly suitable for CI where frequent reflashing happens.

## Lab placement

| Place name | VLAN (isolated) | VLAN (mesh) |
|------------|-----------------|-------------|
| `openwrt_one_1` | 104 | 200 |

Power via Arduino relay. Serial console via USB-C.

## Firmware

```
openwrt-one-initramfs-kernel.itb         # OpenWrt (ITB format)
lime-openwrt-one-initramfs-kernel.itb       # LibreMesh
```

TFTP path: `/srv/tftp/openwrt_one_1/`

!!! note
    The OpenWrt One uses `.itb` (FIT image) format, not `.bin`. Make sure the TFTP configuration points to the correct file extension.

## Running tests

```bash
LG_PLACE=labgrid-fcefyn-openwrt_one_1 \
LG_IMAGE=/srv/tftp/openwrt_one_1/lime-openwrt-one-initramfs-kernel.itb \
uv run pytest tests/test_libremesh.py -v
```

SSH shortcut:

```bash
ssh dut-openwrt-one-1
```

## CI

CI job name pattern: `test-firmware (openwrt_one_1 / RELEASE)`

Results published to: `docs/ci-results/results/physical/openwrt_one_1-RELEASE/report.xml`
