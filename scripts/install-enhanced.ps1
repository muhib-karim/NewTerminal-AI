# Enhanced NewTerminal-AI Installation Script
# Provides system analysis, progress tracking, and intelligent model selection

param(
    [switch]$SkipOllamaInstall,
    [switch]$Verbose
)

# Color scheme for better UX
$Colors = @{
    Header = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
    Progress = 'Magenta'
    Highlight = 'Blue'
}

# Progress tracking variables
$TotalSteps = 8
$CurrentStep = 0
$StartTime = Get-Date

# Function to display progress with ETA
function Show-Progress {
    param(
        [string]$Activity,
        [string]$Status = "",
        [int]$PercentComplete = 0
    )
    
    $script:CurrentStep++
    $ElapsedTime = (Get-Date) - $script:StartTime
    
    if ($script:CurrentStep -gt 1) {
        $EstimatedTotal = $ElapsedTime.TotalSeconds * ($script:TotalSteps / ($script:CurrentStep - 1))
        $RemainingTime = [TimeSpan]::FromSeconds($EstimatedTotal - $ElapsedTime.TotalSeconds)
        $ETA = "ETA: {0:mm\:ss}" -f $RemainingTime
    } else {
        $ETA = "Calculating..."
    }
    
    $ProgressPercent = [math]::Round(($script:CurrentStep / $script:TotalSteps) * 100)
    
    Write-Host "`n[$script:CurrentStep/$script:TotalSteps] $Activity" -ForegroundColor $Colors.Progress
    if ($Status) { Write-Host "    $Status" -ForegroundColor $Colors.Info }
    Write-Host "    Progress: $ProgressPercent% | $ETA" -ForegroundColor $Colors.Highlight
    
    Write-Progress -Activity "NewTerminal-AI Installation" -Status "$Activity - $Status" -PercentComplete $ProgressPercent
}

# Function to detect system specifications
function Get-SystemSpecs {
    Write-Host "`n=== System Analysis ===" -ForegroundColor $Colors.Header
    
    try {
        # CPU Information
        $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
        $CPUName = $CPU.Name.Trim()
        $CPUCores = $CPU.NumberOfCores
        $CPUThreads = $CPU.NumberOfLogicalProcessors
        
        # RAM Information
        $RAM_Bytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
        $RAM_GB = [math]::Round($RAM_Bytes / 1GB, 1)
        
        # GPU Information (if available)
        $GPU = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notlike "*Basic*" } | Select-Object -First 1
        $GPUName = if ($GPU) { $GPU.Name } else { "Integrated Graphics" }
        
        # Storage Information
        $Storage = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $FreeSpace_GB = [math]::Round(($Storage | Measure-Object -Property FreeSpace -Sum).Sum / 1GB, 1)
        
        # OS Information
        $OS = Get-CimInstance Win32_OperatingSystem
        $OSName = $OS.Caption
        $OSVersion = $OS.Version
        
        $SystemInfo = @{
            CPU = @{ Name = $CPUName; Cores = $CPUCores; Threads = $CPUThreads }
            RAM_GB = $RAM_GB
            GPU = $GPUName
            FreeSpace_GB = $FreeSpace_GB
            OS = @{ Name = $OSName; Version = $OSVersion }
        }
        
        # Display system information
        Write-Host "CPU: $CPUName ($CPUCores cores, $CPUThreads threads)" -ForegroundColor $Colors.Info
        Write-Host "RAM: $RAM_GB GB" -ForegroundColor $Colors.Info
        Write-Host "GPU: $GPUName" -ForegroundColor $Colors.Info
        Write-Host "Free Storage: $FreeSpace_GB GB" -ForegroundColor $Colors.Info
        Write-Host "OS: $OSName ($OSVersion)" -ForegroundColor $Colors.Info
        
        return $SystemInfo
    }
    catch {
        Write-Host "Warning: Could not fully detect system specifications" -ForegroundColor $Colors.Warning
        return @{ RAM_GB = 8; CPU = @{ Cores = 4 } }  # Safe defaults
    }
}

# Function to select optimal AI model based on hardware
function Select-OptimalModel {
    param([hashtable]$SystemSpecs)
    
    $RAM_GB = $SystemSpecs.RAM_GB
    $CPUCores = $SystemSpecs.CPU.Cores
    
    Write-Host "`n=== AI Model Selection ===" -ForegroundColor $Colors.Header
    
    # Model selection logic based on available resources
    if ($RAM_GB -ge 16 -and $CPUCores -ge 8) {
        $Model = "mistral:7b"
        $Reason = "High-performance system detected - using advanced 7B model"
    }
    elseif ($RAM_GB -ge 8 -and $CPUCores -ge 4) {
        $Model = "llama3.2:3b"
        $Reason = "Mid-range system detected - using balanced 3B model"
    }
    elseif ($RAM_GB -ge 4) {
        $Model = "phi3:mini"
        $Reason = "Limited resources detected - using efficient mini model"
    }
    else {
        $Model = "tinyllama"
        $Reason = "Very limited resources - using ultra-lightweight model"
    }
    
    Write-Host "Selected Model: $Model" -ForegroundColor $Colors.Success
    Write-Host "Reason: $Reason" -ForegroundColor $Colors.Info
    
    # Estimate download size and time
    $ModelSizes = @{
        "mistral:7b" = 4.1
        "llama3.2:3b" = 2.0
        "phi3:mini" = 2.3
        "tinyllama" = 0.6
    }
    
    $SizeGB = $ModelSizes[$Model]
    Write-Host "Estimated download size: $SizeGB GB" -ForegroundColor $Colors.Info
    
    return @{ Name = $Model; Size = $SizeGB; Reason = $Reason }
}

# Function to check prerequisites
function Test-Prerequisites {
    $Issues = @()
    
    # Check if Ollama is installed
    try {
        $OllamaVersion = ollama --version 2>$null
        if ($OllamaVersion) {
            Write-Host "Ollama is already installed: $OllamaVersion" -ForegroundColor $Colors.Success
            $script:SkipOllamaInstall = $true
        }
    }
    catch {
        if (-not $SkipOllamaInstall) {
            Write-Host "Ollama not found - will install" -ForegroundColor $Colors.Warning
        }
    }
    
    # Check Python installation
    try {
        $PythonVersion = python --version 2>$null
        if ($PythonVersion) {
            Write-Host "Python is installed: $PythonVersion" -ForegroundColor $Colors.Success
        } else {
            $Issues += "Python is not installed or not in PATH"
        }
    }
    catch {
        $Issues += "Python is not installed or not in PATH"
    }
    
    # Check pip installation
    try {
        $PipVersion = pip --version 2>$null
        if ($PipVersion) {
            Write-Host "pip is available" -ForegroundColor $Colors.Success
        } else {
            $Issues += "pip is not available"
        }
    }
    catch {
        $Issues += "pip is not available"
    }
    
    return $Issues
}

# Function to install Ollama (if needed)
function Install-Ollama {
    if ($script:SkipOllamaInstall) {
        Write-Host "Skipping Ollama installation (already installed)" -ForegroundColor $Colors.Info
        return $true
    }
    
    try {
        Write-Host "Downloading Ollama installer..." -ForegroundColor $Colors.Info
        $OllamaUrl = "https://ollama.com/download/OllamaSetup.exe"
        $InstallerPath = "$env:TEMP\OllamaSetup.exe"
        
        # Download with progress
        Invoke-WebRequest -Uri $OllamaUrl -OutFile $InstallerPath -UseBasicParsing
        
        Write-Host "Installing Ollama..." -ForegroundColor $Colors.Info
        Start-Process -FilePath $InstallerPath -Wait -NoNewWindow
        
        # Verify installation
        Start-Sleep -Seconds 3
        $OllamaVersion = ollama --version 2>$null
        if ($OllamaVersion) {
            Write-Host "Ollama installed successfully: $OllamaVersion" -ForegroundColor $Colors.Success
            return $true
        } else {
            throw "Ollama installation verification failed"
        }
    }
    catch {
        Write-Host "Failed to install Ollama: $($_.Exception.Message)" -ForegroundColor $Colors.Error
        Write-Host "Please install Ollama manually from https://ollama.com" -ForegroundColor $Colors.Warning
        return $false
    }
}

# Function to download AI model with progress tracking
function Install-AIModel {
    param([hashtable]$ModelInfo)
    
    try {
        Write-Host "Starting model download: $($ModelInfo.Name)" -ForegroundColor $Colors.Info
        Write-Host "This may take several minutes depending on your internet speed..." -ForegroundColor $Colors.Warning
        
        # Use Invoke-Expression to run ollama pull and capture output
        $Output = & ollama pull $ModelInfo.Name 2>&1
        $ExitCode = $LASTEXITCODE
        
        if ($ExitCode -eq 0 -or $Output -match "success") {
            Write-Host "Model downloaded successfully" -ForegroundColor $Colors.Success
            return $true
        } else {
            throw "Model download failed. Output: $Output"
        }
    }
    catch {
        Write-Host "Failed to download model: $($_.Exception.Message)" -ForegroundColor $Colors.Error
        return $false
    }
}

# Function to install Shell Genie
function Install-ShellGenie {
    try {
        Write-Host "Installing Shell Genie..." -ForegroundColor $Colors.Info
        
        # Try pip install
        $Process = Start-Process -FilePath "pip" -ArgumentList "install", "--upgrade", "shell-genie" -NoNewWindow -PassThru -Wait
        
        if ($Process.ExitCode -eq 0) {
            Write-Host "Shell Genie installed successfully" -ForegroundColor $Colors.Success
            return $true
        } else {
            throw "pip install failed with exit code: $($Process.ExitCode)"
        }
    }
    catch {
        Write-Host "Failed to install Shell Genie: $($_.Exception.Message)" -ForegroundColor $Colors.Error
        Write-Host "Please ensure Python and pip are properly installed" -ForegroundColor $Colors.Warning
        return $false
    }
}

# Function to configure Shell Genie
function Set-GenieConfiguration {
    param([string]$ModelName)
    
    try {
        $ConfigDir = "$HOME\.config\shell-genie"
        New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
        
        $ConfigContent = "model: $ModelName`nprovider: ollama`ntemperature: 0.1`nmax_tokens: 1000"
        
        $ConfigPath = Join-Path $ConfigDir "config.yaml"
        $ConfigContent | Out-File -Encoding UTF8 -FilePath $ConfigPath
        
        Write-Host "Shell Genie configured for model: $ModelName" -ForegroundColor $Colors.Success
        return $true
    }
    catch {
        Write-Host "Failed to configure Shell Genie: $($_.Exception.Message)" -ForegroundColor $Colors.Error
        return $false
    }
}

# Function to setup PowerShell profile
function Set-PowerShellProfile {
    try {
        $ProfilePath = $PROFILE
        
        # Create profile if it doesn't exist
        if (!(Test-Path $ProfilePath)) {
            New-Item -Type File -Path $ProfilePath -Force | Out-Null
        }
        
        # Check if our function already exists
        $ProfileContent = Get-Content $ProfilePath -ErrorAction SilentlyContinue
        if ($ProfileContent -match "Invoke-Genie") {
            Write-Host "PowerShell profile already configured" -ForegroundColor $Colors.Success
            return $true
        }
        
        # Add our enhanced AI function
        $FunctionContent = @'

# NewTerminal-AI Integration
function Invoke-Genie {
    param(
        [string]$Query = $(Read-Host "What would you like me to help you with?")
    )
    
    if ([string]::IsNullOrWhiteSpace($Query)) {
        Write-Host "Please provide a query for the AI assistant." -ForegroundColor Yellow
        return
    }
    
    try {
        Write-Host "Analyzing your request..." -ForegroundColor Cyan
        $cmd = genie $Query
        
        if ([string]::IsNullOrWhiteSpace($cmd)) {
            Write-Host "No command generated. Please try rephrasing your request." -ForegroundColor Red
            return
        }
        
        Write-Host "`nSuggested command:" -ForegroundColor Green
        Write-Host "   $cmd" -ForegroundColor White -BackgroundColor DarkBlue
        
        $confirmation = Read-Host "`nExecute this command? (y/N)"
        if ($confirmation -eq "y" -or $confirmation -eq "Y") {
            Write-Host "Executing..." -ForegroundColor Yellow
            Invoke-Expression $cmd
        } else {
            Write-Host "Command not executed." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Make sure Ollama is running and the AI model is available." -ForegroundColor Yellow
    }
}

# Create aliases for easy access
Set-Alias ai Invoke-Genie
Set-Alias ask Invoke-Genie

# Welcome message (shown once per session)
if (-not $Global:NewTerminalWelcomeShown) {
    Write-Host "NewTerminal-AI is ready! Use 'ai' or 'ask' followed by your request." -ForegroundColor Green
    Write-Host "   Example: ai 'show me running processes'" -ForegroundColor Gray
    $Global:NewTerminalWelcomeShown = $true
}
'@
        
        Add-Content -Path $ProfilePath -Value $FunctionContent
        Write-Host "PowerShell profile configured with AI integration" -ForegroundColor $Colors.Success
        return $true
    }
    catch {
        Write-Host "Failed to configure PowerShell profile: $($_.Exception.Message)" -ForegroundColor $Colors.Error
        return $false
    }
}

# Function to provide post-installation guidance
function Show-PostInstallationGuidance {
    Write-Host "`n=== Installation Complete! ===" -ForegroundColor $Colors.Header
    Write-Host "`nGetting Started:" -ForegroundColor $Colors.Success
    Write-Host "   1. Restart your PowerShell session (or run: . `$PROFILE)" -ForegroundColor $Colors.Info
    Write-Host "   2. Use 'ai' command followed by your request" -ForegroundColor $Colors.Info
    Write-Host "   3. Example: ai 'list all files in current directory'" -ForegroundColor $Colors.Info
    
    Write-Host "`nAvailable Commands:" -ForegroundColor $Colors.Success
    Write-Host "   • ai 'your request'     - Main AI assistant" -ForegroundColor $Colors.Info
    Write-Host "   • ask 'your request'    - Alternative alias" -ForegroundColor $Colors.Info
    
    Write-Host "`nTroubleshooting:" -ForegroundColor $Colors.Success
    Write-Host "   • If AI doesn't respond: Check if Ollama service is running" -ForegroundColor $Colors.Info
    Write-Host "   • For model issues: Run 'ollama list' to see available models" -ForegroundColor $Colors.Info
    Write-Host "   • For help: Visit the project repository or documentation" -ForegroundColor $Colors.Info
    
    Write-Host "`nSystem Integration:" -ForegroundColor $Colors.Success
    Write-Host "   • AI model optimized for your hardware configuration" -ForegroundColor $Colors.Info
    Write-Host "   • Natural language interface for terminal commands" -ForegroundColor $Colors.Info
    Write-Host "   • Safe execution with confirmation prompts" -ForegroundColor $Colors.Info
    
    Write-Host "`nTry these examples:" -ForegroundColor $Colors.Highlight
    Write-Host "   ai 'show system information'" -ForegroundColor $Colors.Info
    Write-Host "   ai 'find large files in downloads folder'" -ForegroundColor $Colors.Info
    Write-Host "   ai 'create a backup of my documents'" -ForegroundColor $Colors.Info
}

# Main installation function
function Start-EnhancedInstallation {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor $Colors.Header
    Write-Host "                    NewTerminal-AI Enhanced Installer            " -ForegroundColor $Colors.Header
    Write-Host "              AI-Powered Natural Language Terminal              " -ForegroundColor $Colors.Header
    Write-Host "================================================================" -ForegroundColor $Colors.Header
    
    # Step 1: System Analysis
    Show-Progress "Analyzing System Configuration" "Detecting hardware specifications..."
    $SystemSpecs = Get-SystemSpecs
    
    # Step 2: Model Selection
    Show-Progress "Selecting Optimal AI Model" "Choosing model based on your hardware..."
    $ModelInfo = Select-OptimalModel -SystemSpecs $SystemSpecs
    
    # Step 3: Prerequisites Check
    Show-Progress "Checking Prerequisites" "Verifying system requirements..."
    $Issues = Test-Prerequisites
    
    if ($Issues.Count -gt 0) {
        Write-Host "`nIssues detected:" -ForegroundColor $Colors.Warning
        foreach ($Issue in $Issues) {
            Write-Host "   • $Issue" -ForegroundColor $Colors.Error
        }
        
        $Continue = Read-Host "`nContinue anyway? (y/N)"
        if ($Continue -ne "y" -and $Continue -ne "Y") {
            Write-Host "Installation cancelled." -ForegroundColor $Colors.Warning
            exit 1
        }
    }
    
    # Step 4: Install Ollama (if needed)
    Show-Progress "Installing Ollama" "Setting up AI model runtime..."
    if (-not (Install-Ollama)) {
        Write-Host "Failed to install Ollama. Installation cannot continue." -ForegroundColor $Colors.Error
        exit 1
    }
    
    # Step 5: Download AI Model
    Show-Progress "Downloading AI Model" "Installing $($ModelInfo.Name) model..."
    if (-not (Install-AIModel -ModelInfo $ModelInfo)) {
        Write-Host "Failed to download AI model. Installation cannot continue." -ForegroundColor $Colors.Error
        exit 1
    }
    
    # Step 6: Install Shell Genie
    Show-Progress "Installing Shell Genie" "Setting up natural language interface..."
    if (-not (Install-ShellGenie)) {
        Write-Host "Failed to install Shell Genie. Installation cannot continue." -ForegroundColor $Colors.Error
        exit 1
    }
    
    # Step 7: Configure Shell Genie
    Show-Progress "Configuring AI Integration" "Setting up model configuration..."
    if (-not (Set-GenieConfiguration -ModelName $ModelInfo.Name)) {
        Write-Host "Failed to configure Shell Genie." -ForegroundColor $Colors.Warning
    }
    
    # Step 8: Setup PowerShell Profile
    Show-Progress "Finalizing Installation" "Configuring PowerShell integration..."
    if (-not (Set-PowerShellProfile)) {
        Write-Host "Failed to configure PowerShell profile." -ForegroundColor $Colors.Warning
    }
    
    # Complete progress
    Write-Progress -Activity "NewTerminal-AI Installation" -Status "Complete" -PercentComplete 100
    
    # Show guidance
    Show-PostInstallationGuidance
    
    # Calculate total installation time
    $TotalTime = (Get-Date) - $StartTime
    $TimeFormatted = "{0:mm\:ss}" -f $TotalTime
    Write-Host "\nTotal installation time: $TimeFormatted" -ForegroundColor $Colors.Highlight
}

# Start the installation
Start-EnhancedInstallation