<#
.SYNOPSIS
    Detects OpenClaw installations on Windows systems.

.DESCRIPTION
    Comprehensive detection script for OpenClaw software installations.
    Performs core checks (affecting exit code) and supplementary checks (informational).

    Exit Codes:
    0 = OpenClaw not present (compliant)
    1 = OpenClaw found (non-compliant)
    2 = Execution error

.PARAMETER Verbose
    Display detailed detection information

.EXAMPLE
    .\Detect-OpenClaw.ps1
    .\Detect-OpenClaw.ps1 -Verbose
#>

[CmdletBinding()]
param()

# Initialize detection state
$script:OpenClawDetected = $false
$script:DetectionResults = @()

function Write-DetectionLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Found')]
        [string]$Level = 'Info',
        [bool]$AffectsExitCode = $false
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[{0}] [{1}] {2}" -f $timestamp, $Level, $Message

    $script:DetectionResults += [PSCustomObject]@{
        Timestamp = $timestamp
        Level = $Level
        Message = $Message
        AffectsExitCode = $AffectsExitCode
    }

    if ($VerbosePreference -eq 'Continue' -or $Level -eq 'Found' -or $Level -eq 'Error') {
        switch ($Level) {
            'Error'   { Write-Host $logEntry -ForegroundColor Red }
            'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
            'Success' { Write-Host $logEntry -ForegroundColor Green }
            'Found'   { Write-Host $logEntry -ForegroundColor Magenta }
            default   { Write-Host $logEntry }
        }
    }
}

function Test-CLIExecutable {
    Write-DetectionLog "Checking for OpenClaw CLI executable..." -Level Info

    # Check PATH
    $pathExe = Get-Command openclaw -ErrorAction SilentlyContinue
    if ($pathExe) {
        Write-DetectionLog "DETECTED: OpenClaw CLI found in PATH: $($pathExe.Source)" -Level Found -AffectsExitCode $true
        $script:OpenClawDetected = $true
        return $true
    }

    # Common installation locations
    $commonPaths = @(
        "$env:ProgramFiles\OpenClaw\openclaw.exe",
        "$env:ProgramFiles\OpenClaw\bin\openclaw.exe",
        "${env:ProgramFiles(x86)}\OpenClaw\openclaw.exe",
        "${env:ProgramFiles(x86)}\OpenClaw\bin\openclaw.exe",
        "$env:LOCALAPPDATA\OpenClaw\openclaw.exe",
        "$env:LOCALAPPDATA\Programs\OpenClaw\openclaw.exe",
        "$env:APPDATA\OpenClaw\openclaw.exe",
        "$env:USERPROFILE\.openclaw\bin\openclaw.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-DetectionLog "DETECTED: OpenClaw CLI found at: $path" -Level Found -AffectsExitCode $true
            $script:OpenClawDetected = $true
            return $true
        }
    }

    Write-DetectionLog "OpenClaw CLI executable not found" -Level Info
    return $false
}

function Test-StateDirectory {
    Write-DetectionLog "Checking for OpenClaw state directory..." -Level Info

    $statePaths = @(
        "$env:USERPROFILE\.openclaw",
        "$env:APPDATA\OpenClaw",
        "$env:LOCALAPPDATA\OpenClaw"
    )

    foreach ($path in $statePaths) {
        if (Test-Path $path) {
            $itemCount = (Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-DetectionLog "DETECTED: OpenClaw state directory found: $path ($itemCount items)" -Level Found -AffectsExitCode $true
            $script:OpenClawDetected = $true
            return $true
        }
    }

    Write-DetectionLog "OpenClaw state directory not found" -Level Info
    return $false
}

function Get-OpenClawVersion {
    Write-DetectionLog "Attempting to retrieve OpenClaw version..." -Level Info

    try {
        $version = & openclaw --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-DetectionLog "DETECTED: OpenClaw version retrieved: $version" -Level Found -AffectsExitCode $true
            $script:OpenClawDetected = $true
            return $true
        }
    } catch {
        Write-DetectionLog "Could not retrieve OpenClaw version" -Level Info
    }

    return $false
}

function Test-ConfigurationFiles {
    Write-DetectionLog "Checking for OpenClaw configuration files..." -Level Info

    $configPaths = @(
        "$env:USERPROFILE\.openclaw\config.yaml",
        "$env:USERPROFILE\.openclaw\config.json",
        "$env:USERPROFILE\.openclaw\settings.yaml",
        "$env:APPDATA\OpenClaw\config.yaml",
        "$env:LOCALAPPDATA\OpenClaw\config.yaml"
    )

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            Write-DetectionLog "DETECTED: OpenClaw configuration file found: $path" -Level Found -AffectsExitCode $true
            $script:OpenClawDetected = $true
            return $true
        }
    }

    Write-DetectionLog "OpenClaw configuration files not found" -Level Info
    return $false
}

function Test-GatewayService {
    Write-DetectionLog "Checking for OpenClaw gateway service..." -Level Info

    $servicePatterns = @('*openclaw*', '*OpenClaw*')

    foreach ($pattern in $servicePatterns) {
        $services = Get-Service -Name $pattern -ErrorAction SilentlyContinue
        if ($services) {
            foreach ($service in $services) {
                Write-DetectionLog "DETECTED: OpenClaw service found: $($service.Name) (Status: $($service.Status))" -Level Found -AffectsExitCode $true
                $script:OpenClawDetected = $true
                return $true
            }
        }
    }

    Write-DetectionLog "OpenClaw gateway service not found" -Level Info
    return $false
}

function Test-GatewayPort {
    Write-DetectionLog "Checking for OpenClaw gateway listening ports..." -Level Info

    # Default ports to check
    $portsToCheck = @(50051, 8080, 8443, 9090)

    # Try to extract port from config
    $configPath = "$env:USERPROFILE\.openclaw\config.yaml"
    if (Test-Path $configPath) {
        try {
            $configContent = Get-Content $configPath -Raw
            if ($configContent -match 'port:\s*(\d+)') {
                $portsToCheck += [int]$matches[1]
            }
        } catch {
            Write-DetectionLog "Could not parse config for port information" -Level Info
        }
    }

    foreach ($port in $portsToCheck) {
        try {
            $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
            if ($connections) {
                $processId = $connections[0].OwningProcess
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                $processName = if ($process) { $process.Name } else { "Unknown" }

                Write-DetectionLog "DETECTED: Service listening on port $port (Process: $processName, PID: $processId)" -Level Found -AffectsExitCode $true
                $script:OpenClawDetected = $true
                return $true
            }
        } catch {
            # Port not in use, continue
        }
    }

    Write-DetectionLog "No OpenClaw gateway ports detected" -Level Info
    return $false
}

function Test-DockerArtifacts {
    Write-DetectionLog "Checking for OpenClaw Docker artifacts..." -Level Info

    # Check if Docker is available
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-DetectionLog "Docker not available, skipping Docker checks" -Level Info
        return $false
    }

    try {
        # Check for OpenClaw images
        $images = docker images --format "{{.Repository}}:{{.Tag}}" 2>&1 | Where-Object { $_ -match 'openclaw' }
        if ($images) {
            foreach ($image in $images) {
                Write-DetectionLog "DETECTED: OpenClaw Docker image found: $image" -Level Found -AffectsExitCode $true
                $script:OpenClawDetected = $true
            }
            return $true
        }

        # Check for running containers
        $containers = docker ps -a --format "{{.Names}} ({{.Image}})" 2>&1 | Where-Object { $_ -match 'openclaw' }
        if ($containers) {
            foreach ($container in $containers) {
                Write-DetectionLog "DETECTED: OpenClaw Docker container found: $container" -Level Found -AffectsExitCode $true
                $script:OpenClawDetected = $true
            }
            return $true
        }
    } catch {
        Write-DetectionLog "Error checking Docker artifacts: $_" -Level Warning
    }

    Write-DetectionLog "No OpenClaw Docker artifacts found" -Level Info
    return $false
}

function Test-RegistryEntries {
    Write-DetectionLog "Checking Windows Registry for OpenClaw..." -Level Info

    $registryPaths = @(
        "HKLM:\SOFTWARE\OpenClaw",
        "HKLM:\SOFTWARE\WOW6432Node\OpenClaw",
        "HKCU:\SOFTWARE\OpenClaw",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        if ($path -like "*Uninstall*") {
            try {
                $uninstallKeys = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayName -like "*OpenClaw*" }
                if ($uninstallKeys) {
                    foreach ($key in $uninstallKeys) {
                        Write-DetectionLog "DETECTED: OpenClaw registry entry in uninstall: $($key.DisplayName)" -Level Found -AffectsExitCode $true
                        $script:OpenClawDetected = $true
                        return $true
                    }
                }
            } catch {
                # Continue to next path
            }
        } else {
            if (Test-Path $path) {
                Write-DetectionLog "DETECTED: OpenClaw registry key found: $path" -Level Found -AffectsExitCode $true
                $script:OpenClawDetected = $true
                return $true
            }
        }
    }

    Write-DetectionLog "No OpenClaw registry entries found" -Level Info
    return $false
}

function Test-ActiveProcesses {
    Write-DetectionLog "[SUPPLEMENTARY] Checking for active OpenClaw processes..." -Level Info

    $processes = Get-Process | Where-Object { $_.Name -like "*openclaw*" -or $_.ProcessName -like "*openclaw*" }

    if ($processes) {
        foreach ($proc in $processes) {
            Write-DetectionLog "[INFO] OpenClaw process found: $($proc.Name) (PID: $($proc.Id))" -Level Info
        }
        return $true
    }

    Write-DetectionLog "[SUPPLEMENTARY] No active OpenClaw processes found" -Level Info
    return $false
}

function Test-EnvironmentVariables {
    Write-DetectionLog "[SUPPLEMENTARY] Checking environment variables..." -Level Info

    $envVars = Get-ChildItem Env: | Where-Object { $_.Name -like "*OPENCLAW*" -or $_.Value -like "*openclaw*" }

    if ($envVars) {
        foreach ($var in $envVars) {
            Write-DetectionLog "[INFO] OpenClaw environment variable: $($var.Name) = $($var.Value)" -Level Info
        }
        return $true
    }

    Write-DetectionLog "[SUPPLEMENTARY] No OpenClaw environment variables found" -Level Info
    return $false
}

function Test-WSLInstances {
    Write-DetectionLog "[SUPPLEMENTARY] Checking WSL for OpenClaw installations..." -Level Info

    $wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wslCmd) {
        Write-DetectionLog "[SUPPLEMENTARY] WSL not available" -Level Info
        return $false
    }

    try {
        $wslDistros = wsl --list --quiet 2>&1
        foreach ($distro in $wslDistros) {
            if ($distro) {
                $result = wsl -d $distro -- bash -c "command -v openclaw 2>/dev/null || test -d ~/.openclaw 2>/dev/null" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-DetectionLog "[INFO] OpenClaw may be present in WSL distro: $distro" -Level Info
                }
            }
        }
    } catch {
        Write-DetectionLog "[SUPPLEMENTARY] Error checking WSL: $_" -Level Info
    }

    return $false
}

# Main execution
try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "OpenClaw Detection Script - Windows" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Core detection checks (affect exit code)
    Write-Host "Running Core Detection Checks..." -ForegroundColor Yellow
    Write-Host "--------------------------------`n" -ForegroundColor Yellow

    Test-CLIExecutable
    Test-StateDirectory
    Get-OpenClawVersion
    Test-ConfigurationFiles
    Test-GatewayService
    Test-GatewayPort
    Test-DockerArtifacts
    Test-RegistryEntries

    # Supplementary checks (informational only)
    Write-Host "`nRunning Supplementary Checks..." -ForegroundColor Yellow
    Write-Host "--------------------------------`n" -ForegroundColor Yellow

    Test-ActiveProcesses
    Test-EnvironmentVariables
    Test-WSLInstances

    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Detection Summary" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    if ($script:OpenClawDetected) {
        Write-Host "STATUS: OpenClaw DETECTED (Non-Compliant)" -ForegroundColor Red
        Write-Host "Exit Code: 1`n" -ForegroundColor Red

        # Show core detections
        $coreDetections = $script:DetectionResults | Where-Object { $_.AffectsExitCode -eq $true }
        if ($coreDetections) {
            Write-Host "Core Detections:" -ForegroundColor Yellow
            foreach ($detection in $coreDetections) {
                Write-Host "  - $($detection.Message)" -ForegroundColor Magenta
            }
        }

        exit 1
    } else {
        Write-Host "STATUS: OpenClaw NOT DETECTED (Compliant)" -ForegroundColor Green
        Write-Host "Exit Code: 0`n" -ForegroundColor Green
        exit 0
    }

} catch {
    Write-Host "`nERROR: Script execution failed" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Exit Code: 2`n" -ForegroundColor Red
    exit 2
}
