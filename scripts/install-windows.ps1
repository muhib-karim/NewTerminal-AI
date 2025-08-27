# NewTerminal-AI Windows Installation Script
# Installs Ollama, AI model, and NewTerminal-AI module

param(
    [switch]$TestMode,
    [string]$InstallPath = "$env:USERPROFILE\NewTerminal-AI",
    [string]$Model = "auto"
)

# Color output function
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Check system requirements
function Test-Requirements {
    Write-ColorOutput "Checking system requirements..." -Color "Yellow"
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "PowerShell 5.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
        exit 1
    }
    
    Write-ColorOutput "[OK] PowerShell version: $($PSVersionTable.PSVersion)" -Color "Green"
}

# Create installation directories
function New-InstallationDirectories {
    Write-ColorOutput "Creating installation directories..." -Color "Yellow"
    
    $directories = @(
        $InstallPath,
        "$InstallPath\bin",
        "$InstallPath\models",
        "$InstallPath\logs"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColorOutput "[CREATED] $dir" -Color "Green"
        } else {
            Write-ColorOutput "[EXISTS] $dir" -Color "Cyan"
        }
    }
}

# Install Ollama
function Install-Ollama {
    Write-ColorOutput "Installing Ollama..." -Color "Yellow"
    
    # Check if Ollama is already installed
    try {
        $ollamaVersion = & ollama --version 2>$null
        if ($ollamaVersion) {
            Write-ColorOutput "[OK] Ollama is already installed: $ollamaVersion" -Color "Green"
            return
        }
    } catch {
        # Ollama not found, proceed with installation
    }
    
    if ($TestMode) {
        Write-ColorOutput "[TEST MODE] Skipping Ollama installation" -Color "Cyan"
        return
    }
    
    try {
        Write-ColorOutput "Downloading Ollama installer..." -Color "Yellow"
        $ollamaUrl = "https://ollama.com/download/windows"
        $installerPath = "$env:TEMP\OllamaSetup.exe"
        
        Invoke-WebRequest -Uri $ollamaUrl -OutFile $installerPath -UseBasicParsing
        
        Write-ColorOutput "Installing Ollama..." -Color "Yellow"
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        
        # Add Ollama to PATH if not already there
        $ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama"
        if (Test-Path $ollamaPath) {
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($currentPath -notlike "*$ollamaPath*") {
                [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$ollamaPath", "User")
                $env:PATH += ";$ollamaPath"
            }
        }
        
        Write-ColorOutput "[OK] Ollama installed successfully" -Color "Green"
    } catch {
        Write-Error "Failed to install Ollama: $($_.Exception.Message)"
        exit 1
    }
}

# Install AI model
function Install-Model {
    Write-ColorOutput "Installing AI model..." -Color "Yellow"
    
    if ($TestMode) {
        Write-ColorOutput "[TEST MODE] Skipping model installation" -Color "Cyan"
        return
    }
    
    # Determine optimal model based on system RAM
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    
    if ($Model -eq "auto") {
        if ($ramGB -ge 16) {
            $selectedModel = "phi3:mini"
        } else {
            $selectedModel = "llama3.2:1b"
        }
    } else {
        $selectedModel = $Model
    }
    
    Write-ColorOutput "System RAM: ${ramGB}GB - Installing model: $selectedModel" -Color "Cyan"
    
    try {
        # Check if model is already installed
        $installedModels = & ollama list 2>$null
        if ($installedModels -like "*$selectedModel*") {
            Write-ColorOutput "[OK] Model $selectedModel is already installed" -Color "Green"
            return
        }
        
        Write-ColorOutput "Downloading and installing $selectedModel (this may take a few minutes)..." -Color "Yellow"
        & ollama pull $selectedModel
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[OK] Model $selectedModel installed successfully" -Color "Green"
        } else {
            throw "Ollama pull failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Error "Failed to install model: $($_.Exception.Message)"
        exit 1
    }
}

# Install NewTerminal-AI module
function Install-NewTerminalAI {
    Write-ColorOutput "Installing NewTerminal-AI module..." -Color "Yellow"
    
    try {
        # Copy the module file
        $moduleSource = Join-Path $PSScriptRoot "..\NewTerminal-AI-fixed.psm1"
        $moduleDestination = "$InstallPath\NewTerminal-AI.psm1"
        
        if (Test-Path $moduleSource) {
            Copy-Item $moduleSource $moduleDestination -Force
            Write-ColorOutput "[OK] Module copied to $moduleDestination" -Color "Green"
        } else {
            # Try current directory
            $moduleSource = "NewTerminal-AI-fixed.psm1"
            if (Test-Path $moduleSource) {
                Copy-Item $moduleSource $moduleDestination -Force
                Write-ColorOutput "[OK] Module copied to $moduleDestination" -Color "Green"
            } else {
                throw "NewTerminal-AI-fixed.psm1 not found"
            }
        }
    } catch {
        Write-Error "Failed to install NewTerminal-AI module: $($_.Exception.Message)"
        exit 1
    }
}

# Set up PowerShell profile integration
function Set-PowerShellIntegration {
    Write-ColorOutput "Setting up PowerShell integration..." -Color "Yellow"
    
    try {
        # Create profile if it doesn't exist
        if (-not (Test-Path $PROFILE)) {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
            Write-ColorOutput "[CREATED] PowerShell profile: $PROFILE" -Color "Green"
        }
        
        # Check if NewTerminal-AI is already in profile
        $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
        $importLine = "Import-Module `"$InstallPath\NewTerminal-AI.psm1`" -Force"
        
        if ($profileContent -notlike "*NewTerminal-AI*") {
            Add-Content $PROFILE "`n# NewTerminal-AI Integration"
            Add-Content $PROFILE $importLine
            Add-Content $PROFILE "Write-Host 'NewTerminal-AI loaded! Use `'ai <request>`' for commands or `'nl`' for interactive mode.' -ForegroundColor Green"
            
            Write-ColorOutput "[OK] Added NewTerminal-AI to PowerShell profile" -Color "Green"
        } else {
            Write-ColorOutput "[OK] NewTerminal-AI already configured in profile" -Color "Cyan"
        }
        
        # Load the module in current session
        Import-Module "$InstallPath\NewTerminal-AI.psm1" -Force
        Write-ColorOutput "[OK] NewTerminal-AI loaded in current session" -Color "Green"
        
    } catch {
        Write-Error "Failed to set up PowerShell integration: $($_.Exception.Message)"
    }
}

# Test installation
function Test-Installation {
    Write-ColorOutput "Testing installation..." -Color "Yellow"
    
    try {
        # Test Ollama
        if (-not $TestMode) {
            $ollamaTest = & ollama --version 2>$null
            if ($ollamaTest) {
                Write-ColorOutput "[OK] Ollama is working" -Color "Green"
            } else {
                Write-ColorOutput "[WARNING] Ollama test failed" -Color "Yellow"
            }
        }
        
        # Test module import
        $moduleTest = Get-Module NewTerminal-AI -ErrorAction SilentlyContinue
        if ($moduleTest) {
            Write-ColorOutput "[OK] NewTerminal-AI module is loaded" -Color "Green"
        } else {
            Write-ColorOutput "[WARNING] NewTerminal-AI module test failed" -Color "Yellow"
        }
        
    } catch {
        Write-Error "Failed to test installation: $($_.Exception.Message)"
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
    Write-ColorOutput "[SUCCESS] Installation completed successfully!" -Color "Green"
    Write-Host ""
    Write-ColorOutput "Next steps:" -Color "Yellow"
    Write-ColorOutput "1. Restart PowerShell or run: . `$PROFILE" -Color "Cyan"
    Write-ColorOutput "2. Try the commands:" -Color "Cyan"
    Write-ColorOutput "   aia 'list files'     - Auto-execute commands" -Color "Yellow"
    Write-ColorOutput "   ai 'create file test.txt' - Generate with confirmation" -Color "Yellow"
    Write-ColorOutput "   nl                   - Interactive natural language mode" -Color "Yellow"
    Write-Host ""
    Write-ColorOutput "Enjoy your AI-powered terminal!" -Color "Green"
}

# Run main installation
Start-Installation