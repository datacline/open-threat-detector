# Open Threat Detector

**Enterprise-grade detection scripts for shadow AI and unauthorized software installations**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](docs/CONTRIBUTING.md)

## Overview

Open Threat Detector is an open-source framework for detecting unauthorized AI tools and shadow IT installations across enterprise environments. Deploy via MDM/EDR platforms to maintain organizational compliance, security posture, and prevent data exfiltration through unmanaged AI services.

### What is Shadow AI?

Shadow AI refers to unauthorized AI tools and services used within organizations without IT department approval or oversight. These tools pose significant risks:

- **Data Leakage**: Sensitive data uploaded to uncontrolled AI services
- **Compliance Violations**: GDPR, HIPAA, SOC2 violations
- **IP Theft**: Proprietary code and information shared externally
- **Security Gaps**: Unvetted tools bypass security controls
- **Audit Failures**: Untracked AI usage creates compliance blind spots

## 🎯 Supported Detectors

| Tool | Status | Windows | macOS | Linux | Description |
|------|--------|---------|-------|-------|-------------|
| **[OpenClaw](detectors/openclaw/)** | ✅ Ready | ✅ | ✅ | ✅ | Detection of Unsecure AI assitant detection |

> Want to add a detector? See [Adding New Detectors](docs/adding-detectors.md)

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/open-threat-detector.git
cd open-threat-detector
```

### 2. Choose Your Detector

Navigate to the specific detector you want to deploy:

```bash
cd detectors/openclaw
```

### 3. Deploy Scripts

**Option A: Direct Execution**
```bash
# Unix/macOS/Linux
./unix/detect-openclaw.sh --verbose

# Windows (PowerShell)
.\windows\Detect-OpenClaw.ps1 -Verbose
```

**Option B: MDM Deployment**

See [Deployment Guide](docs/DEPLOYMENT.md) for platform-specific instructions:
- [Microsoft Intune](docs/deployment/intune.md)
- [Jamf Pro](docs/deployment/jamf.md)
- [Kandji](docs/deployment/kandji.md)
- [JumpCloud](docs/deployment/jumpcloud.md)
- [CrowdStrike Falcon](docs/deployment/crowdstrike.md)
- [VMware Workspace ONE](docs/deployment/workspace-one.md)

## 📋 Exit Codes

All detectors follow a standardized exit code convention:

- **0** = Software NOT detected (Compliant ✅)
- **1** = Software DETECTED (Non-Compliant ❌)
- **2** = Execution Error (Investigation Required ⚠️)

This standardization enables consistent reporting across all MDM/EDR platforms.

## 🏗️ Architecture

```
open-threat-detector/
├── detectors/              # Individual threat detectors
│   ├── openclaw/          # OpenClaw AI detection
│   ├── template/          # Template for new detectors
│   └── [future-tools]/    # Additional detectors
├── docs/                  # Documentation
│   ├── deployment/        # Platform-specific guides
│   ├── DEPLOYMENT.md      # General deployment guide
│   ├── CONTRIBUTING.md    # Contribution guidelines
│   └── adding-detectors.md # How to add new detectors
├── examples/              # Configuration examples
│   ├── mdm-configs/       # MDM platform configs
│   └── reporting/         # Reporting scripts
└── tools/                 # Common utilities
```

## 🔍 How It Works

Each detector performs comprehensive checks:

### Core Detection Checks
These checks determine compliance status (affect exit code):

1. **Binary/Executable Detection** - Searches system PATH and common install locations
2. **Configuration Files** - Identifies application settings and state files
3. **Active Services** - Detects running services and daemons
4. **Network Ports** - Probes for listening services on known ports
5. **Container Artifacts** - Scans Docker images and containers
6. **Registry Entries** (Windows) - Checks installation registry keys
7. **Application Bundles** (macOS) - Identifies .app bundles
8. **Package Managers** - Checks installed packages

### Supplementary Checks
Additional context (informational only):

- Active processes
- Environment variables
- Shell configuration files
- User-specific installations

## 📊 Deployment Integration

Deploy detectors via your existing infrastructure:

### MDM Platforms
- Microsoft Intune
- Jamf Pro
- Kandji
- JumpCloud
- VMware Workspace ONE

### EDR Platforms
- CrowdStrike Falcon
- SentinelOne
- Microsoft Defender
- Carbon Black

### Custom Deployment
- Scheduled Tasks (Windows)
- Cron Jobs (Linux/macOS)
- SystemD Services (Linux)
- CI/CD Pipelines

See [Deployment Documentation](docs/DEPLOYMENT.md) for detailed guides.

## 📈 Compliance Reporting

Generate compliance reports across your fleet:

```python
# Example: Generate compliance report
python examples/reporting/compliance-report.py \
  --input detection-results.csv \
  --output report.pdf \
  --format executive
```

Reports include:
- Executive summary with compliance percentages
- Detailed findings by device and detector
- Trend analysis and historical data
- Remediation recommendations

## 🛡️ Security & Privacy

- **Read-Only Operations**: Scripts only detect, never modify systems
- **No Data Transmission**: All processing happens locally
- **No Telemetry**: Scripts don't send data externally
- **Open Source**: Full transparency, audit the code yourself
- **Minimal Privileges**: Runs with standard user permissions
- **Safe at Scale**: Tested for enterprise deployment

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Add New Detectors**: Contribute detection scripts for additional AI tools
2. **Improve Existing Detectors**: Enhance detection accuracy and coverage
3. **Documentation**: Improve guides and documentation
4. **Platform Support**: Add MDM/EDR platform integrations
5. **Bug Fixes**: Report and fix issues

See [Contributing Guide](docs/CONTRIBUTING.md) for details.

### Adding a New Detector

We've made it easy to add new detectors:

1. Copy the template: `cp -r detectors/template detectors/your-tool`
2. Customize detection logic for your target software
3. Add tests and documentation
4. Submit a pull request

Full guide: [Adding New Detectors](docs/adding-detectors.md)

## 📚 Documentation

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Deploy scripts via MDM/EDR
- **[Contributing Guide](docs/CONTRIBUTING.md)** - Development guidelines
- **[Adding Detectors](docs/adding-detectors.md)** - Create new detectors
- **[Architecture](docs/architecture.md)** - System design and patterns

## 🎓 Use Cases

### Enterprise Security Teams
- Detect unauthorized AI tools across the organization
- Enforce acceptable use policies
- Maintain compliance with data protection regulations
- Prevent data exfiltration through unmanaged services

### IT Operations
- Track shadow IT adoption
- Manage software licenses and compliance
- Audit installed applications
- Generate compliance reports for stakeholders

### Compliance Officers
- Demonstrate control over AI tool usage
- Audit trail for regulatory requirements
- Risk assessment and mitigation
- Policy enforcement verification

## 📖 FAQ

**Q: Will these scripts remove detected software?**
A: No. Scripts are detection-only and read-only. They never modify or remove software.

**Q: Do scripts require admin/root privileges?**
A: Most checks work with standard user permissions. Some system-wide checks may require elevation.

**Q: How often should I run detection scripts?**
A: Daily or weekly scans are typical. Critical environments may run more frequently.

**Q: Can I customize detection logic?**
A: Yes! All scripts are open source and customizable. See each detector's README.

**Q: What data is collected?**
A: Only detection status (found/not found) and locations. No user data is collected.

**Q: How accurate are the detections?**
A: Detectors use multiple verification methods to minimize false positives/negatives.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Community contributors who add and maintain detectors
- Security researchers identifying shadow AI risks
- Enterprise IT teams providing real-world feedback

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/open-threat-detector/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/open-threat-detector/discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for reporting vulnerabilities


---

**Made with ❤️ by the security minded engineers**

*Protecting organizations from shadow AI risks through open-source detection*
