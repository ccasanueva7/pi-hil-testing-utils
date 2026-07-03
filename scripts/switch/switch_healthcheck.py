#!/usr/bin/env python3
"""Switch VLAN healthcheck - verify that DUT port PVIDs match dut-config.yaml.

Reads expected VLAN assignments from dut-config.yaml, queries each DUT port's
current PVID via SSH, and reports mismatches. Exits 0 if all ports match,
1 if any mismatch is found, 2 on connection/config errors.

Useful as a cron job or manual check after switch events (reboot, firmware
update, accidental factory reset).

Usage:
    switch_healthcheck.py
    switch_healthcheck.py --config /path/to/dut-config.yaml
    switch_healthcheck.py --quiet   # exit code only, no output on success
"""

from __future__ import annotations

import argparse
import logging
import sys

from switch_abstraction.client import SwitchClient
from switch_abstraction.vlan_manager import (
    get_default_pool,
    get_vlan_shared,
    load_config,
)

logger = logging.getLogger(__name__)

VALID_POOLS = {"isolated", "shared"}


def _expected_pvid(dut_hw: dict, vlan_shared: int) -> int:
    pool = get_default_pool(dut_hw)
    if pool == "shared":
        return vlan_shared
    return dut_hw["switch_vlan_isolated"]


def check_switch_pvids(
    config_path: str | None = None,
    quiet: bool = False,
) -> bool:
    """Query each DUT port PVID and compare against dut-config.yaml.

    Returns True if all ports match, False otherwise.
    """
    try:
        config = load_config(config_path)
    except Exception as exc:
        logger.error("Cannot load config: %s", exc)
        return False

    dut_map = config.get("duts", {})
    if not dut_map:
        logger.error("No DUTs in config")
        return False

    vlan_shared = get_vlan_shared(config)

    switch_cfg = config.get("switch", {})
    try:
        client = SwitchClient(
            host=switch_cfg.get("host", "192.168.0.1"),
            user=switch_cfg.get("user", "admin"),
        )
    except Exception as exc:
        logger.error("Cannot connect to switch: %s", exc)
        return False

    from switch_abstraction.drivers import get_switch_driver

    driver_name = None
    driver = get_switch_driver(driver_name, config=config)

    get_pvid_cmd = getattr(driver, "get_port_pvid_command", None)
    parse_pvid = getattr(driver, "parse_port_pvid", None)

    if not callable(get_pvid_cmd) or not callable(parse_pvid):
        logger.error("Driver does not support PVID query")
        return False

    all_ok = True
    for name, hw in dut_map.items():
        port = hw["switch_port"]
        expected = _expected_pvid(hw, vlan_shared)

        try:
            output = client.send_command(get_pvid_cmd(port))
            actual = parse_pvid(output)
        except Exception as exc:
            logger.error("  %s (port %d): query failed: %s", name, port, exc)
            all_ok = False
            continue

        if actual is None:
            logger.error("  %s (port %d): could not parse PVID", name, port)
            all_ok = False
        elif actual != expected:
            logger.warning(
                "  MISMATCH %s (port %d): expected PVID %d, got %d",
                name,
                port,
                expected,
                actual,
            )
            all_ok = False
        elif not quiet:
            logger.info("  OK %s (port %d): PVID %d", name, port, actual)

    if all_ok and not quiet:
        logger.info("All DUT ports match expected PVIDs")

    return all_ok


def main():
    parser = argparse.ArgumentParser(
        description="Verify switch DUT port PVIDs against dut-config.yaml",
    )
    parser.add_argument(
        "--config",
        "-c",
        help="Path to dut-config.yaml (default: SWITCH_DUT_CONFIG or /etc/testbed/dut-config.yaml)",
    )
    parser.add_argument(
        "--quiet",
        "-q",
        action="store_true",
        help="Suppress output on success (exit code only)",
    )
    args = parser.parse_args()

    level = logging.WARNING if args.quiet else logging.INFO
    logging.basicConfig(level=level, format="%(message)s")

    try:
        ok = check_switch_pvids(config_path=args.config, quiet=args.quiet)
    except Exception as exc:
        logger.error("Healthcheck failed: %s", exc)
        sys.exit(2)

    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
