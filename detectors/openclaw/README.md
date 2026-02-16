# OpenClaw Detector

Comprehensive detection scripts for identifying OpenClaw AI coding assistant installations across Windows, macOS, and Linux systems.

## Overview

OpenClaw is an AI-powered coding assistant that poses potential risks in enterprise environments:
- Source code exposure to external AI services
- Intellectual property leakage
- Compliance violations (GDPR, HIPAA, SOC2)
- Unvetted third-party service integration

This detector identifies OpenClaw installations through multiple verification methods.

## Detection Methods

### Core Checks (Affect Exit Code)

1. **CLI Executable Detection**
   - Searches system PATH for `openclaw` binary
   - Checks common installation directories
   - Platform-specific executable locations

2. **State Directory Detection**
   - `~/.openclaw` (Unix/macOS)
   - `%USERPROFILE%\.openclaw` (Windows)
   - `/var/lib/openclaw` (Linux system-wide)

3. **Version Information**
   - Executes `openclaw --version`
   - Confirms active installation

4. **Configuration Files**
   - `config.yaml`, `config.json`, `settings.yaml`
   - User and system-wide config locations

5. **Gateway Service Detection**
   - Windows Services
   - macOS launchd agents/daemons
   - Linux systemd units and init.d scripts

6. **Gateway Port Detection**
   - Default ports: 50051, 8080, 8443, 9090
   - Custom ports from configuration files
   - Active listening services

7. **Docker Artifacts**
   - OpenClaw Docker images
   - Running and stopped containers

8. **Application Bundles** (macOS)
   - `/Applications/OpenClaw.app`
   - User-specific app directories

9. **Registry Entries** (Windows)
   - `HKLM\SOFTWARE\OpenClaw`
   - `HKLM\SOFTWARE\WOW6432Node\OpenClaw`
   - Uninstall registry entries

### Supplementary Checks (Informational)

- Active OpenClaw processes
- Environment variables (`OPENCLAW_*`)
- Shell RC files (`.bashrc`, `.zshrc`, etc.)
- Package managers (Homebrew, APT, RPM, Snap)
- WSL instances (Windows)

## Platform Support

| Platform | Script | Status |
|----------|--------|--------|
| Windows 10/11 | [Detect-OpenClaw.ps1](windows/Detect-OpenClaw.ps1) | ✅ Fully Supported |
| macOS 10.14+ | [detect-openclaw.sh](unix/detect-openclaw.sh) | ✅ Fully Supported |
| Linux (Ubuntu/Debian) | [detect-openclaw.sh](unix/detect-openclaw.sh) | ✅ Fully Supported |
| Linux (RHEL/CentOS) | [detect-openclaw.sh](unix/detect-openclaw.sh) | ✅ Fully Supported |

## Usage

### Windows (PowerShell)

```powershell
# Navigate to detector directory
cd detectors/openclaw/windows

# Standard execution
.\Detect-OpenClaw.ps1

# Verbose output
.\Detect-OpenClaw.ps1 -Verbose

# Check exit code
.\Detect-OpenClaw.ps1
echo $LASTEXITCODE
```

### macOS/Linux (Bash)

```bash
# Navigate to detector directory
cd detectors/openclaw/unix

# Make executable (first time only)
chmod +x detect-openclaw.sh

# Standard execution
./detect-openclaw.sh

# Verbose output
./detect-openclaw.sh --verbose

# Check exit code
./detect-openclaw.sh
echo $?
```

## Exit Codes

- **0** = OpenClaw NOT detected (Compliant ✅)
- **1** = OpenClaw DETECTED (Non-Compliant ❌)
- **2** = Execution Error (Investigation Required ⚠️)

## Sample Output

### Compliant System (No OpenClaw)

```
========================================
OpenClaw Detection Script - macos
========================================

Running Core Detection Checks...
--------------------------------

[2026-02-16 10:30:15] [INFO] Checking for OpenClaw CLI executable...
[2026-02-16 10:30:15] [INFO] OpenClaw CLI executable not found
[2026-02-16 10:30:15] [INFO] Checking for OpenClaw state directory...
[2026-02-16 10:30:15] [INFO] OpenClaw state directory not found
...

========================================
Detection Summary
========================================

STATUS: OpenClaw NOT DETECTED (Compliant)
Exit Code: 0
```

### Non-Compliant System (OpenClaw Found)

```
========================================
OpenClaw Detection Script - macos
========================================

Running Core Detection Checks...
--------------------------------

[2026-02-16 10:30:15] [INFO] Checking for OpenClaw CLI executable...
[2026-02-16 10:30:16] [FOUND] DETECTED: OpenClaw CLI found in PATH: /usr/local/bin/openclaw
[2026-02-16 10:30:16] [INFO] Checking for OpenClaw state directory...
[2026-02-16 10:30:16] [FOUND] DETECTED: OpenClaw state directory found: /Users/user/.openclaw (15 items)
[2026-02-16 10:30:16] [INFO] Checking for OpenClaw configuration files...
[2026-02-16 10:30:16] [FOUND] DETECTED: OpenClaw configuration file found: /Users/user/.openclaw/config.yaml
...

========================================
Detection Summary
========================================

STATUS: OpenClaw DETECTED (Non-Compliant)
Exit Code: 1

Core Detections:
  - DETECTED: OpenClaw CLI found in PATH: /usr/local/bin/openclaw
  - DETECTED: OpenClaw state directory found: /Users/user/.openclaw (15 items)
  - DETECTED: OpenClaw configuration file found: /Users/user/.openclaw/config.yaml
```

## Testing

Run the test suite to verify detection logic:

```bash
cd detectors/openclaw/tests
./test-detection.sh
```

The test script will:
1. Validate script syntax
2. Check required tools availability
3. Test positive detection (with test artifacts)
4. Test negative detection (clean system)
5. Verify file permissions

## Customization

### Add Custom Ports

Edit the port arrays in the scripts:

**PowerShell:**
```powershell
$portsToCheck = @(50051, 8080, 8443, 9090, YOUR_CUSTOM_PORT)
```

**Bash:**
```bash
local ports=(50051 8080 8443 9090 YOUR_CUSTOM_PORT)
```

### Add Custom Paths

Add organization-specific installation locations:

**PowerShell:**
```powershell
$commonPaths = @(
    "$env:ProgramFiles\OpenClaw\openclaw.exe",
    "C:\YourOrg\Tools\openclaw.exe"
)
```

**Bash:**
```bash
local common_paths=(
    "/usr/local/bin/openclaw"
    "/opt/your-org/openclaw"
)
```

## MDM Deployment

Deploy via your MDM/EDR platform. See platform-specific guides:

- [Microsoft Intune](../../docs/deployment/intune.md)
- [Jamf Pro](../../docs/deployment/jamf.md)
- [Kandji](../../docs/deployment/kandji.md)
- [JumpCloud](../../docs/deployment/jumpcloud.md)
- [CrowdStrike Falcon](../../docs/deployment/crowdstrike.md)
- [VMware Workspace ONE](../../docs/deployment/workspace-one.md)

## Troubleshooting

### Script Won't Execute

**Windows:**
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**macOS/Linux:**
```bash
# Make executable
chmod +x detect-openclaw.sh

# Verify
ls -l detect-openclaw.sh
```

### False Positives

If detection occurs but OpenClaw isn't installed:
1. Run with `--verbose` or `-Verbose` for details
2. Check detection log for specific findings
3. Investigate flagged paths manually
4. Report issue if bug suspected

### False Negatives

If OpenClaw is present but not detected:
1. Enable verbose mode
2. Verify OpenClaw installation location
3. Add custom paths to detection script
4. Report enhancement request

## Security Considerations

- Scripts are **read-only** and never modify systems
- No data transmitted externally
- Safe for automated deployment
- Minimal system resource usage
- Standard user permissions sufficient (elevated optional)

## Contributing

Improve OpenClaw detection:
1. Report false positives/negatives
2. Add new detection methods
3. Improve cross-platform compatibility
4. Enhance documentation

See [Contributing Guide](../../docs/CONTRIBUTING.md)

## Version History

### v1.0.0 (2026-02-16)
- Initial release
- Windows PowerShell detection script
- macOS/Linux bash detection script
- Core detection methods implemented
- Supplementary informational checks
- Test suite included

## License

MIT License - See [LICENSE](../../LICENSE) for details

## Support

- Report issues: [GitHub Issues](https://github.com/yourusername/open-threat-detector/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/open-threat-detector/discussions)
