# `virtual_mesh` role

Sets up the host so it can run multi-node QEMU mesh tests using `vwifi` to share a virtual radio medium between VMs.

## What it does

- Installs `qemu-system-x86`, `cmake`, `build-essential`, `git`, `libnl-3-dev`, `libnl-genl-3-dev`, and `pkg-config`.
- Clones [`Raizo62/vwifi`](https://github.com/Raizo62/vwifi) into `/tmp/vwifi-build/vwifi`, builds it with `cmake`, and installs `vwifi-server`, `vwifi-add-interfaces` and `vwifi-client` into `/usr/local/bin/`.
- Loads `mac80211_hwsim` on demand (the kernel module that creates virtual 802.11 radios).
- Installs a `vwifi-server.service` systemd unit that runs the broadcast server in the background, ready for QEMU VMs to attach.

## Variables

This role has no overridable variables; build is pinned to upstream `master` of vwifi (the `qemu_x86_64` package recipe in `lime-packages` pins a vetted SHA on the DUT side via `PKG_MIRROR_HASH`).

## Prerequisites

- Host can run KVM: `/dev/kvm` exists and the playbook user has access.
- Enough RAM for the planned mesh size (~512 MB per VM is a safe default; bump it for heavier scenarios).

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags virtual_mesh -K
```

Verify after the run:

```sh
which vwifi-server
systemctl status vwifi-server.service
lsmod | grep hwsim
```

A successful virtual mesh CI run uses `vwifi-server` plus N QEMU VMs each running `vwifi-client`. See [`docs/diseno/virtual-mesh.md`](../../../docs/diseno/virtual-mesh.md) and [`docs/diseno/vwifi.md`](../../../docs/diseno/vwifi.md).

## Related

- [`docs/diseno/qemu-setup.md`](../../../docs/diseno/qemu-setup.md) — VM image layout and boot flow.
- The `qemu_x86_64` matrix entry in `lime-packages/.github/ci/targets.yml` produces the `*-ext4-combined.img` image consumed here.
