#!/usr/bin/env bash

#######################################
# OpenClaw Removal Script
# Platform: macOS & Linux
#
# IMPORTANT: This script REMOVES software and data. Use with caution.
#
# Actions performed:
# - Stops OpenClaw services
# - Removes OpenClaw executables
# - Removes configuration and state directories
# - Cleans up services (launchd/systemd)
# - Removes Docker images and containers
# - Removes environment variables from shell RC files
# - Removes application bundles (macOS)
#
# Exit Codes:
#   0 = Successfully remediated
#   1 = Remediation failed or user cancelled
#   2 = Execution error
#
# Usage:
#   ./remove-openclaw.sh                    # Interactive with confirmation
#   ./remove-openclaw.sh --force            # Skip confirmation (use with caution)
#   ./remove-openclaw.sh --backup-path /path # Custom backup location
#   ./remove-openclaw.sh --skip-backup      # Skip backup (not recommended)
#
# **WARNING**: This script permanently removes OpenClaw and its data.
# Use only when authorized by IT security policies.
# Always test in non-production environment first.
#######################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global state
FORCE=false
SKIP_BACKUP=false
BACKUP_PATH=""
BACKUP_CREATED=false
ITEMS_REMOVED=0
ERRORS=0
REMOVAL_LOG=()
OS_TYPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --backup-path)
            BACKUP_PATH="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force           Skip confirmation prompts"
            echo "  --skip-backup     Skip creating backup (not recommended)"
            echo "  --backup-path     Custom backup location"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 2
            ;;
    esac
done

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    else
        OS_TYPE="unknown"
    fi
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local color="$NC"
    case "$level" in
        ERROR)   color="$RED" ;;
        WARNING) color="$YELLOW" ;;
        SUCCESS) color="$GREEN" ;;
        INFO)    color="$NC" ;;
    esac

    local log_entry="[$timestamp] [$level] $message"
    REMOVAL_LOG+=("$log_entry")

    echo -e "${color}${log_entry}${NC}"
}

confirm_removal() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi

    echo -e "\n${RED}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    ⚠️  WARNING ⚠️                          ║"
    echo "║                                                           ║"
    echo "║  This will PERMANENTLY REMOVE OpenClaw and its data:     ║"
    echo "║                                                           ║"
    echo "║  • All OpenClaw executables                              ║"
    echo "║  • Configuration files                                   ║"
    echo "║  • User data and state                                   ║"
    echo "║  • Services and daemons                                  ║"
    echo "║  • Docker images and containers                          ║"
    echo "║  • Application bundles (macOS)                           ║"
    echo "║                                                           ║"
    echo "║  This action CANNOT be undone (except from backup)       ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    read -p "Type 'REMOVE' to confirm removal: " confirmation

    if [[ "$confirmation" == "REMOVE" ]]; then
        return 0
    else
        return 1
    fi
}

create_backup() {
    if [[ "$SKIP_BACKUP" == "true" ]]; then
        log_message "WARNING" "Skipping backup (--skip-backup flag set)"
        return 0
    fi

    local timestamp
    timestamp=$(date '+%Y%m%d-%H%M%S')
    local backup_dir="${BACKUP_PATH:-/tmp/openclaw-backup-$timestamp}"

    log_message "INFO" "Creating backup at: $backup_dir"

    mkdir -p "$backup_dir"

    # Backup configuration directories
    local config_paths=(
        "$HOME/.openclaw"
        "$HOME/.config/openclaw"
        "/var/lib/openclaw"
        "$HOME/Library/Application Support/OpenClaw"
    )

    for path in "${config_paths[@]}"; do
        if [[ -d "$path" ]]; then
            local backup_name=$(basename "$path")
            log_message "INFO" "Backing up: $path -> $backup_dir/$backup_name"
            cp -R "$path" "$backup_dir/" 2>/dev/null || true
        fi
    done

    # Backup service files (macOS)
    if [[ "$OS_TYPE" == "macos" ]]; then
        local launchd_paths=(
            "$HOME/Library/LaunchAgents/com.openclaw.*.plist"
            "/Library/LaunchAgents/com.openclaw.*.plist"
            "/Library/LaunchDaemons/com.openclaw.*.plist"
        )

        mkdir -p "$backup_dir/launchd"
        for pattern in "${launchd_paths[@]}"; do
            # shellcheck disable=SC2086
            for file in $pattern; do
                if [[ -f "$file" ]]; then
                    log_message "INFO" "Backing up launchd plist: $file"
                    cp "$file" "$backup_dir/launchd/" 2>/dev/null || true
                fi
            done
        done
    fi

    # Backup systemd services (Linux)
    if [[ "$OS_TYPE" == "linux" ]]; then
        mkdir -p "$backup_dir/systemd"
        local unit_paths=(
            "/etc/systemd/system/openclaw*.service"
            "/usr/lib/systemd/system/openclaw*.service"
            "$HOME/.config/systemd/user/openclaw*.service"
        )

        for pattern in "${unit_paths[@]}"; do
            # shellcheck disable=SC2086
            for file in $pattern; do
                if [[ -f "$file" ]]; then
                    log_message "INFO" "Backing up systemd unit: $file"
                    cp "$file" "$backup_dir/systemd/" 2>/dev/null || true
                fi
            done
        done
    fi

    BACKUP_CREATED=true
    log_message "SUCCESS" "Backup completed: $backup_dir"
    echo -e "\n${CYAN}💾 Backup location: $backup_dir${NC}\n"
}

stop_services_macos() {
    log_message "INFO" "Stopping OpenClaw services (macOS)..."

    local launchd_paths=(
        "$HOME/Library/LaunchAgents/com.openclaw.*.plist"
        "/Library/LaunchAgents/com.openclaw.*.plist"
        "/Library/LaunchDaemons/com.openclaw.*.plist"
    )

    for pattern in "${launchd_paths[@]}"; do
        # shellcheck disable=SC2086
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                local label
                label=$(basename "$file" .plist)
                log_message "INFO" "Unloading launchd service: $label"
                launchctl unload "$file" 2>/dev/null || true
                ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
            fi
        done
    done
}

stop_services_linux() {
    log_message "INFO" "Stopping OpenClaw services (Linux)..."

    if command -v systemctl &> /dev/null; then
        # Get list of OpenClaw services
        local services
        services=$(systemctl list-units --all --type=service | grep -i openclaw | awk '{print $1}' || true)

        while IFS= read -r service; do
            if [[ -n "$service" ]]; then
                log_message "INFO" "Stopping and disabling service: $service"
                sudo systemctl stop "$service" 2>/dev/null || true
                sudo systemctl disable "$service" 2>/dev/null || true
                ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
            fi
        done <<< "$services"
    fi
}

stop_services() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        stop_services_macos
    elif [[ "$OS_TYPE" == "linux" ]]; then
        stop_services_linux
    fi
}

remove_executables() {
    log_message "INFO" "Removing OpenClaw executables..."

    local executable_paths=(
        "/usr/local/bin/openclaw"
        "/usr/bin/openclaw"
        "/opt/openclaw"
        "$HOME/.local/bin/openclaw"
        "$HOME/.openclaw/bin"
    )

    for path in "${executable_paths[@]}"; do
        if [[ -e "$path" ]]; then
            log_message "INFO" "Removing: $path"
            rm -rf "$path" 2>/dev/null || sudo rm -rf "$path" 2>/dev/null || {
                log_message "ERROR" "Failed to remove: $path"
                ERRORS=$((ERRORS + 1))
                continue
            }
            log_message "SUCCESS" "Removed: $path"
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    done
}

remove_configuration() {
    log_message "INFO" "Removing OpenClaw configuration..."

    local config_paths=(
        "$HOME/.openclaw"
        "$HOME/.config/openclaw"
        "/var/lib/openclaw"
        "/etc/openclaw"
        "$HOME/Library/Application Support/OpenClaw"
    )

    for path in "${config_paths[@]}"; do
        if [[ -d "$path" ]]; then
            log_message "INFO" "Removing configuration: $path"
            rm -rf "$path" 2>/dev/null || sudo rm -rf "$path" 2>/dev/null || {
                log_message "ERROR" "Failed to remove: $path"
                ERRORS=$((ERRORS + 1))
                continue
            }
            log_message "SUCCESS" "Removed: $path"
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    done
}

remove_services_macos() {
    log_message "INFO" "Removing OpenClaw launchd services..."

    local launchd_paths=(
        "$HOME/Library/LaunchAgents/com.openclaw.*.plist"
        "/Library/LaunchAgents/com.openclaw.*.plist"
        "/Library/LaunchDaemons/com.openclaw.*.plist"
    )

    for pattern in "${launchd_paths[@]}"; do
        # shellcheck disable=SC2086
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                log_message "INFO" "Removing launchd plist: $file"
                rm -f "$file" 2>/dev/null || sudo rm -f "$file" 2>/dev/null || {
                    log_message "ERROR" "Failed to remove: $file"
                    ERRORS=$((ERRORS + 1))
                    continue
                }
                log_message "SUCCESS" "Removed: $file"
                ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
            fi
        done
    done
}

remove_services_linux() {
    log_message "INFO" "Removing OpenClaw systemd services..."

    local unit_paths=(
        "/etc/systemd/system/openclaw*.service"
        "/usr/lib/systemd/system/openclaw*.service"
        "$HOME/.config/systemd/user/openclaw*.service"
    )

    for pattern in "${unit_paths[@]}"; do
        # shellcheck disable=SC2086
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                log_message "INFO" "Removing systemd unit: $file"
                sudo rm -f "$file" 2>/dev/null || {
                    log_message "ERROR" "Failed to remove: $file"
                    ERRORS=$((ERRORS + 1))
                    continue
                }
                log_message "SUCCESS" "Removed: $file"
                ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
            fi
        done
    done

    # Reload systemd
    if command -v systemctl &> /dev/null; then
        log_message "INFO" "Reloading systemd daemon..."
        sudo systemctl daemon-reload 2>/dev/null || true
    fi
}

remove_services() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        remove_services_macos
    elif [[ "$OS_TYPE" == "linux" ]]; then
        remove_services_linux
    fi
}

remove_application_bundles() {
    if [[ "$OS_TYPE" != "macos" ]]; then
        return
    fi

    log_message "INFO" "Removing OpenClaw application bundles (macOS)..."

    local app_paths=(
        "/Applications/OpenClaw.app"
        "$HOME/Applications/OpenClaw.app"
        "/Applications/Utilities/OpenClaw.app"
    )

    for path in "${app_paths[@]}"; do
        if [[ -d "$path" ]]; then
            log_message "INFO" "Removing application bundle: $path"
            rm -rf "$path" 2>/dev/null || sudo rm -rf "$path" 2>/dev/null || {
                log_message "ERROR" "Failed to remove: $path"
                ERRORS=$((ERRORS + 1))
                continue
            }
            log_message "SUCCESS" "Removed: $path"
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    done
}

remove_docker_artifacts() {
    log_message "INFO" "Removing OpenClaw Docker artifacts..."

    if ! command -v docker &> /dev/null; then
        log_message "INFO" "Docker not available, skipping Docker cleanup"
        return
    fi

    # Stop and remove containers
    local containers
    containers=$(docker ps -a --format "{{.ID}} {{.Image}}" 2>/dev/null | grep -i openclaw | awk '{print $1}' || true)

    while IFS= read -r container_id; do
        if [[ -n "$container_id" ]]; then
            log_message "INFO" "Removing Docker container: $container_id"
            docker rm -f "$container_id" &>/dev/null || true
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    done <<< "$containers"

    # Remove images
    local images
    images=$(docker images --format "{{.ID}} {{.Repository}}" 2>/dev/null | grep -i openclaw | awk '{print $1}' || true)

    while IFS= read -r image_id; do
        if [[ -n "$image_id" ]]; then
            log_message "INFO" "Removing Docker image: $image_id"
            docker rmi -f "$image_id" &>/dev/null || true
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    done <<< "$images"

    log_message "SUCCESS" "Docker cleanup completed"
}

clean_shell_rc_files() {
    log_message "INFO" "Cleaning OpenClaw references from shell RC files..."

    local rc_files=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.profile"
    )

    for rc_file in "${rc_files[@]}"; do
        if [[ -f "$rc_file" ]]; then
            if grep -qi openclaw "$rc_file"; then
                log_message "INFO" "Cleaning OpenClaw references from: $rc_file"
                # Create backup
                cp "$rc_file" "${rc_file}.backup-$(date +%Y%m%d)" 2>/dev/null || true
                # Remove lines containing openclaw
                sed -i.tmp '/openclaw/Id' "$rc_file" 2>/dev/null || sed -i '' '/openclaw/Id' "$rc_file" 2>/dev/null || true
                rm -f "${rc_file}.tmp" 2>/dev/null || true
                ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
            fi
        fi
    done
}

remove_package_manager_installations() {
    log_message "INFO" "Checking package managers for OpenClaw..."

    # Homebrew
    if command -v brew &> /dev/null; then
        if brew list 2>/dev/null | grep -qi openclaw; then
            log_message "INFO" "Uninstalling OpenClaw via Homebrew..."
            brew uninstall openclaw 2>/dev/null || true
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    fi

    # APT (Debian/Ubuntu)
    if command -v apt-get &> /dev/null; then
        if dpkg -l | grep -qi openclaw; then
            log_message "INFO" "Uninstalling OpenClaw via APT..."
            sudo apt-get remove -y openclaw 2>/dev/null || true
            sudo apt-get purge -y openclaw 2>/dev/null || true
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    fi

    # RPM (RedHat/CentOS/Fedora)
    if command -v rpm &> /dev/null; then
        if rpm -qa | grep -qi openclaw; then
            log_message "INFO" "Uninstalling OpenClaw via RPM..."
            sudo rpm -e openclaw 2>/dev/null || true
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    fi

    # Snap
    if command -v snap &> /dev/null; then
        if snap list 2>/dev/null | grep -qi openclaw; then
            log_message "INFO" "Uninstalling OpenClaw via Snap..."
            sudo snap remove openclaw 2>/dev/null || true
            ITEMS_REMOVED=$((ITEMS_REMOVED + 1))
        fi
    fi
}

main() {
    detect_os

    echo -e "${CYAN}"
    echo "========================================"
    echo "OpenClaw Removal Script - $OS_TYPE"
    echo "========================================"
    echo -e "${NC}"

    # Confirm removal
    if ! confirm_removal; then
        echo -e "\n${YELLOW}❌ Removal cancelled by user${NC}\n"
        exit 1
    fi

    echo -e "\n${YELLOW}🔄 Starting OpenClaw removal...${NC}\n"

    # Create backup
    if ! create_backup; then
        echo -e "\n${RED}❌ Backup failed. Aborting removal for safety.${NC}"
        echo -e "${YELLOW}Use --skip-backup to proceed without backup (not recommended)${NC}\n"
        exit 1
    fi

    # Perform removal steps
    stop_services
    remove_executables
    remove_configuration
    remove_services
    remove_application_bundles
    remove_docker_artifacts
    clean_shell_rc_files
    remove_package_manager_installations

    # Summary
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}Removal Summary${NC}"
    echo -e "${CYAN}========================================${NC}\n"

    echo -e "Items Removed: ${GREEN}$ITEMS_REMOVED${NC}"
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "Errors: ${RED}$ERRORS${NC}"
    else
        echo -e "Errors: ${GREEN}$ERRORS${NC}"
    fi

    if [[ "$BACKUP_CREATED" == "true" ]] && [[ "$SKIP_BACKUP" != "true" ]]; then
        echo -e "Backup Created: ${GREEN}Yes${NC}"
    fi

    if [[ $ERRORS -eq 0 ]]; then
        echo -e "\n${GREEN}✅ OpenClaw successfully removed${NC}"
        echo -e "\n${CYAN}💡 Note: You may need to restart your shell or system for complete cleanup${NC}\n"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  OpenClaw removed with $ERRORS error(s)${NC}"
        echo -e "${YELLOW}Review the log above for details${NC}\n"
        exit 1
    fi
}

# Error handling
trap 'echo -e "\n${RED}ERROR: Removal failed${NC}"; echo -e "${RED}Exit Code: 2${NC}\n"; exit 2' ERR

# Run main function
main "$@"
