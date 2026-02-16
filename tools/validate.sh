#!/usr/bin/env bash

#######################################
# Detector Validation Tool
#
# Validates detector structure and requirements
#######################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

log_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

validate_detector() {
    local detector_path="$1"
    local detector_name=$(basename "$detector_path")

    echo -e "\n${BLUE}Validating detector: $detector_name${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check directory structure
    if [[ ! -d "$detector_path/windows" ]]; then
        log_error "Missing windows/ directory"
    else
        log_success "Windows directory exists"
    fi

    if [[ ! -d "$detector_path/unix" ]]; then
        log_error "Missing unix/ directory"
    else
        log_success "Unix directory exists"
    fi

    # Check for README
    if [[ ! -f "$detector_path/README.md" ]]; then
        log_error "Missing README.md"
    else
        log_success "README.md exists"
    fi

    # Check Windows script
    local ps_script=$(find "$detector_path/windows" -name "*.ps1" 2>/dev/null | head -n 1)
    if [[ -z "$ps_script" ]]; then
        log_error "No PowerShell script found in windows/"
    else
        log_success "PowerShell script found: $(basename "$ps_script")"

        # Check PowerShell script content
        if grep -q "exit 0" "$ps_script" && \
           grep -q "exit 1" "$ps_script" && \
           grep -q "exit 2" "$ps_script"; then
            log_success "PowerShell script has correct exit codes"
        else
            log_error "PowerShell script missing one or more exit codes (0, 1, 2)"
        fi
    fi

    # Check Unix script
    local sh_script=$(find "$detector_path/unix" -name "*.sh" 2>/dev/null | head -n 1)
    if [[ -z "$sh_script" ]]; then
        log_error "No bash script found in unix/"
    else
        log_success "Bash script found: $(basename "$sh_script")"

        # Check if executable
        if [[ -x "$sh_script" ]]; then
            log_success "Bash script is executable"
        else
            log_warning "Bash script is not executable (run: chmod +x)"
        fi

        # Check bash script content
        if grep -q "exit 0" "$sh_script" && \
           grep -q "exit 1" "$sh_script" && \
           grep -q "exit 2" "$sh_script"; then
            log_success "Bash script has correct exit codes"
        else
            log_error "Bash script missing one or more exit codes (0, 1, 2)"
        fi

        # Check shebang
        if head -n 1 "$sh_script" | grep -q "#!/usr/bin/env bash"; then
            log_success "Bash script has correct shebang"
        else
            log_warning "Bash script shebang should be '#!/usr/bin/env bash'"
        fi

        # Validate syntax
        if bash -n "$sh_script" 2>/dev/null; then
            log_success "Bash script syntax is valid"
        else
            log_error "Bash script has syntax errors"
        fi
    fi

    # Check for tests
    if [[ -d "$detector_path/tests" ]]; then
        log_success "Tests directory exists"

        local test_script=$(find "$detector_path/tests" -name "test-*.sh" 2>/dev/null | head -n 1)
        if [[ -n "$test_script" ]]; then
            log_success "Test script found"
        else
            log_warning "No test script found in tests/"
        fi
    else
        log_warning "No tests/ directory found"
    fi

    # Check README content
    if [[ -f "$detector_path/README.md" ]]; then
        if grep -q "## Usage" "$detector_path/README.md"; then
            log_success "README has Usage section"
        else
            log_warning "README missing Usage section"
        fi

        if grep -q "## Detection Methods" "$detector_path/README.md"; then
            log_success "README has Detection Methods section"
        else
            log_warning "README missing Detection Methods section"
        fi
    fi
}

main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║   Detector Validation Tool            ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"

    local detectors_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/detectors"

    if [[ ! -d "$detectors_dir" ]]; then
        log_error "detectors/ directory not found"
        exit 1
    fi

    # Find all detectors (exclude template)
    local detector_count=0
    for detector in "$detectors_dir"/*; do
        if [[ -d "$detector" ]] && [[ $(basename "$detector") != "template" ]]; then
            validate_detector "$detector"
            detector_count=$((detector_count + 1))
        fi
    done

    # Summary
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Validation Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Detectors validated: $detector_count"
    echo -e "Errors: ${RED}$ERRORS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

    if [[ $ERRORS -eq 0 ]]; then
        echo -e "\n${GREEN}✓ All validations passed!${NC}\n"
        exit 0
    else
        echo -e "\n${RED}✗ Validation failed with $ERRORS error(s)${NC}\n"
        exit 1
    fi
}

main "$@"
