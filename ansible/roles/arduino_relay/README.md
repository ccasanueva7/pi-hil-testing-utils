# `arduino_relay` role

Installs the Arduino-based relay daemon used by PDUDaemon to power-cycle the DUTs that are wired through the SSR relay board.

## What it does

- Installs `python3-serial`.
- Copies `scripts/arduino/arduino_daemon.py` and `scripts/arduino/arduino_relay_control.py` to `/usr/local/bin/`.
- Installs the `99-serial-devices.rules` udev rule from `configs/templates/`. This rule creates a stable `/dev/arduino-relay` symlink when the Arduino is plugged in (matches on USB vendor/product ID + serial), so the daemon does not break when `ttyACM*` numbering changes. The Arduino rule also sets `SYSTEMD_WANTS` so the daemon restarts when the device reappears after USB disconnect (see [Self-healing](../../../docs/configuracion/arduino-relay.md#self-healing)).
- Installs and enables a `arduino-relay-daemon.service` systemd unit that opens `/dev/arduino-relay` and exposes a small TCP API used by PDUDaemon.

## Variables

This role has no overridable variables — the relay board layout (which Arduino pin powers which DUT) lives in `arduino_daemon.py` itself.

## Prerequisites

- The Arduino board (with the SSR relay shield) is plugged into the lab host via USB.
- The DUT power inputs are wired to the SSR channels matching what `arduino_daemon.py` expects.
- Power supplies for the DUTs go through the relay (not directly into the wall) — otherwise the daemon controls nothing.

## Run

```sh
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbook_testbed.yml --tags arduino_relay -K
```

Verify the daemon:

```sh
ls -l /dev/arduino-relay     # should symlink to /dev/ttyACM*
systemctl status arduino-relay-daemon
arduino_relay_control.py status belkin_rt3200_1
```

Power-cycle a DUT manually:

```sh
arduino_relay_control.py off belkin_rt3200_1 && sleep 5 && arduino_relay_control.py on belkin_rt3200_1
```

## Related

- `poe_switch` role — alternative power-control path for DUTs powered over PoE through the TP-Link managed switch.
- [`docs/configuracion/arduino-relay.md`](../../../docs/configuracion/arduino-relay.md) — hardware wiring and operator guide.
