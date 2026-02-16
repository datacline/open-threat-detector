# Architecture

This document describes the architecture and design principles of the Open Threat Detector framework.

## Overview

Open Threat Detector is a modular framework for detecting unauthorized AI tools and shadow IT installations across enterprise environments. The architecture prioritizes:

- **Modularity**: Each detector is independent
- **Consistency**: Standardized exit codes and output formats
- **Simplicity**: Minimal dependencies, shell scripts only
- **Extensibility**: Easy to add new detectors
- **Deployability**: Compatible with major MDM/EDR platforms

## Design Principles

### 1. Detector Independence

Each detector operates independently:
- No shared runtime dependencies between detectors
- Each detector is self-contained
- Detectors can be deployed individually or collectively

### 2. Standardized Interface

All detectors follow the same interface:

**Exit Codes**:
- `0` = Not detected (compliant)
- `1` = Detected (non-compliant)
- `2` = Execution error

**Output Format**:
```
========================================
[TOOL] Detection Script - [PLATFORM]
========================================

Running Core Detection Checks...
--------------------------------
[TIMESTAMP] [LEVEL] Message

Running Supplementary Checks...
--------------------------------
[TIMESTAMP] [LEVEL] Message

========================================
Detection Summary
========================================
STATUS: [DETECTED/NOT DETECTED]
Exit Code: [0/1/2]

Core Detections:
  - Finding 1
  - Finding 2
```

### 3. Two-Tier Checking

**Core Checks** (affect exit code):
- Binary/executable detection
- Configuration file detection
- Service detection
- Registry detection (Windows)
- Application bundle detection (macOS)

**Supplementary Checks** (informational):
- Active processes
- Environment variables
- Shell RC files
- Package managers

### 4. Platform Abstraction

Platform-specific implementations:
- `windows/`: PowerShell scripts for Windows
- `unix/`: Bash scripts for macOS and Linux

Platform detection handled within scripts:
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS-specific logic
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux-specific logic
fi
```

## Directory Structure

```
open-threat-detector/
├── detectors/              # Individual threat detectors
│   ├── openclaw/          # Example: OpenClaw detector
│   │   ├── README.md      # Detector documentation
│   │   ├── windows/       # Windows PowerShell scripts
│   │   │   └── Detect-OpenClaw.ps1
│   │   ├── unix/          # Unix/Linux/macOS bash scripts
│   │   │   └── detect-openclaw.sh
│   │   └── tests/         # Detector-specific tests
│   │       └── test-detection.sh
│   └── template/          # Template for new detectors
│       ├── windows/
│       └── unix/
├── docs/                  # Documentation
│   ├── deployment/        # Platform-specific deployment guides
│   ├── DEPLOYMENT.md      # General deployment guide
│   ├── CONTRIBUTING.md    # Contribution guidelines
│   ├── adding-detectors.md # Guide for adding new detectors
│   └── architecture.md    # This file
├── examples/              # Configuration examples
│   ├── mdm-configs/       # MDM platform configurations
│   │   ├── intune/
│   │   ├── jamf/
│   │   ├── kandji/
│   │   └── jumpcloud/
│   └── reporting/         # Reporting scripts and examples
└── tools/                 # Common utilities
    ├── test-runner.sh     # Run all detector tests
    └── validate.sh        # Validate detector structure
```

## Component Design

### Detector Scripts

Each detector consists of:

1. **Header**:
   - Synopsis and description
   - Exit code documentation
   - Usage examples
   - Parameter documentation

2. **Initialization**:
   - Global state variables
   - Configuration parsing
   - OS detection

3. **Detection Functions**:
   - Core detection methods
   - Supplementary check methods
   - Helper utilities

4. **Main Execution**:
   - Orchestrate checks
   - Aggregate results
   - Format output
   - Return appropriate exit code

5. **Error Handling**:
   - Trap errors
   - Log failures
   - Return exit code 2

### Template System

The template system provides:

1. **Boilerplate Code**:
   - Standard structure
   - Common functions
   - Error handling
   - Logging utilities

2. **Placeholders**:
   - `[TOOL_NAME]`: Tool display name
   - `toolname`: Executable name
   - `ToolName`: Registry/config name

3. **Commented TODOs**:
   - Guide customization
   - Highlight required changes
   - Provide examples

### Testing Framework

Each detector includes:

1. **Syntax Validation**:
   - `bash -n` for shell scripts
   - PowerShell syntax checking

2. **Negative Tests**:
   - Verify clean system returns 0
   - No false positives

3. **Positive Tests**:
   - Create test artifacts
   - Verify detection returns 1
   - Clean up artifacts

4. **Cross-Platform Tests**:
   - Windows, macOS, Linux
   - Different OS versions

## Data Flow

```
┌─────────────────┐
│  MDM Platform   │
│   (Intune,      │
│   Jamf, etc.)   │
└────────┬────────┘
         │
         │ Schedule & Deploy
         │
         ▼
┌─────────────────┐
│  Target Device  │
└────────┬────────┘
         │
         │ Execute Detection Script
         │
         ▼
┌─────────────────────────────────┐
│  Detection Script               │
│  ┌──────────────────────────┐  │
│  │ 1. Initialize            │  │
│  │ 2. Run Core Checks       │  │
│  │ 3. Run Supplementary     │  │
│  │ 4. Aggregate Results     │  │
│  │ 5. Generate Report       │  │
│  │ 6. Return Exit Code      │  │
│  └──────────────────────────┘  │
└────────┬────────────────────────┘
         │
         │ Exit Code (0/1/2)
         │ Output Log
         │
         ▼
┌─────────────────┐
│  MDM Platform   │
│  (Collect       │
│   Results)      │
└────────┬────────┘
         │
         │ Aggregate Fleet-Wide
         │
         ▼
┌─────────────────┐
│  Compliance     │
│  Dashboard      │
└─────────────────┘
```

## Detection Strategy

### Multi-Layered Approach

Detectors use multiple verification methods to reduce false positives/negatives:

1. **Executable Detection**:
   - PATH search
   - Common install locations
   - Platform-specific directories

2. **State Detection**:
   - Configuration directories
   - User data directories
   - System data directories

3. **Service Detection**:
   - Windows Services
   - macOS launchd
   - Linux systemd

4. **Registry Detection** (Windows):
   - Installation keys
   - Uninstall entries
   - 32-bit/64-bit locations

5. **Network Detection**:
   - Listening ports
   - Active connections
   - Configuration-derived ports

6. **Container Detection**:
   - Docker images
   - Running containers
   - Container configuration

### Confidence Levels

Detection confidence based on number of positive checks:

- **High Confidence**: 3+ core checks positive
- **Medium Confidence**: 2 core checks positive
- **Low Confidence**: 1 core check positive

All confidence levels result in exit code 1, but detailed output shows evidence level.

## Integration Points

### MDM/EDR Platforms

Integration via standard mechanisms:

**Microsoft Intune**:
- Platform Scripts
- Detection and Remediation
- Compliance Policies

**Jamf Pro**:
- Scripts
- Extension Attributes
- Policies
- Smart Groups

**Kandji**:
- Custom Scripts
- Audit Scripts
- Blueprints

**JumpCloud**:
- Commands
- Triggers
- System Groups

**CrowdStrike Falcon**:
- Real Time Response Scripts
- Custom IOAs
- API Integration

### Reporting Systems

Output can be integrated with:

- SIEM platforms (Splunk, ELK, etc.)
- Ticketing systems (Jira, ServiceNow)
- Dashboards (Grafana, Kibana)
- Compliance tools (Vanta, Drata)

### CI/CD Pipelines

Detection scripts can run in:

- GitHub Actions
- GitLab CI
- Jenkins
- Azure DevOps
- CircleCI

## Security Architecture

### Read-Only Design

Scripts never modify the system:
- No file writes (except logs)
- No deletions
- No configuration changes
- No software removal

### Privilege Model

**Minimal Privileges**:
- Most checks: standard user
- Optional: elevated for system-wide checks
- Never require root/admin by default

**Privilege Escalation**:
- Documented when needed
- Optional, not required
- Alternative methods provided

### Data Privacy

**No External Communication**:
- Scripts don't phone home
- No telemetry collected
- All processing local

**Minimal Data Collection**:
- Detection status only
- File paths (not contents)
- Service names (not configs)

## Performance Considerations

### Execution Time

Target execution times:
- Simple detectors: < 5 seconds
- Complex detectors: < 30 seconds
- Network checks: < 10 seconds

### Resource Usage

Minimal resource footprint:
- CPU: < 5% sustained
- Memory: < 50MB
- Disk I/O: Read-only, minimal
- Network: Optional, probe only

### Optimization Strategies

1. **Early Exit**:
   - Return 1 as soon as detected
   - Don't run all checks if unnecessary

2. **Parallel Checks**:
   - Independent checks can run concurrently
   - Platform-dependent implementation

3. **Caching**:
   - Cache `command -v` results
   - Reuse path expansions

4. **Conditional Checks**:
   - Skip inapplicable checks
   - Platform-specific execution

## Future Architecture

### Planned Enhancements

1. **Centralized Reporting**:
   - Aggregation service
   - Fleet-wide dashboard
   - Historical trending

2. **API Integration**:
   - RESTful API for detectors
   - Webhook notifications
   - External integrations

3. **Configuration Management**:
   - Central config distribution
   - Custom detection rules
   - Whitelisting/exceptions

4. **Automated Remediation**:
   - Optional removal scripts
   - Remediation workflows
   - Approval processes

### Extensibility Points

1. **Custom Detectors**:
   - Community contributions
   - Organization-specific tools
   - Regional/industry tools

2. **Plugin System**:
   - Pre/post-detection hooks
   - Custom output formatters
   - Integration adapters

3. **Rule Engine**:
   - Custom detection logic
   - Composite detectors
   - Complex conditions

## Conventions

### Naming

- Detector directories: lowercase with hyphens (e.g., `github-copilot`)
- Scripts: Platform-specific casing
  - Windows: `Detect-ToolName.ps1` (PascalCase)
  - Unix: `detect-toolname.sh` (lowercase)
- Functions: Verb-noun pattern
  - PowerShell: `Test-Configuration`
  - Bash: `check_configuration`

### Versioning

Semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New detectors or features
- PATCH: Bug fixes and improvements

### Documentation

Required documentation:
- Detector README.md
- Code comments for complex logic
- Usage examples
- Testing instructions

## Contributing to Architecture

Architecture changes should:

1. Maintain backward compatibility
2. Follow established patterns
3. Be documented thoroughly
4. Include migration guides
5. Be discussed in GitHub Discussions

For significant changes:
1. Open RFC (Request for Comments)
2. Gather community feedback
3. Create detailed design doc
4. Implement with tests
5. Update all documentation

## References

- [Adding New Detectors](adding-detectors.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Security Policy](../SECURITY.md)
