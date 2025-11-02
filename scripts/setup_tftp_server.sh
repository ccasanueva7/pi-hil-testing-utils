#!/bin/bash
# Script to configure and install TFTP server for U-Boot recovery
# Compatible with openwrt-tests directory structure (subdirectories per device)
#
# This script:
# - Installs 'tftpd-hpa' only if not already installed
# - Creates root directory for TFTP files (/srv/tftp)
# - Creates subdirectories for each testbed device
# - Configures 'tftpd-hpa' to start automatically on boot
# - Provides useful commands for service administration

set -e

TFTP_ROOT="${HIL_TFTP_ROOT:-/srv/tftp}"
TFTP_USER="tftp"
SERVICE_NAME="tftpd-hpa"

# Testbed devices dictionary for FCEFYN lab
# Format: "device_id:description"
# Can be overridden with HIL_TESTBED_DEVICES environment variable
DEFAULT_DEVICES=(
    "belkin_rt3200_1:Belkin RT3200 #1 (Linksys E8450)"
    "belkin_rt3200_2:Belkin RT3200 #2 (Linksys E8450)"
    "gl_mt300n_v2:GL.iNet GL-MT300N-v2 (Mango)"
)

# Read devices from environment variable or use defaults
IFS=',' read -ra TESTBED_DEVICES <<< "${HIL_TESTBED_DEVICES:-}"
if [ ${#TESTBED_DEVICES[@]} -eq 0 ]; then
    TESTBED_DEVICES=("${DEFAULT_DEVICES[@]}")
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════"
    echo ""
}

# Check if package is installed
is_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

print_header "Configuring TFTP Server for U-Boot Recovery"

# 1. Install tftpd-hpa only if not already installed
if is_package_installed "$SERVICE_NAME"; then
    print_success "Package '$SERVICE_NAME' is already installed"
else
    print_info "Installing package '$SERVICE_NAME'..."
    sudo apt-get update -qq
    sudo apt-get install -y "$SERVICE_NAME"
    print_success "Package '$SERVICE_NAME' installed successfully"
fi

# 2. Create and configure TFTP root directory
print_info "Configuring TFTP root directory: $TFTP_ROOT"
sudo mkdir -p "$TFTP_ROOT"
sudo chown -R "$TFTP_USER:$TFTP_USER" "$TFTP_ROOT"
sudo chmod -R 755 "$TFTP_ROOT"
print_success "Root directory configured"

# 3. Create subdirectories for each testbed device
print_info "Creating subdirectories for testbed devices..."
echo ""

device_count=0
for device_entry in "${TESTBED_DEVICES[@]}"; do
    # Parse device_id:description
    device_id=$(echo "$device_entry" | cut -d':' -f1)
    device_desc=$(echo "$device_entry" | cut -d':' -f2-)
    
    device_dir="$TFTP_ROOT/$device_id"
    
    if [ -d "$device_dir" ]; then
        print_info "  ✓ $device_id/ (already exists) - $device_desc"
    else
        sudo mkdir -p "$device_dir"
        sudo chown "$TFTP_USER:$TFTP_USER" "$device_dir"
        sudo chmod 755 "$device_dir"
        print_success "  ✓ $device_id/ (created) - $device_desc"
    fi
    
    device_count=$((device_count + 1))
done

echo ""
print_success "Created/verified $device_count device subdirectories"

# 4. Create metadata directory
print_info "Configuring metadata directory..."
sudo mkdir -p "$TFTP_ROOT/.metadata"
sudo chown "$TFTP_USER:$TFTP_USER" "$TFTP_ROOT/.metadata"
print_success "Metadata directory configured"

# 5. Configure tftpd-hpa
print_info "Configuring file '/etc/default/$SERVICE_NAME'..."
sudo tee "/etc/default/$SERVICE_NAME" > /dev/null <<EOF
# /etc/default/tftpd-hpa
# Configuration for high-availability TFTP server
# Compatible with openwrt-tests structure

TFTP_USERNAME="$TFTP_USER"
TFTP_DIRECTORY="$TFTP_ROOT"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure --create"
EOF
print_success "Configuration file updated"

# 6. Start and enable the service
print_info "Restarting and enabling service '$SERVICE_NAME'..."
sudo systemctl restart "$SERVICE_NAME"
sudo systemctl enable "$SERVICE_NAME" >/dev/null 2>&1
print_success "Service configured for automatic startup"

# 7. Verify service status
echo ""
if systemctl is-active --quiet "$SERVICE_NAME"; then
    print_success "TFTP server is running correctly"
else
    print_error "TFTP server is not active"
    print_info "Verify with: sudo systemctl status $SERVICE_NAME"
fi

# 8. Show created structure
print_header "TFTP Structure Created"

echo "Root directory: $TFTP_ROOT"
echo ""
echo "Subdirectories per device:"
for device_entry in "${TESTBED_DEVICES[@]}"; do
    device_id=$(echo "$device_entry" | cut -d':' -f1)
    device_desc=$(echo "$device_entry" | cut -d':' -f2-)
    echo "  📁 $device_id/"
    echo "     └─ $device_desc"
done

echo ""
print_info "To upload firmware to a specific device:"
echo "  ./tftp_firmware_manage.sh upload <image_path> --device <device_id>"
echo ""
print_info "To list all devices and their images:"
echo "  ./tftp_firmware_manage.sh list-devices"

print_header "Useful Commands for TFTP Server"

cat <<EOF
• Check service status:
    sudo systemctl status $SERVICE_NAME

• Restart service:
    sudo systemctl restart $SERVICE_NAME

• View logs in real-time:
    sudo journalctl -u $SERVICE_NAME -f

• Stop service:
    sudo systemctl stop $SERVICE_NAME

• Start service:
    sudo systemctl start $SERVICE_NAME

• Disable automatic startup:
    sudo systemctl disable $SERVICE_NAME

• Enable automatic startup:
    sudo systemctl enable $SERVICE_NAME

• List files in TFTP:
    ls -lh $TFTP_ROOT/*/

• Test TFTP connectivity:
    tftp localhost -c get test_file

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

print_success "Configuration completed successfully"

echo ""
echo "Optional environment variables:"
echo "  HIL_TFTP_ROOT         - Change root directory (default: /srv/tftp)"
echo "  HIL_TESTBED_DEVICES   - Comma-separated list of devices"
echo ""
echo "Example of custom devices:"
echo "  export HIL_TESTBED_DEVICES=\"router1:My Router 1,router2:My Router 2\""
echo "  ./setup_tftp_server.sh"
