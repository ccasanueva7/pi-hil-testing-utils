# QEMU setup for virtual mesh tests

QEMU x86_64 VMs running LibreMesh allow running multi-node mesh tests in CI without physical hardware. Each VM boots a LibreMesh image with virtual WiFi via `mac80211_hwsim` + `vwifi`.

## Requirements

### Host dependencies

```bash
# Debian/Ubuntu
sudo apt install qemu-system-x86 openssh-client

# Arch
sudo pacman -S qemu-system-x86
```

`vwifi-server` must also be installed or built from source. See [vwifi setup](vwifi.md).

### Image

The VM image must be a LibreMesh x86_64 build that includes:

| Package | Purpose |
|---------|---------|
| `kmod-mac80211-hwsim` | Virtual WiFi radios (load with `radios=0` at boot; vwifi adds them) |
| `vwifi-client` | Connects hwsim radios to vwifi-server on the host |
| `wpad-basic-mbedtls` | Required for `hostapd` to bring up mesh iface on hwsim |
| `libstdcpp6` | Dependency of vwifi-client |

!!! warning
    Without `wpad-basic-mbedtls`, `wlan0-mesh` stays `NO-CARRIER` and batman-adv sees no active interfaces. Include it in the image before testing.

Pre-built images are stored under `firmwares/qemu/libremesh/`.

## Networking model

Each VM uses QEMU **user-mode networking**:

```
-netdev user,id=net0,hostfwd=tcp:127.0.0.1:PORT-:22
```

- Host reaches each VM via `ssh -p PORT root@127.0.0.1`
- VMs reach the host (vwifi-server) at `10.0.2.2`
- No TAP, no bridge, no `sudo` required — works on GitHub-hosted runners

SSH ports are allocated sequentially from a base port (default `10022`):

| Node | SSH port |
|------|----------|
| vm1 | 10022 |
| vm2 | 10023 |
| vm3 | 10024 |

## Launching VMs manually

```bash
# Start vwifi-server on the host first (see vwifi.md)
vwifi-server &

# Launch one VM (adjust PORT and IMAGE path)
qemu-system-x86_64 \
  -nographic \
  -m 256M \
  -drive file=firmwares/qemu/libremesh/libremesh-x86_64.img,if=virtio \
  -netdev user,id=eth0,hostfwd=tcp:127.0.0.1:10022-:22 \
  -device virtio-net-pci,netdev=eth0 \
  -netdev user,id=eth1 \
  -device virtio-net-pci,netdev=eth1 &

# Wait for SSH to come up (~30s), then connect
ssh -o StrictHostKeyChecking=no -p 10022 root@127.0.0.1
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MESH_NODES` | `3` | Number of nodes to launch |
| `MESH_SSH_BASE_PORT` | `10022` | First SSH port; subsequent nodes use `base+1`, `base+2`, … |
| `VIRTUAL_MESH_IMAGE` | — | Path to the LibreMesh x86_64 image |
| `VIRTUAL_MESH_MAX_NODES` | `3` (CI) / `5` (self-hosted) | Upper limit enforced by the launcher |

## Resource limits

| Runner | Max nodes | Rationale |
|--------|-----------|-----------|
| `ubuntu-latest` (GitHub) | 3 | 2-core, ~7 GB RAM |
| Self-hosted | 5 | More CPU/RAM available |

## Running mesh tests

```bash
MESH_NODES=3 \
VIRTUAL_MESH_IMAGE=firmwares/qemu/libremesh/libremesh-x86_64.img \
uv run pytest tests/mesh/ -v
```

See [Virtual mesh design](virtual-mesh.md) for the full architecture and CI integration.
