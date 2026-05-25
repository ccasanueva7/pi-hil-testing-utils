# `wireguard` role

Sets up the WireGuard tunnel that connects the lab host to the upstream openwrt-tests `global-coordinator` (so the lab can be reached from `aparcar/openwrt-tests` CI).

## What it does

- Installs `wireguard-tools`.
- Generates a private key on the host (if it does not exist) under `wireguard_private_key_path`.
- Renders `/etc/wireguard/<interface>.conf` from `wg0.conf.j2` with the lab address, the peer's public key, endpoint and allowed IPs.
- Enables and starts `wg-quick@<interface>.service`.

## Variables

| Variable | Default | Description |
|---|---|---|
| `wireguard_interface` | `wg0` | Interface name (`wg-quick@wg0.service`). |
| `wireguard_private_key_path` | `/etc/wireguard/private.key` | Path to the host's WireGuard private key. |
| `wireguard_address` | `10.0.0.10/24` | Lab-side tunnel address (assigned by the coordinator maintainer). |
| `wireguard_peer_public_key` | upstream coordinator key | Public key of the global-coordinator peer. |
| `wireguard_peer_endpoint` | `195.37.88.188:51820` | Coordinator endpoint. |
| `wireguard_peer_allowed_ips` | `10.0.0.0/24` | What traffic the lab forwards over the tunnel. |
| `wireguard_peer_keepalive` | `25` | Persistent keepalive (seconds) so NAT mappings stay alive. |

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags wireguard -K
```

The WireGuard panel on the Orchestrator Host Grafana dashboard reports bandwidth, packet rate, and link status for this interface. See [`docs/configuracion/observabilidad.md`](../../../docs/configuracion/observabilidad.md).

## Notes

- The private key is generated locally and never leaves the host. The lab admin shares the corresponding **public** key with the coordinator maintainer out of band so they can add the lab as a peer.
- Rotating the key requires regenerating on the lab side and updating the peer entry on the coordinator side.
