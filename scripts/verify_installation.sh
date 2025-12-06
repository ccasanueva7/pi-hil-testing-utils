#!/bin/bash
#
# verify_installation.sh - Verify FCEFYN HIL Lab installation
#
# This script checks all components and reports their status.
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() { echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"; }
print_ok() { echo -e "  ${GREEN}✓${NC} $1"; }
print_fail() { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
print_warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARNINGS=$((WARNINGS + 1)); }
print_info() { echo -e "  ${BLUE}ℹ${NC} $1"; }

ERRORS=0
WARNINGS=0

print_header "FCEFYN HIL Lab Installation Verification"

# 1. Check ser2net
echo "1. ser2net:"
if /usr/local/sbin/ser2net -v 2>&1 | grep -q "4.6"; then
    VERSION=$(/usr/local/sbin/ser2net -v 2>&1 | head -1)
    print_ok "$VERSION"
else
    print_fail "ser2net not found or wrong version"
fi

# 2. Check Labgrid
echo ""
echo "2. Labgrid:"
if command -v labgrid-client &>/dev/null; then
    VERSION=$(labgrid-client --version 2>&1 || echo "unknown")
    print_ok "labgrid-client installed ($VERSION)"
else
    print_fail "labgrid-client not found"
fi

if command -v labgrid-exporter &>/dev/null; then
    print_ok "labgrid-exporter installed"
else
    print_fail "labgrid-exporter not found"
fi

if [ -x /usr/local/sbin/labgrid-bound-connect ]; then
    print_ok "labgrid-bound-connect installed"
else
    print_fail "labgrid-bound-connect not found"
fi

# 3. Check PDUDaemon
echo ""
echo "3. PDUDaemon:"
if command -v pdudaemon &>/dev/null; then
    print_ok "pdudaemon installed"
else
    print_fail "pdudaemon not found"
fi

if systemctl is-active --quiet pdudaemon; then
    print_ok "pdudaemon service running"
else
    print_warn "pdudaemon service not running"
fi

if [ -f /etc/pdudaemon/pdudaemon.conf ]; then
    print_ok "pdudaemon.conf exists"
else
    print_fail "pdudaemon.conf not found"
fi

# 4. Check Arduino Relay Control
echo ""
echo "4. Arduino Relay Control:"
if [ -x /usr/local/bin/arduino_relay_control.py ]; then
    print_ok "arduino_relay_control.py installed"
else
    print_fail "arduino_relay_control.py not found"
fi

if [ -e /dev/arduino-relay ]; then
    print_ok "/dev/arduino-relay exists"
    if /usr/local/bin/arduino_relay_control.py status 2>/dev/null | grep -q "STATUS"; then
        print_ok "Arduino responds to commands"
    else
        print_warn "Arduino not responding (may need to restart daemon)"
    fi
else
    print_warn "/dev/arduino-relay not found (check udev rules or USB connection)"
fi

# 5. Check Serial Devices
echo ""
echo "5. Serial Devices:"
for DEV in belkin-rt3200-1 belkin-rt3200-2; do
    if [ -e /dev/$DEV ]; then
        print_ok "/dev/$DEV exists"
    else
        print_warn "/dev/$DEV not found"
    fi
done

# 6. Check dnsmasq
echo ""
echo "6. TFTP Server (dnsmasq):"
if systemctl is-active --quiet dnsmasq; then
    print_ok "dnsmasq service running"
else
    print_fail "dnsmasq service not running"
fi

if [ -f /etc/dnsmasq.d/tftp.conf ]; then
    print_ok "tftp.conf exists"
else
    print_fail "tftp.conf not found"
fi

if [ -d /srv/tftp ]; then
    print_ok "/srv/tftp directory exists"
else
    print_fail "/srv/tftp directory not found"
fi

# 7. Check VLAN Interfaces
echo ""
echo "7. VLAN Interfaces:"
for VLAN in 100 101; do
    if ip link show vlan$VLAN &>/dev/null; then
        print_ok "vlan$VLAN exists"
        
        # Check IPs
        if ip addr show vlan$VLAN | grep -q "192.168.$VLAN.1"; then
            print_ok "  TFTP IP: 192.168.$VLAN.1"
        else
            print_fail "  Missing TFTP IP 192.168.$VLAN.1"
        fi
        
        if ip addr show vlan$VLAN | grep -q "192.168.1.$VLAN"; then
            print_ok "  SSH IP: 192.168.1.$VLAN"
        else
            print_fail "  Missing SSH IP 192.168.1.$VLAN"
        fi
    else
        print_fail "vlan$VLAN not found"
    fi
done

# 8. Check Firmware
echo ""
echo "8. Firmware:"
FIRMWARE="/srv/tftp/firmwares/belkin_rt3200/openwrt-23.05.5-mediatek-mt7622-linksys_e8450-ubi-initramfs-recovery.itb"
if [ -f "$FIRMWARE" ]; then
    SIZE=$(du -h "$FIRMWARE" | cut -f1)
    print_ok "Belkin firmware exists ($SIZE)"
else
    print_fail "Belkin firmware not found"
fi

# 9. Check Sudoers
echo ""
echo "9. Sudoers Configuration:"
if [ -f /etc/sudoers.d/labgrid ]; then
    if sudo -n labgrid-bound-connect --help &>/dev/null; then
        print_ok "labgrid-bound-connect runs without password"
    else
        print_warn "labgrid-bound-connect may require password"
    fi
else
    print_fail "sudoers.d/labgrid not found"
fi

# 10. Check Labgrid Coordinator Directory
echo ""
echo "10. Labgrid Coordinator:"
if [ -d ~/labgrid-coordinator ]; then
    print_ok "~/labgrid-coordinator exists"
    if [ -f ~/labgrid-coordinator/places.yaml ]; then
        print_ok "places.yaml exists"
    else
        print_warn "places.yaml not found"
    fi
else
    print_fail "~/labgrid-coordinator not found"
fi

# 11. Check socat
echo ""
echo "11. Additional Tools:"
if command -v socat &>/dev/null; then
    print_ok "socat installed"
else
    print_fail "socat not found"
fi

if command -v screen &>/dev/null; then
    print_ok "screen installed"
else
    print_warn "screen not installed"
fi

# Summary
print_header "Summary"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    echo ""
    echo "You can now run the labgrid manager:"
    echo "  cd ~/pi/pi-hil-testing-utils"
    echo "  ./scripts/labgrid_manager.sh start both"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}$WARNINGS warnings, but no critical errors.${NC}"
    echo "The lab should work, but some features may be limited."
else
    echo -e "${RED}$ERRORS errors and $WARNINGS warnings found.${NC}"
    echo "Please fix the errors before running tests."
fi

echo ""
echo "For detailed troubleshooting, see MIGRATION.md"

exit $ERRORS

