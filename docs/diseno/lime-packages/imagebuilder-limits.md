# ImageBuilder limits for RAM-bootable LibreMesh

`tools/ci/build_image.sh` produces RAM-bootable LibreMesh images by
repacking three artifacts that come out of `make image PROFILE=...`:

1. The pre-built kernel binary `<profile>-kernel.bin`.
2. The pre-built device tree blob `image-<dts>.dtb` (FIT only).
3. A freshly-built rootfs CPIO of the LibreMesh root.

These are wrapped in a FIT (mediatek/filogic, mt7622) or in a legacy
`IH_TYPE_MULTI` uImage (ath79) that the testbed TFTP-boots from RAM.
The strategy works only when ImageBuilder ships a `KERNEL_INITRAMFS`
recipe for the profile - otherwise it cannot emit a kernel binary
that is RAM-bootable on its own.

This page documents two devices that fall outside that path and the
prototype work that was rejected.

## Devices with special build paths

### `librerouter_librerouter-v1` (ath79/generic, MIPS) - dual-TFTP

Integrated into the CI matrix via `IMAGE_FORMAT=dual-tftp`. The ath79
ImageBuilder cannot produce an initramfs kernel
(`CONFIG_INITRAMFS_SOURCE` requires kernel recompilation), so the CI
ships two separate TFTP artifacts instead - see
[dual-TFTP boot](#dual-tftp-boot-kernel--ramdisk-uimage) below.

### `linksys_e8450` legacy (mediatek/mt7622, NAND non-UBI)

Replaced in `targets.yml` with `linksys_e8450-ubi`, which targets the
same Belkin RT3200 hardware via the UBI boot path. The legacy profile
in `target/linux/mediatek/image/mt7622.mk` does not define a
`KERNEL_INITRAMFS` recipe, so
`linksys_e8450-kernel.bin` is never produced under
`build_dir/.../linux-mediatek_mt7622/`. The `-ubi` profile defines
`KERNEL_INITRAMFS` and is the upstream-recommended boot path.

## Prototypes rejected for ath79

Three build paths for `librerouter_librerouter-v1` were tried before
removing the device from CI:

1. **`image_format: multi-uimage`** (legacy `IH_TYPE_MULTI` uImage with
   `[kernel.lzma, rootfs.cpio]`). The kernel boots, but the LibreRouter
   U-Boot 1.1.x fork ([LibreRouterOrg/u-boot][lr-uboot],
   `lib_mips/mips_linux.c`) does not propagate sub-image-1 to the MIPS
   kernel as `initrd_start` / `initrd_size`. The kernel cmdline ends up
   `console=ttyS0,115200n8 rootfstype=squashfs,jffs2`, the initramfs
   unpacker never runs, and the device falls through to the on-flash
   squashfs. CI symptom: `root@margarita:/#` instead of
   `root@LiMe-XXXXXX:/#`.

2. **OpenWrt SDK** (`ghcr.io/openwrt/sdk:ath79-generic-*`).
   `make image` inside the SDK fails immediately:

       make[1]: *** No rule to make target 'image'. Stop.

   The SDK ships only the `package/` subtree and the host toolchain;
   its `target/` and `include/image.mk` are deliberately stripped. By
   design the SDK compiles `.ipk` files against a pre-built kernel; it
   cannot rebuild the kernel.

3. **ImageBuilder with `CONFIG_TARGET_ROOTFS_INITRAMFS=y`**. Even with
   the kconfig flag forced, ImageBuilder only emits
   `*-squashfs-sysupgrade.bin`. `include/image.mk` skips the initramfs
   recipe entirely under `$(if $(IB),,...)`, again because there are
   no kernel sources to recompile.

[lr-uboot]: https://github.com/LibreRouterOrg/u-boot

## Dual-TFTP boot (kernel + ramdisk uImage)

Instead of embedding the CPIO in the kernel, the CI ships two separate
TFTP artifacts. U-Boot loads each to a distinct RAM address and
`bootm <kernel> <ramdisk>` passes the initrd boundaries natively.

| Artifact | RAM address | Source |
|---|---|---|
| `kernel.bin` (uImage lzma + appended DTB) | `0x82000000` | ImageBuilder pre-built |
| `rootfs.uimage` (uImage ramdisk wrapping newc CPIO) | `0x84000FC0` | `build_image.sh` via `mkimage -T ramdisk` |

U-Boot sequence:

```
tftp 0x82000000                         # kernel
tftp 0x84000FC0 ${bootfile_initrd}      # ramdisk uImage
bootm 0x82000000 0x84000FC0
```

### Why not `rd_start`/`rd_size` bootargs?

The ImageBuilder kernel for ath79 (OpenWrt 24.10) ships with:

- `CONFIG_MIPS_CMDLINE_FROM_DTB=y` - take kernel arguments from the
  Device Tree (DTB) embedded in the kernel image.
- `CONFIG_CMDLINE_BOOL=y` with `CONFIG_CMDLINE="rootfstype=squashfs,jffs2"`.

The LibreRouter DT (`qca955x.dtsi`) sets
`chosen { bootargs = "console=ttyS0,115200n8"; }`. Because
`MIPS_CMDLINE_DTB_EXTEND` is not enabled, U-Boot `bootargs` (including
`rd_start=`, `rd_size=`, or `initrd=`) are not merged into the command
line the kernel actually uses. The serial log therefore shows only
`console=ttyS0,115200n8 rootfstype=squashfs,jffs2`.

Note: `CONFIG_CMDLINE_OVERRIDE` is **not** set on ath79 in OpenWrt
24.10 (`target/linux/ath79/config-6.6`). That option would force the
compiled-in line only; on LibreRouter the same practical outcome comes
from `MIPS_CMDLINE_FROM_DTB` plus DT `chosen/bootargs`.

### How two-argument `bootm` bypasses this

When U-Boot receives `bootm <kernel_addr> <ramdisk_addr>`, its
`do_bootm_linux()` (in `lib_mips/mips_linux.c` on the Atheros 1.1.x
fork) reads the uImage header at `<ramdisk_addr>`, computes the data
boundaries, and passes `initrd_start`/`initrd_end` to the kernel via
`linux_env_set()`. This mechanism operates through the MIPS boot
parameter block, not through the kernel command line, so DT bootargs and
`MIPS_CMDLINE_FROM_DTB` do not block initrd loading.

### Page alignment

The ramdisk loads at `0x84000FC0` (not `0x84000000`) so the CPIO
data - which starts 64 bytes past the uImage header - lands at
`0x84001000`, a 4K page boundary. The kernel rejects non-aligned
initrd with `initrd start must be page aligned`.

### INITRAMFS=1 in `/init`

The CPIO's `/init` must export `INITRAMFS=1` before exec'ing
`/sbin/init` (procd). Without this variable, OpenWrt's
`/lib/preinit/80_mount_root` registers `do_mount_root`, which finds the
`rootfs_data` partition on flash, attempts a jffs2 overlay +
`pivot_root` (which fails on rootfs), and the ramoverlay fallback loses
`/proc`. Result: `lime-config` never runs, hostname stays `(none)`.

`build_image.sh` creates this script (matching OpenWrt upstream
`target/linux/generic/other-files/init`):

```sh
#!/bin/sh
export INITRAMFS=1
exec /sbin/init
```

### Requirements

- `CONFIG_BLK_DEV_INITRD=y` (ath79/generic enables it via
  `FEATURES:=ramdisk`).
- U-Boot must support two-argument `bootm` with `IH_TYPE_RAMDISK`
  (Atheros 1.1.x does).
- The rootfs CPIO must contain `/init` with `INITRAMFS=1`.

`build_image.sh` implements this as `IMAGE_FORMAT=dual-tftp`.
`targets.yml` entry: `librerouter_v1` with `image_format: dual-tftp`.

## Rejected: full source build

A full OpenWrt source-tree build (`make world`) with
`CONFIG_INITRAMFS_SOURCE` pointing at the LibreMesh CPIO was
prototyped (`build_image_source.sh`, ~780 lines, `v24.10.6`).
Cold: ~50-60 min, warm: ~10-20 min. Discarded for excessive build
time and maintenance surface. The prototype lives in git history
(commit `057282fd`) if ever needed as fallback.

## Manual lab runs

For local lab runs with the dual-TFTP path:

```bash
labgrid-client -p labgrid-fcefyn-librerouter_1 acquire
export LG_PLACE=labgrid-fcefyn-librerouter_1
export LG_ENV=targets/librerouter_v1.yaml
export LG_IMAGE=/path/to/kernel.bin
export LG_IMAGE_INITRD=/path/to/rootfs.uimage
uv run python -m pytest tests/test_libremesh.py tests/test_base.py tests/test_lan.py -v
labgrid-client -p labgrid-fcefyn-librerouter_1 release
```

## See also

- [CI: firmware build pipeline](../lime-packages-ci-flow.md) - the
  high-level pipeline that consumes `BUILD_INITRAMFS=1` artifacts.
- `tools/ci/build_image.sh` - the `mkimage` repack flow and
  `dual-tftp` artifact emission.
- `.github/ci/targets.yml` - `build_initramfs` / `test_firmware` keys.
