#!/usr/bin/env bash

#######################################
# OpenClaw Detection Script
# Platform: macOS & Linux
#
# Comprehensive detection script for OpenClaw software installations.
# Performs core checks (affecting exit code) and supplementary checks (informational).
#
# Exit Codes:
#   0 = OpenClaw not present (compliant)
#   1 = OpenClaw found (non-compliant)
#   2 = Execution error
#
# Usage:
#   ./detect-openclaw.sh           # Standard output
#   ./detect-openclaw.sh --verbose # Detailed output
#######################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global state
OPENCLAW_DETECTED=false
VERBOSE=false
DETECTION_LOG=()
OS_TYPE=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE=true
            shift
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
    local affects_exit_code="${3:-false}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local color="$NC"
    case "$level" in
        ERROR)   color="$RED" ;;
        WARNING) color="$YELLOW" ;;
        SUCCESS) color="$GREEN" ;;
        FOUND)   color="$MAGENTA" ;;
        INFO)    color="$NC" ;;
    esac

    local log_entry="[$timestamp] [$level] $message"
    DETECTION_LOG+=("$log_entry|$affects_exit_code")

    if [[ "$VERBOSE" == "true" ]] || [[ "$level" == "FOUND" ]] || [[ "$level" == "ERROR" ]]; then
        echo -e "${color}${log_entry}${NC}"
    fi
}

check_cli_executable() {
    log_message "INFO" "Checking for OpenClaw CLI executable..."

    # Check PATH
    if command -v openclaw &> /dev/null; then
        local cli_path
        cli_path=$(command -v openclaw)
        log_message "FOUND" "DETECTED: OpenClaw CLI found in PATH: $cli_path" "true"
        OPENCLAW_DETECTED=true
        return 0
    fi

    # Common installation locations
    local common_paths=(
        "/usr/local/bin/openclaw"
        "/usr/bin/openclaw"
        "/opt/openclaw/bin/openclaw"
        "/opt/openclaw/openclaw"
        "$HOME/.openclaw/bin/openclaw"
        "$HOME/.local/bin/openclaw"
        "/Applications/OpenClaw.app/Contents/MacOS/openclaw"
    )

    for path in "${common_paths[@]}"; do
        if [[ -f "$path" ]] && [[ -x "$path" ]]; then
            log_message "FOUND" "DETECTED: OpenClaw CLI found at: $path" "true"
            OPENCLAW_DETECTED=true
            return 0
        fi
    done

    log_message "INFO" "OpenClaw CLI executable not found"
    return 1
}

check_state_directory() {
    log_message "INFO" "Checking for OpenClaw state directory..."

    local state_paths=(
        "$HOME/.openclaw"
        "$HOME/.config/openclaw"
        "/var/lib/openclaw"
        "/Library/Application Support/OpenClaw"
        "$HOME/Library/Application Support/OpenClaw"
    )

    for path in "${state_paths[@]}"; do
        if [[ -d "$path" ]]; then
            local item_count
            item_count=$(find "$path" -maxdepth 1 2>/dev/null | wc -l)
            log_message "FOUND" "DETECTED: OpenClaw state directory found: $path ($item_count items)" "true"
            OPENCLAW_DETECTED=true
            return 0
        fi
    done

    log_message "INFO" "OpenClaw state directory not found"
    return 1
}

get_openclaw_version() {
    log_message "INFO" "Attempting to retrieve OpenClaw version..."

    if command -v openclaw &> /dev/null; then
        local version
        if version=$(openclaw --version 2>&1); then
            log_message "FOUND" "DETECTED: OpenClaw version retrieved: $version" "true"
            OPENCLAW_DETECTED=true
            return 0
        fi
    fi

    log_message "INFO" "Could not retrieve OpenClaw version"
    return 1
}

check_configuration_files() {
    log_message "INFO" "Checking for OpenClaw configuration files..."

    local config_paths=(
        "$HOME/.openclaw/config.yaml"
        "$HOME/.openclaw/config.json"
        "$HOME/.openclaw/settings.yaml"
        "$HOME/.config/openclaw/config.yaml"
        "/etc/openclaw/config.yaml"
        "$HOME/Library/Application Support/OpenClaw/config.yaml"
    )

    for path in "${config_paths[@]}"; do
        if [[ -f "$path" ]]; then
            log_message "FOUND" "DETECTED: OpenClaw configuration file found: $path" "true"
            OPENCLAW_DETECTED=true
            return 0
        fi
    done

    log_message "INFO" "OpenClaw configuration files not found"
    return 1
}

check_gateway_service_macos() {
    log_message "INFO" "Checking for OpenClaw gateway service (macOS)..."

    local launchd_paths=(
        "$HOME/Library/LaunchAgents/com.openclaw.*.plist"
        "/Library/LaunchAgents/com.openclaw.*.plist"
        "/Library/LaunchDaemons/com.openclaw.*.plist"
        "/System/Library/LaunchDaemons/com.openclaw.*.plist"
    )

    for pattern in "${launchd_paths[@]}"; do
        # shellcheck disable=SC2086
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                log_message "FOUND" "DETECTED: OpenClaw launchd service found: $file" "true"
                OPENCLAW_DETECTED=true

                # Check if service is loaded
                if launchctl list | grep -i openclaw &> /dev/null; then
                    log_message "FOUND" "DETECTED: OpenClaw service is currently loaded" "true"
                fi
                return 0
            fi
        done
    done

    log_message "INFO" "OpenClaw gateway service not found (launchd)"
    return 1
}

check_gateway_service_linux() {
    log_message "INFO" "Checking for OpenClaw gateway service (Linux)..."

    # Check systemd services
    if command -v systemctl &> /dev/null; then
        if systemctl list-units --all --type=service | grep -i openclaw &> /dev/null; then
            local services
            services=$(systemctl list-units --all --type=service | grep -i openclaw | awk '{print $1}')
            while IFS= read -r service; do
                log_message "FOUND" "DETECTED: OpenClaw systemd service found: $service" "true"
                OPENCLAW_DETECTED=true
            done <<< "$services"
            return 0
        fi

        # Check systemd unit files
        local unit_paths=(
            "/etc/systemd/system/openclaw*.service"
            "/usr/lib/systemd/system/openclaw*.service"
            "$HOME/.config/systemd/user/openclaw*.service"
        )

        for pattern in "${unit_paths[@]}"; do
            # shellcheck disable=SC2086
            for file in $pattern; do
                if [[ -f "$file" ]]; then
                    log_message "FOUND" "DETECTED: OpenClaw systemd unit file found: $file" "true"
                    OPENCLAW_DETECTED=true
                    return 0
                fi
            done
        done
    fi

    # Check init.d scripts
    if [[ -d /etc/init.d ]]; then
        if ls /etc/init.d/*openclaw* &> /dev/null; then
            for file in /etc/init.d/*openclaw*; do
                log_message "FOUND" "DETECTED: OpenClaw init.d script found: $file" "true"
                OPENCLAW_DETECTED=true
                return 0
            done
        fi
    fi

    log_message "INFO" "OpenClaw gateway service not found (systemd/init.d)"
    return 1
}

check_gateway_service() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        check_gateway_service_macos
    elif [[ "$OS_TYPE" == "linux" ]]; then
        check_gateway_service_linux
    fi
}

check_gateway_port() {
    log_message "INFO" "Checking for OpenClaw gateway listening ports..."

    # Default ports to check
    local ports=(50051 8080 8443 9090)

    # Try to extract port from config
    local config_path="$HOME/.openclaw/config.yaml"
    if [[ -f "$config_path" ]]; then
        if grep -q "port:" "$config_path" 2>/dev/null; then
            local config_port
            config_port=$(grep "port:" "$config_path" | awk '{print $2}' | tr -d '"' | tr -d "'")
            if [[ -n "$config_port" ]]; then
                ports+=("$config_port")
            fi
        fi
    fi

    for port in "${ports[@]}"; do
        # Check listening ports
        if command -v lsof &> /dev/null; then
            if lsof -i ":$port" -sTCP:LISTEN &> /dev/null; then
                local process_info
                process_info=$(lsof -i ":$port" -sTCP:LISTEN | tail -n +2 | head -n 1)
                log_message "FOUND" "DETECTED: Service listening on port $port: $process_info" "true"
                OPENCLAW_DETECTED=true
                return 0
            fi
        elif command -v netstat &> /dev/null; then
            if netstat -an | grep -E "LISTEN.*:$port" &> /dev/null; then
                log_message "FOUND" "DETECTED: Service listening on port $port" "true"
                OPENCLAW_DETECTED=true
                return 0
            fi
        elif command -v ss &> /dev/null; then
            if ss -tuln | grep -E ":$port " &> /dev/null; then
                log_message "FOUND" "DETECTED: Service listening on port $port" "true"
                OPENCLAW_DETECTED=true
                return 0
            fi
        fi
    done

    log_message "INFO" "No OpenClaw gateway ports detected"
    return 1
}

check_docker_artifacts() {
    log_message "INFO" "Checking for OpenClaw Docker artifacts..."

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_message "INFO" "Docker not available, skipping Docker checks"
        return 1
    fi

    # Check for OpenClaw images
    if docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -i openclaw &> /dev/null; then
        local images
        images=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -i openclaw)
        while IFS= read -r image; do
            log_message "FOUND" "DETECTED: OpenClaw Docker image found: $image" "true"
            OPENCLAW_DETECTED=true
        done <<< "$images"
        return 0
    fi

    # Check for running containers
    if docker ps -a --format "{{.Names}} ({{.Image}})" 2>/dev/null | grep -i openclaw &> /dev/null; then
        local containers
        containers=$(docker ps -a --format "{{.Names}} ({{.Image}})" 2>/dev/null | grep -i openclaw)
        while IFS= read -r container; do
            log_message "FOUND" "DETECTED: OpenClaw Docker container found: $container" "true"
            OPENCLAW_DETECTED=true
        done <<< "$containers"
        return 0
    fi

    log_message "INFO" "No OpenClaw Docker artifacts found"
    return 1
}

check_application_bundles_macos() {
    log_message "INFO" "Checking for OpenClaw application bundles (macOS)..."

    local app_paths=(
        "/Applications/OpenClaw.app"
        "$HOME/Applications/OpenClaw.app"
        "/Applications/Utilities/OpenClaw.app"
    )

    for path in "${app_paths[@]}"; do
        if [[ -d "$path" ]]; then
            log_message "FOUND" "DETECTED: OpenClaw application bundle found: $path" "true"
            OPENCLAW_DETECTED=true
            return 0
        fi
    done

    log_message "INFO" "No OpenClaw application bundles found"
    return 1
}

check_active_processes() {
    log_message "INFO" "[SUPPLEMENTARY] Checking for active OpenClaw processes..."

    if pgrep -if openclaw &> /dev/null; then
        local processes
        processes=$(ps aux | grep -i "[o]penclaw")
        while IFS= read -r proc; do
            log_message "INFO" "[INFO] OpenClaw process found: $proc"
        done <<< "$processes"
        return 0
    fi

    log_message "INFO" "[SUPPLEMENTARY] No active OpenClaw processes found"
    return 1
}

check_environment_variables() {
    log_message "INFO" "[SUPPLEMENTARY] Checking environment variables..."

    local found=false
    while IFS='=' read -r name value; do
        if [[ "$name" == *"OPENCLAW"* ]] || [[ "$value" == *"openclaw"* ]]; then
            log_message "INFO" "[INFO] OpenClaw environment variable: $name = $value"
            found=true
        fi
    done < <(env)

    if [[ "$found" == "false" ]]; then
        log_message "INFO" "[SUPPLEMENTARY] No OpenClaw environment variables found"
    fi
}

check_shell_rc_files() {
    log_message "INFO" "[SUPPLEMENTARY] Checking shell RC files..."

    local rc_files=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.config/fish/config.fish"
    )

    for rc_file in "${rc_files[@]}"; do
        if [[ -f "$rc_file" ]]; then
            if grep -i openclaw "$rc_file" &> /dev/null; then
                log_message "INFO" "[INFO] OpenClaw reference found in: $rc_file"
            fi
        fi
    done
}

check_package_managers() {
    log_message "INFO" "[SUPPLEMENTARY] Checking package managers..."

    # Homebrew (macOS/Linux)
    if command -v brew &> /dev/null; then
        if brew list 2>/dev/null | grep -i openclaw &> /dev/null; then
            log_message "INFO" "[INFO] OpenClaw found in Homebrew packages"
        fi
    fi

    # APT (Debian/Ubuntu)
    if command -v dpkg &> /dev/null; then
        if dpkg -l | grep -i openclaw &> /dev/null; then
            log_message "INFO" "[INFO] OpenClaw found in dpkg packages"
        fi
    fi

    # RPM (RedHat/CentOS/Fedora)
    if command -v rpm &> /dev/null; then
        if rpm -qa | grep -i openclaw &> /dev/null; then
            log_message "INFO" "[INFO] OpenClaw found in RPM packages"
        fi
    fi

    # Snap (Linux)
    if command -v snap &> /dev/null; then
        if snap list 2>/dev/null | grep -i openclaw &> /dev/null; then
            log_message "INFO" "[INFO] OpenClaw found in Snap packages"
        fi
    fi
}

main() {
    detect_os

    echo -e "${CYAN}"
    echo "========================================"
    echo "OpenClaw Detection Script - $OS_TYPE"
    echo "========================================"
    echo -e "${NC}"

    # Core detection checks (affect exit code)
    echo -e "${YELLOW}Running Core Detection Checks...${NC}"
    echo -e "${YELLOW}--------------------------------${NC}\n"

    check_cli_executable
    check_state_directory
    get_openclaw_version
    check_configuration_files
    check_gateway_service
    check_gateway_port
    check_docker_artifacts

    if [[ "$OS_TYPE" == "macos" ]]; then
        check_application_bundles_macos
    fi

    # Supplementary checks (informational only)
    echo -e "\n${YELLOW}Running Supplementary Checks...${NC}"
    echo -e "${YELLOW}--------------------------------${NC}\n"

    check_active_processes
    check_environment_variables
    check_shell_rc_files
    check_package_managers

    # Summary
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}Detection Summary${NC}"
    echo -e "${CYAN}========================================${NC}\n"

    if [[ "$OPENCLAW_DETECTED" == "true" ]]; then
        echo -e "${RED}STATUS: OpenClaw DETECTED (Non-Compliant)${NC}"
        echo -e "${RED}Exit Code: 1${NC}\n"

        # Show core detections
        echo -e "${YELLOW}Core Detections:${NC}"
        for log_entry in "${DETECTION_LOG[@]}"; do
            local message="${log_entry%|*}"
            local affects_exit="${log_entry##*|}"
            if [[ "$affects_exit" == "true" ]]; then
                echo -e "${MAGENTA}  - ${message#*] [*] }${NC}"
            fi
        done
        echo

        exit 1
    else
        echo -e "${GREEN}STATUS: OpenClaw NOT DETECTED (Compliant)${NC}"
        echo -e "${GREEN}Exit Code: 0${NC}\n"
        exit 0
    fi
}

# Error handling
trap 'echo -e "\n${RED}ERROR: Script execution failed${NC}"; echo -e "${RED}Exit Code: 2${NC}\n"; exit 2' ERR

# Run main function
main "$@"
