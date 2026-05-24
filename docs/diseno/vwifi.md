# vwifi — virtual WiFi for mesh tests

[vwifi](https://github.com/Raizo62/vwifi) bridges `mac80211_hwsim` radios across separate QEMU VMs, making them visible to each other as if they share physical WiFi. This is what allows LibreMesh's batman-adv/babeld mesh to form between virtual nodes.

## How it works

```
VM1 (mac80211_hwsim + vwifi-client) ──┐
VM2 (mac80211_hwsim + vwifi-client) ──┼── TCP ──► vwifi-server (host)
VM3 (mac80211_hwsim + vwifi-client) ──┘
```

- `mac80211_hwsim` creates virtual WiFi radios inside each VM
- `vwifi-client` connects each VM's radios to `vwifi-server` over TCP
- `vwifi-server` forwards 802.11 frames between all connected clients
- VMs see a shared medium — association, beacons, and mesh peering work normally

Without vwifi, hwsim radios on different VMs are isolated and batman-adv cannot form neighbors across VMs.

## Installing vwifi-server (host)

```bash
git clone https://github.com/Raizo62/vwifi.git
cd vwifi
make
sudo make install   # installs vwifi-server to /usr/local/bin
```

Or build from the Debian/Ubuntu package if available:

```bash
sudo apt install vwifi   # if packaged in your distro
```

Verify:

```bash
vwifi-server --version
```

## Installing vwifi-client (VM image)

The client is built as an OpenWrt package via the feed at [`vwifi_cli_package`](https://github.com/javierbrk/vwifi_cli_package). To include it in a custom image:

1. Clone OpenWrt
2. Add to `feeds.conf`:
   ```
   src-git vwifi https://github.com/javierbrk/vwifi_cli_package.git
   ```
3. Update and install feeds:
   ```bash
   scripts/feeds update -a
   scripts/feeds install -a
   ```
4. Enable in `make menuconfig` → Network → vwifi-client
5. Build the image

Pre-built images with vwifi-client are stored at `firmwares/qemu/libremesh/`.

## Configuring vwifi-client inside a VM

After boot, the client needs to know the server IP (the QEMU host is always `10.0.2.2` in user-mode networking):

```bash
uci set vwifi.config.server_ip=10.0.2.2
uci set vwifi.config.mac_prefix="74:f8:f6:66"
uci set vwifi.config.enabled='1'
uci commit vwifi
service vwifi-client start
```

In the LibreMesh images used for CI this is pre-configured at build time — the client starts automatically on boot.

## Running vwifi-server for tests

Start the server before launching VMs:

```bash
vwifi-server &
```

The default port is `9090` (TCP). VMs connect on startup; no further configuration needed on the host side.

## Verifying the mesh formed

After VMs are up and vwifi-client is running in each:

```bash
# On vm1 (ssh -p 10022 root@127.0.0.1)
batctl n       # should show MAC addresses of vm2, vm3
ip route show proto babel   # babeld routes should appear
```

If `batctl n` is empty, check:

1. `vwifi-server` is running on the host
2. `vwifi-client` started in each VM (`logread | grep vwifi`)
3. `wpad` is running and `wlan0-mesh` is up (`ip link show wlan0-mesh`)
4. `kmod-mac80211-hwsim` is loaded (`lsmod | grep hwsim`)

## References

- [vwifi GitHub](https://github.com/Raizo62/vwifi)
- [vwifi on OpenWrt wiki](https://github.com/Raizo62/vwifi/wiki/Install-on-OpenWRT-X86_64)
- [vwifi_cli_package feed](https://github.com/javierbrk/vwifi_cli_package)
