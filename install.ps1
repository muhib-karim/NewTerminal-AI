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
if ($RAM_GB -lt 4) { $MODEL = "phi-3-mini-4k" }
elseif ($RAM_GB -lt 8) { $MODEL = "llama3.2:3b" }
else { $MODEL = "mistral:7b" }
Write-Host "Selected AI model: $MODEL" -ForegroundColor Cyan

# Pull the model with error handling
Write-Host "Downloading AI model (this may take several minutes)..." -ForegroundColor Cyan
try {
    ollama pull $MODEL
    Write-Host "Model downloaded successfully." -ForegroundColor Green
} catch {
    Write-Host "Error downloading model: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure Ollama is running and try again." -ForegroundColor Yellow
    exit 1
}

# Install shell-genie with error handling
Write-Host "Installing Shell Genie..." -ForegroundColor Cyan
try {
    # Try pip3 first, then pip
    if (Get-Command pip3 -ErrorAction SilentlyContinue) {
        pip3 install --upgrade shell-genie
    } elseif (Get-Command pip -ErrorAction SilentlyContinue) {
        pip install --upgrade shell-genie
    } else {
        throw "Neither pip nor pip3 found in PATH"
    }
    Write-Host "Shell Genie installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error installing Shell Genie: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please install Python 3 and pip, then run: pip install shell-genie" -ForegroundColor Yellow
    exit 1
}
$genieConfig = "$HOME\.config\shell-genie"
New-Item -ItemType Directory -Force -Path $genieConfig | Out-Null
@"
model: $MODEL
provider: ollama
"@ | Out-File -Encoding utf8 "$genieConfig\config.yaml"
$profilePath = $PROFILE
if (!(Test-Path $profilePath)) { New-Item -Type File -Path $profilePath -Force }
Add-Content $profilePath @"
function Invoke-Genie {
    param([string]$Query = $(Read-Host "AI Command"))
    $cmd = genie $Query
    Write-Host "`nSuggested: $cmd"
    $yn = Read-Host "Run this? (y/n)"
    if ($yn -eq "y") { Invoke-Expression $cmd }
}
Set-Alias ai Invoke-Genie
"@
Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host "Usage: ai \"your request\"" -ForegroundColor Cyan
Write-Host "Example: ai \"list all running processes\"" -ForegroundColor Gray
Write-Host "\nRestart your PowerShell session to use the 'ai' command." -ForegroundColor Yellow
