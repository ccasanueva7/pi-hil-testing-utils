#!/bin/bash

DAEMON_SCRIPT="/home/franco/pi/pi-hil-testing-utils/scripts/arduino_daemon.py"
ARDUINO_PORT="/dev/arduino-relay"

echo "🚀 Starting Arduino Relay Daemon..."

# Stop previous daemon if exists
python3 "$DAEMON_SCRIPT" stop 2>/dev/null

sleep 2

# Start daemon in background
nohup python3 "$DAEMON_SCRIPT" start --port "$ARDUINO_PORT" > /tmp/arduino-daemon.log 2>&1 &

sleep 3

# Verify it started
if python3 "$DAEMON_SCRIPT" status | grep -q "running"; then
    echo "✅ Daemon started successfully"
    echo "📋 Test it: python3 /home/franco/pi/pi-hil-testing-utils/scripts/arduino_relay_control.py status"
else
    echo "❌ Failed to start daemon"
    echo "📋 Check log: tail /tmp/arduino-daemon.log"
    exit 1
fi
