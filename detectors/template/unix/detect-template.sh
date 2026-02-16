#!/usr/bin/env bash

#######################################
# [TOOL_NAME] Detection Script
# Platform: macOS & Linux
#
# Comprehensive detection script for [TOOL_NAME] software installations.
# Performs core checks (affecting exit code) and supplementary checks (informational).
#
# Exit Codes:
#   0 = [TOOL_NAME] not present (compliant)
#   1 = [TOOL_NAME] found (non-compliant)
#   2 = Execution error
#
# Usage:
#   ./detect-template.sh           # Standard output
#   ./detect-template.sh --verbose # Detailed output
#
# Template version: 1.0.0
# TODO: Replace [TOOL_NAME] with your target software name
# TODO: Customize detection methods for your specific tool
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
TOOL_DETECTED=false
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

#######################################
# Core Detection Functions
# These affect the exit code
#######################################

check_cli_executable() {
    log_message "INFO" "Checking for [TOOL_NAME] CLI executable..."

    # TODO: Replace 'toolname' with actual executable name
    if command -v toolname &> /dev/null; then
        local cli_path
        cli_path=$(command -v toolname)
        log_message "FOUND" "DETECTED: [TOOL_NAME] CLI found in PATH: $cli_path" "true"
        TOOL_DETECTED=true
        return 0
    fi

    # TODO: Add common installation locations for your tool
    local common_paths=(
        "/usr/local/bin/toolname"
        "/usr/bin/toolname"
        "/opt/toolname/bin/toolname"
        "$HOME/.local/bin/toolname"
        "/Applications/ToolName.app/Contents/MacOS/toolname"
    )

    for path in "${common_paths[@]}"; do
        if [[ -f "$path" ]] && [[ -x "$path" ]]; then
            log_message "FOUND" "DETECTED: [TOOL_NAME] CLI found at: $path" "true"
            TOOL_DETECTED=true
            return 0
        fi
    done

    log_message "INFO" "[TOOL_NAME] CLI executable not found"
    return 1
}

check_state_directory() {
    log_message "INFO" "Checking for [TOOL_NAME] state directory..."

    # TODO: Add state directory paths for your tool
    local state_paths=(
        "$HOME/.toolname"
        "$HOME/.config/toolname"
        "/var/lib/toolname"
        "$HOME/Library/Application Support/ToolName"
    )

    for path in "${state_paths[@]}"; do
        if [[ -d "$path" ]]; then
            local item_count
            item_count=$(find "$path" -maxdepth 1 2>/dev/null | wc -l)
            log_message "FOUND" "DETECTED: [TOOL_NAME] state directory found: $path ($item_count items)" "true"
            TOOL_DETECTED=true
            return 0
        fi
    done

    log_message "INFO" "[TOOL_NAME] state directory not found"
    return 1
}

get_tool_version() {
    log_message "INFO" "Attempting to retrieve [TOOL_NAME] version..."

    # TODO: Replace with actual version command
    if command -v toolname &> /dev/null; then
        local version
        if version=$(toolname --version 2>&1); then
            log_message "FOUND" "DETECTED: [TOOL_NAME] version retrieved: $version" "true"
            TOOL_DETECTED=true
            return 0
        fi
    fi

    log_message "INFO" "Could not retrieve [TOOL_NAME] version"
    return 1
}

check_configuration_files() {
    log_message "INFO" "Checking for [TOOL_NAME] configuration files..."

    # TODO: Add configuration file paths for your tool
    local config_paths=(
        "$HOME/.toolname/config.yaml"
        "$HOME/.config/toolname/config.json"
        "/etc/toolname/config.yaml"
    )

    for path in "${config_paths[@]}"; do
        if [[ -f "$path" ]]; then
            log_message "FOUND" "DETECTED: [TOOL_NAME] configuration file found: $path" "true"
            TOOL_DETECTED=true
            return 0
        fi
    done

    log_message "INFO" "[TOOL_NAME] configuration files not found"
    return 1
}

check_service_macos() {
    log_message "INFO" "Checking for [TOOL_NAME] service (macOS)..."

    # TODO: Add launchd plist paths for your tool
    local launchd_paths=(
        "$HOME/Library/LaunchAgents/com.toolname.*.plist"
        "/Library/LaunchAgents/com.toolname.*.plist"
        "/Library/LaunchDaemons/com.toolname.*.plist"
    )

    for pattern in "${launchd_paths[@]}"; do
        # shellcheck disable=SC2086
        for file in $pattern; do
            if [[ -f "$file" ]]; then
                log_message "FOUND" "DETECTED: [TOOL_NAME] launchd service found: $file" "true"
                TOOL_DETECTED=true
                return 0
            fi
        done
    done

    log_message "INFO" "[TOOL_NAME] service not found (launchd)"
    return 1
}

check_service_linux() {
    log_message "INFO" "Checking for [TOOL_NAME] service (Linux)..."

    # TODO: Replace with actual service name
    if command -v systemctl &> /dev/null; then
        if systemctl list-units --all --type=service | grep -i toolname &> /dev/null; then
            local services
            services=$(systemctl list-units --all --type=service | grep -i toolname | awk '{print $1}')
            while IFS= read -r service; do
                log_message "FOUND" "DETECTED: [TOOL_NAME] systemd service found: $service" "true"
                TOOL_DETECTED=true
            done <<< "$services"
            return 0
        fi
    fi

    log_message "INFO" "[TOOL_NAME] service not found (systemd)"
    return 1
}

check_service() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        check_service_macos
    elif [[ "$OS_TYPE" == "linux" ]]; then
        check_service_linux
    fi
}

#######################################
# Supplementary Functions
# These are informational only
#######################################

check_active_processes() {
    log_message "INFO" "[SUPPLEMENTARY] Checking for active [TOOL_NAME] processes..."

    # TODO: Replace with actual process name
    if pgrep -if toolname &> /dev/null; then
        local processes
        processes=$(ps aux | grep -i "[t]oolname")
        while IFS= read -r proc; do
            log_message "INFO" "[INFO] [TOOL_NAME] process found: $proc"
        done <<< "$processes"
        return 0
    fi

    log_message "INFO" "[SUPPLEMENTARY] No active [TOOL_NAME] processes found"
    return 1
}

check_environment_variables() {
    log_message "INFO" "[SUPPLEMENTARY] Checking environment variables..."

    local found=false
    # TODO: Replace with actual environment variable pattern
    while IFS='=' read -r name value; do
        if [[ "$name" == *"TOOLNAME"* ]] || [[ "$value" == *"toolname"* ]]; then
            log_message "INFO" "[INFO] [TOOL_NAME] environment variable: $name = $value"
            found=true
        fi
    done < <(env)

    if [[ "$found" == "false" ]]; then
        log_message "INFO" "[SUPPLEMENTARY] No [TOOL_NAME] environment variables found"
    fi
}

#######################################
# Main Function
#######################################

main() {
    detect_os

    echo -e "${CYAN}"
    echo "========================================"
    echo "[TOOL_NAME] Detection Script - $OS_TYPE"
    echo "========================================"
    echo -e "${NC}"

    # Core detection checks (affect exit code)
    echo -e "${YELLOW}Running Core Detection Checks...${NC}"
    echo -e "${YELLOW}--------------------------------${NC}\n"

    check_cli_executable
    check_state_directory
    get_tool_version
    check_configuration_files
    check_service

    # Supplementary checks (informational only)
    echo -e "\n${YELLOW}Running Supplementary Checks...${NC}"
    echo -e "${YELLOW}--------------------------------${NC}\n"

    check_active_processes
    check_environment_variables

    # Summary
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}Detection Summary${NC}"
    echo -e "${CYAN}========================================${NC}\n"

    if [[ "$TOOL_DETECTED" == "true" ]]; then
        echo -e "${RED}STATUS: [TOOL_NAME] DETECTED (Non-Compliant)${NC}"
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
        echo -e "${GREEN}STATUS: [TOOL_NAME] NOT DETECTED (Compliant)${NC}"
        echo -e "${GREEN}Exit Code: 0${NC}\n"
        exit 0
    fi
}

# Error handling
trap 'echo -e "\n${RED}ERROR: Script execution failed${NC}"; echo -e "${RED}Exit Code: 2${NC}\n"; exit 2' ERR

# Run main function
main "$@"
