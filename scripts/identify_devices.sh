#!/bin/bash
# Script to identify USB serial devices and generate udev rules

echo "=== USB Serial Device Identification ==="
echo
echo "1. Searching for connected USB serial devices..."
serial_devices=$(lsusb | grep -i "arduino\|ch340\|cp210\|ftdi\|pl2303\|usb-serial\|uart\|bridge")
if [ -z "$serial_devices" ]; then
    echo "No known USB serial devices found."
    echo "Showing all USB devices:"
    lsusb
    echo
    echo "Please verify that devices are connected and detected by the system."
    exit 1
fi
echo "Found devices:"
echo "$serial_devices"
echo
echo "2. Available serial ports:"
ls -la /dev/tty* | grep -E "(USB|ACM)" || echo "No USB/ACM ports found"
echo
echo "3. Detailed device information:"
for device in /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$device" ]; then
        echo "--- Device: $device ---"
        udevadm info -a -n "$device" | grep -E "(KERNEL|SUBSYSTEM|DRIVER|ATTRS\{idVendor\}|ATTRS\{idProduct\}|ATTRS\{serial\}|ATTRS\{product\}|ATTRS\{manufacturer\})" | head -10
        echo
    fi
done
echo "=== Creating udev rule ==="
echo
echo "1. Identify the device to map from the list above"
echo "2. Note the values of idVendor, idProduct, and serial (if available)"
echo "3. Run the following command to create the rule:"
echo
echo "sudo nano /etc/udev/rules.d/99-serial-devices.rules"
echo
echo "4. Add a line similar to this (replace values):"
echo 'SUBSYSTEM=="tty", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", SYMLINK+="descriptive-name", MODE="0666", GROUP="dialout"'
echo
echo "5. If the device has a unique serial number available, it is recommended to use it for greater precision:"
echo 'SUBSYSTEM=="tty", ATTRS{idVendor}=="XXXX", ATTRS{idProduct}=="YYYY", ATTRS{serial}=="ZZZZ", SYMLINK+="descriptive-name", MODE="0666", GROUP="dialout"'
echo
echo "6. Reload udev rules:"
echo "sudo udevadm control --reload-rules"
echo "sudo udevadm trigger"
echo
echo "7. Disconnect and reconnect the device, then verify:"
echo "ls -la /dev/descriptive-name"
