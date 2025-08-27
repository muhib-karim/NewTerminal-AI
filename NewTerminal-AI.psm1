# NewTerminal-AI PowerShell Module
# A native AI-powered terminal assistant using Ollama

# Configuration
$script:OllamaBaseUrl = "http://localhost:11434"
$script:DefaultModel = "qwen2.5:0.5b"
$script:MaxRetries = 3
$script:TimeoutSeconds = 30

# Enhanced Model Management Configuration
$script:OptimalModels = @(
    @{ Name = "qwen2.5:0.5b"; Size = "0.5B"; Speed = "Fast"; Quality = "Good"; Recommended = $true },
    @{ Name = "llama3.2:1b"; Size = "1B"; Speed = "Fast"; Quality = "Better"; Recommended = $true },
    @{ Name = "phi3:mini"; Size = "3.8B"; Speed = "Medium"; Quality = "Excellent"; Recommended = $false },
    @{ Name = "gemma2:2b"; Size = "2B"; Speed = "Fast"; Quality = "Very Good"; Recommended = $true }
)
$script:ModelInstallationPath = "$env:USERPROFILE\.ollama\models"
$script:MinimumDiskSpaceGB = 5

# ANSI Color Codes for better UX
$script:Colors = @{
    Green = "`e[32m"
    Yellow = "`e[33m"
    Red = "`e[31m"
    Blue = "`e[34m"
    Cyan = "`e[36m"
    Magenta = "`e[35m"
    Reset = "`e[0m"
    Bold = "`e[1m"
}

# System Information Cache
$script:SystemInfo = @{
    OS = (Get-CimInstance Win32_OperatingSystem).Caption
    Shell = "PowerShell $($PSVersionTable.PSVersion)"
    Architecture = $env:PROCESSOR_ARCHITECTURE
    UserName = $env:USERNAME
    ComputerName = $env:COMPUTERNAME
}

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "Reset"
    )
    Write-Host "$($script:Colors[$Color])$Text$($script:Colors.Reset)" -NoNewline
}

function Write-AIResponse {
    param([string]$Message, [string]$Type = "Info")
    
    $icon = switch ($Type) {
        "Success" { "[OK]" }
        "Warning" { "[WARN]" }
        "Error" { "[ERROR]" }
        "Info" { "[AI]" }
        "Command" { "[CMD]" }
        default { "[INFO]" }
    }
    
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Info" { "Cyan" }
        "Command" { "Magenta" }
        default { "Blue" }
    }
    
    Write-ColorText "$icon " $color
    Write-ColorText $Message $color
    Write-Host
}

function Write-ProgressStatus {
    <#
    .SYNOPSIS
    Displays enhanced progress indicators with icons and colors
    
    .DESCRIPTION
    Provides clear visual feedback for operations with consistent formatting
    
    .PARAMETER Message
    The message to display
    
    .PARAMETER Type
    The type of status (Info, Success, Warning, Error, Progress, Complete)
    
    .PARAMETER ShowTime
    Whether to include timestamp in the output
    #>
    param(
        [string]$Message,
        [string]$Type = "Info",
        [switch]$ShowTime
    )
    
    $timestamp = if ($ShowTime) { "[$(Get-Date -Format 'HH:mm:ss')] " } else { "" }
    
    $icon = switch ($Type) {
         "Success" { "[+]" }
         "Warning" { "[!]" }
         "Error" { "[X]" }
         "Progress" { "[>]" }
         "Complete" { "[*]" }
         "Download" { "[v]" }
         "Install" { "[#]" }
         "Check" { "[?]" }
         "Config" { "[=]" }
         "Info" { "[i]" }
         default { "[*]" }
     }
    
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Progress" { "Blue" }
        "Complete" { "Green" }
        "Download" { "Cyan" }
        "Install" { "Magenta" }
        "Check" { "Yellow" }
        "Config" { "Blue" }
        "Info" { "Cyan" }
        default { "Blue" }
    }
    
    Write-ColorText "$timestamp$icon " $color
    Write-ColorText $Message $color
    Write-Host
}

function Show-ProgressBar {
    <#
    .SYNOPSIS
    Displays a simple text-based progress bar
    
    .PARAMETER Percent
    Progress percentage (0-100)
    
    .PARAMETER Width
    Width of the progress bar in characters
    
    .PARAMETER Message
    Optional message to display with the progress bar
    #>
    param(
        [int]$Percent,
        [int]$Width = 40,
        [string]$Message = ""
    )
    
    $filled = [math]::Floor($Width * $Percent / 100)
    $empty = $Width - $filled
    
    $bar = "[" + ("█" * $filled) + ("-" * $empty) + "]"
    $percentText = "$Percent%".PadLeft(4)
    
    Write-ColorText "$bar " "Cyan"
    Write-ColorText $percentText "White"
    if ($Message) {
        Write-ColorText " $Message" "Blue"
    }
    
    Write-Host "`r" -NoNewline
    
    if ($Percent -eq 100) {
        Write-Host "" # New line when complete
    }
}

function Test-OllamaConnection {
    try {
        $response = Invoke-RestMethod -Uri "$script:OllamaBaseUrl/api/tags" -Method Get -TimeoutSec 5
        return $response.models.Count -gt 0
    }
    catch {
        return $false
    }
}

function Get-OllamaModels {
    try {
        $response = Invoke-RestMethod -Uri "$script:OllamaBaseUrl/api/tags" -Method Get -TimeoutSec 10
        return $response.models | ForEach-Object { $_.name }
    }
    catch {
        Write-AIResponse "Failed to fetch available models: $($_.Exception.Message)" "Error"
        return @()
    }
}

# Enhanced Model Detection and Management Functions
function Test-SystemRequirements {
    param([switch]$Detailed)
    
    $requirements = @{
        OllamaInstalled = $false
        OllamaRunning = $false
        SufficientDiskSpace = $false
        SufficientMemory = $false
        OptimalModelPresent = $false
        Details = @{}
    }
    
    # Check if Ollama is installed
    try {
        $ollamaPath = Get-Command ollama -ErrorAction SilentlyContinue
        $requirements.OllamaInstalled = $null -ne $ollamaPath
        if ($Detailed) { $requirements.Details.OllamaPath = $ollamaPath.Source }
    } catch {
        Write-AIResponse "Error running performance optimization: $($_.Exception.Message)" "Error"
    }
    
    # Check if Ollama is running
    $requirements.OllamaRunning = Test-OllamaConnection
    
    # Check disk space
    try {
        $drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
        $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $requirements.SufficientDiskSpace = $freeSpaceGB -ge $script:MinimumDiskSpaceGB
        if ($Detailed) { $requirements.Details.FreeSpaceGB = $freeSpaceGB }
    } catch { }
    
    # Check memory
    try {
        $memory = Get-WmiObject -Class Win32_ComputerSystem
        $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        $requirements.SufficientMemory = $totalMemoryGB -ge 4
        if ($Detailed) { $requirements.Details.TotalMemoryGB = $totalMemoryGB }
    } catch { }
    
    # Check for optimal models
    if ($requirements.OllamaRunning) {
        $installedModels = Get-OllamaModels
        $optimalModelNames = $script:OptimalModels | Where-Object { $_.Recommended } | ForEach-Object { $_.Name }
        $requirements.OptimalModelPresent = ($installedModels | Where-Object { $_ -in $optimalModelNames }).Count -gt 0
        if ($Detailed) { 
            $requirements.Details.InstalledModels = $installedModels
            $requirements.Details.RecommendedModels = $optimalModelNames
        }
    }
    
    return $requirements
}

function Install-OptimalModel {
    <#
    .SYNOPSIS
    Installs an optimal AI model for NewTerminal-AI
    
    .DESCRIPTION
    Downloads and installs a recommended AI model based on system capabilities
    with enhanced progress feedback
    
    .PARAMETER PreferredModel
    Specific model to install (optional, will auto-select if not provided)
    
    .PARAMETER Force
    Force installation even if a model already exists
    
    .PARAMETER Quiet
    Run installation silently without progress output
    
    .EXAMPLE
    Install-OptimalModel
    
    .EXAMPLE
    Install-OptimalModel -PreferredModel "llama3.2:1b" -Force
    #>
    param(
        [string]$PreferredModel = "",
        [switch]$Force,
        [switch]$Quiet
    )
    
    if (-not $Quiet) {
        Write-ProgressStatus "Starting optimal model installation process..." "Install" -ShowTime
    }
    
    # Step 1: Check system requirements
    if (-not $Quiet) {
        Write-ProgressStatus "Checking system requirements..." "Check"
    }
    $sysReq = Test-SystemRequirements -Detailed
    
    if (-not $sysReq.OllamaInstalled) {
        Write-AIResponse "Ollama is not installed. Please install Ollama first from https://ollama.ai" "Error"
        return $false
    }
    
    # Step 2: Check Ollama service
    if (-not $sysReq.OllamaRunning) {
        if (-not $Quiet) {
            Write-ProgressStatus "Ollama not running. Starting service..." "Progress"
        }
        try {
            Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
            
            # Show progress while waiting for service to start
            if (-not $Quiet) {
                for ($i = 1; $i -le 3; $i++) {
                    Show-ProgressBar -Percent ($i * 33) -Message "Starting Ollama service..."
                    Start-Sleep -Seconds 1
                }
                Show-ProgressBar -Percent 100 -Message "Service started"
            } else {
                Start-Sleep -Seconds 3
            }
            
            if (-not (Test-OllamaConnection)) {
                Write-AIResponse "Failed to start Ollama service" "Error"
                return $false
            }
            if (-not $Quiet) {
                Write-ProgressStatus "Ollama service started successfully" "Success"
            }
        } catch {
            Write-AIResponse "Failed to start Ollama: $($_.Exception.Message)" "Error"
            return $false
        }
    } else {
        if (-not $Quiet) {
            Write-ProgressStatus "Ollama service is running" "Success"
        }
    }
    
    if (-not $sysReq.SufficientDiskSpace) {
        Write-AIResponse "Insufficient disk space. Need at least $($script:MinimumDiskSpaceGB)GB free" "Error"
        return $false
    }
    
    # Step 3: Check existing models
    if (-not $Quiet) {
        Write-ProgressStatus "Scanning for existing models..." "Check"
    }
    if (-not $Force) {
        $currentModels = Get-OllamaModels
        if ($currentModels -and $currentModels.Count -gt 0) {
            # Check if we have an optimal model
            $optimalFound = $false
            $optimalModelNames = $script:OptimalModels | Where-Object { $_.Recommended } | ForEach-Object { $_.Name }
            foreach ($model in $currentModels) {
                if ($model -in $optimalModelNames) {
                    if (-not $Quiet) {
                        Write-ProgressStatus "Optimal model already installed: $model" "Success"
                    }
                    $optimalFound = $true
                    break
                }
            }
            
            if ($optimalFound -and [string]::IsNullOrEmpty($PreferredModel)) {
                if (-not $Quiet) {
                    Write-ProgressStatus "Installation skipped - optimal model already present. Use -Force to reinstall." "Complete"
                }
                return $true
            }
        }
    }
    
    # Step 4: Determine best model to install
    $targetModel = $PreferredModel
    if ([string]::IsNullOrEmpty($targetModel)) {
        if (-not $Quiet) {
            Write-ProgressStatus "Auto-selecting optimal model based on system..." "Config"
        }
        
        # Enhanced system capability detection
        try {
            $memory = Get-WmiObject -Class Win32_ComputerSystem
            $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
            
            if ($totalMemoryGB -ge 16) {
                 $targetModel = "phi3:mini"  # Best quality for high-memory systems
                 if (-not $Quiet) {
                     Write-ProgressStatus "High memory detected ($totalMemoryGB GB) - selected: $targetModel" "Config"
                 }
             } elseif ($totalMemoryGB -ge 8) {
                 $targetModel = "llama3.2:1b"  # Balanced for medium-memory systems
                 if (-not $Quiet) {
                     Write-ProgressStatus "Medium memory detected ($totalMemoryGB GB) - selected: $targetModel" "Config"
                 }
             } else {
                 $recommendedModels = $script:OptimalModels | Where-Object { $_.Recommended } | Sort-Object { $_.Size }
                 $targetModel = $recommendedModels[0].Name
                 if (-not $Quiet) {
                     Write-ProgressStatus "Lower memory detected ($totalMemoryGB GB) - selected: $targetModel" "Config"
                 }
             }
        } catch {
            $recommendedModels = $script:OptimalModels | Where-Object { $_.Recommended } | Sort-Object { $_.Size }
            $targetModel = $recommendedModels[0].Name
            if (-not $Quiet) {
                Write-ProgressStatus "Could not detect system specs - using safe default: $targetModel" "Config"
            }
        }
    } else {
        if (-not $Quiet) {
            Write-ProgressStatus "Using specified model: $targetModel" "Config"
        }
    }
    
    # Step 5: Download and install model
    if (-not $Quiet) {
        Write-ProgressStatus "Downloading model: $targetModel" "Download"
        Write-ProgressStatus "This may take several minutes depending on your internet connection..." "Info"
    }
    
    # Install the model
    try {
        # Start the installation process
        $installProcess = Start-Process "ollama" -ArgumentList "pull", $targetModel -PassThru -NoNewWindow
        
        # Show progress animation while downloading
        if (-not $Quiet) {
            $progressChars = @('|', '/', '-', '\\')
            $charIndex = 0
            
            while (-not $installProcess.HasExited) {
                $char = $progressChars[$charIndex % $progressChars.Length]
                Write-Host "`r$($script:Colors.Cyan)[$char]$($script:Colors.Reset) Downloading $targetModel..." -NoNewline
                Start-Sleep -Milliseconds 500
                $charIndex++
            }
            
            Write-Host "" # New line
        } else {
            $installProcess.WaitForExit()
        }
        
        if ($installProcess.ExitCode -eq 0) {
            if (-not $Quiet) {
                Write-ProgressStatus "Successfully downloaded model: $targetModel" "Success"
                
                # Step 6: Test the installed model
                Write-ProgressStatus "Testing installed model..." "Check"
                
                # Show test progress
                for ($i = 1; $i -le 3; $i++) {
                    Show-ProgressBar -Percent ($i * 33) -Message "Running model test..."
                    Start-Sleep -Milliseconds 500
                }
                Show-ProgressBar -Percent 100 -Message "Test complete"
            }
            
            # Test the model
            try {
                $testResult = Invoke-OllamaAPI -Prompt "Hello" -Model $targetModel
                if ($testResult) {
                    if (-not $Quiet) {
                        Write-ProgressStatus "Model installation and test completed successfully!" "Complete"
                        Write-ProgressStatus "Model '$targetModel' is ready for use" "Success"
                    }
                    $script:DefaultModel = $targetModel
                    return $true
                } else {
                    Write-AIResponse "Model installed but test failed" "Warning"
                    $script:DefaultModel = $targetModel
                    return $false
                }
            } catch {
                Write-AIResponse "Model installed but test failed: $($_.Exception.Message)" "Warning"
                $script:DefaultModel = $targetModel
                return $false
            }
        } else {
            Write-AIResponse "Failed to install model: $targetModel (Exit code: $($installProcess.ExitCode))" "Error"
            return $false
        }
    } catch {
        Write-AIResponse "Error during model installation: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Optimize-ModelConfiguration {
    param([switch]$RemoveOutdated)
    
    Write-AIResponse "Analyzing current model configuration..." "Info"
    
    $installedModels = Get-OllamaModels
    $optimalModelNames = $script:OptimalModels | ForEach-Object { $_.Name }
    
    # Identify outdated or suboptimal models
    $outdatedModels = $installedModels | Where-Object { 
        $_ -notin $optimalModelNames -and 
        ($_ -like "*:latest" -or $_ -like "*:7b" -or $_ -like "*:13b" -or $_ -like "*:70b")
    }
    
    if ($outdatedModels.Count -gt 0) {
        Write-AIResponse "Found potentially outdated models: $($outdatedModels -join ', ')" "Warning"
        
        if ($RemoveOutdated) {
            foreach ($model in $outdatedModels) {
                Write-AIResponse "Removing outdated model: $model" "Info"
                try {
                    $removeProcess = Start-Process "ollama" -ArgumentList "rm", $model -Wait -PassThru -NoNewWindow
                    if ($removeProcess.ExitCode -eq 0) {
                        Write-AIResponse "Removed: $model" "Success"
                    }
                } catch {
                    Write-AIResponse "Failed to remove $model`: $($_.Exception.Message)" "Warning"
                }
            }
        } else {
            Write-AIResponse "Use -RemoveOutdated to automatically remove these models" "Info"
        }
    }
    
    # Check if we have at least one optimal model
    $hasOptimalModel = ($installedModels | Where-Object { $_ -in ($script:OptimalModels | Where-Object { $_.Recommended } | ForEach-Object { $_.Name }) }).Count -gt 0
    
    if (-not $hasOptimalModel) {
        Write-AIResponse "No optimal models found. Installing recommended model..." "Warning"
        Install-OptimalModel
    } else {
        Write-AIResponse "Model configuration is optimal" "Success"
    }
}

function Start-AutoSetup {
    param([switch]$Force)
    
    Write-AIResponse "NewTerminal AI Auto-Setup Starting..." "Info"
    Write-AIResponse "Scanning system configuration..." "Info"
    
    $requirements = Test-SystemRequirements -Detailed
    
    # Display system status
    Write-AIResponse "System Requirements Check:" "Info"
    Write-Host "  Ollama Installed: $(if($requirements.OllamaInstalled){'✓'}else{'✗'})" -ForegroundColor $(if($requirements.OllamaInstalled){'Green'}else{'Red'})
    Write-Host "  Ollama Running: $(if($requirements.OllamaRunning){'✓'}else{'✗'})" -ForegroundColor $(if($requirements.OllamaRunning){'Green'}else{'Red'})
    Write-Host "  Sufficient Disk Space: $(if($requirements.SufficientDiskSpace){'✓'}else{'✗'})" -ForegroundColor $(if($requirements.SufficientDiskSpace){'Green'}else{'Red'})
    Write-Host "  Sufficient Memory: $(if($requirements.SufficientMemory){'✓'}else{'✗'})" -ForegroundColor $(if($requirements.SufficientMemory){'Green'}else{'Red'})
    Write-Host "  Optimal Model Present: $(if($requirements.OptimalModelPresent){'✓'}else{'✗'})" -ForegroundColor $(if($requirements.OptimalModelPresent){'Green'}else{'Red'})
    Write-Host
    
    # Auto-fix issues
    $needsSetup = -not ($requirements.OllamaRunning -and $requirements.OptimalModelPresent)
    
    if ($needsSetup -or $Force) {
        if (-not $requirements.OptimalModelPresent) {
            Write-AIResponse "Setting up optimal AI model for best performance..." "Info"
            $success = Install-OptimalModel
            if ($success) {
                Write-AIResponse "Auto-setup completed successfully!" "Success"
                Write-AIResponse "NewTerminal AI is ready to use. Type 'warp' to start!" "Success"
            } else {
                Write-AIResponse "Auto-setup encountered issues. Please check the errors above." "Warning"
            }
        } else {
            Write-AIResponse "Optimizing existing model configuration..." "Info"
            Optimize-ModelConfiguration
        }
    } else {
        Write-AIResponse "System is already optimally configured!" "Success"
        Write-AIResponse "NewTerminal AI is ready to use. Type 'warp' to start!" "Success"
    }
}

function Invoke-OllamaAPI {
    param(
        [string]$Prompt,
        [string]$Model = $script:DefaultModel,
        [string]$SystemPrompt = ""
    )
    
    $body = @{
        model = $Model
        prompt = $Prompt
        stream = $false
        options = @{
            temperature = 0.1
            top_p = 0.9
            max_tokens = 1000
        }
    }
    
    if ($SystemPrompt) {
        $body.system = $SystemPrompt
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$script:OllamaBaseUrl/api/generate" -Method Post -Body ($body | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec $script:TimeoutSeconds
        return $response.response
    }
    catch {
        throw "Ollama API Error: $($_.Exception.Message)"
    }
}

function Get-SystemContext {
    $currentPath = Get-Location
    $recentFiles = Get-ChildItem -Path $currentPath -File | Select-Object -First 5 | ForEach-Object { $_.Name }
    $runningProcesses = Get-Process | Select-Object -First 10 | ForEach-Object { $_.ProcessName }
    
    $contextInfo = "Current System Context:`n"
    $contextInfo += "Operating System: $($script:SystemInfo.OS)`n"
    $contextInfo += "Shell: $($script:SystemInfo.Shell)`n"
    $contextInfo += "Current Directory: $currentPath`n"
    $contextInfo += "Recent Files: $($recentFiles -join ', ')`n"
    $contextInfo += "Top Processes: $($runningProcesses -join ', ')`n"
    $contextInfo += "User: $($script:SystemInfo.UserName)@$($script:SystemInfo.ComputerName)"
    
    return $contextInfo
}

function Get-CommandSuggestion {
    param(
        [string]$UserRequest,
        [switch]$IncludeExplanation
    )
    
    $systemPrompt = @"
You are an expert PowerShell and Windows command-line assistant. Your job is to generate ONLY the exact command(s) that should be executed to fulfill the user's request.

IMPORTANT RULES:
1. Return ONLY the command(s) to execute, nothing else
2. Use PowerShell syntax when possible
3. For multiple commands, separate with semicolons or use pipeline
4. Ensure commands are safe and won't cause system damage
5. Use full parameter names when clarity is important
6. If the request is unclear, provide the most likely interpretation

System Information:
$($script:SystemInfo.OS)
Shell: $($script:SystemInfo.Shell)
Current User: $($script:SystemInfo.UserName)

Current Context:
$(Get-SystemContext)
"@
    
    if ($IncludeExplanation) {
        $systemPrompt += "

For this request, provide the command followed by a brief explanation in this format:
COMMAND: [exact command here]
EXPLANATION: [brief explanation]"
    }
    
    try {
        $response = Invoke-OllamaAPI -Prompt $UserRequest -SystemPrompt $systemPrompt
        return $response.Trim()
    }
    catch {
        throw "Failed to generate command suggestion: $($_.Exception.Message)"
    }
}

function Test-CommandSafety {
    param([string]$Command)
    
    $dangerousPatterns = @(
        'rm\s+-rf\s+/',
        'del\s+/s\s+/q\s+c:\\',
        'format\s+c:',
        'shutdown\s+/s',
        'reg\s+delete.*HKLM',
        'Remove-Item.*-Recurse.*-Force.*C:\\',
        'Stop-Computer',
        'Restart-Computer'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Command -match $pattern) {
            return $false
        }
    }
    
    return $true
}

# Natural Language Processing Function
function Start-NaturalLanguageMode {
    Write-AIResponse "Natural Language Mode Activated!" "Success"
    Write-AIResponse "Type naturally - no quotes needed! Type 'exit-nl' to return to normal mode." "Info"
    Write-Host
    
    while ($true) {
        Write-Host "$(Get-Location)> " -NoNewline -ForegroundColor Green
        $input = Read-Host
        
        if ($input -eq "exit-nl" -or $input -eq "exit") {
            Write-AIResponse "Exiting Natural Language Mode" "Info"
            break
        }
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            continue
        }
        
        # Check if it's a standard PowerShell command first
        $isStandardCommand = $false
        try {
            $command = Get-Command $input.Split(' ')[0] -ErrorAction SilentlyContinue
            if ($command) {
                $isStandardCommand = $true
            }
        }
        catch { }
        
        if ($isStandardCommand) {
            # Execute standard PowerShell command
            try {
                Invoke-Expression $input
            }
            catch {
                Write-AIResponse "Error: $($_.Exception.Message)" "Error"
            }
        }
        else {
            # Process as natural language
            Process-NaturalLanguageInput -UserInput $input -AutoExecute
        }
        
        Write-Host
    }
}

# Warp AI-style natural language to command conversion with immediate execution
function Convert-NaturalLanguageToCommand {
    param([string]$UserInput)
    
    try {
        # Show thinking indicator (like Warp AI)
        Write-Host "🤔 " -NoNewline -ForegroundColor Yellow
        Write-Host "Converting..." -NoNewline -ForegroundColor Gray
        
        # Get command suggestion from AI
        $suggestion = Get-CommandSuggestion -UserInput $UserInput
        
        if ($suggestion) {
            # Clear the thinking line and show the command
            Write-Host "`r" -NoNewline
            Write-Host "💡 " -NoNewline -ForegroundColor Green
            Write-Host $suggestion -ForegroundColor Cyan
            
            # Execute immediately if safe (Warp AI style)
            if (Test-CommandSafety -Command $suggestion) {
                try {
                    # Execute the command
                    Invoke-Expression $suggestion
                }
                catch {
                    Write-Host "❌ Execution failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            else {
                Write-Host "⚠️  Command flagged as potentially unsafe - skipped execution" -ForegroundColor Yellow
                Write-Host "   Generated: $suggestion" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "`r" -NoNewline
            Write-Host "❓ Could not understand: '$UserInput'" -ForegroundColor Red
            Write-Host "   Try rephrasing your request" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "`r" -NoNewline
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Process-NaturalLanguageInput {
    param(
        [string]$UserInput,
        [switch]$AutoExecute
    )
    
    # Determine if this is a question or a command request
    $questionWords = @('what', 'how', 'why', 'when', 'where', 'who', 'explain', 'tell me', 'help me understand')
    $isQuestion = $false
    
    foreach ($word in $questionWords) {
        if ($UserInput.ToLower().Contains($word.ToLower())) {
            $isQuestion = $true
            break
        }
    }
    
    if ($isQuestion) {
        # Process as a question
        Write-AIResponse "Processing question..." "Info"
        Ask-AI -Question $UserInput
    }
    else {
        # Process as a command request
        if ($AutoExecute) {
            # Use Warp AI-style conversion for auto-execute mode
            Convert-NaturalLanguageToCommand -UserInput $UserInput
        }
        else {
            # Original behavior for non-auto-execute mode
            Write-AIResponse "Generating command..." "Info"
            
            try {
                $suggestion = Get-CommandSuggestion -UserRequest $UserInput
                
                Write-AIResponse "Generated Command:" "Command"
                Write-Host "  $suggestion" -ForegroundColor White
                
                # Auto-execute safe commands, prompt for potentially dangerous ones
                if (Test-CommandSafety -Command $suggestion) {
                    # Prompt for confirmation in regular mode
                    Write-AIResponse "Execute? (Y/n/explain): " "Warning" 
                    $response = Read-Host
                    
                    if ($response -eq "" -or $response -match '^[Yy]') {
                        Write-AIResponse "Executing..." "Info"
                        try {
                            Invoke-Expression $suggestion
                            Write-AIResponse "Done!" "Success"
                        }
                        catch {
                            Write-AIResponse "Error: $($_.Exception.Message)" "Error"
                        }
                    }
                    elseif ($response -match '^[Ee]') {
                        # Provide explanation
                        $explanation = Get-CommandExplanation -Command $suggestion
                        Write-AIResponse "Explanation: $explanation" "Info"
                    }
                }
                else {
                    Write-AIResponse "This command requires manual confirmation (potentially dangerous)" "Warning"
                    Write-AIResponse "Type 'yes-execute' to run it anyway:" "Warning"
                    $confirmation = Read-Host
                    if ($confirmation -eq "yes-execute") {
                        try {
                            Invoke-Expression $suggestion
                            Write-AIResponse "Done!" "Success"
                        }
                        catch {
                            Write-AIResponse "Error: $($_.Exception.Message)" "Error"
                        }
                    }
                }
            }
            catch {
                Write-AIResponse "Error processing request: $($_.Exception.Message)" "Error"
            }
        }
    }
}

function Get-CommandExplanation {
    param([string]$Command)
    
    $systemPrompt = "Explain what this PowerShell command does in simple terms: $Command"
    
    try {
        $response = Invoke-OllamaAPI -Prompt $Command -SystemPrompt $systemPrompt
        return $response.Trim()
    }
    catch {
        return "Unable to generate explanation at this time."
    }
}

function Invoke-AICommand {
    param(
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Request,
        [switch]$Execute,
        [switch]$Explain,
        [switch]$Force
    )
    
    # Join all request parameters into a single string
    $RequestString = $Request -join ' '
    
    # Check Ollama connection
    if (-not (Test-OllamaConnection)) {
        Write-AIResponse "Ollama is not running or accessible at $script:OllamaBaseUrl" "Error"
        Write-AIResponse "Please start Ollama and ensure the model '$script:DefaultModel' is available" "Info"
        return
    }
    
    Write-AIResponse "Analyzing request: '$RequestString'" "Info"
    
    try {
        # Generate command suggestion
        $suggestion = Get-CommandSuggestion -UserRequest $RequestString -IncludeExplanation:$Explain
        
        if ($Explain -and $suggestion -match "COMMAND:\s*(.+?)\s*EXPLANATION:\s*(.+)") {
            $command = $matches[1].Trim()
            $explanation = $matches[2].Trim()
            
            Write-AIResponse "Generated Command:" "Command"
            Write-ColorText "  $command" "Bold"
            Write-Host
            Write-AIResponse "Explanation: $explanation" "Info"
        }
        else {
            $command = $suggestion
            Write-AIResponse "Generated Command:" "Command"
            Write-ColorText "  $command" "Bold"
            Write-Host
        }
        
        # Safety check
        if (-not (Test-CommandSafety $command)) {
            Write-AIResponse "WARNING: This command may be potentially dangerous!" "Warning"
            if (-not $Force) {
                $confirmation = Read-Host "Do you want to proceed anyway? (type 'yes' to confirm)"
                if ($confirmation -ne "yes") {
                    Write-AIResponse "Command execution cancelled for safety" "Info"
                    return
                }
            }
        }
        
        # Execute if requested
        if ($Execute) {
            if (-not $Force) {
                Write-AIResponse "Execute this command? (Y/N)" "Warning"
                $confirmation = Read-Host
                if ($confirmation -notmatch '^[Yy]') {
                    Write-AIResponse "Command execution cancelled" "Info"
                    return
                }
            }
            
            Write-AIResponse "Executing command..." "Info"
            try {
                Invoke-Expression $command
                Write-AIResponse "Command executed successfully" "Success"
            }
            catch {
                Write-AIResponse "Command execution failed: $($_.Exception.Message)" "Error"
            }
        }
        else {
            Write-AIResponse "Use -Execute to run this command, or copy and paste it manually" "Info"
        }
    }
    catch {
        Write-AIResponse "Error generating command: $($_.Exception.Message)" "Error"
    }
}

function Ask-AI {
    param(
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Question
    )
    
    # Join all question parameters into a single string
    $QuestionString = $Question -join ' '
    
    if (-not (Test-OllamaConnection)) {
        Write-AIResponse "Ollama is not running or accessible" "Error"
        return
    }
    
    $systemPrompt = @"
You are a helpful AI assistant with expertise in Windows, PowerShell, and system administration.
Provide clear, accurate, and helpful responses to user questions.
If the question is about commands or technical procedures, provide step-by-step guidance.

System Context:
$(Get-SystemContext)
"@
    
    try {
        Write-AIResponse "Thinking..." "Info"
        $response = Invoke-OllamaAPI -Prompt $QuestionString -SystemPrompt $systemPrompt
        Write-AIResponse "AI Response:" "Info"
        Write-Host $response
    }
    catch {
        Write-AIResponse "Error getting AI response: $($_.Exception.Message)" "Error"
    }
}

function Show-AIStatus {
    Write-AIResponse "NewTerminal-AI Status" "Info"
    Write-Host
    
    # Ollama connection
    $ollamaStatus = Test-OllamaConnection
    $statusColor = if ($ollamaStatus) { "Success" } else { "Error" }
    $statusText = if ($ollamaStatus) { "Connected" } else { "Disconnected" }
    Write-AIResponse "Ollama Status: $statusText" $statusColor
    
    # Available models
    if ($ollamaStatus) {
        $models = Get-OllamaModels
        Write-AIResponse "Available Models: $($models -join ', ')" "Info"
        Write-AIResponse "Current Model: $script:DefaultModel" "Info"
    }
    
    # System info
    Write-AIResponse "System: $($script:SystemInfo.OS)" "Info"
    Write-AIResponse "Shell: $($script:SystemInfo.Shell)" "Info"
    Write-AIResponse "User: $($script:SystemInfo.UserName)@$($script:SystemInfo.ComputerName)" "Info"
}

# New NewTerminal AI instant activation interface
function Start-NewTerminalAIMode {
    Write-AIResponse "NewTerminal AI Mode Activated!" "Success"
    Write-AIResponse "Type anything - commands execute directly, questions get AI responses!" "Info"
    Write-AIResponse "Type 'exit-newterminal' to return to normal PowerShell." "Info"
    Write-Host
    
    while ($true) {
        Write-Host "$(Get-Location)> " -NoNewline -ForegroundColor Cyan
        $input = Read-Host
        
        if ($input -eq "exit-newterminal" -or $input -eq "exit") {
            Write-AIResponse "Exiting NewTerminal AI Mode" "Info"
            break
        }
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            continue
        }
        
        # Process input with intelligent detection
        Process-IntelligentInput -UserInput $input
        
        Write-Host
    }
}

function Process-IntelligentInput {
    param([string]$UserInput)
    
    # Enhanced detection logic for different input types
    $isDirectCommand = Test-DirectCommand $UserInput
    $isQuestion = Test-QuestionPattern $UserInput
    $isSystemCommand = Test-SystemCommand $UserInput
    
    if ($isDirectCommand) {
        # Execute as direct PowerShell command
        try {
            Invoke-Expression $UserInput
        }
        catch {
            # If direct execution fails, try as natural language
            Write-AIResponse "Command not found, interpreting as natural language..." "Info"
            Process-NaturalLanguageInput -UserInput $UserInput -AutoExecute
        }
    }
    elseif ($isQuestion) {
        # Process as AI question
        Write-AIResponse "Processing question..." "Info"
        Ask-AI -Question $UserInput
    }
    else {
        # Default to natural language command generation
        Process-NaturalLanguageInput -UserInput $UserInput -AutoExecute
    }
}

function Test-DirectCommand {
    param([string]$Input)
    
    # List of common PowerShell commands that should be executed directly
    $directCommands = @(
        'Get-*', 'Set-*', 'New-*', 'Remove-*', 'Test-*', 'Start-*', 'Stop-*',
        'ls', 'dir', 'cd', 'pwd', 'cat', 'type', 'echo', 'cls', 'clear',
        'help', 'man', 'where', 'which', 'whoami', 'hostname', 'ipconfig',
        'ping', 'tracert', 'nslookup', 'netstat', 'tasklist', 'taskkill',
        'sc', 'service', 'reg', 'regedit', 'msconfig', 'control',
        'notepad', 'calc', 'mspaint', 'explorer'
    )
    
    $firstWord = ($Input -split ' ')[0]
    
    # Check if it matches any direct command pattern
    foreach ($pattern in $directCommands) {
        if ($firstWord -like $pattern) {
            return $true
        }
    }
    
    # Check if it's a valid PowerShell cmdlet
    try {
        $command = Get-Command $firstWord -ErrorAction SilentlyContinue
        if ($command) {
            return $true
        }
    }
    catch {
        # Ignore errors
    }
    
    return $false
}

function Test-QuestionPattern {
    param([string]$Input)
    
    # Enhanced question detection
    $questionWords = @('what', 'how', 'why', 'when', 'where', 'who', 'which', 'can you', 'could you', 'would you', 'should i', 'do you', 'is it', 'are there', 'explain', 'tell me', 'help me', 'show me')
    $questionMarkers = @('?', 'help', 'explain')
    
    $lowerInput = $Input.ToLower()
    
    # Check for question words at the beginning
    foreach ($word in $questionWords) {
        if ($lowerInput.StartsWith($word)) {
            return $true
        }
    }
    
    # Check for question markers
    foreach ($marker in $questionMarkers) {
        if ($lowerInput.Contains($marker)) {
            return $true
        }
    }
    
    return $false
}

function Test-SystemCommand {
    param([string]$Input)
    
    # System command patterns
    $systemPatterns = @('shutdown', 'restart', 'reboot', 'sleep', 'hibernate', 'lock')
    $lowerInput = $Input.ToLower()
    
    foreach ($pattern in $systemPatterns) {
        if ($lowerInput.Contains($pattern)) {
            return $true
        }
    }
    
    return $false
}

# Aliases for easier usage
Set-Alias -Name "ai" -Value "Invoke-AICommand"
Set-Alias -Name "ask" -Value "Ask-AI"
Set-Alias -Name "ai-status" -Value "Show-AIStatus"
Set-Alias -Name "nl" -Value "Start-NaturalLanguageMode"
Set-Alias -Name "natural" -Value "Start-NaturalLanguageMode"
Set-Alias -Name "warp" -Value "Start-NewTerminalAIMode"
Set-Alias -Name "w" -Value "Start-NewTerminalAIMode"
Set-Alias -Name "setup" -Value "Start-AutoSetup"
Set-Alias -Name "install-model" -Value "Install-OptimalModel"
Set-Alias -Name "optimize" -Value "Optimize-ModelConfiguration"

function Start-PerformanceOptimization {
    <#
    .SYNOPSIS
    Optimizes NewTerminal-AI performance for faster local processing
    
    .DESCRIPTION
    Runs comprehensive performance optimizations including PowerShell settings,
    system resources, network configuration, and Ollama optimization
    
    .PARAMETER Aggressive
    Enable aggressive optimizations that may use more system resources
    
    .PARAMETER Quiet
    Run optimization silently without progress output
    
    .EXAMPLE
    Start-PerformanceOptimization
    
    .EXAMPLE
    optimize-performance -Aggressive
    #>
    param(
        [switch]$Aggressive,
        [switch]$Quiet
    )
    
    try {
        $scriptPath = Join-Path $PSScriptRoot "scripts\optimize-performance.ps1"
        
        if (Test-Path $scriptPath) {
            $params = @{}
            if ($Aggressive) { $params.Aggressive = $true }
            if ($Quiet) { $params.Quiet = $true }
            
            & $scriptPath @params
        } else {
            Write-AIResponse "Performance optimization script not found at: $scriptPath" "Error"
            Write-AIResponse "Please ensure the scripts folder is present in the module directory" "Warning"
        }
    } catch {
        Write-AIResponse "Error running performance optimization: $($_.Exception.Message)" "Error"
    }
}

# Aliases for easier usage
Set-Alias -Name "optimize-performance" -Value "Start-PerformanceOptimization"

# Export functions
Export-ModuleMember -Function @(
    'Invoke-AICommand',
    'Ask-AI', 
    'Show-AIStatus',
    'Test-OllamaConnection',
    'Get-OllamaModels',
    'Start-NaturalLanguageMode',
    'Start-NewTerminalAIMode',
    'Process-IntelligentInput',
    'Process-NaturalLanguageInput',
    'Get-CommandExplanation',
    'Get-CommandSuggestion',
    'Test-DirectCommand',
    'Test-QuestionPattern',
    'Test-SystemCommand',
    'Test-SystemRequirements',
    'Install-OptimalModel',
    'Optimize-ModelConfiguration',
    'Start-AutoSetup',
    'Start-PerformanceOptimization',
    'Test-CommandSafety',
    'Write-AIResponse',
    'Write-ProgressStatus',
    'Convert-NaturalLanguageToCommand'
) -Alias @('ai', 'ask', 'ai-status', 'nl', 'natural', 'warp', 'w', 'setup', 'install-model', 'optimize', 'optimize-performance')

# Welcome message
Write-AIResponse "NewTerminal-AI loaded successfully!" "Success"
Write-AIResponse "NEW: Type 'warp' for instant NewTerminal AI mode!" "Success"
Write-AIResponse "Use 'setup' for automatic model detection and installation" "Info"
Write-AIResponse "Use 'ai [your request]' to generate commands" "Info"
Write-AIResponse "Use 'ask [your question]' for general AI assistance" "Info"
Write-AIResponse "Use 'ai-status' to check system status" "Info"

# Auto-run setup check on module load
if (-not (Test-SystemRequirements).OptimalModelPresent) {
    Write-AIResponse "No optimal AI model detected. Run 'setup' for automatic configuration." "Warning"
}