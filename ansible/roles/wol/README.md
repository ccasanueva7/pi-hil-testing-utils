# `wol` role

Enables Wake-on-LAN on the lab host's Ethernet interface so the machine can be powered on remotely.

## Why

Out of the box, Linux NIC drivers reset the WoL flag on every reboot (or even on `systemctl suspend`), so without re-applying it the host falls into a state where the magic packet does nothing. This role drops a tiny systemd oneshot service that re-applies `ethtool -s <interface> wol g` at boot.

## What it does

- Installs `ethtool`.
- Renders `wol.service.j2` to `/etc/systemd/system/wol.service` (a `Type=oneshot` unit that runs `ethtool -s {{ wol_interface }} wol g`).
- Reloads systemd and enables the unit so it runs on boot.

## Variables

| Variable | Default | Description |
|---|---|---|
| `wol_interface` | `enp0s25` | Name of the Ethernet interface to enable WoL on. The Lenovo T430 lab host uses `enp0s25`; change to match the actual host hardware. |

## Prerequisites

- The host BIOS / UEFI must have **Wake on LAN** enabled. On the T430 set "Wake on LAN" to **AC Only** in the Power menu.
- The MAC of `wol_interface` must be on the same broadcast domain as wherever the magic packet is sent from (or reachable via a router that supports directed broadcasts).

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags wol -K
```

Verify after the run:

```sh
sudo ethtool enp0s25 | grep "Wake-on"
# Wake-on: g       <- means the magic packet is honoured
```

Then from another machine on the same LAN, when the host is off:

```sh
wakeonlan <host-mac-address>
```

See [`docs/operar/wake-on-lan-setup.md`](../../../docs/operar/wake-on-lan-setup.md) for the full operator guide.
