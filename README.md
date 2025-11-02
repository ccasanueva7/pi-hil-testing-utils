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

### Installation

```bash
# Install Python dependencies
pip install pyserial

# Setup TFTP server with device directories
cd scripts
./setup_tftp_server.sh

# Test Arduino relay controller
python3 arduino_relay_control.py status
```

## Scripts Documentation

### Arduino Relay Control

**`arduino_relay_control.py`** - Main CLI for controlling relays

```bash
# Turn on relay channel 2
python3 arduino_relay_control.py on 2

# Turn off relay channel 2
python3 arduino_relay_control.py off 2

# Check status of all relays
python3 arduino_relay_control.py status

# Turn on multiple relays
python3 arduino_relay_control.py on 0 1 2

# Use custom serial port
python3 arduino_relay_control.py --port /dev/ttyUSB0 on 1
```

**Features:**
- Persistent connection to avoid Arduino reset
- Automatic daemon detection
- Multi-channel control
- Pulse commands for power cycling

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
python3 arduino_relay_control.py --port /dev/ttyUSB0 on 1
```

### Udev Rules

Create `/etc/udev/rules.d/99-serial-devices.rules` for consistent device naming:

```
SUBSYSTEM=="tty", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="arduino-relay", MODE="0666", GROUP="dialout"
```

Use `identify_devices.sh` to help generate these rules.

