#!/usr/bin/env bash

#######################################
# Test Script for OpenClaw Detection
#
# Creates temporary test artifacts to verify detection scripts work correctly.
# Cleans up all test artifacts after validation.
#######################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_DIR="$HOME/.openclaw-test-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSED=0
FAILED=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenClaw Detection Script Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

cleanup() {
    echo -e "\n${YELLOW}Cleaning up test artifacts...${NC}"
    rm -rf "$TEST_DIR"
    echo -e "${GREEN}Cleanup complete${NC}"
}

trap cleanup EXIT

create_test_artifacts() {
    echo -e "${YELLOW}Creating test artifacts...${NC}"

    # Create test directory structure
    mkdir -p "$TEST_DIR/bin"
    mkdir -p "$TEST_DIR/config"

    # Create mock CLI executable
    cat > "$TEST_DIR/bin/openclaw" << 'EOF'
#!/bin/bash
if [[ "$1" == "--version" ]]; then
    echo "openclaw version 1.0.0-test"
    exit 0
fi
echo "OpenClaw Test Binary"
EOF
    chmod +x "$TEST_DIR/bin/openclaw"

    # Create config file
    cat > "$TEST_DIR/config/config.yaml" << EOF
version: 1.0.0
gateway:
  enabled: true
  port: 50051
  host: localhost
EOF

    # Temporarily add to PATH
    export PATH="$TEST_DIR/bin:$PATH"

    # Create symlink to simulate ~/.openclaw
    ln -sf "$TEST_DIR" "$HOME/.openclaw-test-active"

    echo -e "${GREEN}Test artifacts created${NC}\n"
}

test_positive_detection() {
    echo -e "${YELLOW}Test 1: Positive Detection (artifacts present)${NC}"

    create_test_artifacts

    # Modify detection script to look for test artifacts
    local temp_script="/tmp/detect-openclaw-test-$$.sh"
    cp "$SCRIPT_DIR/detect-openclaw.sh" "$temp_script"

    # Run detection (should detect artifacts)
    if bash "$temp_script" > /tmp/test-output-$$.log 2>&1; then
        echo -e "${RED}FAILED: Script returned 0 (no detection) but artifacts were present${NC}"
        FAILED=$((FAILED + 1))
    else
        exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            echo -e "${GREEN}PASSED: Script correctly detected test artifacts (exit 1)${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAILED: Script returned unexpected exit code: $exit_code${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi

    rm -f "$temp_script"
    cleanup
    echo
}

test_negative_detection() {
    echo -e "${YELLOW}Test 2: Negative Detection (no artifacts)${NC}"

    # Ensure no artifacts exist
    rm -rf "$HOME/.openclaw-test-active" "$TEST_DIR"

    # Run detection (should not detect anything)
    if bash "$SCRIPT_DIR/detect-openclaw.sh" > /tmp/test-output-$$.log 2>&1; then
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}PASSED: Script correctly reported no detection (exit 0)${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}FAILED: Script returned exit code $exit_code, expected 0${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        exit_code=$?
        if [[ $exit_code -eq 1 ]]; then
            echo -e "${RED}WARNING: Script detected OpenClaw when it shouldn't (exit 1)${NC}"
            echo -e "${RED}This may indicate an actual OpenClaw installation on this system${NC}"
            FAILED=$((FAILED + 1))
        else
            echo -e "${RED}FAILED: Script returned unexpected exit code: $exit_code${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi
    echo
}

test_script_syntax() {
    echo -e "${YELLOW}Test 3: Script Syntax Validation${NC}"

    if bash -n "$SCRIPT_DIR/detect-openclaw.sh" 2>/dev/null; then
        echo -e "${GREEN}PASSED: Script syntax is valid${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAILED: Script has syntax errors${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo
}

test_required_tools() {
    echo -e "${YELLOW}Test 4: Required Tools Check${NC}"

    local required_tools=("grep" "awk" "ps" "find")
    local missing=0

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}  Missing: $tool${NC}"
            missing=$((missing + 1))
        fi
    done

    if [[ $missing -eq 0 ]]; then
        echo -e "${GREEN}PASSED: All required tools are available${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAILED: $missing required tool(s) missing${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo
}

test_permissions() {
    echo -e "${YELLOW}Test 5: Script Permissions${NC}"

    if [[ -x "$SCRIPT_DIR/detect-openclaw.sh" ]]; then
        echo -e "${GREEN}PASSED: Script is executable${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAILED: Script is not executable${NC}"
        echo -e "${YELLOW}Run: chmod +x $SCRIPT_DIR/detect-openclaw.sh${NC}"
        FAILED=$((FAILED + 1))
    fi
    echo
}

# Run tests
test_script_syntax
test_required_tools
test_permissions
test_negative_detection

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}\n"

total=$((PASSED + FAILED))
echo -e "Total Tests: $total"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}\n"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}\n"
    exit 1
fi
