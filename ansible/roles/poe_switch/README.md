# `poe_switch` role

Installs the PoE power-control bridge used by PDUDaemon to cut power to DUTs via the lab's TP-Link managed switch.

## What it does

- Installs `python3-netmiko` (system package, avoids PEP 668 issues with `pip`).
- Installs the `labgrid-switch-abstraction` Python package from the upstream repo (`fcefyn-testbed/labgrid-switch-abstraction`).
- Copies `scripts/switch/poe_switch_control.py` to `/usr/local/bin/`.
- Creates a config file for the script with the switch IP, credentials, and the PoE port that maps to each DUT (e.g. `openwrt_one` → port 4).
- Used by PDUDaemon's `fcefyn-poe` driver (configured in the openwrt-tests `playbook_labgrid.yml`) to power-cycle DUTs that are powered over the switch instead of via the Arduino relay.

## Variables

| Variable | Default | Description |
|---|---|---|
| `poe_switch_interface` | `enp0s25` | Ethernet interface that reaches the management VLAN of the TP-Link switch. Must match the netplan link on the host. |

(Switch IP, credentials and port→DUT mapping live in the script config rather than in role defaults.)

## Prerequisites

- The TP-Link managed switch is reachable on the host's `poe_switch_interface` (same physical Ethernet, dedicated management VLAN).
- A user with PoE-control permissions exists on the switch.

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags poe_switch -K
```

Verify the script can talk to the switch:

```sh
poe_switch_control.py status openwrt_one
poe_switch_control.py off openwrt_one && sleep 5 && poe_switch_control.py on openwrt_one
```

## Related

- [`scripts/switch/poe_switch_control.py`](../../../scripts/switch/poe_switch_control.py) — the helper script itself.
- [`docs/configuracion/poe-switch-control.md`](../../../docs/configuracion/poe-switch-control.md) — operator guide.
- `arduino_relay` role — alternative power-control path for DUTs powered through the Arduino + SSR relay board.
