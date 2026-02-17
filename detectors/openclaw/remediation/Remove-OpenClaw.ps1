<#
.SYNOPSIS
    Removes OpenClaw installations from Windows systems.

.DESCRIPTION
    Remediation script that removes OpenClaw software installations.

    IMPORTANT: This script REMOVES software and data. Use with caution.

    Actions performed:
    - Stops OpenClaw services
    - Removes OpenClaw executables
    - Removes configuration and state directories
    - Cleans up registry entries
    - Removes Docker images and containers
    - Removes environment variables

    Exit Codes:
    0 = Successfully remediated
    1 = Remediation failed or user cancelled
    2 = Execution error

.PARAMETER Force
    Skip confirmation prompts (for automated deployment)

.PARAMETER BackupPath
    Path to store backups before removal (default: $env:TEMP\openclaw-backup-{timestamp})

.PARAMETER SkipBackup
    Skip creating backups (not recommended)

.EXAMPLE
    .\Remove-OpenClaw.ps1
    Interactive removal with confirmation prompts

.EXAMPLE
    .\Remove-OpenClaw.ps1 -Force
    Automated removal without prompts (use with caution)

.EXAMPLE
    .\Remove-OpenClaw.ps1 -BackupPath "C:\Backups\openclaw"
    Remove with custom backup location

.NOTES
    **WARNING**: This script permanently removes OpenClaw and its data.
    Use only when authorized by IT security policies.
    Always test in non-production environment first.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [string]$BackupPath,
    [switch]$SkipBackup
)

# Initialize state
$script:RemovalLog = @()
$script:BackupCreated = $false
$script:ItemsRemoved = 0
$script:Errors = 0

function Write-RemovalLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message

    $script:RemovalLog += $logEntry

    switch ($Level) {
        'Error'   { Write-Host $logEntry -ForegroundColor Red }
        'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
        'Success' { Write-Host $logEntry -ForegroundColor Green }
        default   { Write-Host $logEntry }
    }
}

function Confirm-Removal {
    if ($Force) {
        return $true
    }

    Write-Host "`n" -NoNewline
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                    ⚠️  WARNING ⚠️                          ║" -ForegroundColor Red
    Write-Host "║                                                           ║" -ForegroundColor Red
    Write-Host "║  This will PERMANENTLY REMOVE OpenClaw and its data:     ║" -ForegroundColor Red
    Write-Host "║                                                           ║" -ForegroundColor Red
    Write-Host "║  • All OpenClaw executables                              ║" -ForegroundColor Red
    Write-Host "║  • Configuration files                                   ║" -ForegroundColor Red
    Write-Host "║  • User data and state                                   ║" -ForegroundColor Red
    Write-Host "║  • Services and registry entries                         ║" -ForegroundColor Red
    Write-Host "║  • Docker images and containers                          ║" -ForegroundColor Red
    Write-Host "║                                                           ║" -ForegroundColor Red
    Write-Host "║  This action CANNOT be undone (except from backup)       ║" -ForegroundColor Red
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    $confirmation = Read-Host "Type 'REMOVE' to confirm removal"
    return ($confirmation -eq 'REMOVE')
}

function New-Backup {
    if ($SkipBackup) {
        Write-RemovalLog "Skipping backup (SkipBackup flag set)" -Level Warning
        return $true
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = if ($BackupPath) { $BackupPath } else { "$env:TEMP\openclaw-backup-$timestamp" }

    try {
        Write-RemovalLog "Creating backup at: $backupDir" -Level Info
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

        # Backup configuration directories
        $configPaths = @(
            "$env:USERPROFILE\.openclaw",
            "$env:APPDATA\OpenClaw",
            "$env:LOCALAPPDATA\OpenClaw"
        )

        foreach ($path in $configPaths) {
            if (Test-Path $path) {
                $backupName = Split-Path $path -Leaf
                $dest = Join-Path $backupDir $backupName
                Write-RemovalLog "Backing up: $path -> $dest" -Level Info
                Copy-Item -Path $path -Destination $dest -Recurse -Force
            }
        }

        # Export registry keys
        $regKeys = @(
            "HKCU\SOFTWARE\OpenClaw",
            "HKLM\SOFTWARE\OpenClaw",
            "HKLM\SOFTWARE\WOW6432Node\OpenClaw"
        )

        foreach ($key in $regKeys) {
            if (Test-Path "Registry::$key") {
                $regFile = Join-Path $backupDir "registry-$(($key -replace '\\','-')).reg"
                Write-RemovalLog "Exporting registry: $key" -Level Info
                reg export $key $regFile /y 2>&1 | Out-Null
            }
        }

        $script:BackupCreated = $true
        Write-RemovalLog "Backup completed successfully: $backupDir" -Level Success
        Write-Host "`n💾 Backup location: $backupDir`n" -ForegroundColor Cyan
        return $true

    } catch {
        Write-RemovalLog "Backup failed: $_" -Level Error
        $script:Errors++
        return $false
    }
}

function Stop-OpenClawServices {
    Write-RemovalLog "Stopping OpenClaw services..." -Level Info

    $servicePatterns = @('*openclaw*', '*OpenClaw*')

    foreach ($pattern in $servicePatterns) {
        $services = Get-Service -Name $pattern -ErrorAction SilentlyContinue
        if ($services) {
            foreach ($service in $services) {
                try {
                    Write-RemovalLog "Stopping service: $($service.Name)" -Level Info
                    Stop-Service -Name $service.Name -Force -ErrorAction Stop
                    Set-Service -Name $service.Name -StartupType Disabled -ErrorAction Stop
                    Write-RemovalLog "Service stopped and disabled: $($service.Name)" -Level Success
                    $script:ItemsRemoved++
                } catch {
                    Write-RemovalLog "Failed to stop service $($service.Name): $_" -Level Error
                    $script:Errors++
                }
            }
        }
    }
}

function Remove-OpenClawExecutables {
    Write-RemovalLog "Removing OpenClaw executables..." -Level Info

    $executablePaths = @(
        "$env:ProgramFiles\OpenClaw",
        "${env:ProgramFiles(x86)}\OpenClaw",
        "$env:LOCALAPPDATA\OpenClaw",
        "$env:LOCALAPPDATA\Programs\OpenClaw",
        "$env:APPDATA\OpenClaw",
        "$env:USERPROFILE\.openclaw\bin"
    )

    foreach ($path in $executablePaths) {
        if (Test-Path $path) {
            try {
                Write-RemovalLog "Removing directory: $path" -Level Info
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                Write-RemovalLog "Removed: $path" -Level Success
                $script:ItemsRemoved++
            } catch {
                Write-RemovalLog "Failed to remove $path: $_" -Level Error
                $script:Errors++
            }
        }
    }

    # Remove from PATH if present
    try {
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($userPath -like "*openclaw*") {
            Write-RemovalLog "Cleaning OpenClaw from PATH" -Level Info
            $newPath = ($userPath -split ';' | Where-Object { $_ -notlike "*openclaw*" }) -join ';'
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            Write-RemovalLog "Cleaned PATH variable" -Level Success
        }
    } catch {
        Write-RemovalLog "Failed to clean PATH: $_" -Level Warning
    }
}

function Remove-OpenClawConfiguration {
    Write-RemovalLog "Removing OpenClaw configuration..." -Level Info

    $configPaths = @(
        "$env:USERPROFILE\.openclaw",
        "$env:APPDATA\OpenClaw",
        "$env:LOCALAPPDATA\OpenClaw"
    )

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            try {
                Write-RemovalLog "Removing configuration: $path" -Level Info
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                Write-RemovalLog "Removed: $path" -Level Success
                $script:ItemsRemoved++
            } catch {
                Write-RemovalLog "Failed to remove $path: $_" -Level Error
                $script:Errors++
            }
        }
    }
}

function Remove-OpenClawRegistry {
    Write-RemovalLog "Removing OpenClaw registry entries..." -Level Info

    $regPaths = @(
        "HKLM:\SOFTWARE\OpenClaw",
        "HKLM:\SOFTWARE\WOW6432Node\OpenClaw",
        "HKCU:\SOFTWARE\OpenClaw"
    )

    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            try {
                Write-RemovalLog "Removing registry key: $path" -Level Info
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                Write-RemovalLog "Removed: $path" -Level Success
                $script:ItemsRemoved++
            } catch {
                Write-RemovalLog "Failed to remove $path: $_" -Level Error
                $script:Errors++
            }
        }
    }

    # Remove uninstall entries
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        try {
            $uninstallKeys = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*OpenClaw*" }

            foreach ($key in $uninstallKeys) {
                $keyPath = $key.PSPath
                Write-RemovalLog "Removing uninstall entry: $($key.DisplayName)" -Level Info
                Remove-Item -Path $keyPath -Force -ErrorAction Stop
                $script:ItemsRemoved++
            }
        } catch {
            Write-RemovalLog "Failed to remove uninstall entry: $_" -Level Warning
        }
    }
}

function Remove-OpenClawDocker {
    Write-RemovalLog "Removing OpenClaw Docker artifacts..." -Level Info

    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-RemovalLog "Docker not available, skipping Docker cleanup" -Level Info
        return
    }

    try {
        # Stop and remove containers
        $containers = docker ps -a --format "{{.ID}} {{.Image}}" 2>&1 | Where-Object { $_ -match 'openclaw' }
        if ($containers) {
            foreach ($container in $containers) {
                $containerId = ($container -split ' ')[0]
                Write-RemovalLog "Removing Docker container: $containerId" -Level Info
                docker rm -f $containerId 2>&1 | Out-Null
                $script:ItemsRemoved++
            }
        }

        # Remove images
        $images = docker images --format "{{.ID}} {{.Repository}}" 2>&1 | Where-Object { $_ -match 'openclaw' }
        if ($images) {
            foreach ($image in $images) {
                $imageId = ($image -split ' ')[0]
                Write-RemovalLog "Removing Docker image: $imageId" -Level Info
                docker rmi -f $imageId 2>&1 | Out-Null
                $script:ItemsRemoved++
            }
        }

        Write-RemovalLog "Docker cleanup completed" -Level Success

    } catch {
        Write-RemovalLog "Docker cleanup failed: $_" -Level Warning
    }
}

function Remove-OpenClawEnvironmentVariables {
    Write-RemovalLog "Removing OpenClaw environment variables..." -Level Info

    $envVars = Get-ChildItem Env: | Where-Object { $_.Name -like "*OPENCLAW*" }

    foreach ($var in $envVars) {
        try {
            Write-RemovalLog "Removing environment variable: $($var.Name)" -Level Info
            [Environment]::SetEnvironmentVariable($var.Name, $null, "User")
            [Environment]::SetEnvironmentVariable($var.Name, $null, "Machine")
            $script:ItemsRemoved++
        } catch {
            Write-RemovalLog "Failed to remove environment variable $($var.Name): $_" -Level Warning
        }
    }
}

function Remove-OpenClawServices {
    Write-RemovalLog "Removing OpenClaw services..." -Level Info

    $servicePatterns = @('*openclaw*', '*OpenClaw*')

    foreach ($pattern in $servicePatterns) {
        $services = Get-Service -Name $pattern -ErrorAction SilentlyContinue
        if ($services) {
            foreach ($service in $services) {
                try {
                    Write-RemovalLog "Removing service: $($service.Name)" -Level Info
                    sc.exe delete $service.Name | Out-Null
                    Write-RemovalLog "Service removed: $($service.Name)" -Level Success
                    $script:ItemsRemoved++
                } catch {
                    Write-RemovalLog "Failed to remove service $($service.Name): $_" -Level Error
                    $script:Errors++
                }
            }
        }
    }
}

# Main execution
try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "OpenClaw Removal Script - Windows" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Confirm removal
    if (-not (Confirm-Removal)) {
        Write-Host "`n❌ Removal cancelled by user`n" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "`n🔄 Starting OpenClaw removal...`n" -ForegroundColor Yellow

    # Create backup
    if (-not (New-Backup)) {
        Write-Host "`n❌ Backup failed. Aborting removal for safety." -ForegroundColor Red
        Write-Host "Use -SkipBackup to proceed without backup (not recommended)`n" -ForegroundColor Yellow
        exit 1
    }

    # Perform removal steps
    Stop-OpenClawServices
    Remove-OpenClawExecutables
    Remove-OpenClawConfiguration
    Remove-OpenClawRegistry
    Remove-OpenClawDocker
    Remove-OpenClawEnvironmentVariables
    Remove-OpenClawServices

    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Removal Summary" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Items Removed: $($script:ItemsRemoved)" -ForegroundColor Green
    Write-Host "Errors: $($script:Errors)" -ForegroundColor $(if ($script:Errors -gt 0) { 'Red' } else { 'Green' })

    if ($script:BackupCreated -and -not $SkipBackup) {
        Write-Host "Backup Created: Yes" -ForegroundColor Green
    }

    if ($script:Errors -eq 0) {
        Write-Host "`n✅ OpenClaw successfully removed" -ForegroundColor Green
        Write-Host "`n💡 Note: A system restart may be required for complete cleanup`n" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "`n⚠️  OpenClaw removed with $($script:Errors) error(s)" -ForegroundColor Yellow
        Write-Host "Review the log above for details`n" -ForegroundColor Yellow
        exit 1
    }

} catch {
    Write-Host "`nERROR: Removal failed" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Exit Code: 2`n" -ForegroundColor Red
    exit 2
}
