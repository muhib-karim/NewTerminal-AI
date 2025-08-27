# NewTerminal-AI Installation Script for Windows
# This script installs NewTerminal-AI with Ollama integration

param(
    [switch]$Force,
    [string]$InstallPath = "$env:USERPROFILE\.newterminal-ai",
    [string]$Model = "auto"
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [string]$Prefix = ""
    )
    
    $colors = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Blue"
        "Cyan" = "Cyan"
        "White" = "White"
    }
    
    if ($Prefix) {
        Write-Host "[$Prefix] " -ForegroundColor $colors[$Color] -NoNewline
    }
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Write-Status { param([string]$Message) Write-ColorOutput -Message $Message -Color "Green" -Prefix "INFO" }
function Write-Warning { param([string]$Message) Write-ColorOutput -Message $Message -Color "Yellow" -Prefix "WARNING" }
function Write-Error { param([string]$Message) Write-ColorOutput -Message $Message -Color "Red" -Prefix "ERROR" }

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check system requirements
function Test-Requirements {
    Write-Status "Checking system requirements..."
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
        exit 1
    }
    
    # Check if Chocolatey is available (optional)
    $hasChoco = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $hasChoco) {
        Write-Warning "Chocolatey not found. Manual Ollama installation may be required."
    }
    
    Write-Status "System requirements check passed."
}

# Install Ollama if not present
function Install-Ollama {
    if (Get-Command ollama -ErrorAction SilentlyContinue) {
        Write-Status "Ollama is already installed."
        return
    }
    
    Write-Status "Installing Ollama..."
    
    try {
        # Try to download and install Ollama
        $ollamaUrl = "https://ollama.ai/download/windows"
        $tempFile = "$env:TEMP\ollama-windows-amd64.exe"
        
        Write-Status "Downloading Ollama installer..."
        Invoke-WebRequest -Uri $ollamaUrl -OutFile $tempFile -UseBasicParsing
        
        Write-Status "Running Ollama installer..."
        Start-Process -FilePath $tempFile -ArgumentList "/S" -Wait
        
        # Add Ollama to PATH if not already there
        $ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama"
        if (Test-Path $ollamaPath) {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notlike "*$ollamaPath*") {
                [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$ollamaPath", "User")
                $env:PATH += ";$ollamaPath"
            }
        }
        
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        Write-Status "Ollama installed successfully."
    }
    catch {
        Write-Error "Failed to install Ollama automatically. Please install it manually from https://ollama.ai"
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Install optimal AI model
function Install-Model {
    Write-Status "Installing AI model..."
    
    # Start Ollama service if not running
    $ollamaProcess = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
    if (-not $ollamaProcess) {
        Write-Status "Starting Ollama service..."
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }
    
    # Determine optimal model based on system memory
    $totalMemoryGB = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $targetModel = "llama3.2:1b"
    
    if ($Model -eq "auto") {
        if ($totalMemoryGB -ge 16) {
            $targetModel = "phi3:mini"
        } elseif ($totalMemoryGB -ge 8) {
            $targetModel = "llama3.2:1b"
        } else {
            $targetModel = "llama3.2:1b"
        }
    } else {
        $targetModel = $Model
    }
    
    Write-Status "Installing model: $targetModel (System RAM: ${totalMemoryGB}GB)"
    
    try {
        $pullResult = & ollama pull $targetModel 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Model $targetModel installed successfully."
            
            # Update the model in the PowerShell module
            $moduleContent = Get-Content "$InstallPath\NewTerminal-AI-fixed.psm1" -Raw
            $moduleContent = $moduleContent -replace 'OLLAMA_MODEL = "[^"]*"', "OLLAMA_MODEL = `"$targetModel`""
            Set-Content -Path "$InstallPath\NewTerminal-AI-fixed.psm1" -Value $moduleContent
        } else {
            Write-Error "Failed to install model $targetModel"
            Write-Error $pullResult
            exit 1
        }
    }
    catch {
        Write-Error "Failed to install model: $($_.Exception.Message)"
        exit 1
    }
}

# Create installation directory
function New-InstallationDirectories {
    Write-Status "Setting up directories..."
    
    if (-not (Test-Path $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    }
    
    Write-Status "Directories created successfully."
}

# Install NewTerminal-AI
function Install-NewTerminalAI {
    Write-Status "Installing NewTerminal-AI..."
    
    # Copy the PowerShell module to installation directory
    if (Test-Path "NewTerminal-AI-fixed.psm1") {
        Copy-Item "NewTerminal-AI-fixed.psm1" -Destination $InstallPath -Force
    } else {
        Write-Error "NewTerminal-AI-fixed.psm1 not found in current directory"
        exit 1
    }
    
    Write-Status "NewTerminal-AI installed successfully."
}

# Setup PowerShell profile integration
function Set-PowerShellIntegration {
    Write-Status "Setting up PowerShell profile integration..."
    
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path $profilePath -Parent
    
    # Create profile directory if it doesn't exist
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Create or update PowerShell profile
    $profileContent = ""
    if (Test-Path $profilePath) {
        $profileContent = Get-Content $profilePath -Raw
    }
    
    $integrationCode = @"

# NewTerminal-AI Integration
if (Test-Path "$InstallPath\NewTerminal-AI-fixed.psm1") {
    Import-Module "$InstallPath\NewTerminal-AI-fixed.psm1" -Force
}
"@
    
    if ($profileContent -notlike "*NewTerminal-AI Integration*") {
        Add-Content -Path $profilePath -Value $integrationCode
        Write-Status "PowerShell profile updated: $profilePath"
    } else {
        Write-Status "PowerShell profile integration already exists"
    }
}

# Test installation
function Test-Installation {
    Write-Status "Testing installation..."
    
    # Import the module for testing
    try {
        Import-Module "$InstallPath\NewTerminal-AI-fixed.psm1" -Force
        
        # Test if commands are available
        $commands = @("Invoke-AICommandAuto", "Invoke-AICommand", "Start-NLMode")
        foreach ($cmd in $commands) {
            if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                Write-Status "✅ $cmd command available"
            } else {
                Write-Error "❌ $cmd command not found"
            }
        }
        
        # Test Ollama connection
        try {
            $ollamaTest = & ollama list 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Status "✅ Ollama connection successful"
            } else {
                Write-Warning "⚠️  Ollama connection failed. You may need to start Ollama manually."
            }
        }
        catch {
            Write-Warning "⚠️  Could not test Ollama connection: $($_.Exception.Message)"
        }
    }
    catch {
        Write-Error "Failed to import NewTerminal-AI module: $($_.Exception.Message)"
    }
}

# Main installation process
function Start-Installation {
    Write-Host ""
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" -Color "Cyan"
    Write-ColorOutput "║                    NewTerminal-AI Installer                  ║" -Color "Cyan"
    Write-ColorOutput "║              Natural Language Terminal Interface             ║" -Color "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" -Color "Cyan"
    Write-Host ""
    
    Test-Requirements
    New-InstallationDirectories
    Install-Ollama
    Install-Model
    Install-NewTerminalAI
    Set-PowerShellIntegration
    Test-Installation
    
    Write-Host ""
    Write-ColorOutput "🎉 Installation completed successfully!" -Color "Green"
    Write-Host ""
    Write-ColorOutput "Next steps:" -Color "Yellow"
    Write-ColorOutput "1. Restart PowerShell or run: . `$PROFILE" -Color "Cyan"
    Write-ColorOutput "2. Try the commands:" -Color "Cyan"
    Write-ColorOutput "   aia 'list files'     - Auto-execute commands" -Color "Yellow"
    Write-ColorOutput "   ai 'create file test.txt' - Generate with confirmation" -Color "Yellow"
    Write-ColorOutput "   nl                   - Interactive natural language mode" -Color "Yellow"
    Write-Host ""
    Write-ColorOutput "Enjoy your AI-powered terminal! 🚀" -Color "Green"
}

# Run main installation
Start-Installation