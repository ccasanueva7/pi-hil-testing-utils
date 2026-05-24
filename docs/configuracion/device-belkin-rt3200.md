# Belkin RT3200 / Linksys E8450

Three units in the lab (**belkin_rt3200_1**, **belkin_rt3200_2**, **belkin_rt3200_3**). Same hardware sold under Belkin (RT3200) and Linksys (E8450) brands. Primary DUT for LibreMesh CI.

## Hardware

| Attribute | Detail |
|-----------|--------|
| SoC | MediaTek **MT7622BV** (dual Cortex-A53 @ 1.35 GHz) + MT7915E (Wi-Fi 6) |
| Architecture | ARM64 |
| RAM | 512 MB DDR3 |
| Flash | 128 MB SPI-NAND (**UBI** layout on OpenWrt) |
| Ethernet | 5 × 1 GbE (1 WAN + 4 LAN) |
| Wi-Fi | Dual-band AX3200 (2.4 GHz 2×2 + 5 GHz 4×4) |
| USB | 1 × USB 2.0 |
| OpenWrt target | `mediatek/mt7622` — profile `linksys_e8450-ubi` |

## Lab placement

| Place name | Rack slot | VLAN (isolated) | VLAN (mesh) |
|------------|-----------|-----------------|-------------|
| `belkin_rt3200_1` | Slot 1 | 100 | 200 |
| `belkin_rt3200_2` | Slot 2 | 101 | 200 |
| `belkin_rt3200_3` | Slot 3 | 102 | 200 |

Power is controlled via Arduino relay. Serial console via USB-to-serial adapter connected to the host.

## Firmware

OpenWrt uses **UBI** layout on this device — the standard sysupgrade image does not apply. Use the `-initramfs-kernel.bin` for testing (TFTP boot, no flash write).

```
linksys_e8450-ubi-initramfs-kernel.bin    # OpenWrt
lime-linksys_e8450-ubi-initramfs-kernel.bin  # LibreMesh
```

TFTP path: `/srv/tftp/belkin_rt3200_N/` where N is 1, 2 or 3.

## Running tests

```bash
# Single unit — OpenWrt base tests
LG_PLACE=labgrid-fcefyn-belkin_rt3200_1 \
LG_IMAGE=/srv/tftp/belkin_rt3200_1/linksys_e8450-ubi-initramfs-kernel.bin \
uv run pytest tests/ -v

# Single unit — LibreMesh tests
LG_PLACE=labgrid-fcefyn-belkin_rt3200_1 \
LG_IMAGE=/srv/tftp/belkin_rt3200_1/lime-linksys_e8450-ubi-initramfs-kernel.bin \
uv run pytest tests/test_libremesh.py -v
```

SSH shortcut (after test boot):

```bash
ssh dut-belkin-rt3200-1   # alias defined in ~/.ssh/config
```

## CI

CI job name pattern: `test-firmware (belkin_rt3200_N / RELEASE)`

Results published to: `docs/ci-results/results/physical/belkin_rt3200_N-RELEASE/report.xml`

## Known issues

- UBI migration must be done once before any initramfs test if the device was previously flashed with the non-UBI image. See [OpenWrt TOH](https://openwrt.org/toh/linksys/e8450) for the procedure.
- Serial baud rate: **115200**.
