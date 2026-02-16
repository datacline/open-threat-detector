# Detector Template

This directory contains templates for creating new shadow AI detection scripts.

## Quick Start

1. **Copy this template**:
   ```bash
   cp -r detectors/template detectors/your-tool-name
   ```

2. **Rename scripts**:
   ```bash
   cd detectors/your-tool-name/windows
   mv Detect-Template.ps1 Detect-YourTool.ps1

   cd ../unix
   mv detect-template.sh detect-yourtool.sh
   ```

3. **Customize detection logic**:
   - Open both scripts in your editor
   - Search for `[TOOL_NAME]` and replace with your tool's display name
   - Search for `toolname` and replace with the actual executable name
   - Search for `TODO:` comments and implement tool-specific logic

4. **Update this README**:
   - Document your tool's detection methods
   - Add usage instructions
   - Include testing procedures

## What to Customize

### In PowerShell Script (windows/Detect-Template.ps1)

1. **Header Documentation**:
   - Update `.SYNOPSIS` and `.DESCRIPTION`
   - Add tool-specific notes

2. **Detection Functions**:
   - `Test-CLIExecutable`: Add tool's executable names and paths
   - `Test-StateDirectory`: Add tool's config/state directories
   - `Get-ToolVersion`: Update version command
   - `Test-ConfigurationFiles`: Add config file paths
   - `Test-WindowsService`: Add service name patterns
   - `Test-RegistryEntries`: Add registry key paths

3. **Supplementary Functions**:
   - `Test-ActiveProcesses`: Add process name patterns
   - `Test-EnvironmentVariables`: Add env var patterns

### In Bash Script (unix/detect-template.sh)

1. **Header Comments**:
   - Update script description
   - Add tool-specific usage notes

2. **Detection Functions**:
   - `check_cli_executable`: Add executable names and paths
   - `check_state_directory`: Add state directory paths
   - `get_tool_version`: Update version command
   - `check_configuration_files`: Add config file paths
   - `check_service_macos`: Add launchd plist patterns
   - `check_service_linux`: Add systemd service names

3. **Supplementary Functions**:
   - `check_active_processes`: Add process name patterns
   - `check_environment_variables`: Add env var patterns

## Required Changes Checklist

- [ ] Renamed PowerShell script
- [ ] Renamed Bash script
- [ ] Replaced all `[TOOL_NAME]` placeholders
- [ ] Replaced all `toolname` executable references
- [ ] Updated CLI executable paths
- [ ] Updated state directory paths
- [ ] Updated configuration file paths
- [ ] Updated service/daemon names
- [ ] Updated registry keys (Windows)
- [ ] Updated process names
- [ ] Updated environment variable patterns
- [ ] Made bash script executable (`chmod +x`)
- [ ] Created custom README.md
- [ ] Added tests directory with test scripts
- [ ] Validated with `tools/validate.sh`

## Testing Your Detector

1. **Validate structure**:
   ```bash
   ../../tools/validate.sh
   ```

2. **Test manually**:
   ```bash
   # Windows
   .\windows\Detect-YourTool.ps1 -Verbose

   # Unix/macOS/Linux
   ./unix/detect-yourtool.sh --verbose
   ```

3. **Create test suite**:
   ```bash
   mkdir tests
   # Create test-detection.sh based on openclaw example
   ```

## Documentation

See the [Adding New Detectors Guide](../../docs/adding-detectors.md) for comprehensive instructions.

## Examples

Look at existing detectors for reference:
- [OpenClaw Detector](../openclaw/) - Full example implementation

## Need Help?

- Review [Adding Detectors Guide](../../docs/adding-detectors.md)
- Check [Architecture Documentation](../../docs/architecture.md)
- Open a GitHub Discussion for questions
- Look at OpenClaw detector as reference implementation
