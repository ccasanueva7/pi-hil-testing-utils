# Hardware-in-the-Loop (HIL) Testing Utilities

Utilities and scripts for managing physical hardware in OpenWrt testing infrastructure. This repository provides tools for controlling Arduino-based relay controllers, managing TFTP servers, and automating device setup for HIL testing with labgrid.

## Overview

This project provides automation tools for:

- **Arduino Relay Control**: Control power and serial isolation for physical devices
- **TFTP Server Management**: Automated firmware deployment for U-Boot recovery
- **Device Setup**: Automated physical device configuration and verification
- **Serial Communication**: Utilities for testing and verifying serial connections

## Repository Structure

```
pi-hil-testing-utils/
├── arduino/              # Arduino firmware and sketches
│   └── relay_ctrl.ino   # Relay controller firmware
├── configs/              # System configuration files
│   └── 99-serial-devices.rules  # Udev rules for serial devices
├── firmwares/           # Firmware images organized by device
│   ├── belkin_rt3200/
│   ├── gl-mt300n-v2/
│   └── qemu/
└── scripts/             # Automation scripts
    ├── arduino_relay_control.py    # Relay control CLI
    ├── arduino_daemon.py            # Persistent relay daemon
    ├── setup_tftp_server.sh        # TFTP server setup
    ├── tftp_firmware_manage.sh     # Firmware management
    ├── setup_physical_device.sh    # Device setup automation
    ├── identify_devices.sh         # Serial device identification
    ├── check_router_serial_conn.py # Serial communication tester
    ├── verify_uboot_recovery.sh    # U-Boot recovery verification
    └── start_daemon.sh             # Daemon startup script
```

## Quick Start

### Prerequisites

- Python 3.6+
- `pyserial` Python package
- `tftpd-hpa` (for TFTP server)
- Arduino with relay controller firmware

### Basic Installation

```bash
# Install Python dependencies
pip install pyserial

# Install arduino_relay_control.py to system path (for use with pdudaemon)
# This makes it available system-wide, consistent with other lab setups
sudo cp scripts/arduino_relay_control.py /usr/local/bin/arduino_relay_control.py
sudo chmod +x /usr/local/bin/arduino_relay_control.py

# Setup TFTP server with device directories
cd scripts
./setup_tftp_server.sh

# Test Arduino relay controller
arduino_relay_control.py status
# Or using full path:
# python3 scripts/arduino_relay_control.py status
```

## Complete Setup for Labgrid Integration

This section covers the complete setup required for integrating with `openwrt-tests` and labgrid.

### 1. Install System Dependencies

```bash
# Install required packages
sudo apt install ser2net pipx libsystemd-dev pkg-config python3-dev

# Ensure pipx is in PATH
pipx ensurepath
```

**ser2net**: Required by Labgrid for serial port access over network. Install and configure it:

```bash
sudo apt install ser2net
# Configuration is typically in /etc/ser2net.yaml
```

### 2. Install PDUDaemon

PDUDaemon provides a standardized interface for power management that integrates with labgrid:

```bash
sudo apt install pipx
# Install pdudaemon from GitHub (same version as openwrt-tests uses)
pipx install git+https://github.com/jonasjelonek/pdudaemon.git@main
```

### 3. Install Arduino Relay Control Script

Install the relay control script to a system-wide location:

```bash
# Install arduino_relay_control.py to system path
sudo cp scripts/arduino_relay_control.py /usr/local/bin/arduino_relay_control.py
sudo chmod +x /usr/local/bin/arduino_relay_control.py
```

This allows `pdudaemon` to call it from a standard location, consistent with other lab setups.

### 4. Configure PDUDaemon

Create the PDUDaemon configuration directory and file (the file should be an exact copy of the one available
at openwrt-tests/ansible/files/exporter/labgrid-fcefyn/pdudaemon.conf):

```bash
# Create configuration directory
sudo mkdir -p /etc/pdudaemon

# Copy configuration file (or create it)
sudo cp ansible/files/exporter/labgrid-fcefyn/pdudaemon.conf /etc/pdudaemon/pdudaemon.conf

# Create configuration file
sudo tee /etc/pdudaemon/pdudaemon.conf > /dev/null << 'EOF'
{
    "daemon": {
        "hostname": "localhost",
        "port": 16421,
        "logging_level": "INFO",
        "listener": "http"
    },
    "pdus": {
        "fcefyn-arduino": {
            "driver": "localcmdline",
            "cmd_on": "/usr/local/bin/arduino_relay_control.py on %s",
            "cmd_off": "/usr/local/bin/arduino_relay_control.py off %s"
        },
        "fcefyn-arduino-glinet": {
            "driver": "localcmdline",
            "cmd_on": "/usr/local/bin/arduino_relay_control.py on %s --glinet-sequence",
            "cmd_off": "/usr/local/bin/arduino_relay_control.py off %s"
        }
    }
}
EOF

# Set proper permissions
sudo chmod 644 /etc/pdudaemon/pdudaemon.conf
```

**Configuration Notes**:
- The `%s` placeholder is required by the `localcmdline` driver and will be replaced with the relay index
- `fcefyn-arduino-glinet` uses the `--glinet-sequence` flag to handle the GL.iNet MT300N-v2's special power sequence (disconnect serial → power on → reconnect serial)
- Relay mapping:
  - Index 0 (Relay 0): GL.iNet MT300N-v2
  - Index 2 (Relay 2): Belkin RT3200 #1
  - Index 3 (Relay 3): Belkin RT3200 #2

### 5. Create PDUDaemon Systemd Service

Create a systemd service to run PDUDaemon automatically:

```bash
# Find the pdudaemon binary location (usually in ~/.local/bin after pipx install)
which pdudaemon
# Example output: /home/user/.local/bin/pdudaemon

# Create systemd service (replace /home/user/.local/bin/pdudaemon with your actual path)
sudo tee /etc/systemd/system/pdudaemon.service > /dev/null << 'EOF'
[Unit]
Description=Control and Queueing daemon for PDUs

[Service]
ExecStart=/home/franco/.local/bin/pdudaemon --conf=/etc/pdudaemon/pdudaemon.conf
Type=simple
User=franco
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Replace /home/user with your actual username and update the ExecStart path accordingly
# If pdudaemon is installed to a different location, update the ExecStart path

# Reload systemd
sudo systemctl daemon-reload

# Start and enable pdudaemon service
sudo systemctl start pdudaemon
sudo systemctl enable pdudaemon

# Verify service is running
sudo systemctl status pdudaemon
```

**Important**: Replace `/home/user/.local/bin/pdudaemon` with the actual path returned by `which pdudaemon`, and update the `User=` field with your actual username.

### 6. Install Labgrid (for Local Testing)

For local testing before connecting to the global coordinator:

```bash
pip install labgrid
```

## Scripts Documentation

### Arduino Relay Control

**`arduino_relay_control.py`** - Main CLI for controlling relays

```bash
# Turn on relay channel 2
arduino_relay_control.py on 2

# Turn off relay channel 2
arduino_relay_control.py off 2

# Check status of all relays
arduino_relay_control.py status

# Turn on multiple relays
arduino_relay_control.py on 0 1 2

# Use custom serial port
arduino_relay_control.py --port /dev/ttyUSB0 on 1

# GL.iNet MT300N-v2 special sequence (disconnect serial → power on → reconnect serial)
arduino_relay_control.py on 0 --glinet-sequence
arduino_relay_control.py off 0 --glinet-sequence
```

**Note**: After installation to `/usr/local/bin/`, you can use `arduino_relay_control.py` directly without `python3` prefix, as it has a shebang (`#!/usr/bin/env python3`).

**Features**:
- Persistent connection to avoid Arduino reset
- Automatic daemon detection
- Multi-channel control
- Pulse commands for power cycling
- Special GL.iNet sequence support (`--glinet-sequence` flag)

**GL.iNet Power Sequence**: When using `--glinet-sequence` with relay 0, the script automatically:
1. Disconnects serial line (relay 1 ON)
2. Powers on device (relay 0 ON)
3. Waits 2 seconds for boot
4. Reconnects serial line (relay 1 OFF)

### TFTP Server Management

**`setup_tftp_server.sh`** - Setup TFTP server with device directories

```bash
# Setup with default devices
./setup_tftp_server.sh

# Custom device list
export HIL_TESTBED_DEVICES="router1:My Router,router2:Another Router"
./setup_tftp_server.sh
```

**`tftp_firmware_manage.sh`** - Manage firmware images

```bash
# Upload firmware to device
./tftp_firmware_manage.sh upload firmware.itb --device belkin_rt3200_1

# List all devices and images
./tftp_firmware_manage.sh list-devices

# List images for specific device
./tftp_firmware_manage.sh list belkin_rt3200_1

# Verify image integrity
./tftp_firmware_manage.sh verify belkin_rt3200_1/firmware.itb
```

### Device Setup

**`setup_physical_device.sh`** - Automated device setup for GL-MT300N-V2

Verifies Arduino connectivity, serial ports, power sequencing, and dependencies.

**`identify_devices.sh`** - Identify USB serial devices

Helps create udev rules for consistent device naming.

**`check_router_serial_conn.py`** - Test serial communication

```bash
python3 check_router_serial_conn.py /dev/glinet-mango --verbose
```

## Configuration

### Environment Variables

- `HIL_TFTP_ROOT`: TFTP server root directory (default: `/srv/tftp`)
- `HIL_TESTBED_DEVICES`: Comma-separated device list with descriptions
- `TFTP_USER`: TFTP server user (default: `tftp`)

### Arduino Serial Port

By default, scripts expect Arduino at `/dev/arduino-relay`. To use a different port:

```bash
arduino_relay_control.py --port /dev/ttyUSB0 on 1
```

### Udev Rules

Create `/etc/udev/rules.d/99-serial-devices.rules` for consistent device naming:

```
SUBSYSTEM=="tty", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="arduino-relay", MODE="0666", GROUP="dialout"
```

Use `identify_devices.sh` to help generate these rules.

## Local Testing with Labgrid

Before connecting to the global coordinator, test your exporter locally:

### 1. Start Local Coordinator

```bash
# Start local coordinator
labgrid-coordinator

# Or run in background
labgrid-coordinator &
```

### 2. Start Exporter

```bash
# In another terminal
export LG_CROSSBAR=ws://localhost:20408/ws
labgrid-exporter /path/to/exporter.yaml
```

**Note**: The exporter requires places to be created. For local testing, create `~/labgrid-coordinator/places.yaml` manually or let pytest create them automatically.

### 3. Verify Devices

```bash
export LG_CROSSBAR=ws://localhost:20408/ws

# List available places (devices)
labgrid-client places

# Or view all resources
labgrid-client resources
```

### 4. Test Device Control

```bash
# Set environment
export LG_CROSSBAR=ws://localhost:20408/ws
export LG_PLACE="labgrid-fcefyn-belkin_rt3200_1"

# Lock device
labgrid-client lock

# Test power control (watch the device physically!)
labgrid-client power off
sleep 3
labgrid-client power on

# Test serial console (optional)
labgrid-client console

# Release device
labgrid-client unlock
```

### 5. Run Test Locally

```bash
export LG_CROSSBAR=ws://localhost:20408/ws
export LG_ENV=targets/belkin_rt3200_1.yaml
export LG_PLACE=labgrid-fcefyn-belkin_rt3200_1
export LG_IMAGE=/srv/tftp/belkin_rt3200_1/openwrt-mediatek-mt7622-linksys_e8450-ubi-initramfs-recovery.itb

pytest tests/test_base.py::test_shell -v --lg-log
```

## Troubleshooting

### PDUDaemon Service Issues

If the service fails to start:

```bash
# Check service status
sudo systemctl status pdudaemon

# View logs
sudo journalctl -u pdudaemon -f

# Verify pdudaemon binary path
which pdudaemon

# Check configuration file syntax
cat /etc/pdudaemon/pdudaemon.conf | python3 -m json.tool
```

### Serial Port Access

If you get permission errors accessing serial ports:

```bash
# Add user to dialout group
sudo usermod -a -G dialout $USER

# Log out and log back in for changes to take effect
```

### Arduino Communication Issues

If the relay control script can't communicate with Arduino:

```bash
# Check if device exists
ls -l /dev/arduino-relay

# Test direct communication
arduino_relay_control.py status --port /dev/arduino-relay

# Check udev rules
cat /etc/udev/rules.d/99-serial-devices.rules
```
