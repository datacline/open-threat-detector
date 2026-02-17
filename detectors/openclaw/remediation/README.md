# OpenClaw Remediation Scripts

**⚠️ WARNING: These scripts permanently remove software and data. Use with extreme caution.**

## Overview

Remediation scripts provide automated removal of detected OpenClaw installations. These scripts are **separate from detection** and should only be used when:

1. Removal is authorized by IT security policy
2. User has been notified and given opportunity to backup data
3. Removal is part of an approved compliance remediation workflow

## Exit Codes

- **0** = Successfully remediated (OpenClaw removed)
- **1** = Remediation failed or user cancelled
- **2** = Execution error

## Safety Features

### 1. Confirmation Required

Scripts require explicit confirmation before removal:
- Interactive mode asks user to type 'REMOVE'
- Prevents accidental execution
- Can be bypassed with `--force` for automation

### 2. Automatic Backups

Before removal, scripts create backups:
- **Default location**: `/tmp/openclaw-backup-{timestamp}` (Unix) or `%TEMP%\openclaw-backup-{timestamp}` (Windows)
- **Custom location**: Use `--backup-path` parameter
- **Skip backup**: Use `--skip-backup` (not recommended)

**Backed up items:**
- Configuration directories
- State files
- Service definitions (launchd/systemd)
- Registry keys (Windows)

### 3. Detailed Logging

All actions are logged with timestamps:
- What was removed
- Any errors encountered
- Backup location
- Summary of operations

### 4. Graceful Error Handling

- Continues removal even if some steps fail
- Reports errors at the end
- Non-zero exit code if errors occurred

## Usage

### Windows (PowerShell)

**Interactive removal with confirmation:**
```powershell
.\Remove-OpenClaw.ps1
```

**Automated removal (no prompts):**
```powershell
.\Remove-OpenClaw.ps1 -Force
```

**Custom backup location:**
```powershell
.\Remove-OpenClaw.ps1 -BackupPath "C:\Backups\openclaw"
```

**Skip backup (not recommended):**
```powershell
.\Remove-OpenClaw.ps1 -SkipBackup
```

**Check exit code:**
```powershell
.\Remove-OpenClaw.ps1
echo $LASTEXITCODE
```

### macOS/Linux (Bash)

**Interactive removal with confirmation:**
```bash
./remove-openclaw.sh
```

**Automated removal (no prompts):**
```bash
./remove-openclaw.sh --force
```

**Custom backup location:**
```bash
./remove-openclaw.sh --backup-path /backup/openclaw
```

**Skip backup (not recommended):**
```bash
./remove-openclaw.sh --skip-backup
```

**Check exit code:**
```bash
./remove-openclaw.sh
echo $?
```

## What Gets Removed

### All Platforms

1. **Executables**
   - CLI binaries
   - Application files
   - Helper tools

2. **Configuration**
   - User configuration files
   - System configuration files
   - State directories

3. **Services**
   - Windows Services
   - macOS launchd agents/daemons
   - Linux systemd units

4. **Docker Artifacts**
   - OpenClaw Docker images
   - Running containers
   - Stopped containers

5. **Environment Variables**
   - OPENCLAW_* variables
   - PATH cleanup

### Windows-Specific

6. **Registry Entries**
   - Installation keys
   - Uninstall entries
   - 32-bit and 64-bit locations

### macOS-Specific

7. **Application Bundles**
   - `/Applications/OpenClaw.app`
   - User Applications

8. **Shell Configuration**
   - Cleanup from `.bashrc`, `.zshrc`

### Linux-Specific

9. **Package Manager Installations**
   - APT (Debian/Ubuntu)
   - RPM (RedHat/CentOS)
   - Snap packages

## MDM/EDR Deployment

### Microsoft Intune

Deploy as remediation script:

1. **Create Remediation Package**:
   - Detection: Use existing `Detect-OpenClaw.ps1`
   - Remediation: Upload `Remove-OpenClaw.ps1`
   - Run as: System
   - Enforce signature: No

2. **Configure Settings**:
   ```powershell
   # Add -Force parameter for automated remediation
   .\Remove-OpenClaw.ps1 -Force
   ```

3. **Schedule**:
   - Run after detection
   - Frequency: Daily (until compliant)

### Jamf Pro

Deploy as policy script:

1. **Upload Script**:
   - Upload `remove-openclaw.sh`
   - Set parameters: `--force`

2. **Create Policy**:
   - Trigger: When detection EA shows "Detected"
   - Scope: Smart Group (Non-Compliant devices)

3. **Notifications**:
   - Notify user before removal
   - Provide backup instructions

### Kandji

Deploy as remediation audit script:

1. **Create Remediation Script**:
   - Upload `remove-openclaw.sh`
   - Set as remediation for detection audit

2. **Configure**:
   - Run with `--force` flag
   - Auto-remediate: Optional

### JumpCloud

Deploy as command:

1. **Create Remediation Command**:
   ```bash
   # Download and run remediation
   curl -o /tmp/remove-openclaw.sh https://your-repo/remove-openclaw.sh
   chmod +x /tmp/remove-openclaw.sh
   /tmp/remove-openclaw.sh --force
   ```

2. **Trigger**:
   - Manual trigger
   - Or automated after detection

## Best Practices

### 1. Test in Non-Production First

```bash
# Create test VM or container
# Install OpenClaw
# Run remediation script
# Verify complete removal
# Document any issues
```

### 2. Notify Users

Before automated remediation:
- Send email notification
- Provide deadline for manual removal
- Offer to backup user data
- Explain compliance requirements

### 3. Staged Rollout

1. **Phase 1**: Run detection only (gather data)
2. **Phase 2**: Manual remediation for high-priority systems
3. **Phase 3**: Automated remediation for remaining systems

### 4. Monitor and Report

- Track remediation success rate
- Document failures
- Follow up on persistent installations
- Generate compliance reports

### 5. Backup Strategy

```bash
# Always create backups
./remove-openclaw.sh --backup-path /network/backups/openclaw

# Keep backups for retention period
# Archive to long-term storage
# Document backup locations
```

### 6. Verify Removal

After remediation, run detection again:

```bash
# Windows
.\Detect-OpenClaw.ps1 -Verbose
# Should return exit code 0

# Unix
./detect-openclaw.sh --verbose
# Should return exit code 0
```

## Rollback Procedure

If removal was unintended:

### Windows

```powershell
# Locate backup
$backupPath = "$env:TEMP\openclaw-backup-*"

# Restore configuration
Copy-Item "$backupPath\.openclaw" "$env:USERPROFILE\" -Recurse

# Import registry
$regFiles = Get-ChildItem "$backupPath\*.reg"
foreach ($file in $regFiles) {
    reg import $file.FullName
}
```

### macOS/Linux

```bash
# Locate backup
backup_dir="/tmp/openclaw-backup-*"

# Restore configuration
cp -R $backup_dir/.openclaw $HOME/

# Restore launchd plists (macOS)
cp $backup_dir/launchd/*.plist ~/Library/LaunchAgents/

# Restore systemd units (Linux)
sudo cp $backup_dir/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
```

**Note**: Executables are not backed up, only configuration. Reinstall OpenClaw software to fully restore.

## Troubleshooting

### Permission Errors

**Windows:**
```powershell
# Run as Administrator
Start-Process powershell -Verb RunAs -ArgumentList "-File Remove-OpenClaw.ps1 -Force"
```

**macOS/Linux:**
```bash
# Use sudo for system-wide removal
sudo ./remove-openclaw.sh --force
```

### Backup Fails

```bash
# Check disk space
df -h  # Unix
Get-PSDrive  # PowerShell

# Use custom backup location
./remove-openclaw.sh --backup-path /path/with/space
```

### Service Won't Stop

**Windows:**
```powershell
# Force stop service
Stop-Service -Name "OpenClawService" -Force

# Kill process if needed
Get-Process | Where-Object {$_.Name -like "*openclaw*"} | Stop-Process -Force
```

**macOS/Linux:**
```bash
# Force unload launchd (macOS)
launchctl remove com.openclaw.service

# Kill processes
pkill -9 openclaw
```

### Partial Removal

If script exits with errors:

1. Review log output
2. Note what failed to remove
3. Manually remove remaining items
4. Re-run detection to verify

## Security Considerations

### Authorization Required

Only run remediation scripts when:
- ✅ Authorized by IT security policy
- ✅ Part of approved compliance program
- ✅ User has been notified
- ✅ Documented in change management system

### Audit Trail

Maintain records:
- When remediation was performed
- Which systems were remediated
- Who authorized the action
- Backup locations
- Any errors encountered

### User Data Protection

Before automated remediation:
- Review what data will be removed
- Ensure users have opportunity to backup
- Verify no business-critical data affected
- Document retention policy for backups

## Legal and Compliance

### Before Deployment

- Review with legal team
- Ensure compliance with:
  - Company acceptable use policy
  - Employment agreements
  - Data protection regulations
  - Industry-specific requirements

### User Notice

Provide clear notice:
- What will be removed
- Why it's being removed
- Timeline for remediation
- How to backup personal data
- Who to contact with questions

### Documentation

Maintain records for:
- Compliance audits
- Legal inquiries
- User disputes
- Process improvement

## Support

### Getting Help

- **Script errors**: Review verbose output
- **Permission issues**: Run with appropriate privileges
- **MDM integration**: Consult MDM documentation
- **Questions**: Open GitHub Discussion

### Reporting Issues

If remediation fails:
1. Run with verbose output
2. Save complete log
3. Note OS version and environment
4. Open GitHub issue with details

## Version History

### v1.0.0 (2026-02-16)
- Initial release
- Windows PowerShell remediation script
- macOS/Linux bash remediation script
- Automatic backup functionality
- Interactive confirmation
- Comprehensive logging

## License

MIT License - See [LICENSE](../../../LICENSE) for details

---

**Remember**: Remediation is destructive. Always backup, always test, always authorize.
