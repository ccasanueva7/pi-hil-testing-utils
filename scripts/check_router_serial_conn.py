#!/usr/bin/env python3
"""
Script to verify serial communication with router
"""

import serial
import time
import sys
import argparse

def test_communication(port, baudrate=115200, timeout=2):
    """
    Tests serial communication with the router.

    Args:
        port: Serial port (e.g., /dev/glinet-mango)
        baudrate: Communication speed
        timeout: Timeout for operations

    Returns:
        tuple: (success, response_text)
    """
    try:
        ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=timeout,
            xonxoff=False,
            rtscts=False,
            dsrdtr=False
        )

        # Clear buffers
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        # Wait and send Enter multiple times
        time.sleep(1)
        for i in range(5):
            ser.write(b'\r\n')
            ser.flush()
            time.sleep(0.5)

        # Send test command
        ser.write(b'echo "ROUTER_TEST_OK"\r\n')
        ser.flush()
        time.sleep(1)

        # Read response
        response = ser.read(500).decode('utf-8', errors='ignore')
        ser.close()

        return True, response.strip()

    except Exception as e:
        return False, str(e)


def main():
    """Main function for command-line usage."""
    parser = argparse.ArgumentParser(description="Verify serial communication with router")
    parser.add_argument('port', help='Serial port (e.g., /dev/glinet-mango)')
    parser.add_argument('--baudrate', type=int, default=115200, help='Communication speed')
    parser.add_argument('--timeout', type=float, default=2.0, help='Timeout for operations')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show full response')

    args = parser.parse_args()

    success, response = test_communication(args.port, args.baudrate, args.timeout)

    if success and response:
        print('✅ Router responds via serial')
        if args.verbose:
            print(f'   Full response: {repr(response)}')
        else:
            print(f'   Response: {response[:100]}...' if len(response) > 100 else f'   Response: {response}')
        return 0
    elif success:
        print('⚠️  Router connected but no response')
        return 1
    else:
        print(f'❌ Communication error: {response}')
        return 1


if __name__ == "__main__":
    sys.exit(main())
