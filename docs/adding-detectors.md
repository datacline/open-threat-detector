# Adding New Detectors

This guide explains how to add detection scripts for new shadow AI tools to the Open Threat Detector framework.

## Table of Contents

- [Quick Start](#quick-start)
- [Template Structure](#template-structure)
- [Step-by-Step Guide](#step-by-step-guide)
- [Detection Best Practices](#detection-best-practices)
- [Testing Your Detector](#testing-your-detector)
- [Submitting Your Detector](#submitting-your-detector)

## Quick Start

1. **Copy the template**:
   ```bash
   cp -r detectors/template detectors/your-tool-name
   cd detectors/your-tool-name
   ```

2. **Customize the scripts**:
   - Edit `windows/Detect-Template.ps1`
   - Edit `unix/detect-template.sh`
   - Replace all `[TOOL_NAME]` placeholders
   - Update detection logic for your specific tool

3. **Create README**:
   - Copy and customize `detectors/openclaw/README.md`
   - Document tool-specific detection methods

4. **Add tests**:
   - Create `tests/` directory
   - Add test scripts

5. **Submit pull request**:
   - Test thoroughly
   - Update main README
   - Submit PR with documentation

## Template Structure

```
detectors/template/
├── README.md              # Template documentation
├── windows/
│   └── Detect-Template.ps1  # PowerShell template
└── unix/
    └── detect-template.sh   # Bash template
```

## Step-by-Step Guide

### Step 1: Research Your Target Tool

Before writing detection logic, understand how the tool is installed and configured:

1. **Installation methods**:
   - Package managers (npm, pip, brew, etc.)
   - Direct downloads
   - IDE extensions
   - Standalone applications

2. **File locations**:
   - Executable paths
   - Configuration directories
   - State/cache directories
   - Log locations

3. **System integration**:
   - Services/daemons
   - Registry entries (Windows)
   - Network ports
   - Environment variables

4. **Platform differences**:
   - Windows vs macOS vs Linux variations
   - Different installation paths per platform

### Step 2: Copy and Rename Template

```bash
# Choose a short, lowercase name for your detector
TOOL_NAME="github-copilot"

# Copy template
cp -r detectors/template detectors/$TOOL_NAME

# Navigate to new detector
cd detectors/$TOOL_NAME
```

### Step 3: Customize PowerShell Script (Windows)

Edit `windows/Detect-Template.ps1`:

1. **Update header**:
   ```powershell
   <#
   .SYNOPSIS
       Detects GitHub Copilot installations on Windows systems.
   #>
   ```

2. **Replace tool name**:
   - Find and replace `[TOOL_NAME]` with "GitHub Copilot"
   - Find and replace `ToolName` with "GitHubCopilot"
   - Find and replace `toolname` with actual executable name

3. **Update detection functions**:

   **CLI Executable**:
   ```powershell
   function Test-CLIExecutable {
       Write-DetectionLog "Checking for GitHub Copilot CLI executable..." -Level Info

       # Check for CLI in PATH
       $pathExe = Get-Command copilot -ErrorAction SilentlyContinue
       if ($pathExe) {
           Write-DetectionLog "DETECTED: GitHub Copilot CLI found in PATH: $($pathExe.Source)" -Level Found -AffectsExitCode $true
           $script:ToolDetected = $true
           return $true
       }

       # Common installation paths
       $commonPaths = @(
           "$env:ProgramFiles\GitHub Copilot\copilot.exe",
           "$env:LOCALAPPDATA\Programs\GitHub Copilot\copilot.exe",
           "$env:APPDATA\npm\copilot.cmd"
       )

       foreach ($path in $commonPaths) {
           if (Test-Path $path) {
               Write-DetectionLog "DETECTED: GitHub Copilot CLI found at: $path" -Level Found -AffectsExitCode $true
               $script:ToolDetected = $true
               return $true
           }
       }

       Write-DetectionLog "GitHub Copilot CLI executable not found" -Level Info
       return $false
   }
   ```

   **State Directories**:
   ```powershell
   function Test-StateDirectory {
       Write-DetectionLog "Checking for GitHub Copilot state directory..." -Level Info

       $statePaths = @(
           "$env:USERPROFILE\.github-copilot",
           "$env:APPDATA\GitHub Copilot",
           "$env:LOCALAPPDATA\GitHub\Copilot"
       )

       foreach ($path in $statePaths) {
           if (Test-Path $path) {
               $itemCount = (Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Measure-Object).Count
               Write-DetectionLog "DETECTED: GitHub Copilot state directory found: $path ($itemCount items)" -Level Found -AffectsExitCode $true
               $script:ToolDetected = $true
               return $true
           }
       }

       Write-DetectionLog "GitHub Copilot state directory not found" -Level Info
       return $false
   }
   ```

4. **Add tool-specific checks**:
   - IDE extensions (VS Code, Visual Studio, JetBrains)
   - Browser extensions
   - Application-specific directories

### Step 4: Customize Bash Script (Unix/macOS/Linux)

Edit `unix/detect-template.sh`:

1. **Update header**:
   ```bash
   # GitHub Copilot Detection Script
   # Platform: macOS & Linux
   ```

2. **Replace tool name**:
   - Find and replace `[TOOL_NAME]` with "GitHub Copilot"
   - Find and replace `toolname` with actual executable name

3. **Update detection functions**:

   **CLI Executable**:
   ```bash
   check_cli_executable() {
       log_message "INFO" "Checking for GitHub Copilot CLI executable..."

       # Check PATH
       if command -v copilot &> /dev/null; then
           local cli_path
           cli_path=$(command -v copilot)
           log_message "FOUND" "DETECTED: GitHub Copilot CLI found in PATH: $cli_path" "true"
           TOOL_DETECTED=true
           return 0
       fi

       # Common installation locations
       local common_paths=(
           "/usr/local/bin/copilot"
           "/usr/bin/copilot"
           "$HOME/.local/bin/copilot"
           "/opt/github-copilot/bin/copilot"
       )

       for path in "${common_paths[@]}"; do
           if [[ -f "$path" ]] && [[ -x "$path" ]]; then
               log_message "FOUND" "DETECTED: GitHub Copilot CLI found at: $path" "true"
               TOOL_DETECTED=true
               return 0
           fi
       done

       log_message "INFO" "GitHub Copilot CLI executable not found"
       return 1
   }
   ```

### Step 5: Create Detector README

Create `README.md` in your detector directory:

```markdown
# [Tool Name] Detector

Brief description of the tool and why detection is important.

## Detection Methods

### Core Checks
1. CLI Executable Detection
2. State Directory Detection
...

### Supplementary Checks
- Active processes
...

## Platform Support

| Platform | Status |
|----------|--------|
| Windows 10/11 | ✅ |
| macOS 10.14+ | ✅ |
| Linux (Ubuntu/Debian) | ✅ |

## Usage

[Usage instructions]

## Testing

[Testing instructions]
```

### Step 6: Add Tests

Create `tests/test-detection.sh`:

```bash
#!/usr/bin/env bash

# Test script for [Tool Name] Detection

# Test 1: Syntax validation
test_syntax() {
    echo "Testing script syntax..."
    if bash -n ../unix/detect-toolname.sh; then
        echo "PASS: Syntax valid"
    else
        echo "FAIL: Syntax errors"
        exit 1
    fi
}

# Test 2: Negative detection (clean system)
test_negative_detection() {
    echo "Testing negative detection..."
    if ../unix/detect-toolname.sh > /dev/null 2>&1; then
        exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            echo "PASS: Correctly reported no detection"
        else
            echo "FAIL: Unexpected exit code: $exit_code"
            exit 1
        fi
    fi
}

# Run tests
test_syntax
test_negative_detection

echo "All tests passed!"
```

Make executable:
```bash
chmod +x tests/test-detection.sh
```

## Detection Best Practices

### 1. Multiple Verification Methods

Use multiple checks to reduce false positives:

```bash
# Not just executable
check_cli_executable

# Also check for state
check_state_directory

# And configuration
check_configuration_files

# Services too
check_service
```

### 2. Platform-Specific Paths

Account for different installation locations per platform:

**Windows**:
- `%ProgramFiles%`
- `%LOCALAPPDATA%`
- `%APPDATA%`
- User profile directories

**macOS**:
- `/Applications`
- `~/Library/Application Support`
- `/usr/local/bin`
- Homebrew paths

**Linux**:
- `/usr/bin`, `/usr/local/bin`
- `/opt`
- `~/.local`
- Package manager locations

### 3. Version Detection

Always attempt to run version commands:

```bash
if command -v toolname &> /dev/null; then
    version=$(toolname --version 2>&1)
    log_message "FOUND" "Detected: $version" "true"
fi
```

### 4. Process Detection (Supplementary)

Check for running processes but make it supplementary only:

```bash
check_active_processes() {
    log_message "INFO" "[SUPPLEMENTARY] Checking for processes..."
    # Don't set TOOL_DETECTED=true here
    # This is informational only
}
```

### 5. Error Handling

Handle errors gracefully:

```bash
# Bash
set -euo pipefail
trap 'echo "ERROR"; exit 2' ERR

# PowerShell
try {
    # Detection logic
} catch {
    Write-Host "ERROR" -ForegroundColor Red
    exit 2
}
```

### 6. Minimal Dependencies

Keep dependencies minimal:
- Use built-in commands when possible
- Check for availability before using optional tools
- Provide fallbacks

### 7. Performance

Optimize for speed:
- Exit early when detected
- Avoid expensive operations when possible
- Cache results within the script

## Testing Your Detector

### Manual Testing

1. **Clean System Test**:
   ```bash
   # Should return 0 (not detected)
   ./unix/detect-toolname.sh
   echo $?
   ```

2. **Installed System Test**:
   - Install the target tool
   - Run detection script
   - Should return 1 (detected)

3. **Verbose Output Test**:
   ```bash
   ./unix/detect-toolname.sh --verbose
   ```
   - Review all checks
   - Verify logging is clear

4. **Cross-Platform Testing**:
   - Test on Windows
   - Test on macOS
   - Test on Linux (multiple distros if possible)

### Automated Testing

Run the test suite:

```bash
cd tests
./test-detection.sh
```

All tests should pass before submission.

## Submitting Your Detector

### Pre-Submission Checklist

- [ ] Scripts tested on all target platforms
- [ ] README.md created with full documentation
- [ ] Test suite created and passing
- [ ] Code follows style guidelines
- [ ] No hardcoded personal information
- [ ] Exit codes follow standard (0/1/2)
- [ ] Logging is clear and informative
- [ ] Comments explain complex logic

### Update Main README

Add your detector to the main README.md table:

```markdown
| **[Your Tool](detectors/your-tool/)** | ✅ Ready | ✅ | ✅ | ✅ | Brief description |
```

### Create Pull Request

1. Fork the repository
2. Create feature branch:
   ```bash
   git checkout -b detector/your-tool-name
   ```

3. Commit changes:
   ```bash
   git add detectors/your-tool-name
   git commit -m "feat: add Your Tool detector

   - Windows PowerShell detection script
   - macOS/Linux bash detection script
   - Comprehensive detection methods
   - Test suite included"
   ```

4. Push and create PR:
   ```bash
   git push origin detector/your-tool-name
   ```

5. Fill out PR template completely

### PR Requirements

Your PR should include:

1. **Detector scripts**:
   - PowerShell script (Windows)
   - Bash script (Unix/macOS/Linux)

2. **Documentation**:
   - Detector README.md
   - Update to main README.md

3. **Tests**:
   - Test scripts
   - Test documentation

4. **Examples** (optional):
   - MDM configuration examples
   - Deployment guides

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Issues**: Report via GitHub Issues
- **Review**: Request early feedback on draft PRs

## Recognition

Contributors who add detectors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Recognized in project documentation

Thank you for contributing to Open Threat Detector!
