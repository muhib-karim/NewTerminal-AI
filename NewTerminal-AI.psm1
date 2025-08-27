# NewTerminal-AI PowerShell Module
# A native AI-powered terminal assistant using Ollama

# Configuration
$script:OllamaBaseUrl = "http://localhost:11434"
$script:DefaultModel = "llama3.2:3b"
$script:MaxRetries = 3
$script:TimeoutSeconds = 30

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

function Invoke-AICommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Request,
        [switch]$Execute,
        [switch]$Explain,
        [switch]$Force
    )
    
    # Check Ollama connection
    if (-not (Test-OllamaConnection)) {
        Write-AIResponse "Ollama is not running or accessible at $script:OllamaBaseUrl" "Error"
        Write-AIResponse "Please start Ollama and ensure the model '$script:DefaultModel' is available" "Info"
        return
    }
    
    Write-AIResponse "Analyzing request: '$Request'" "Info"
    
    try {
        # Generate command suggestion
        $suggestion = Get-CommandSuggestion -UserRequest $Request -IncludeExplanation:$Explain
        
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
            Write-AIResponse "⚠️ WARNING: This command may be potentially dangerous!" "Warning"
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
        [Parameter(Mandatory = $true)]
        [string]$Question
    )
    
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
        $response = Invoke-OllamaAPI -Prompt $Question -SystemPrompt $systemPrompt
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

# Aliases for easier usage
Set-Alias -Name "ai" -Value "Invoke-AICommand"
Set-Alias -Name "ask" -Value "Ask-AI"
Set-Alias -Name "ai-status" -Value "Show-AIStatus"

# Export functions
Export-ModuleMember -Function @(
    'Invoke-AICommand',
    'Ask-AI', 
    'Show-AIStatus',
    'Test-OllamaConnection',
    'Get-OllamaModels'
) -Alias @('ai', 'ask', 'ai-status')

# Welcome message
Write-AIResponse "NewTerminal-AI loaded successfully!" "Success"
Write-AIResponse "Use 'ai [your request]' to generate commands" "Info"
Write-AIResponse "Use 'ask [your question]' for general AI assistance" "Info"
Write-AIResponse "Use 'ai-status' to check system status" "Info"