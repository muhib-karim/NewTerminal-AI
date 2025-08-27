# Universal NewTerminal-AI Installation Script for PowerShell
# Automatically detects platform and runs the appropriate enhanced installer

param(
    [switch]$Force = $false
)

# Color scheme for consistent output
$Colors = @{
    Error = 'Red'
    Success = 'Green'
    Warning = 'Yellow'
    Info = 'Blue'
    Highlight = 'Magenta'
    Progress = 'Cyan'
    Text = 'White'
}

# Function to detect platform and run appropriate installer
function Start-UniversalInstaller {
    Write-Host "=== NewTerminal-AI Universal Installer ===" -ForegroundColor $Colors.Info
    Write-Host "Detecting your platform..." -ForegroundColor $Colors.Text
    
    # Get the directory where this script is located
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    
    # Detect platform
    $Platform = ""
    $Installer = ""
    
    if ($IsWindows -or $env:OS -eq "Windows_NT" -or [System.Environment]::OSVersion.Platform -eq "Win32NT") {
        $Platform = "Windows"
        $Installer = Join-Path $ScriptDir "install-enhanced.ps1"
    }
    elseif ($IsMacOS -or (uname -s 2>$null) -eq "Darwin") {
        $Platform = "macOS"
        $Installer = Join-Path $ScriptDir "install-enhanced.sh"
    }
    elseif ($IsLinux -or (uname -s 2>$null) -eq "Linux") {
        $Platform = "Linux"
        $Installer = Join-Path $ScriptDir "install-enhanced.sh"
    }
    else {
        Write-Host "Unsupported platform" -ForegroundColor $Colors.Error
        Write-Host "This installer supports Windows, macOS, and Linux only." -ForegroundColor $Colors.Warning
        exit 1
    }
    
    Write-Host "Platform detected: $Platform" -ForegroundColor $Colors.Success
    
    # Check if the appropriate installer exists
    if (-not (Test-Path $Installer)) {
        Write-Host "Error: Enhanced installer not found at $Installer" -ForegroundColor $Colors.Error
        Write-Host "Please ensure all installation files are present." -ForegroundColor $Colors.Warning
        exit 1
    }
    
    Write-Host "Running enhanced installer for $Platform..." -ForegroundColor $Colors.Progress
    Start-Sleep -Seconds 1
    
    # Run the appropriate installer
    try {
        switch ($Platform) {
            "Windows" {
                if ($Force) {
                    & powershell -ExecutionPolicy Bypass -File $Installer
                } else {
                    & $Installer
                }
            }
            { $_ -in @("macOS", "Linux") } {
                # Make sure the script is executable and run it
                if (Get-Command chmod -ErrorAction SilentlyContinue) {
                    chmod +x $Installer
                }
                if (Get-Command bash -ErrorAction SilentlyContinue) {
                    & bash $Installer
                } else {
                    Write-Host "Error: Bash not found" -ForegroundColor $Colors.Error
                    Write-Host "Please install Bash or run the installer directly." -ForegroundColor $Colors.Warning
                    exit 1
                }
            }
        }
    }
    catch {
        Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor $Colors.Error
        exit 1
    }
}

# Function to show help information
function Show-Help {
    Write-Host "NewTerminal-AI Universal Installer" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "DESCRIPTION:" -ForegroundColor $Colors.Text
    Write-Host "    Automatically detects your platform and runs the appropriate enhanced installer."
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor $Colors.Text
    Write-Host "    .\install-universal.ps1 [-Force]"
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor $Colors.Text
    Write-Host "    -Force    Bypass execution policy restrictions (Windows only)"
    Write-Host ""
    Write-Host "SUPPORTED PLATFORMS:" -ForegroundColor $Colors.Text
    Write-Host "    • Windows (PowerShell)"
    Write-Host "    • macOS (Bash)"
    Write-Host "    • Linux (Bash)"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor $Colors.Text
    Write-Host "    .\install-universal.ps1"
    Write-Host "    .\install-universal.ps1 -Force"
}

# Main execution
if ($args -contains "-h" -or $args -contains "--help" -or $args -contains "/?") {
    Show-Help
    exit 0
}

# Run the universal installer
Start-UniversalInstaller