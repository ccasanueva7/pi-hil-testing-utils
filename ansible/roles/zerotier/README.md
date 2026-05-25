# `zerotier` role

Installs ZeroTier on the lab host and joins the FCEFyN lab network, providing an admin-only remote access path that does not depend on WireGuard.

## What it does

- Ensures `curl` is installed.
- Sanity-fixes DNS on the default-route interface (sets `8.8.8.8 / 8.8.4.4` via `resolvectl`) so the official ZeroTier install script can resolve `install.zerotier.com`. `apt.zerotier.com` is unreliable on some networks.
- Runs the official install script (`curl -s https://install.zerotier.com | bash`).
- Joins the configured `zerotier_network_id`.
- Enables and starts `zerotier-one.service`.

## Variables

| Variable | Default | Description |
|---|---|---|
| `zerotier_network_id` | `b103a835d2ead2b6` | ZeroTier network for the FCEFyN lab (same network all lab DUTs join). |

## Manual step after first run

ZeroTier requires the new node to be **authorised in ZeroTier Central** before it can talk to the network. After running the role:

1. Open https://my.zerotier.com.
2. Pick the lab network (`b103a835d2ead2b6`).
3. Find the newly joined node (its node-ID is shown in the host's `zerotier-cli listnetworks` output) and tick **Auth**.
4. Optionally assign a stable IP under "Managed IPs".

## Why this exists alongside WireGuard

- **WireGuard** connects this lab to the upstream openwrt-tests global-coordinator (see the [`wireguard`](../wireguard/README.md) role).
- **ZeroTier** is the *admin's* remote path: when WireGuard is misconfigured or the host's network is half-broken, ZeroTier still tends to come up and lets you SSH in to fix things.

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags zerotier -K
```

Verify:

```sh
zerotier-cli listnetworks
zerotier-cli info
```

See [`docs/operar/zerotier-remote-access.md`](../../../docs/operar/zerotier-remote-access.md) for the operator guide.
