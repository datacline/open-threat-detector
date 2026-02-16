# Deployment Guide

Detailed deployment instructions for OpenClaw Threat Detector across various MDM/EDR platforms.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Microsoft Intune](#microsoft-intune)
- [Jamf Pro](#jamf-pro)
- [Kandji](#kandji)
- [JumpCloud](#jumpcloud)
- [CrowdStrike Falcon](#crowdstrike-falcon)
- [VMware Workspace ONE](#vmware-workspace-one)
- [Custom Deployment](#custom-deployment)
- [Compliance Reporting](#compliance-reporting)

## Prerequisites

### General Requirements

- Administrative access to MDM/EDR platform
- Target devices must be enrolled and managed
- Network connectivity between MDM and endpoints
- Appropriate licensing for script deployment features

### Platform-Specific Requirements

**Windows:**
- PowerShell 5.1 or higher
- Execution policy allows script execution
- Administrator privileges for system-wide checks

**macOS:**
- macOS 10.14 or higher
- Bash 3.2+ or Zsh
- Appropriate permissions for system checks

**Linux:**
- Bash 4.0+
- Standard utilities: grep, awk, ps, lsof/netstat
- Root or sudo access for system-wide checks

## Microsoft Intune

### Step 1: Prepare the Script

1. Download `Detect-OpenClaw.ps1` from the repository
2. Review and customize detection parameters if needed
3. Test locally on a Windows device

### Step 2: Upload to Intune

1. Sign in to [Microsoft Endpoint Manager admin center](https://endpoint.microsoft.com)
2. Navigate to **Devices** > **Scripts and remediations** > **Platform scripts**
3. Click **+ Add** > **Windows 10 and later**
4. Configure basic settings:
   - **Name**: OpenClaw Detection Script
   - **Description**: Detects unauthorized OpenClaw installations
   - **Publisher**: Your Organization

### Step 3: Configure Script Settings

1. Upload `Detect-OpenClaw.ps1`
2. Configure settings:
   - **Run this script using the logged-on credentials**: No
   - **Enforce script signature check**: No (unless you've signed the script)
   - **Run script in 64-bit PowerShell**: Yes

### Step 4: Assign to Device Groups

1. Click **Next** to Assignments
2. Select target device groups:
   - All devices
   - Specific security groups
   - Dynamic device groups
3. Set schedule:
   - Frequency: Daily or Weekly
   - Time window: Off-peak hours recommended

### Step 5: Monitor Results

1. Navigate to **Devices** > **Monitor** > **Device script status**
2. View execution results:
   - **Success (Exit 0)**: Compliant - No OpenClaw detected
   - **Failed (Exit 1)**: Non-Compliant - OpenClaw detected
   - **Error (Exit 2)**: Execution error
3. Export reports for compliance auditing

### Step 6: Create Compliance Policy (Optional)

1. Navigate to **Devices** > **Compliance policies**
2. Create new policy for Windows 10 and later
3. Add custom compliance settings based on script results
4. Configure actions for noncompliance:
   - Email notifications
   - Device restrictions
   - Mark device as non-compliant

## Jamf Pro

### Step 1: Upload Script

1. Log in to Jamf Pro console
2. Navigate to **Settings** > **Computer Management** > **Scripts**
3. Click **+ New**
4. Configure script:
   - **Display Name**: OpenClaw Detection Script
   - **Category**: Security
   - **Script Contents**: Paste contents of `detect-openclaw.sh`
   - **Parameter Labels**: Optional parameters for customization

### Step 2: Create Extension Attribute

1. Navigate to **Settings** > **Computer Management** > **Extension Attributes**
2. Click **+ New**
3. Configure:
   - **Display Name**: OpenClaw Detection Status
   - **Data Type**: String or Integer
   - **Inventory Display**: General
   - **Input Type**: Script
   - **Script**: Upload or paste `detect-openclaw.sh`

### Step 3: Create Policy

1. Navigate to **Computers** > **Policies**
2. Click **+ New**
3. Configure policy:
   - **Display Name**: Run OpenClaw Detection
   - **Category**: Security
   - **Trigger**: Recurring Check-In
   - **Execution Frequency**: Once per day

4. Add script:
   - Go to **Scripts** section
   - Click **Configure**
   - Select "OpenClaw Detection Script"
   - Set priority order

5. Set scope:
   - **Targets**: Specific computer groups or All Managed Computers
   - **Exclusions**: Define if needed

### Step 4: Create Smart Group

1. Navigate to **Computers** > **Smart Computer Groups**
2. Click **+ New**
3. Configure:
   - **Display Name**: Computers with OpenClaw Detected
   - **Criteria**:
     - Extension Attribute: OpenClaw Detection Status
     - Operator: is
     - Value: 1 (or "Detected")

### Step 5: Setup Notifications

1. Configure policy to send notifications on detection
2. Options:
   - Email administrators
   - Create Jamf Pro alert
   - Trigger remediation workflow

### Step 6: Reporting

1. Navigate to **Reports**
2. Create advanced search:
   - Type: Computers
   - Criteria: OpenClaw Detection Status is 1
3. Schedule report delivery:
   - Daily/Weekly email reports
   - Export to CSV for compliance auditing

## Kandji

### Step 1: Create Custom Script

1. Log in to Kandji dashboard
2. Navigate to **Library** > **Custom Scripts**
3. Click **Add Custom Script**
4. Configure:
   - **Name**: OpenClaw Detection
   - **Category**: Security
   - **Script Type**: Audit Script
   - **Script**: Upload `detect-openclaw.sh`

### Step 2: Configure Execution Settings

1. **Execution Frequency**:
   - Run once per day
   - Run once per week
   - Run on-demand

2. **Conditions**:
   - Run on all devices
   - Run if specific conditions met

3. **Actions on Failure**:
   - Alert administrators
   - Create support ticket
   - Apply remediation script

### Step 3: Assign to Blueprint

1. Navigate to **Blueprints**
2. Select target Blueprint
3. Click **Add Library Item**
4. Select "OpenClaw Detection" script
5. Configure assignment rules:
   - All devices in Blueprint
   - Specific device families
   - Manual assignment

### Step 4: Monitor Results

1. Navigate to **Devices**
2. View audit script status:
   - Green: Compliant (Exit 0)
   - Red: Non-Compliant (Exit 1)
   - Yellow: Execution Error (Exit 2)

3. Filter devices by status
4. Export device lists for reporting

### Step 5: Create Device Group (Optional)

1. Navigate to **Devices** > **Device Groups**
2. Create smart group:
   - **Name**: Non-Compliant - OpenClaw Detected
   - **Criteria**: Audit Script "OpenClaw Detection" = Failed
3. Apply additional restrictions to this group

## JumpCloud

### Step 1: Create Command

1. Log in to JumpCloud Admin Portal
2. Navigate to **Commands**
3. Click **+** to create new command
4. Select command type:
   - Windows Command (PowerShell)
   - Mac Command (Bash)
   - Linux Command (Bash)

### Step 2: Configure Command

**For Windows:**
```powershell
# Paste contents of Detect-OpenClaw.ps1
# Or download from URL:
$scriptUrl = "https://your-repo/scripts/Detect-OpenClaw.ps1"
$scriptPath = "$env:TEMP\Detect-OpenClaw.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
& $scriptPath -Verbose
```

**For macOS/Linux:**
```bash
#!/bin/bash
# Download and execute detection script
curl -o /tmp/detect-openclaw.sh https://your-repo/scripts/detect-openclaw.sh
chmod +x /tmp/detect-openclaw.sh
/tmp/detect-openclaw.sh --verbose
```

### Step 3: Set Command Trigger

1. **Launch Type**:
   - trigger: Run on schedule
   - manual: Run on-demand from admin portal

2. **Schedule** (if triggered):
   - Cron expression for timing
   - Example: `0 2 * * *` (Daily at 2 AM)

### Step 4: Assign to Systems

1. In command configuration, go to **Systems** tab
2. Select target systems:
   - All systems
   - Specific systems
   - System groups
3. Save command

### Step 5: Monitor Results

1. Navigate to **Commands** > Command History
2. View execution results:
   - Exit code 0: Compliant
   - Exit code 1: Non-Compliant
   - Exit code 2: Error

3. Filter by:
   - Command name
   - Exit code
   - System name
   - Date range

4. Export results:
   - CSV export
   - API integration
   - SIEM forwarding

### Step 6: Create System Group (Optional)

1. Navigate to **System Groups**
2. Create group for non-compliant systems
3. Manually add systems based on command results
4. Apply policies to this group:
   - Additional monitoring
   - Access restrictions
   - Remediation commands

## CrowdStrike Falcon

### Step 1: Create RTR Script

1. Log in to Falcon console
2. Navigate to **Response** > **Real Time Response** > **Scripts**
3. Click **Create Script**
4. Configure:
   - **Name**: openclaw-detect
   - **Description**: Detects OpenClaw installations
   - **Platform**: Windows, Mac, or Linux
   - **Permission**: Read-only or Active Responder
   - **Script Content**: Upload detection script

### Step 2: Create Custom IOA (Indicator of Attack)

1. Navigate to **Configuration** > **Custom IOA Rules**
2. Click **Create Rule**
3. Configure detection logic:
   - Process execution: openclaw
   - File paths: ~/.openclaw/*
   - Network connections: port 50051, 8080, etc.

### Step 3: Deploy via RTR

**Manual Execution:**
```bash
# Connect to host
connect <hostname>

# Execute script
runscript -CloudFile="openclaw-detect"

# View results
# Exit code in command output
```

**Bulk Deployment:**
1. Navigate to **Host Management** > **Hosts**
2. Select multiple hosts
3. Click **Actions** > **Run RTR Script**
4. Select "openclaw-detect"
5. Execute and collect results

### Step 4: Automate via API

```python
import requests

# CrowdStrike API credentials
client_id = "YOUR_CLIENT_ID"
client_secret = "YOUR_CLIENT_SECRET"
base_url = "https://api.crowdstrike.com"

# Authenticate
auth_response = requests.post(
    f"{base_url}/oauth2/token",
    data={
        "client_id": client_id,
        "client_secret": client_secret
    }
)
token = auth_response.json()["access_token"]

# Execute script on hosts
headers = {"Authorization": f"Bearer {token}"}
script_payload = {
    "device_ids": ["device_id_1", "device_id_2"],
    "command_string": "runscript -CloudFile='openclaw-detect'"
}

response = requests.post(
    f"{base_url}/real-time-response/combined/batch-init-session/v1",
    headers=headers,
    json=script_payload
)

# Parse results
# Exit codes indicate compliance status
```

### Step 5: Create Detection Policy

1. Navigate to **Configuration** > **Prevention Policies**
2. Create new policy or modify existing
3. Add custom detection for OpenClaw artifacts
4. Configure prevention actions:
   - Alert only
   - Block execution
   - Quarantine

### Step 6: Reporting and Alerting

1. **Detection Dashboard**:
   - View OpenClaw detections
   - Filter by severity, host, time

2. **Create Custom Report**:
   - Navigate to **Investigate** > **Dashboard**
   - Create widget for OpenClaw detections
   - Schedule report delivery

3. **Configure Alerts**:
   - Navigate to **Configuration** > **Notifications**
   - Create workflow for OpenClaw detection
   - Route to SIEM, email, or ticketing system

## VMware Workspace ONE

### Step 1: Create Script Product

1. Log in to Workspace ONE UEM console
2. Navigate to **Resources** > **Apps & Books** > **Internal**
3. Click **Add Application**
4. Select **Script**

### Step 2: Configure Product

1. **General**:
   - **Name**: OpenClaw Detection Script
   - **Description**: Security compliance check
   - **Category**: Security

2. **Files**:
   - Upload appropriate script (Windows/Mac/Linux)
   - Set as detection script only

3. **Scripts**:
   - **Installation Script**: Not required
   - **Uninstall Script**: Not required
   - **Detection Script**: Upload detection script

4. **Detection Logic**:
   - Check exit code
   - Exit 0 = Installed (not applicable)
   - Exit 1 = Needs attention

### Step 3: Deployment Configuration

1. **Assignment**:
   - Select smart groups
   - Configure deployment type:
     - Auto: Automatic deployment
     - On-Demand: Manual installation

2. **Deployment Options**:
   - **Make App Managed**: Yes
   - **Push Mode**: Auto
   - **Desired State Management**: Enabled

3. **Schedule**:
   - Configure re-evaluation frequency
   - Daily or weekly checks

### Step 4: Create Smart Groups

1. Navigate to **Groups & Settings** > **Groups** > **Assignment Groups**
2. Click **Add Smart Group**
3. Configure criteria:
   - **Name**: Non-Compliant - OpenClaw Detected
   - **Criteria**:
     - Application: OpenClaw Detection Script
     - Status: Needs Attention

### Step 5: Compliance Policy

1. Navigate to **Devices** > **Compliance Policies**
2. Create new policy
3. Add rule:
   - **Type**: Application
   - **Application**: OpenClaw Detection Script
   - **Compliance**: Compliant if not installed
   - **Remediation**: Email, enterprise wipe, etc.

### Step 6: Reporting

1. **Dashboard**:
   - Navigate to **Monitor** > **Dashboard**
   - Add widget for OpenClaw Detection status

2. **Reports**:
   - Navigate to **Monitor** > **Reports**
   - Create custom report:
     - Application compliance
     - Filter: OpenClaw Detection Script
     - Group by: Compliance status

3. **Export**:
   - Schedule automated report delivery
   - Export to CSV/PDF
   - API integration for SIEM

## Custom Deployment

### Scheduled Task (Windows)

```powershell
# Create scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Detect-OpenClaw.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2am

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "OpenClaw Detection" `
    -Action $action -Trigger $trigger -Principal $principal
```

### Cron Job (macOS/Linux)

```bash
# Add to crontab
crontab -e

# Run daily at 2 AM
0 2 * * * /usr/local/bin/detect-openclaw.sh > /var/log/openclaw-detection.log 2>&1
```

### SystemD Service (Linux)

```ini
# /etc/systemd/system/openclaw-detection.service
[Unit]
Description=OpenClaw Detection Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/detect-openclaw.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/openclaw-detection.timer
[Unit]
Description=OpenClaw Detection Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
sudo systemctl enable openclaw-detection.timer
sudo systemctl start openclaw-detection.timer
```

## Compliance Reporting

### Report Structure

1. **Executive Summary**:
   - Total devices scanned
   - Compliant devices (%)
   - Non-compliant devices (%)
   - Execution errors

2. **Detailed Findings**:
   - Device hostname
   - Operating system
   - Detection timestamp
   - Specific findings (CLI, config, services, etc.)
   - Remediation status

3. **Trend Analysis**:
   - Week-over-week comparison
   - New installations detected
   - Remediated devices

### Sample SQL Query (for MDM database)

```sql
SELECT
    device_name,
    os_type,
    detection_date,
    exit_code,
    CASE
        WHEN exit_code = 0 THEN 'Compliant'
        WHEN exit_code = 1 THEN 'Non-Compliant'
        WHEN exit_code = 2 THEN 'Error'
    END AS compliance_status,
    detection_details
FROM
    script_execution_results
WHERE
    script_name = 'OpenClaw Detection'
    AND detection_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY
    exit_code DESC, device_name;
```

### Automated Reporting Script

```python
#!/usr/bin/env python3
"""
Generate OpenClaw Detection Compliance Report
"""
import csv
from datetime import datetime
from collections import Counter

def generate_report(results_file, output_file):
    """Generate compliance report from detection results"""

    with open(results_file, 'r') as f:
        reader = csv.DictReader(f)
        results = list(reader)

    # Calculate statistics
    total = len(results)
    compliant = sum(1 for r in results if r['exit_code'] == '0')
    non_compliant = sum(1 for r in results if r['exit_code'] == '1')
    errors = sum(1 for r in results if r['exit_code'] == '2')

    # Generate report
    report = f"""
    OpenClaw Detection Compliance Report
    Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

    Summary:
    ========
    Total Devices Scanned: {total}
    Compliant: {compliant} ({compliant/total*100:.1f}%)
    Non-Compliant: {non_compliant} ({non_compliant/total*100:.1f}%)
    Errors: {errors} ({errors/total*100:.1f}%)

    Non-Compliant Devices:
    ======================
    """

    for result in results:
        if result['exit_code'] == '1':
            report += f"\n{result['device_name']} - {result['os_type']}"
            report += f"\n  Detection Date: {result['detection_date']}"
            report += f"\n  Details: {result['detection_details']}\n"

    with open(output_file, 'w') as f:
        f.write(report)

    print(f"Report generated: {output_file}")

if __name__ == "__main__":
    generate_report('detection_results.csv', 'compliance_report.txt')
```

## Best Practices

1. **Testing**:
   - Test scripts on sample devices before mass deployment
   - Verify exit codes and output format
   - Test on all OS versions in your environment

2. **Scheduling**:
   - Run during off-peak hours
   - Consider time zones for global deployments
   - Balance detection frequency with system load

3. **Notifications**:
   - Configure alerts for new detections
   - Set up escalation procedures
   - Define response workflows

4. **Documentation**:
   - Maintain deployment documentation
   - Document customizations
   - Track versions and changes

5. **Security**:
   - Store scripts in secure, centralized location
   - Use signed scripts when possible
   - Restrict script modification access
   - Log all executions for audit trail

6. **Remediation**:
   - Define clear remediation procedures
   - Create removal scripts if needed
   - Track remediation completion
   - Verify successful removal

## Support

For deployment assistance:
- Review platform-specific documentation
- Contact your MDM/EDR vendor support
- Consult your security operations team
- Open GitHub issue for script-related questions
