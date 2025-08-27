Write-Host "=== Installing NewTerminal on Windows ===" -ForegroundColor Green

# Check if running as Administrator for Ollama installation
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Warning: Running without administrator privileges. Ollama installation may require elevation." -ForegroundColor Yellow
}

# Install Ollama with error handling
Write-Host "Installing Ollama..." -ForegroundColor Cyan
try {
    Invoke-WebRequest https://ollama.com/download/OllamaSetup.exe -OutFile "$env:TEMP\OllamaSetup.exe" -ErrorAction Stop
    Start-Process "$env:TEMP\OllamaSetup.exe" -Wait -ErrorAction Stop
    Write-Host "Ollama installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error installing Ollama: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please install Ollama manually from https://ollama.com" -ForegroundColor Yellow
    exit 1
}

# Detect RAM with error handling
try {
    $RAM_GB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    Write-Host "Detected RAM: $RAM_GB GB" -ForegroundColor Cyan
} catch {
    Write-Host "Could not detect RAM. Defaulting to 4GB assumption." -ForegroundColor Yellow
    $RAM_GB = 4
}
if ($RAM_GB -lt 4) { $MODEL = "qwen2.5:0.5b" }
elseif ($RAM_GB -lt 8) { $MODEL = "qwen2.5:0.5b" }
else { $MODEL = "qwen2.5:0.5b" }
Write-Host "Selected AI model: $MODEL" -ForegroundColor Cyan

# Enhanced AI Model Detection and Selection
Write-Host "Scanning for existing AI models..." -ForegroundColor Cyan

# Function to detect available AI models from various providers
function Get-AvailableAIModels {
    $availableModels = @()
    
    # Check Ollama models
    try {
        $ollamaModels = ollama list 2>$null
        if ($ollamaModels) {
            $ollamaModels | ForEach-Object {
                if ($_ -match '^([^\s]+)\s+([^\s]+)\s+([^\s]+)') {
                    $availableModels += @{
                        Name = $matches[1]
                        Provider = "Ollama"
                        Size = $matches[3]
                        ID = $matches[2]
                    }
                }
            }
        }
    } catch { }
    
    # Check LM Studio models (common installation paths)
    $lmStudioPaths = @(
        "$env:USERPROFILE\.cache\lm-studio\models",
        "$env:LOCALAPPDATA\LMStudio\models"
    )
    
    foreach ($path in $lmStudioPaths) {
        if (Test-Path $path) {
            Get-ChildItem $path -Recurse -Filter "*.gguf" | ForEach-Object {
                $availableModels += @{
                    Name = $_.BaseName
                    Provider = "LM Studio"
                    Size = [math]::Round($_.Length / 1GB, 1).ToString() + " GB"
                    Path = $_.FullName
                }
            }
        }
    }
    
    return $availableModels
}

# Get all available models
$availableModels = Get-AvailableAIModels

if ($availableModels.Count -gt 0) {
    Write-Host "Found existing AI models:" -ForegroundColor Green
    $availableModels | ForEach-Object { 
        Write-Host "  - $($_.Name) ($($_.Provider), $($_.Size))" -ForegroundColor Gray 
    }
    
    # Check if our preferred model exists
    $preferredModel = $availableModels | Where-Object { $_.Name -match $MODEL -or $_.Name -match "llama" -or $_.Name -match "mistral" -or $_.Name -match "phi" } | Select-Object -First 1
    
    if ($preferredModel) {
        Write-Host "Using existing model: $($preferredModel.Name) from $($preferredModel.Provider)" -ForegroundColor Green
        $MODEL = $preferredModel.Name
    } else {
        Write-Host "No compatible model found. Downloading $MODEL..." -ForegroundColor Cyan
        try {
            ollama pull $MODEL
            Write-Host "Model downloaded successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error downloading model: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Please ensure Ollama is running and try again." -ForegroundColor Yellow
            exit 1
        }
    }
} else {
    Write-Host "No existing AI models found. Downloading $MODEL..." -ForegroundColor Cyan
    try {
        ollama pull $MODEL
        Write-Host "Model downloaded successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error downloading model: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please ensure Ollama is running and try again." -ForegroundColor Yellow
        exit 1
    }
}

# Setup NewTerminal-AI Custom Module
Write-Host "Setting up NewTerminal-AI custom module..." -ForegroundColor Cyan
try {
    # The module file should already exist in the current directory
    $modulePath = Join-Path $PSScriptRoot "NewTerminal-AI.psm1"
    if (Test-Path $modulePath) {
        Write-Host "NewTerminal-AI module found and ready" -ForegroundColor Green
    } else {
        Write-Host "NewTerminal-AI module not found at $modulePath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error setting up AI module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# Configure NewTerminal-AI module
$aiConfig = "$HOME\.newterminal-ai"
New-Item -ItemType Directory -Force -Path $aiConfig | Out-Null
@"
model: $MODEL
provider: ollama
"@ | Out-File -Encoding utf8 "$aiConfig\config.yaml"

# Configure PowerShell profile for AI integration
Write-Host "⚙️ Configuring PowerShell profile..." -ForegroundColor Yellow

try {
    # Get PowerShell profile path
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path $profilePath -Parent
    
    # Create profile directory if it doesn't exist
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Copy our custom profile
    $customProfilePath = Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1"
    if (Test-Path $customProfilePath) {
        Copy-Item $customProfilePath $profilePath -Force
        Write-Host "✅ PowerShell profile configured with NewTerminal-AI" -ForegroundColor Green
    } else {
        # Fallback: create basic profile content
        $profileContent = @"
# NewTerminal-AI Configuration
`$ModulePath = Join-Path `"$PSScriptRoot`" `"NewTerminal-AI.psm1`"
if (Test-Path `$ModulePath) {
    Import-Module `$ModulePath -Force
} else {
    Write-Warning `"NewTerminal-AI module not found at `$ModulePath`"
}

Write-Host `"🚀 NewTerminal-AI is ready! Use 'ai' or 'ask' followed by your request.`" -ForegroundColor Green
Write-Host `"   Example: ai 'show me running processes'`" -ForegroundColor Gray
"@
        
        $profileContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force
        Write-Host "✅ Basic PowerShell profile configured" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Error configuring PowerShell profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host "Usage: ai \"your request\"" -ForegroundColor Cyan
Write-Host "Example: ai \"list all running processes\"" -ForegroundColor Gray
Write-Host "\nRestart your PowerShell session to use the 'ai' command." -ForegroundColor Yellow
Write-Host "\nNewTerminal-AI is now ready with model: $MODEL" -ForegroundColor Green
