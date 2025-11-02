#!/bin/bash
# TFTP Firmware Manager for U-Boot Recovery
# ==========================================
# Manages firmware images in TFTP server for device recovery operations.
# Compatible with openwrt-tests directory structure (subdirectories per device)
#
# Features:
# - Upload firmware images to device-specific TFTP subdirectories
# - List available devices and their firmware images
# - Verify checksums (SHA256)
# - Set symlinks for device-specific bootfiles
# - Clean up old/unused images
#
# Usage:
#   ./tftp_firmware_manager.sh upload <image_path> --device <device_id>
#   ./tftp_firmware_manager.sh list-devices
#   ./tftp_firmware_manager.sh list [device_id]
#   ./tftp_firmware_manager.sh link <device_id/image_name> <bootfile_name>
#   ./tftp_firmware_manager.sh verify <device_id/image_name>
#   ./tftp_firmware_manager.sh clean [device_id] [--older-than <days>]

set -e

# Configuration
TFTP_ROOT="${HIL_TFTP_ROOT:-/srv/tftp}"
TFTP_USER="${TFTP_USER:-tftp}"
METADATA_DIR="$TFTP_ROOT/.metadata"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if TFTP server is accessible
check_tftp_server() {
    if [ ! -d "$TFTP_ROOT" ]; then
        print_error "TFTP root directory not found: $TFTP_ROOT"
        print_info "Run setup_tftp_server.sh first or set HIL_TFTP_ROOT environment variable"
        exit 1
    fi

    if ! systemctl is-active --quiet tftpd-hpa 2>/dev/null; then
        print_warning "TFTP server (tftpd-hpa) is not running"
        print_info "Start it with: sudo systemctl start tftpd-hpa"
    fi

    # Ensure metadata directory exists
    sudo mkdir -p "$METADATA_DIR"
    sudo chown -R "$TFTP_USER:$TFTP_USER" "$METADATA_DIR" 2>/dev/null || true
}

# Calculate SHA256 checksum
calculate_sha256() {
    local file="$1"
    sha256sum "$file" | awk '{print $1}'
}

# Get human-readable file size
get_file_size() {
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$file" | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "$(stat -f%z "$file") bytes"
    else
        stat --format=%s "$file" | numfmt --to=iec-i --suffix=B 2>/dev/null || echo "$(stat --format=%s "$file") bytes"
    fi
}

# Get device directories
get_device_directories() {
    find "$TFTP_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name ".*" -printf "%f\n" 2>/dev/null | sort
}

# Count firmware images in a directory
count_firmware_images() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f \( -name "*.bin" -o -name "*.itb" -o -name "*.img" -o -name "*.elf" \) 2>/dev/null | wc -l
}

# Upload firmware image to TFTP (device-specific subdirectory)
cmd_upload() {
    local image_path="$1"
    local device_id="${2:-}"

    if [ ! -f "$image_path" ]; then
        print_error "Image file not found: $image_path"
        exit 1
    fi

    if [ -z "$device_id" ]; then
        print_error "Device ID is required"
        print_info "Usage: $0 upload <image_path> --device <device_id>"
        echo ""
        print_info "Available devices:"
        get_device_directories | while read -r dev; do
            echo "  - $dev"
        done
        exit 1
    fi

    local device_dir="$TFTP_ROOT/$device_id"

    if [ ! -d "$device_dir" ]; then
        print_warning "Device directory not found: $device_dir"
        print_info "Creating directory for device: $device_id"
        sudo mkdir -p "$device_dir"
        sudo chown "$TFTP_USER:$TFTP_USER" "$device_dir"
        sudo chmod 755 "$device_dir"
    fi

    print_header "Uploading Firmware to TFTP"

    local image_basename=$(basename "$image_path")
    local dest_path="$device_dir/$image_basename"
    local metadata_file="$METADATA_DIR/${device_id}_${image_basename}.meta"

    print_info "Source:      $image_path"
    print_info "Destination: $dest_path"
    print_info "Device:      $device_id"

    # Calculate checksum before upload
    print_info "Calculating SHA256 checksum..."
    local sha256=$(calculate_sha256 "$image_path")
    local file_size=$(get_file_size "$image_path")

    print_info "SHA256:      $sha256"
    print_info "Size:        $file_size"

    # Copy to TFTP device directory
    print_info "Copying to TFTP directory..."
    sudo cp "$image_path" "$dest_path"
    sudo chown "$TFTP_USER:$TFTP_USER" "$dest_path"
    sudo chmod 644 "$dest_path"

    # Verify upload
    print_info "Verifying upload integrity..."
    local dest_sha256=$(calculate_sha256 "$dest_path")

    if [ "$sha256" != "$dest_sha256" ]; then
        print_error "Checksum mismatch! Upload may be corrupted."
        sudo rm "$dest_path"
        exit 1
    fi

    # Save metadata
    print_info "Saving metadata..."
    sudo tee "$metadata_file" > /dev/null <<EOF
# Metadata for $device_id/$image_basename
upload_date=$(date -Iseconds)
device=$device_id
firmware=$(basename "$image_path")
sha256=$sha256
size_bytes=$(stat --format=%s "$image_path" 2>/dev/null || stat -f%z "$image_path")
size_human=$file_size
source_path=$image_path
EOF
    sudo chown "$TFTP_USER:$TFTP_USER" "$metadata_file"

    print_success "Firmware uploaded successfully!"
    print_info "TFTP path: $device_id/$image_basename"

    # Show U-Boot command example
    echo ""
    print_info "Example U-Boot commands:"
    echo "  setenv serverip <TFTP_SERVER_IP>"
    echo "  setenv ipaddr <DEVICE_IP>"
    echo "  setenv bootfile $device_id/$image_basename"
    echo "  tftpboot 0x4007ff28"
    echo "  bootm 0x4007ff28"
}

# List all devices and their firmware images
cmd_list_devices() {
    print_header "TFTP Devices and Firmware Images"

    if [ ! -d "$TFTP_ROOT" ]; then
        print_error "TFTP directory not found: $TFTP_ROOT"
        exit 1
    fi

    local total_devices=0
    local total_images=0

    # Iterate through device directories
    while read -r device_id; do
        local device_dir="$TFTP_ROOT/$device_id"
        local image_count=$(count_firmware_images "$device_dir")

        total_devices=$((total_devices + 1))
        total_images=$((total_images + image_count))

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${CYAN}📁 Device: ${NC}${GREEN}$device_id${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Path:   $device_dir"
        echo "  Images: $image_count"

        # List firmware images in this device directory
        if [ $image_count -gt 0 ]; then
            echo ""
            echo "  Firmware files:"
            find "$device_dir" -maxdepth 1 -type f \( -name "*.bin" -o -name "*.itb" -o -name "*.img" -o -name "*.elf" \) -printf "    ├─ %f (%s bytes)\n" 2>/dev/null | sort
        else
            echo "  (No firmware images found)"
        fi

    done < <(get_device_directories)

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_success "Found $total_devices device(s) with $total_images total image(s)"
}

# List firmware images (all or for specific device)
cmd_list() {
    local device_id="${1:-}"

    if [ -n "$device_id" ]; then
        # List images for specific device
        print_header "Firmware Images for Device: $device_id"

        local device_dir="$TFTP_ROOT/$device_id"

        if [ ! -d "$device_dir" ]; then
            print_error "Device directory not found: $device_id"
            exit 1
        fi

        local count=0

        while IFS= read -r -d '' file; do
            local basename=$(basename "$file")
            local metadata_file="$METADATA_DIR/${device_id}_${basename}.meta"

            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${GREEN}📦 $basename${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

            # Show basic info
            local size=$(get_file_size "$file")
            local modified=$(stat --format='%y' "$file" 2>/dev/null | cut -d'.' -f1 || stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$file")

            echo "  Path:     $file"
            echo "  Size:     $size"
            echo "  Modified: $modified"

            # Show metadata if available
            if [ -f "$metadata_file" ]; then
                while IFS= read -r line; do
                    if [[ ! "$line" =~ ^# ]] && [[ -n "$line" ]]; then
                        local key=$(echo "$line" | cut -d'=' -f1)
                        local value=$(echo "$line" | cut -d'=' -f2-)
                        case "$key" in
                            sha256) echo "  SHA256:   $value" ;;
                            upload_date) echo "  Uploaded: $value" ;;
                        esac
                    fi
                done < "$metadata_file"
            fi

            count=$((count + 1))
        done < <(find "$device_dir" -maxdepth 1 -type f \( -name "*.bin" -o -name "*.itb" -o -name "*.img" -o -name "*.elf" \) -print0 | sort -z)

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print_success "Found $count image(s) for device $device_id"
    else
        # List all devices (same as list-devices)
        cmd_list_devices
    fi
}

# Create symlink for bootfile (within device directory)
cmd_link() {
    local source="$1"
    local link_name="$2"

    if [ -z "$source" ] || [ -z "$link_name" ]; then
        print_error "Usage: $0 link <device_id/image_name> <bootfile_name>"
        exit 1
    fi

    # Parse device_id/image_name
    if [[ "$source" == */* ]]; then
        local device_id=$(dirname "$source")
        local image_name=$(basename "$source")
    else
        print_error "Source must include device directory: device_id/image_name"
        exit 1
    fi

    local device_dir="$TFTP_ROOT/$device_id"
    local image_path="$device_dir/$image_name"
    local link_path="$device_dir/$link_name"

    if [ ! -f "$image_path" ]; then
        print_error "Image not found: $source"
        exit 1
    fi

    print_info "Creating symlink: $device_id/$link_name -> $image_name"

    # Remove existing symlink if it exists
    if [ -L "$link_path" ]; then
        sudo rm "$link_path"
        print_warning "Removed existing symlink"
    fi

    sudo ln -s "$image_name" "$link_path"
    sudo chown -h "$TFTP_USER:$TFTP_USER" "$link_path"

    print_success "Symlink created successfully"
    print_info "U-Boot bootfile: $device_id/$link_name"
}

# Verify image checksum
cmd_verify() {
    local source="$1"

    if [ -z "$source" ]; then
        print_error "Usage: $0 verify <device_id/image_name>"
        exit 1
    fi

    # Parse device_id/image_name
    if [[ "$source" == */* ]]; then
        local device_id=$(dirname "$source")
        local image_name=$(basename "$source")
    else
        print_error "Source must include device directory: device_id/image_name"
        exit 1
    fi

    local image_path="$TFTP_ROOT/$device_id/$image_name"
    local metadata_file="$METADATA_DIR/${device_id}_${image_name}.meta"

    if [ ! -f "$image_path" ]; then
        print_error "Image not found: $source"
        exit 1
    fi

    print_header "Verifying Firmware Image"
    print_info "Image: $source"

    # Calculate current checksum
    print_info "Calculating SHA256..."
    local current_sha256=$(calculate_sha256 "$image_path")
    echo "  Current: $current_sha256"

    # Compare with stored metadata
    if [ -f "$metadata_file" ]; then
        local stored_sha256=$(grep '^sha256=' "$metadata_file" | cut -d'=' -f2)
        echo "  Stored:  $stored_sha256"

        if [ "$current_sha256" = "$stored_sha256" ]; then
            print_success "Checksum verification PASSED"
        else
            print_error "Checksum verification FAILED"
            print_warning "Image may be corrupted or modified"
            exit 1
        fi
    else
        print_warning "No metadata found, cannot verify against original"
        print_info "Current SHA256: $current_sha256"
    fi
}

# Clean up old images
cmd_clean() {
    local device_id="${1:-}"
    local days="${2:-30}"

    print_header "Cleaning Up Old Firmware Images"

    local search_path="$TFTP_ROOT"
    if [ -n "$device_id" ]; then
        search_path="$TFTP_ROOT/$device_id"
        print_info "Cleaning device: $device_id"
    fi
    print_info "Removing images older than $days days"

    local count=0

    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")
        local dirname=$(basename $(dirname "$file"))
        local metadata_file="$METADATA_DIR/${dirname}_${basename}.meta"

        print_info "Removing: $dirname/$basename"
        sudo rm "$file"

        if [ -f "$metadata_file" ]; then
            sudo rm "$metadata_file"
        fi

        count=$((count + 1))
    done < <(find "$search_path" -type f \( -name "*.bin" -o -name "*.itb" -o -name "*.img" \) -mtime "+$days" -print0)

    if [ $count -eq 0 ]; then
        print_success "No old images to clean"
    else
        print_success "Removed $count image(s)"
    fi
}

# Show usage
cmd_usage() {
    cat <<EOF
TFTP Firmware Manager - Manage firmware images for U-Boot recovery
Compatible with openwrt-tests directory structure

Usage:
  $0 upload <image_path> --device <device_id>
      Upload firmware to device-specific TFTP subdirectory
      Example: $0 upload firmware.itb --device belkin_rt3200_1

  $0 list-devices
      List all device directories and their firmware images

  $0 list [device_id]
      List firmware images (all devices or specific device)
      Example: $0 list belkin_rt3200_1

  $0 link <device_id/image_name> <bootfile_name>
      Create symlink within device directory
      Example: $0 link belkin_rt3200_1/firmware.itb recovery.itb

  $0 verify <device_id/image_name>
      Verify firmware image checksum integrity
      Example: $0 verify belkin_rt3200_1/firmware.itb

  $0 clean [device_id] [--older-than <days>]
      Remove old firmware images (all devices or specific device)
      Example: $0 clean belkin_rt3200_1 --older-than 60

  $0 help
      Show this help message

Environment Variables:
  HIL_TFTP_ROOT    TFTP server root directory (default: /srv/tftp)

Directory Structure (openwrt-tests compatible):
  /srv/tftp/
  ├── belkin_rt3200_1/
  │   ├── openwrt-...-initramfs-recovery.itb
  │   └── openwrt-...-sysupgrade.itb
  ├── belkin_rt3200_2/
  │   └── openwrt-...-initramfs-recovery.itb
  └── gl_mt300n_v2/
      └── openwrt-...-initramfs-kernel.bin

Examples:
  # Upload firmware to specific device
  $0 upload ~/Downloads/openwrt-firmware.itb --device belkin_rt3200_1

  # List all devices and their images
  $0 list-devices

  # List images for specific device
  $0 list belkin_rt3200_1

  # Verify image integrity
  $0 verify belkin_rt3200_1/openwrt-firmware.itb

  # Clean up old images for specific device
  $0 clean belkin_rt3200_1 --older-than 60

EOF
}

# Main command dispatcher
main() {
    check_tftp_server

    local command="${1:-help}"
    shift || true

    case "$command" in
        upload)
            local image_path="$1"
            shift || true
            local device_id=""

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --device)
                        device_id="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            cmd_upload "$image_path" "$device_id"
            ;;
        list-devices)
            cmd_list_devices
            ;;
        list)
            cmd_list "$1"
            ;;
        link)
            cmd_link "$1" "$2"
            ;;
        verify)
            cmd_verify "$1"
            ;;
        clean)
            local device_or_days="$1"
            local days=30
            
            # Check if first arg is a device directory
            if [ -d "$TFTP_ROOT/$device_or_days" ]; then
                # It's a device, check for --older-than
                if [ "$2" = "--older-than" ]; then
                    days="$3"
                fi
                cmd_clean "$device_or_days" "$days"
            else
                # Not a device, check if it's --older-than
                if [ "$device_or_days" = "--older-than" ]; then
                    days="$2"
                fi
                cmd_clean "" "$days"
            fi
            ;;
        help|--help|-h)
            cmd_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            cmd_usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
