#!/bin/bash
# Script to manage local labgrid coordinator and exporter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OPENWRT_TESTS_DIR="${OPENWRT_TESTS_DIR:-$HOME/Documents/openwrt-tests}"
COORDINATOR_DIR="${LABGRID_COORDINATOR_DIR:-$HOME/labgrid-coordinator}"
EXPORTER_CONFIG="${LABGRID_EXPORTER_CONFIG:-$OPENWRT_TESTS_DIR/ansible/files/exporter/labgrid-fcefyn/exporter.yaml}"
CROSSBAR_URL="${LG_CROSSBAR:-ws://localhost:20408/ws}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if a process is running
is_running() {
    local pattern="$1"
    pgrep -f "$pattern" > /dev/null 2>&1
}

# Stop processes
stop_process() {
    local pattern="$1"
    local name="$2"
    
    if is_running "$pattern"; then
        print_info "Stopping $name..."
        pkill -f "$pattern" || true
        sleep 1
        if is_running "$pattern"; then
            print_warning "Force stopping $name..."
            pkill -9 -f "$pattern" || true
            sleep 1
        fi
        if ! is_running "$pattern"; then
            print_success "$name stopped"
        else
            print_error "Failed to stop $name"
            return 1
        fi
    else
        print_info "$name is not running"
    fi
}

# Start coordinator
start_coordinator() {
    if is_running "labgrid-coordinator"; then
        print_warning "Coordinator is already running"
        return 0
    fi
    
    print_info "Starting coordinator..."
    
    if [ ! -d "$COORDINATOR_DIR" ]; then
        print_error "Coordinator directory does not exist: $COORDINATOR_DIR"
        print_info "Creating directory..."
        mkdir -p "$COORDINATOR_DIR"
    fi
    
    cd "$COORDINATOR_DIR"
    
    if [ ! -f "places.yaml" ]; then
        print_warning "places.yaml not found in $COORDINATOR_DIR"
        print_info "Generating places.yaml..."
        if [ -f "$OPENWRT_TESTS_DIR/ansible/files/coordinator/places.yaml.j2" ]; then
            python3 "$SCRIPT_DIR/generate_places_yaml.py" || {
                print_error "Error generating places.yaml"
                return 1
            }
        else
            print_error "Template places.yaml.j2 not found"
            return 1
        fi
    fi
    
    labgrid-coordinator > "$COORDINATOR_DIR/coordinator.log" 2>&1 &
    sleep 2
    
    if is_running "labgrid-coordinator"; then
        print_success "Coordinator started (PID: $(pgrep -f 'labgrid-coordinator'))"
        print_info "Logs: $COORDINATOR_DIR/coordinator.log"
    else
        print_error "Error starting coordinator. Check logs: $COORDINATOR_DIR/coordinator.log"
        return 1
    fi
}

# Start exporter
start_exporter() {
    if is_running "labgrid-exporter.*exporter.yaml"; then
        print_warning "Exporter is already running"
        return 0
    fi
    
    print_info "Starting exporter..."
    
    if [ ! -f "$EXPORTER_CONFIG" ]; then
        print_error "Exporter configuration not found: $EXPORTER_CONFIG"
        return 1
    fi
    
    labgrid-exporter "$EXPORTER_CONFIG" > "$COORDINATOR_DIR/exporter.log" 2>&1 &
    sleep 2
    
    if is_running "labgrid-exporter.*exporter.yaml"; then
        print_success "Exporter started (PID: $(pgrep -f 'labgrid-exporter.*exporter.yaml'))"
        print_info "Logs: $COORDINATOR_DIR/exporter.log"
    else
        print_error "Error starting exporter. Check logs: $COORDINATOR_DIR/exporter.log"
        return 1
    fi
}

# Stop coordinator
stop_coordinator() {
    stop_process "labgrid-coordinator" "Coordinator"
}

# Stop exporter
stop_exporter() {
    stop_process "labgrid-exporter.*exporter.yaml" "Exporter"
}

# Check status
status() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Labgrid Status"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    # Coordinator
    if is_running "labgrid-coordinator"; then
        local pid=$(pgrep -f "labgrid-coordinator")
        print_success "Coordinator: RUNNING (PID: $pid)"
        print_info "  Directory: $COORDINATOR_DIR"
        print_info "  Crossbar: $CROSSBAR_URL"
    else
        print_error "Coordinator: STOPPED"
    fi
    
    echo ""
    
    # Exporter
    if is_running "labgrid-exporter.*exporter.yaml"; then
        local pid=$(pgrep -f "labgrid-exporter.*exporter.yaml")
        print_success "Exporter: RUNNING (PID: $pid)"
        print_info "  Config: $EXPORTER_CONFIG"
    else
        print_error "Exporter: STOPPED"
    fi
    
    echo ""
    
    # Check available places
    if is_running "labgrid-coordinator"; then
        print_info "Checking available places..."
        export LG_CROSSBAR="$CROSSBAR_URL"
        if command -v labgrid-client > /dev/null 2>&1; then
            labgrid-client places 2>/dev/null || print_warning "Could not list places (coordinator just started?)"
        else
            print_warning "labgrid-client not found"
        fi
    fi
    
    echo ""
}

# Show logs
logs() {
    local service="${1:-both}"
    
    case "$service" in
        coordinator|coord)
            if [ -f "$COORDINATOR_DIR/coordinator.log" ]; then
                tail -f "$COORDINATOR_DIR/coordinator.log"
            else
                print_error "Coordinator log not found"
            fi
            ;;
        exporter|exp)
            if [ -f "$COORDINATOR_DIR/exporter.log" ]; then
                tail -f "$COORDINATOR_DIR/exporter.log"
            else
                print_error "Exporter log not found"
            fi
            ;;
        both|all)
            if [ -f "$COORDINATOR_DIR/coordinator.log" ] && [ -f "$COORDINATOR_DIR/exporter.log" ]; then
                tail -f "$COORDINATOR_DIR/coordinator.log" "$COORDINATOR_DIR/exporter.log"
            else
                print_error "Logs not found"
            fi
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Usage: $0 logs [coordinator|exporter|both]"
            exit 1
            ;;
    esac
}

# Restart services
restart() {
    local service="${1:-both}"
    
    case "$service" in
        coordinator|coord)
            stop_coordinator
            sleep 1
            start_coordinator
            ;;
        exporter|exp)
            stop_exporter
            sleep 1
            start_exporter
            ;;
        both|all)
            stop_exporter
            stop_coordinator
            sleep 2
            start_coordinator
            sleep 2
            start_exporter
            ;;
        *)
            print_error "Unknown service: $service"
            echo "Usage: $0 restart [coordinator|exporter|both]"
            exit 1
            ;;
    esac
}

# Show help
show_help() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
  start [coordinator|exporter|both]  Start services
  stop [coordinator|exporter|both]   Stop services
  restart [coordinator|exporter|both] Restart services
  status                             Show service status
  logs [coordinator|exporter|both]  Show logs (tail -f)
  help                               Show this help

Examples:
  $0 start both              # Start coordinator and exporter
  $0 restart exporter        # Restart only the exporter
  $0 status                  # View status
  $0 logs coordinator        # View coordinator logs

Environment variables:
  LABGRID_COORDINATOR_DIR    Coordinator directory (default: ~/labgrid-coordinator)
  LABGRID_EXPORTER_CONFIG     Exporter config (default: .../labgrid-fcefyn/exporter.yaml)
  LG_CROSSBAR                 Crossbar URL (default: ws://localhost:20408/ws)
  OPENWRT_TESTS_DIR          openwrt-tests directory (default: ~/Documents/openwrt-tests)

EOF
}

# Main
case "${1:-help}" in
    start)
        case "${2:-both}" in
            coordinator|coord)
                start_coordinator
                ;;
            exporter|exp)
                start_exporter
                ;;
            both|all)
                start_coordinator
                sleep 1
                start_exporter
                ;;
            *)
                print_error "Servicio desconocido: $2"
                show_help
                exit 1
                ;;
        esac
        ;;
    stop)
        case "${2:-both}" in
            coordinator|coord)
                stop_coordinator
                ;;
            exporter|exp)
                stop_exporter
                ;;
            both|all)
                stop_exporter
                stop_coordinator
                ;;
            *)
                print_error "Servicio desconocido: $2"
                show_help
                exit 1
                ;;
        esac
        ;;
    restart)
        restart "${2:-both}"
        ;;
    status)
        status
        ;;
    logs)
        logs "${2:-both}"
        ;;
    help|--help|-h)
        show_help
        ;;
        *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

