# AI Terminal - Windows Installation Script
# PowerShell installation for Windows users

param(
    [switch]$Force
)

Write-Host "🤖 AI Terminal - Windows Installation" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $Force) {
    Write-Host "⚠️  For best experience, run as Administrator to install system-wide." -ForegroundColor Yellow
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
    Write-Host "❌ PowerShell 5.0 or higher is required." -ForegroundColor Red
    Write-Host "   Please update PowerShell: https://aka.ms/powershell" -ForegroundColor Yellow
    exit 1
}

# Check if Ollama is installed
$ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollamaPath) {
    Write-Host "❌ Ollama is required but not installed." -ForegroundColor Red
    Write-Host "📦 Installing Ollama..." -ForegroundColor Yellow
    
    # Check if winget is available
    $wingetPath = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetPath) {
        try {
            winget install Ollama.Ollama
        } catch {
            Write-Host "❌ Failed to install via winget. Please install manually:" -ForegroundColor Red
            Write-Host "   https://ollama.ai/download/windows" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "❌ Please install Ollama manually from: https://ollama.ai/download/windows" -ForegroundColor Red
        Write-Host "   Then run this script again." -ForegroundColor Yellow
        exit 1
    }
    
    # Refresh PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# Start Ollama service
Write-Host "🚀 Starting Ollama service..." -ForegroundColor Cyan
try {
    $ollamaProcess = Get-Process ollama -ErrorAction SilentlyContinue
    if (-not $ollamaProcess) {
        Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 3
    }
} catch {
    Write-Host "⚠️  Could not start Ollama service automatically." -ForegroundColor Yellow
    Write-Host "   Please start Ollama manually before using AI Terminal." -ForegroundColor Gray
}

# Pull required model
Write-Host "📥 Downloading AI model (llama3.2:3b)..." -ForegroundColor Cyan
try {
    & ollama pull llama3.2:3b
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to pull model"
    }
} catch {
    Write-Host "❌ Failed to download AI model. Please run 'ollama pull llama3.2:3b' manually." -ForegroundColor Red
}

# Determine installation path
if ($isAdmin -and -not $Force) {
    $modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\AITerminal"
    $scope = "AllUsers"
} else {
    $modulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\AITerminal"
    $scope = "CurrentUser"
}

# Create module directory
Write-Host "📦 Installing AI Terminal module to $scope..." -ForegroundColor Cyan
if (-not (Test-Path $modulePath)) {
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
}

# Copy module file
$sourceModule = Join-Path $PSScriptRoot "NewTerminal-AI.psm1"
if (Test-Path $sourceModule) {
    Copy-Item $sourceModule -Destination (Join-Path $modulePath "AITerminal.psm1") -Force
} else {
    Write-Host "❌ Source module not found: $sourceModule" -ForegroundColor Red
    exit 1
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
    FunctionsToExport = @('Start-AITerminal', 'Invoke-AICommand')
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
$importLine = "Import-Module AITerminal -Force"
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
    $shortcut.Arguments = "-NoExit -Command `"Import-Module AITerminal -Force`""
    $shortcut.Description = "AI Terminal - Natural Language Interface"
    $shortcut.IconLocation = "powershell.exe,0"
    $shortcut.Save()
}

Write-Host ""
Write-Host "✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Usage:" -ForegroundColor Yellow
Write-Host "   • Open a new PowerShell window (AI Terminal will auto-start)" -ForegroundColor Cyan
Write-Host "   • Or use the desktop shortcut 'AI Terminal'" -ForegroundColor Cyan
Write-Host "   • Or run: Import-Module AITerminal" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 The AI Terminal starts automatically in natural language mode." -ForegroundColor Green
Write-Host "   Just describe what you want to do in plain English!" -ForegroundColor Green
Write-Host ""
Write-Host "Examples:" -ForegroundColor Yellow
Write-Host "   'list all files in this directory'" -ForegroundColor Gray
Write-Host "   'show my git status'" -ForegroundColor Gray
Write-Host "   'create a new folder called projects'" -ForegroundColor Gray