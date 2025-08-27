# NewTerminal-AI Enhanced Auto-Installation Script
# Automatically installs Ollama, optimal AI models, and configures the system

param(
    [switch]$Force,
    [switch]$Quiet,
    [string]$PreferredModel = "",
    [switch]$SkipOllama
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ANSI Colors for better output
$Colors = @{
    Green = "`e[32m"
    Yellow = "`e[33m"
    Red = "`e[31m"
    Blue = "`e[34m"
    Cyan = "`e[36m"
    Reset = "`e[0m"
    Bold = "`e[1m"
}

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    
    $icon = switch ($Type) {
        "Success" { "[✓]" }
        "Warning" { "[!]" }
        "Error" { "[✗]" }
        "Info" { "[i]" }
        default { "[*]" }
    }
    
    $color = switch ($Type) {
        "Success" { $Colors.Green }
        "Warning" { $Colors.Yellow }
        "Error" { $Colors.Red }
        "Info" { $Colors.Cyan }
        default { $Colors.Blue }
    }
    
    Write-Host "$color$icon$($Colors.Reset) $Message"
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Ollama {
    if ($SkipOllama) {
        Write-Status "Skipping Ollama installation as requested" "Info"
        return $true
    }
    
    Write-Status "Checking for Ollama installation..." "Info"
    
    # Check if Ollama is already installed
    try {
        $ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue
        if ($ollamaPath) {
            Write-Status "Ollama is already installed at: $($ollamaPath.Source)" "Success"
            return $true
        }
    } catch { }
    
    Write-Status "Ollama not found. Installing Ollama..." "Warning"
    
    # Download and install Ollama
    try {
        $ollamaUrl = "https://ollama.ai/download/windows"
        $tempPath = "$env:TEMP\OllamaSetup.exe"
        
        Write-Status "Downloading Ollama installer..." "Info"
        Invoke-WebRequest -Uri $ollamaUrl -OutFile $tempPath -UseBasicParsing
        
        Write-Status "Installing Ollama (this may take a few minutes)..." "Info"
        $installProcess = Start-Process -FilePath $tempPath -ArgumentList "/S" -Wait -PassThru
        
        if ($installProcess.ExitCode -eq 0) {
            Write-Status "Ollama installed successfully!" "Success"
            
            # Add Ollama to PATH if not already there
            $ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama"
            if (Test-Path $ollamaPath) {
                $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                if ($currentPath -notlike "*$ollamaPath*") {
                    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$ollamaPath", "User")
                    $env:PATH += ";$ollamaPath"
                }
            }
            
            # Clean up installer
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Status "Ollama installation failed with exit code: $($installProcess.ExitCode)" "Error"
            return $false
        }
    } catch {
        Write-Status "Error installing Ollama: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Start-OllamaService {
    Write-Status "Starting Ollama service..." "Info"
    
    try {
        # Start Ollama service in background
        $ollamaProcess = Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 5
        
        # Test connection
        $maxRetries = 10
        $retryCount = 0
        
        do {
            try {
                $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 3
                Write-Status "Ollama service is running successfully!" "Success"
                return $true
            } catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Status "Waiting for Ollama service to start... ($retryCount/$maxRetries)" "Info"
                    Start-Sleep -Seconds 2
                } else {
                    Write-Status "Failed to start Ollama service after $maxRetries attempts" "Error"
                    return $false
                }
            }
        } while ($retryCount -lt $maxRetries)
        
    } catch {
        Write-Status "Error starting Ollama service: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Install-OptimalModel {
    param([string]$ModelName = "qwen2.5:0.5b")
    
    Write-Status "Installing optimal AI model: $ModelName" "Info"
    Write-Status "This may take several minutes depending on your internet connection..." "Warning"
    
    try {
        # Show progress during model download
        $installProcess = Start-Process "ollama" -ArgumentList "pull", $ModelName -Wait -PassThru -NoNewWindow
        
        if ($installProcess.ExitCode -eq 0) {
            Write-Status "Successfully installed model: $ModelName" "Success"
            return $true
        } else {
            Write-Status "Failed to install model: $ModelName (Exit code: $($installProcess.ExitCode))" "Error"
            return $false
        }
    } catch {
        Write-Status "Error installing model: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Install-NewTerminalAI {
    Write-Status "Installing NewTerminal-AI module..." "Info"
    
    try {
        # Get the script directory
        $scriptDir = Split-Path -Parent $PSCommandPath
        $moduleDir = Split-Path -Parent $scriptDir
        $modulePath = Join-Path $moduleDir "NewTerminal-AI.psm1"
        
        if (-not (Test-Path $modulePath)) {
            Write-Status "NewTerminal-AI.psm1 not found at: $modulePath" "Error"
            return $false
        }
        
        # Import the module
        Import-Module $modulePath -Force -Global
        
        # Add to PowerShell profile for auto-loading
        $profilePath = $PROFILE.CurrentUserAllHosts
        $profileDir = Split-Path -Parent $profilePath
        
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        $importLine = "Import-Module '$modulePath' -Force"
        
        if (Test-Path $profilePath) {
            $profileContent = Get-Content $profilePath -Raw
            if ($profileContent -notlike "*$importLine*") {
                Add-Content -Path $profilePath -Value "`n# NewTerminal-AI Auto-Load`n$importLine"
                Write-Status "Added NewTerminal-AI to PowerShell profile" "Success"
            } else {
                Write-Status "NewTerminal-AI already in PowerShell profile" "Info"
            }
        } else {
            Set-Content -Path $profilePath -Value "# NewTerminal-AI Auto-Load`n$importLine"
            Write-Status "Created PowerShell profile with NewTerminal-AI" "Success"
        }
        
        return $true
    } catch {
        Write-Status "Error installing NewTerminal-AI: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Test-SystemRequirements {
    Write-Status "Checking system requirements..." "Info"
    
    $requirements = @{
        OS = $true
        PowerShell = $true
        DiskSpace = $true
        Memory = $true
        Internet = $true
    }
    
    # Check OS version
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10) {
        Write-Status "Windows 10 or later is required" "Error"
        $requirements.OS = $false
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Status "PowerShell 5.0 or later is required" "Error"
        $requirements.PowerShell = $false
    }
    
    # Check disk space (need at least 5GB)
    try {
        $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        if ($freeSpaceGB -lt 5) {
            Write-Status "Insufficient disk space. Need at least 5GB, have $freeSpaceGB GB" "Error"
            $requirements.DiskSpace = $false
        } else {
            Write-Status "Disk space: $freeSpaceGB GB available" "Success"
        }
    } catch {
        Write-Status "Could not check disk space" "Warning"
    }
    
    # Check memory (recommend at least 4GB)
    try {
        $memory = Get-WmiObject -Class Win32_ComputerSystem
        $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        if ($totalMemoryGB -lt 4) {
            Write-Status "Low memory detected: $totalMemoryGB GB (4GB+ recommended)" "Warning"
        } else {
            Write-Status "Memory: $totalMemoryGB GB" "Success"
        }
    } catch {
        Write-Status "Could not check memory" "Warning"
    }
    
    # Check internet connection
    try {
        $null = Invoke-WebRequest -Uri "https://ollama.ai" -UseBasicParsing -TimeoutSec 10
        Write-Status "Internet connection: Available" "Success"
    } catch {
        Write-Status "Internet connection required for model downloads" "Error"
        $requirements.Internet = $false
    }
    
    return $requirements
}

# Main installation process
function Start-Installation {
    Write-Host "`n$($Colors.Bold)$($Colors.Cyan)NewTerminal-AI Enhanced Auto-Installer$($Colors.Reset)`n"
    Write-Status "Starting enhanced installation process..." "Info"
    
    # Check system requirements
    $sysReq = Test-SystemRequirements
    $canProceed = $sysReq.OS -and $sysReq.PowerShell -and $sysReq.DiskSpace -and $sysReq.Internet
    
    if (-not $canProceed -and -not $Force) {
        Write-Status "System requirements not met. Use -Force to override." "Error"
        return $false
    }
    
    # Install Ollama
    if (-not (Install-Ollama)) {
        Write-Status "Failed to install Ollama" "Error"
        return $false
    }
    
    # Start Ollama service
    if (-not (Start-OllamaService)) {
        Write-Status "Failed to start Ollama service" "Error"
        return $false
    }
    
    # Install optimal model
    $modelToInstall = if ($PreferredModel) { $PreferredModel } else { "qwen2.5:0.5b" }
    if (-not (Install-OptimalModel -ModelName $modelToInstall)) {
        Write-Status "Failed to install AI model" "Error"
        return $false
    }
    
    # Install NewTerminal-AI module
    if (-not (Install-NewTerminalAI)) {
        Write-Status "Failed to install NewTerminal-AI module" "Error"
        return $false
    }
    
    Write-Host "`n$($Colors.Bold)$($Colors.Green)Installation completed successfully!$($Colors.Reset)`n"
    Write-Status "NewTerminal-AI is ready to use!" "Success"
    Write-Status "Type 'warp' to start the NewTerminal AI interface" "Info"
    Write-Status "Type 'setup' to run system optimization" "Info"
    
    return $true
}

# Run installation
if ($MyInvocation.InvocationName -ne '.') {
    Start-Installation
}