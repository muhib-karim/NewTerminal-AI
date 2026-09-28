# NewTerminal-AI - Enhanced PowerShell Module with Natural Language Interface
# Version: 2.0 (Fixed)
# Author: AI Assistant
# Description: Provides natural language to PowerShell command conversion using local Ollama AI

# Global variables (override with NEWTERMINAL_AI_OLLAMA_URL / NEWTERMINAL_AI_MODEL)
$script:OllamaBaseUrl = if ($env:NEWTERMINAL_AI_OLLAMA_URL) { $env:NEWTERMINAL_AI_OLLAMA_URL.TrimEnd('/') } else { "http://localhost:11434" }
# Default must match the model pulled by install.ps1 / install.sh
$script:OllamaModel = if ($env:NEWTERMINAL_AI_MODEL) { $env:NEWTERMINAL_AI_MODEL } else { "llama3.2:3b" }
$script:UserHistory = @()
$script:SystemInfo = @{
    # $IsLinux / $IsMacOS do not exist on Windows PowerShell 5.1, where they evaluate to $null
    OS = if ($IsLinux) { "Linux" } elseif ($IsMacOS) { "macOS" } else { "Windows" }
    UserName = [System.Environment]::UserName
    MachineName = [System.Environment]::MachineName
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
}

function Write-AIResponse {
    param(
        [string]$Message,
        [string]$Type = "info"
    )
    
    $colors = @{
        "success" = "Green"
        "error" = "Red"
        "warning" = "Yellow"
        "info" = "Cyan"
        "command" = "White"
    }
    
    $color = $colors[$Type.ToLower()]
    if (-not $color) { $color = "White" }
    
    $prefix = switch ($Type.ToLower()) {
        "success" { "[SUCCESS $(Get-Date -Format 'HH:mm:ss')]" }
        "error" { "[ERROR $(Get-Date -Format 'HH:mm:ss')]" }
        "warning" { "[WARN $(Get-Date -Format 'HH:mm:ss')]" }
        "info" { "[INFO $(Get-Date -Format 'HH:mm:ss')]" }
        "command" { "[COMMAND $(Get-Date -Format 'HH:mm:ss')]" }
        default { "[$(Get-Date -Format 'HH:mm:ss')]" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Test-OllamaConnection {
    try {
        $response = Invoke-RestMethod -Uri "$script:OllamaBaseUrl/api/tags" -Method Get -TimeoutSec 5
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-OllamaAPI {
    param(
        [string]$Prompt,
        [string]$SystemPrompt = "",
        [string]$Model = $script:OllamaModel
    )
    
    $body = @{
        model = $Model
        prompt = $Prompt
        system = $SystemPrompt
        stream = $false
        options = @{
            temperature = 0.1
            top_p = 0.9
            num_predict = 1000
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        # The first request after startup loads the model into memory, which can take well over 30s on CPU
        $response = Invoke-RestMethod -Uri "$script:OllamaBaseUrl/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 120
        return $response.response
    }
    catch {
        $details = "$($_.ErrorDetails.Message) $($_.Exception.Message)"
        if ($details -match 'not found') {
            throw "Ollama model '$Model' is not installed. Run 'ollama pull $Model' or set NEWTERMINAL_AI_MODEL to an installed model."
        }
        throw "Ollama API call failed: $($_.Exception.Message)"
    }
}

function Show-ThinkingAnimation {
    param(
        [string]$Message = "Thinking",
        [int]$DurationMs = 2000
    )
    
    $frames = @("[*]", "[+]", "[x]", "[+]")
    $startTime = Get-Date
    $frameIndex = 0
    
    while ((Get-Date) - $startTime -lt [TimeSpan]::FromMilliseconds($DurationMs)) {
        Write-Host "`r$($frames[$frameIndex]) $Message..." -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 200
        $frameIndex = ($frameIndex + 1) % $frames.Length
    }
    
    Write-Host "`r" -NoNewline
    Write-Host (" " * ($Message.Length + 20)) -NoNewline
    Write-Host "`r" -NoNewline
}

function Get-ContextInfo {
    $currentPath = Get-Location
    $pathType = "General Directory"
    $gitBranch = $null
    $gitStatus = $null
    
    if (Test-Path ".git") {
        $pathType = "Git Repository"
        try {
            $gitBranch = (git branch --show-current 2>$null).Trim()
            $gitStatusOutput = git status --porcelain 2>$null
            $gitStatus = if ($gitStatusOutput) { "Modified files present" } else { "Clean" }
        }
        catch {
            $gitBranch = "unknown"
            $gitStatus = "unknown"
        }
    }
    elseif (Test-Path "package.json") {
        $pathType = "Node.js Project"
    }
    elseif ((Test-Path "*.sln") -or (Test-Path "*.csproj")) {
        $pathType = ".NET Project"
    }
    elseif ((Test-Path "requirements.txt") -or (Test-Path "*.py")) {
        $pathType = "Python Project"
    }
    
    return @{
        Path = $currentPath.Path
        PathType = $pathType
        GitBranch = $gitBranch
        GitStatus = $gitStatus
    }
}

function ConvertTo-CleanCommand {
    param([string]$Text)

    if (-not $Text) { return "" }

    # Models sometimes wrap the command in a markdown code fence despite the instructions
    $lines = $Text -split "`r?`n" | Where-Object { $_ -notmatch '^\s*```' }
    $command = ($lines -join "`n").Trim()

    # Unwrap a command wrapped in single inline backticks, e.g. `Get-Date`
    if ($command -match '^`([^`]+)`$') {
        $command = $Matches[1].Trim()
    }

    return $command
}

function Get-CommandSuggestion {
    param(
        [string]$NaturalLanguage
    )
    
    $context = Get-ContextInfo
    
    # Check if user is asking about the AI model
    if ($NaturalLanguage -match "(?i)(what|which|tell me|show me).*(model|llm|ai model|language model).*using" -or 
        $NaturalLanguage -match "(?i)(model|llm|ai model|language model).*(are you|is this|am i).*using" -or
        $NaturalLanguage -match "(?i)what.*model.*this" -or
        $NaturalLanguage -match "(?i)which.*model.*running") {
        return "Write-Host 'Current AI Model: $script:OllamaModel' -ForegroundColor Green"
    }
    
    $systemPrompt = @"
You are a PowerShell command generator. Convert natural language requests into PowerShell commands.

CRITICAL: Return ONLY the PowerShell command. No explanations, no markdown, no code blocks, no additional text.

Rules:
1. Generate ONLY the PowerShell command, nothing else
2. NO markdown formatting (no ```, no code blocks)
3. NO explanations or descriptions
4. Use simple, direct PowerShell cmdlets when possible
5. For common tasks, prefer these patterns:
   - Date/time: Get-Date
   - File listing: Get-ChildItem or ls
   - Disk space: Get-PSDrive -PSProvider FileSystem | Select-Object Name,Used,Free,@{Name='Size(GB)';Expression={[math]::Round((`$_.Used+`$_.Free)/1GB,2)}},@{Name='FreeSpace(GB)';Expression={[math]::Round(`$_.Free/1GB,2)}}
   - Disk usage simple: Get-PSDrive -PSProvider FileSystem
   - Processes: Get-Process
   - Services: Get-Service
   - System info: Get-ComputerInfo
   - Network info: Get-NetIPAddress
   - Current user: whoami
   - System uptime: (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
   - Create file: New-Item -ItemType File -Name "filename.ext"
   - Create empty file: New-Item -ItemType File -Path "filename.ext" -Force
   - Write to file: "content" | Out-File -FilePath "filename.ext"
   - Find/search file: Get-ChildItem -Name "filename*" -Recurse
   - Check if file exists: Test-Path "filename.ext"
   - Read file content: Get-Content "filename.ext"
   - Delete file: Remove-Item "filename.ext"
   - Copy file: Copy-Item "source.ext" "destination.ext"
   - Move/rename file: Move-Item "old.ext" "new.ext"
6. Avoid complex WMI queries unless specifically needed
7. Use PowerShell 5+ compatible syntax
8. Generate complete, working commands
9. For disk space, always show human-readable format
10. For file operations, always use appropriate cmdlets (New-Item, Get-ChildItem, Test-Path, etc.)

System Context:
OS: $($script:SystemInfo.OS)
Current Directory: $($context.Path)
Directory Type: $($context.PathType)

Examples:
Input: "show disk space"
Output: Get-PSDrive -PSProvider FileSystem

Input: "create a file named test.txt"
Output: New-Item -ItemType File -Name "test.txt"

Input: "find file test.txt"
Output: Get-ChildItem -Name "test.txt" -Recurse

Input: "list all files"
Output: Get-ChildItem
"@

    if ($context.GitBranch) {
        $systemPrompt += "`nGit Branch: $($context.GitBranch) ($($context.GitStatus))"
    }

    try {
        $response = Invoke-OllamaAPI -Prompt $NaturalLanguage -SystemPrompt $systemPrompt
        return ConvertTo-CleanCommand $response
    }
    catch {
        throw "Failed to generate command: $($_.Exception.Message)"
    }
}

function Test-CommandSafety {
    param([string]$Command)
    
    # Matched case-insensitively. Generated commands are run through Invoke-Expression,
    # so anything that can destroy data or the system must be caught here.
    $dangerousPatterns = @(
        # Recursive or wildcard deletion (PowerShell, POSIX and cmd.exe)
        'Remove-Item.*-Recurse',
        '-Recurse.*\|\s*(Remove-Item|ri|rm|del|erase|rd|rmdir)\b',
        '\brm\s+(-\S+\s+)*(-[a-z]*r|--recursive)',
        '\brm\s+(-\S+\s+)*(/|~|\*)(\s|$)',
        '\b(del|erase|rd|rmdir)\s+.*/s\b',
        # Disk and filesystem destruction
        '\bformat\s+[a-z]:',
        '\b(Format-Volume|Clear-Disk|Initialize-Disk|Remove-Partition)\b',
        '\bmkfs(\.\w+)?\b',
        '\bdd\s+.*\bof=/dev/',
        '>\s*/dev/(sd|hd|nvme|disk|mmcblk)',
        '\bdiskpart\b',
        # Power state
        'shutdown',
        'restart',
        '\b(reboot|halt|poweroff)\b',
        'Stop-Computer',
        'Restart-Computer',
        # System configuration and permissions
        'reg\s+delete.*HKLM',
        'Remove-Item.*\$env:(SystemRoot|windir|ProgramFiles)',
        '\bch(mod|own|grp)\s+(-\S+\s+)*-[a-z]*R',
        # Download-and-execute
        '\b(curl|wget|iwr|irm|Invoke-WebRequest|Invoke-RestMethod)\b.*\|\s*(sudo\s+)?(sh|bash|zsh|iex|Invoke-Expression)\b',
        '\b(iex|Invoke-Expression)\b.*\b(iwr|irm|Invoke-WebRequest|Invoke-RestMethod|DownloadString)\b',
        # Fork bomb
        ':\(\)\s*\{.*\};\s*:',
        # Destructive git operations
        '\bgit\s+push\b.*\s(--force|-f)\b',
        '\bgit\s+reset\s+--hard\b',
        '\bgit\s+clean\s+(-\S+\s+)*-[a-z]*f'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($Command -match $pattern) {
            return $false
        }
    }
    
    return $true
}

function Add-ToHistory {
    param(
        [string]$Request,
        [string]$Command,
        [bool]$Executed
    )
    
    $entry = @{
        Timestamp = Get-Date
        Request = $Request
        Command = $Command
        Executed = $Executed
        Context = Get-ContextInfo
    }
    
    $script:UserHistory += $entry
    
    # Keep only last 50 entries
    if ($script:UserHistory.Count -gt 50) {
        $script:UserHistory = $script:UserHistory | Select-Object -Last 50
    }
}

function Show-CommandHistory {
    param([int]$Last = 10)
    
    if ($script:UserHistory.Count -eq 0) {
        Write-AIResponse "No command history available" "info"
        return
    }
    
    # @() keeps a single entry as an array (a lone hashtable's .Count is its key count)
    $recentHistory = @($script:UserHistory | Select-Object -Last $Last)
    
    Write-AIResponse "Recent Command History:" "info"
    Write-Host ""
    
    for ($i = 0; $i -lt $recentHistory.Count; $i++) {
        $entry = $recentHistory[$i]
        if ($entry -and $entry.Timestamp) {
            $status = if ($entry.Executed) { "[OK]" } else { "[FAIL]" }
            $timeStr = $entry.Timestamp.ToString("HH:mm:ss")
            
            Write-Host "[$($i+1)] " -NoNewline -ForegroundColor Cyan
            Write-Host "$status " -NoNewline
            Write-Host "$timeStr " -NoNewline -ForegroundColor Gray
            Write-Host "'$($entry.Request)'" -ForegroundColor Yellow
            Write-Host "    -> " -NoNewline -ForegroundColor Gray
            Write-Host "$($entry.Command)" -ForegroundColor White
            
            if ($entry.Context -and $entry.Context.PathType -ne "General Directory") {
                Write-Host "    [DIR] $($entry.Context.PathType)" -ForegroundColor DarkGray
            }
            Write-Host ""
        }
    }
}

function Clear-CommandHistory {
    $script:UserHistory = @()
    Write-AIResponse "Command history cleared" "success"
}

function Invoke-AICommand {
    param(
        [string]$NaturalLanguage,
        [switch]$AutoExecute,
        [switch]$CleanOutput
    )
    
    if (-not $NaturalLanguage.Trim()) {
        if (-not $CleanOutput) {
            Write-AIResponse "Please provide a command request" "warning"
        }
        return
    }
    
    # Silent connection check for clean output mode
    if (-not (Test-OllamaConnection)) {
        if ($CleanOutput) {
            Write-Host "⚠️  Ollama not running" -ForegroundColor Yellow
        } else {
            Write-AIResponse "Ollama is not running. Please start Ollama first." "error"
            Write-AIResponse "Tip: Run 'ollama serve' in another terminal" "info"
        }
        return
    }
    
    if (-not $CleanOutput) {
        $context = Get-ContextInfo
        Write-AIResponse "Context: $($context.PathType)" "info"
        if ($context.GitBranch) {
            Write-AIResponse "Git: $($context.GitBranch) - $($context.GitStatus)" "info"
        }
        Show-ThinkingAnimation -Message "Analyzing your request" -DurationMs 1500
    }
    
    try {
        $command = Get-CommandSuggestion -NaturalLanguage $NaturalLanguage
    }
    catch {
        if ($CleanOutput) {
            Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
        } else {
            Write-AIResponse $_.Exception.Message "error"
        }
        Add-ToHistory -Request $NaturalLanguage -Command "" -Executed $false
        return
    }
    
    if (-not $command) {
        if ($CleanOutput) {
            Write-Host "❌ Could not understand: '$NaturalLanguage'" -ForegroundColor Red
        } else {
            Write-AIResponse "Could not generate command for: '$NaturalLanguage'" "error"
            Write-AIResponse "Tip: Try rephrasing your request or being more specific" "info"
        }
        Add-ToHistory -Request $NaturalLanguage -Command "" -Executed $false
        return
    }
    
    $command = ConvertTo-CleanCommand $command
    
    if (-not $CleanOutput) {
        Write-AIResponse "Generated Command:" "command"
        Write-Host "    $command" -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host ""
    }
    
    if (-not (Test-CommandSafety -Command $command)) {
        if ($CleanOutput) {
            Write-Host "⚠️  Potentially harmful command detected" -ForegroundColor Red
            Write-Host "   $command" -ForegroundColor Yellow
        } else {
            Write-AIResponse "DANGER: Command flagged as potentially harmful!" "warning"
            Write-Host "    $command" -ForegroundColor White -BackgroundColor DarkRed
            Write-AIResponse "Please review carefully before proceeding" "warning"
        }
        Add-ToHistory -Request $NaturalLanguage -Command $command -Executed $false
        return
    }
    
    if ($AutoExecute) {
        # Show the command being executed for educational purposes
        if ($CleanOutput) {
            Write-Host "💻 " -NoNewline -ForegroundColor Cyan
            Write-Host "$command" -ForegroundColor Yellow
        }
        
        try {
            # Reset so a failed native command from earlier is not reported for this one
            $global:LASTEXITCODE = 0
            # Execute command and capture output
            $result = Invoke-Expression $command 2>&1
            
            # Display the command output in clean format
            if ($result) {
                $result | ForEach-Object { 
                    Write-Host $_ 
                }
            }
            
            # Only show status for non-clean output or errors
            if (-not $CleanOutput) {
                if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
                    Write-AIResponse "Command executed successfully" "success"
                } else {
                    Write-AIResponse "Command completed with exit code: $LASTEXITCODE" "warning"
                }
            } elseif ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
                Write-Host "❌ Exit code: $LASTEXITCODE" -ForegroundColor Red
            }
            
            Add-ToHistory -Request $NaturalLanguage -Command $command -Executed $true
        } catch {
            if ($CleanOutput) {
                Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
            } else {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                Write-AIResponse "Execution failed" "error"
            }
            Add-ToHistory -Request $NaturalLanguage -Command $command -Executed $false
        }
    } else {
        $confirmation = Read-Host "Execute this command? [y/N/e(dit)]"
        
        switch ("$confirmation".Trim().ToLower()) {
            'y' {
                Write-AIResponse "Executing command..." "info"
                try {
                    Invoke-Expression $command
                    Write-AIResponse "Command executed successfully" "success"
                    Add-ToHistory -Request $NaturalLanguage -Command $command -Executed $true
                } catch {
                    Write-AIResponse "Execution failed: $($_.Exception.Message)" "error"
                    Add-ToHistory -Request $NaturalLanguage -Command $command -Executed $false
                }
            }
            'e' {
                Write-Host "Edit command: " -NoNewline -ForegroundColor Cyan
                $editedCommand = Read-Host
                if ("$editedCommand".Trim()) {
                    Write-AIResponse "Executing edited command..." "info"
                    try {
                        Invoke-Expression $editedCommand
                        Write-AIResponse "Edited command executed successfully" "success"
                        Add-ToHistory -Request $NaturalLanguage -Command $editedCommand -Executed $true
                    } catch {
                        Write-AIResponse "Execution failed: $($_.Exception.Message)" "error"
                        Add-ToHistory -Request $NaturalLanguage -Command $editedCommand -Executed $false
                    }
                }
            }
            default {
                Write-AIResponse "Command cancelled by user" "info"
                Add-ToHistory -Request $NaturalLanguage -Command $command -Executed $false
            }
        }
    }
}

function Start-NLMode {
    # Clean startup - minimal output
    Write-Host "🤖 AI Terminal" -ForegroundColor Green
    Write-Host "Type commands in natural language. Type 'exit' to quit." -ForegroundColor Gray
    Write-Host ""
    
    $sessionCommands = 0
    
    :nlLoop while ($true) {
        $context = Get-ContextInfo
        $prompt = ">"
        
        # Clean prompt with minimal context
        if ($context.GitBranch) {
            $prompt = "($($context.GitBranch)) >"
        }
        
        Write-Host "$prompt " -NoNewline -ForegroundColor Cyan
        $userInput = Read-Host
        if ($null -eq $userInput) { break nlLoop }
        
        switch ($userInput.ToLower().Trim()) {
            'exit' {
                Write-Host "👋 Goodbye!" -ForegroundColor Green
                break nlLoop
            }
            'history' {
                Show-CommandHistory -Last 10
                continue
            }
            'clear' {
                Clear-Host
                Write-Host "🤖 AI Terminal" -ForegroundColor Green
                Write-Host "Type commands in natural language. Type 'exit' to quit." -ForegroundColor Gray
                Write-Host ""
                continue
            }
            'help' {
                Write-Host "Available commands:" -ForegroundColor Yellow
                Write-Host "  exit     - Exit AI terminal" -ForegroundColor Cyan
                Write-Host "  history  - Show command history" -ForegroundColor Cyan
                Write-Host "  clear    - Clear screen" -ForegroundColor Cyan
                Write-Host "  help     - Show this help" -ForegroundColor Cyan
                Write-Host "  Or describe what you want to do!" -ForegroundColor Green
                continue
            }
            default {
                if ($userInput.Trim()) {
                    $sessionCommands++
                    # Use clean output mode for Warp AI-style experience
                    Invoke-AICommand -NaturalLanguage $userInput -AutoExecute -CleanOutput
                    Write-Host ""
                }
            }
        }
    }
}

# Create wrapper function for auto-execution with clean output
function Invoke-AICommandAuto {
    param([string]$NaturalLanguage)
    Invoke-AICommand -NaturalLanguage $NaturalLanguage -AutoExecute -CleanOutput
}

# Aliases
Set-Alias -Name "ai" -Value "Invoke-AICommand"
Set-Alias -Name "aia" -Value "Invoke-AICommandAuto"
Set-Alias -Name "nl" -Value "Start-NLMode"

# Auto-start in natural language mode
function Start-AITerminal {
    Write-Host "🤖 AI Terminal - Natural Language Interface" -ForegroundColor Green
    Write-Host "Describe what you want to do in plain English. Type 'exit' to quit." -ForegroundColor Gray
    Write-Host ""
    
    $sessionCommands = 0
    
    :aiLoop while ($true) {
        $context = Get-ContextInfo
        $prompt = "AI>"
        
        # Clean prompt with minimal context
        if ($context.GitBranch) {
            $prompt = "AI($($context.GitBranch))>"
        }
        
        Write-Host "$prompt " -NoNewline -ForegroundColor Cyan
        $userInput = Read-Host
        if ($null -eq $userInput) { break aiLoop }
        
        switch ($userInput.ToLower().Trim()) {
            'exit' {
                Write-Host "👋 Goodbye!" -ForegroundColor Green
                break aiLoop
            }
            'history' {
                Show-CommandHistory -Last 10
                continue
            }
            'clear' {
                Clear-Host
                Write-Host "🤖 AI Terminal - Natural Language Interface" -ForegroundColor Green
                Write-Host "Describe what you want to do in plain English. Type 'exit' to quit." -ForegroundColor Gray
                Write-Host ""
                continue
            }
            'help' {
                Write-Host "Available commands:" -ForegroundColor Yellow
                Write-Host "  exit     - Exit AI terminal" -ForegroundColor Cyan
                Write-Host "  history  - Show command history" -ForegroundColor Cyan
                Write-Host "  clear    - Clear screen" -ForegroundColor Cyan
                Write-Host "  help     - Show this help" -ForegroundColor Cyan
                Write-Host "  Or describe what you want to do in natural language!" -ForegroundColor Green
                continue
            }
            default {
                if ($userInput.Trim()) {
                    $sessionCommands++
                    # Smart execution with confirmation for dangerous commands
                    try {
                        $command = Get-CommandSuggestion -NaturalLanguage $userInput
                    }
                    catch {
                        Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
                        Add-ToHistory -Request $userInput -Command "" -Executed $false
                        Write-Host ""
                        continue
                    }
                    
                    if ($command) {
                        
                        # Show the command being generated
                        Write-Host "💻 " -NoNewline -ForegroundColor Cyan
                        Write-Host "$command" -ForegroundColor Yellow
                        
                        if (Test-CommandSafety -Command $command) {
                            # Auto-execute safe commands
                            try {
                                $result = Invoke-Expression $command 2>&1
                                if ($result) {
                                    $result | ForEach-Object { Write-Host $_ }
                                }
                                Add-ToHistory -Request $userInput -Command $command -Executed $true
                            } catch {
                                Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
                                Add-ToHistory -Request $userInput -Command $command -Executed $false
                            }
                        } else {
                            # Ask for confirmation on potentially dangerous commands
                            Write-Host "⚠️  This command may be potentially harmful. Execute? [y/N]: " -NoNewline -ForegroundColor Yellow
                            $confirm = Read-Host
                            if ("$confirm".Trim() -eq 'y') {
                                try {
                                    $result = Invoke-Expression $command 2>&1
                                    if ($result) {
                                        $result | ForEach-Object { Write-Host $_ }
                                    }
                                    Add-ToHistory -Request $userInput -Command $command -Executed $true
                                } catch {
                                    Write-Host "❌ $($_.Exception.Message)" -ForegroundColor Red
                                    Add-ToHistory -Request $userInput -Command $command -Executed $false
                                }
                            } else {
                                Write-Host "Command cancelled" -ForegroundColor Gray
                                Add-ToHistory -Request $userInput -Command $command -Executed $false
                            }
                        }
                    } else {
                        Write-Host "❌ Could not understand: '$userInput'" -ForegroundColor Red
                        Add-ToHistory -Request $userInput -Command "" -Executed $false
                    }
                    Write-Host ""
                }
            }
        }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Invoke-AICommand',
    'Invoke-AICommandAuto',
    'Start-NLMode',
    'Start-AITerminal',
    'Test-OllamaConnection',
    'Show-CommandHistory',
    'Clear-CommandHistory',
    'Get-ContextInfo',
    'Add-ToHistory',
    'Show-ThinkingAnimation'
) -Alias @('ai', 'aia', 'nl')

# Welcome message and auto-start. Skipped when NEWTERMINAL_AI_NO_AUTOSTART is set or the host was
# started with -NonInteractive, so scripts, installers and tests can import the module without blocking.
$script:IsNonInteractiveHost = [bool]([Environment]::GetCommandLineArgs() | Where-Object { $_ -match '^-noni' })
if (-not $env:NEWTERMINAL_AI_NO_AUTOSTART -and -not $script:IsNonInteractiveHost) {
    Write-Host "[SUCCESS $(Get-Date -Format 'HH:mm:ss')] AI Terminal loaded! Starting natural language interface..." -ForegroundColor Green
    Start-Sleep -Milliseconds 500
    Start-AITerminal
}