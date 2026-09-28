# AI Terminal - Windows Installation Script
# PowerShell installation for Windows users

param(
    [switch]$Force
)

Write-Host "AI Terminal - Windows Installation" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $Force) {
    Write-Host "[WARN] For best experience, run as Administrator to install system-wide." -ForegroundColor Yellow
    Write-Host "   Use -Force to install for current user only." -ForegroundColor Gray
    Write-Host ""
    $choice = Read-Host "Continue with user installation? [y/N]"
    if ($choice.ToLower() -ne 'y') {
        Write-Host "Installation cancelled. Run as Administrator or use -Force flag." -ForegroundColor Red
        exit 1
    }
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERROR] PowerShell 5.0 or higher is required." -ForegroundColor Red
    Write-Host "   Please update PowerShell: https://aka.ms/powershell" -ForegroundColor Yellow
    exit 1
}

# Check if Ollama is installed
$ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollamaPath) {
    Write-Host "[ERROR] Ollama is required but not installed." -ForegroundColor Red
    Write-Host "[*] Installing Ollama..." -ForegroundColor Yellow
    
    # Check if winget is available
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetPath) {
        try {
            winget install Ollama.Ollama
        } catch {
            Write-Host "[ERROR] Failed to install via winget. Please install manually:" -ForegroundColor Red
            Write-Host "   https://ollama.ai/download/windows" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "[ERROR] Please install Ollama manually from: https://ollama.ai/download/windows" -ForegroundColor Red
        Write-Host "   Then run this script again." -ForegroundColor Yellow
        exit 1
    }
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# Start Ollama service
Write-Host "[*] Starting Ollama service..." -ForegroundColor Cyan
try {
    $ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
    if (-not $ollamaProcess) {
        Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 3
    }
} catch {
    Write-Host "[WARN] Could not start Ollama service automatically." -ForegroundColor Yellow
    Write-Host "   Please start Ollama manually before using AI Terminal." -ForegroundColor Gray
}

# Pull required model
Write-Host "[*] Downloading AI model (llama3.2:3b)..." -ForegroundColor Cyan
try {
    & ollama pull llama3.2:3b
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to pull model"
    }
} catch {
    Write-Host "[ERROR] Failed to download AI model. Please run 'ollama pull llama3.2:3b' manually." -ForegroundColor Red
}

# Determine installation path (PowerShell 7 does not search the Windows PowerShell user module folder)
$psFolder = if ($PSVersionTable.PSEdition -eq 'Core') { 'PowerShell' } else { 'WindowsPowerShell' }
if ($isAdmin -and -not $Force) {
    $modulePath = "$env:ProgramFiles\$psFolder\Modules\AITerminal"
    $scope = "AllUsers"
} else {
    $modulePath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "$psFolder\Modules\AITerminal"
    $scope = "CurrentUser"
}

# Create module directory
Write-Host "[*] Installing AI Terminal module to $scope..." -ForegroundColor Cyan
if (-not (Test-Path $modulePath)) {
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
}

# Copy module file. When run via "irm | iex" $PSScriptRoot is empty, so download the module instead.
$moduleUrl = "https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/NewTerminal-AI.psm1"
$sourceModule = if ($PSScriptRoot) { Join-Path $PSScriptRoot "NewTerminal-AI.psm1" } else { $null }
if ($sourceModule -and (Test-Path $sourceModule)) {
    Copy-Item $sourceModule -Destination (Join-Path $modulePath "AITerminal.psm1") -Force
} else {
    try {
        Invoke-WebRequest -Uri $moduleUrl -OutFile (Join-Path $modulePath "AITerminal.psm1") -UseBasicParsing
    } catch {
        Write-Host "[ERROR] Could not find or download the module ($moduleUrl): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Create module manifest
$manifestPath = Join-Path $modulePath "AITerminal.psd1"
$manifestContent = @"
@{
    RootModule = 'AITerminal.psm1'
    ModuleVersion = '2.1.0'
    GUID = '$(New-Guid)'
    Author = 'AI Terminal Team'
    Description = 'Natural Language AI Terminal - Convert plain English to CLI commands'
    PowerShellVersion = '5.0'
    FunctionsToExport = @('Invoke-AICommand', 'Invoke-AICommandAuto', 'Start-NLMode', 'Start-AITerminal', 'Test-OllamaConnection', 'Show-CommandHistory', 'Clear-CommandHistory', 'Get-ContextInfo', 'Add-ToHistory', 'Show-ThinkingAnimation')
    AliasesToExport = @('ai', 'aia', 'nl')
}
"@

$manifestContent | Out-File -FilePath $manifestPath -Encoding UTF8

# Update PowerShell profile
$profilePath = $PROFILE.CurrentUserAllHosts
if (-not $profilePath) {
    $profilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
}

$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Add auto-import to profile
$importLine = "Import-Module AITerminal"
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    if ($profileContent -notmatch [regex]::Escape($importLine)) {
        Add-Content -Path $profilePath -Value "`n# AI Terminal Auto-Load`n$importLine"
    }
} else {
    "# AI Terminal Auto-Load`n$importLine" | Out-File -FilePath $profilePath -Encoding UTF8
}

# Create desktop shortcut
if ($isAdmin -or $Force) {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "AI Terminal.lnk"
    
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoExit -Command `"Import-Module AITerminal`""
    $shortcut.Description = "AI Terminal - Natural Language Interface"
    $shortcut.IconLocation = "powershell.exe,0"
    $shortcut.Save()
}

Write-Host ""
Write-Host "[OK] Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "[*] Usage:" -ForegroundColor Yellow
Write-Host "   - Open a new PowerShell window (AI Terminal will auto-start)" -ForegroundColor Cyan
Write-Host "   - Or use the desktop shortcut 'AI Terminal'" -ForegroundColor Cyan
Write-Host "   - Or run: Import-Module AITerminal" -ForegroundColor Cyan
Write-Host ""
Write-Host "The AI Terminal starts automatically in natural language mode." -ForegroundColor Green
Write-Host "   Just describe what you want to do in plain English!" -ForegroundColor Green
Write-Host ""
Write-Host "Examples:" -ForegroundColor Yellow
Write-Host "   'list all files in this directory'" -ForegroundColor Gray
Write-Host "   'show my git status'" -ForegroundColor Gray
Write-Host "   'create a new folder called projects'" -ForegroundColor Gray