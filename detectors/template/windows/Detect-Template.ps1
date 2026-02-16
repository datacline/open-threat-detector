<#
.SYNOPSIS
    Detects [TOOL_NAME] installations on Windows systems.

.DESCRIPTION
    Comprehensive detection script for [TOOL_NAME] software installations.
    Performs core checks (affecting exit code) and supplementary checks (informational).

    Exit Codes:
    0 = [TOOL_NAME] not present (compliant)
    1 = [TOOL_NAME] found (non-compliant)
    2 = Execution error

.PARAMETER Verbose
    Display detailed detection information

.EXAMPLE
    .\Detect-Template.ps1
    .\Detect-Template.ps1 -Verbose

.NOTES
    Template version: 1.0.0
    Replace [TOOL_NAME] with your target software name
    Customize detection methods for your specific tool
#>

[CmdletBinding()]
param()

# Initialize detection state
$script:ToolDetected = $false
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

#region Core Detection Functions (Affect Exit Code)

function Test-CLIExecutable {
    Write-DetectionLog "Checking for [TOOL_NAME] CLI executable..." -Level Info

    # TODO: Replace 'toolname' with actual executable name
    $pathExe = Get-Command toolname -ErrorAction SilentlyContinue
    if ($pathExe) {
        Write-DetectionLog "DETECTED: [TOOL_NAME] CLI found in PATH: $($pathExe.Source)" -Level Found -AffectsExitCode $true
        $script:ToolDetected = $true
        return $true
    }

    # TODO: Add common installation paths for your tool
    $commonPaths = @(
        "$env:ProgramFiles\ToolName\toolname.exe",
        "$env:LOCALAPPDATA\ToolName\toolname.exe",
        "$env:APPDATA\ToolName\toolname.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            Write-DetectionLog "DETECTED: [TOOL_NAME] CLI found at: $path" -Level Found -AffectsExitCode $true
            $script:ToolDetected = $true
            return $true
        }
    }

    Write-DetectionLog "[TOOL_NAME] CLI executable not found" -Level Info
    return $false
}

function Test-StateDirectory {
    Write-DetectionLog "Checking for [TOOL_NAME] state directory..." -Level Info

    # TODO: Add state directory paths for your tool
    $statePaths = @(
        "$env:USERPROFILE\.toolname",
        "$env:APPDATA\ToolName",
        "$env:LOCALAPPDATA\ToolName"
    )

    foreach ($path in $statePaths) {
        if (Test-Path $path) {
            $itemCount = (Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Measure-Object).Count
            Write-DetectionLog "DETECTED: [TOOL_NAME] state directory found: $path ($itemCount items)" -Level Found -AffectsExitCode $true
            $script:ToolDetected = $true
            return $true
        }
    }

    Write-DetectionLog "[TOOL_NAME] state directory not found" -Level Info
    return $false
}

function Get-ToolVersion {
    Write-DetectionLog "Attempting to retrieve [TOOL_NAME] version..." -Level Info

    # TODO: Replace with actual version command
    try {
        $version = & toolname --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-DetectionLog "DETECTED: [TOOL_NAME] version retrieved: $version" -Level Found -AffectsExitCode $true
            $script:ToolDetected = $true
            return $true
        }
    } catch {
        Write-DetectionLog "Could not retrieve [TOOL_NAME] version" -Level Info
    }

    return $false
}

function Test-ConfigurationFiles {
    Write-DetectionLog "Checking for [TOOL_NAME] configuration files..." -Level Info

    # TODO: Add configuration file paths for your tool
    $configPaths = @(
        "$env:USERPROFILE\.toolname\config.yaml",
        "$env:APPDATA\ToolName\config.json"
    )

    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            Write-DetectionLog "DETECTED: [TOOL_NAME] configuration file found: $path" -Level Found -AffectsExitCode $true
            $script:ToolDetected = $true
            return $true
        }
    }

    Write-DetectionLog "[TOOL_NAME] configuration files not found" -Level Info
    return $false
}

function Test-WindowsService {
    Write-DetectionLog "Checking for [TOOL_NAME] Windows service..." -Level Info

    # TODO: Add service name patterns for your tool
    $servicePatterns = @('*toolname*', '*ToolName*')

    foreach ($pattern in $servicePatterns) {
        $services = Get-Service -Name $pattern -ErrorAction SilentlyContinue
        if ($services) {
            foreach ($service in $services) {
                Write-DetectionLog "DETECTED: [TOOL_NAME] service found: $($service.Name) (Status: $($service.Status))" -Level Found -AffectsExitCode $true
                $script:ToolDetected = $true
                return $true
            }
        }
    }

    Write-DetectionLog "[TOOL_NAME] Windows service not found" -Level Info
    return $false
}

function Test-RegistryEntries {
    Write-DetectionLog "Checking Windows Registry for [TOOL_NAME]..." -Level Info

    # TODO: Add registry paths for your tool
    $registryPaths = @(
        "HKLM:\SOFTWARE\ToolName",
        "HKLM:\SOFTWARE\WOW6432Node\ToolName",
        "HKCU:\SOFTWARE\ToolName"
    )

    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            Write-DetectionLog "DETECTED: [TOOL_NAME] registry key found: $path" -Level Found -AffectsExitCode $true
            $script:ToolDetected = $true
            return $true
        }
    }

    # Check uninstall entries
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        try {
            $uninstallKeys = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -like "*ToolName*" }
            if ($uninstallKeys) {
                foreach ($key in $uninstallKeys) {
                    Write-DetectionLog "DETECTED: [TOOL_NAME] registry entry in uninstall: $($key.DisplayName)" -Level Found -AffectsExitCode $true
                    $script:ToolDetected = $true
                    return $true
                }
            }
        } catch {
            # Continue to next path
        }
    }

    Write-DetectionLog "No [TOOL_NAME] registry entries found" -Level Info
    return $false
}

#endregion

#region Supplementary Functions (Informational Only)

function Test-ActiveProcesses {
    Write-DetectionLog "[SUPPLEMENTARY] Checking for active [TOOL_NAME] processes..." -Level Info

    # TODO: Replace with actual process name
    $processes = Get-Process | Where-Object { $_.Name -like "*toolname*" }

    if ($processes) {
        foreach ($proc in $processes) {
            Write-DetectionLog "[INFO] [TOOL_NAME] process found: $($proc.Name) (PID: $($proc.Id))" -Level Info
        }
        return $true
    }

    Write-DetectionLog "[SUPPLEMENTARY] No active [TOOL_NAME] processes found" -Level Info
    return $false
}

function Test-EnvironmentVariables {
    Write-DetectionLog "[SUPPLEMENTARY] Checking environment variables..." -Level Info

    # TODO: Replace with actual environment variable pattern
    $envVars = Get-ChildItem Env: | Where-Object { $_.Name -like "*TOOLNAME*" }

    if ($envVars) {
        foreach ($var in $envVars) {
            Write-DetectionLog "[INFO] [TOOL_NAME] environment variable: $($var.Name) = $($var.Value)" -Level Info
        }
        return $true
    }

    Write-DetectionLog "[SUPPLEMENTARY] No [TOOL_NAME] environment variables found" -Level Info
    return $false
}

#endregion

# Main execution
try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "[TOOL_NAME] Detection Script - Windows" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Core detection checks (affect exit code)
    Write-Host "Running Core Detection Checks..." -ForegroundColor Yellow
    Write-Host "--------------------------------`n" -ForegroundColor Yellow

    Test-CLIExecutable
    Test-StateDirectory
    Get-ToolVersion
    Test-ConfigurationFiles
    Test-WindowsService
    Test-RegistryEntries

    # Supplementary checks (informational only)
    Write-Host "`nRunning Supplementary Checks..." -ForegroundColor Yellow
    Write-Host "--------------------------------`n" -ForegroundColor Yellow

    Test-ActiveProcesses
    Test-EnvironmentVariables

    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Detection Summary" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    if ($script:ToolDetected) {
        Write-Host "STATUS: [TOOL_NAME] DETECTED (Non-Compliant)" -ForegroundColor Red
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
        Write-Host "STATUS: [TOOL_NAME] NOT DETECTED (Compliant)" -ForegroundColor Green
        Write-Host "Exit Code: 0`n" -ForegroundColor Green
        exit 0
    }

} catch {
    Write-Host "`nERROR: Script execution failed" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Exit Code: 2`n" -ForegroundColor Red
    exit 2
}
