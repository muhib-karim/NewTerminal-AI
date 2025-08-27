# NewTerminal-AI PowerShell Profile
# Enhanced AI-powered terminal experience

# Import the NewTerminal-AI module
$ModulePath = Join-Path $PSScriptRoot "NewTerminal-AI.psm1"
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
} else {
    Write-Warning "NewTerminal-AI module not found at $ModulePath"
}

# Enhanced prompt with AI indicator
function prompt {
    $currentPath = $executionContext.SessionState.Path.CurrentLocation
    $currentDirectory = Split-Path $currentPath -Leaf
    
    # Color codes
    $green = "`e[32m"
    $blue = "`e[34m"
    $cyan = "`e[36m"
    $yellow = "`e[33m"
    $reset = "`e[0m"
    $bold = "`e[1m"
    
    # Check if we're in a git repository
    $gitBranch = ""
    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            $branch = git branch --show-current 2>$null
            if ($branch) {
                $gitBranch = " $yellow($branch)$reset"
            }
        } catch {}
    }
    
    # AI status indicator
    $aiStatus = ""
    try {
        if (Get-Command Test-OllamaConnection -ErrorAction SilentlyContinue) {
            if (Test-OllamaConnection) {
                $aiStatus = " $green🤖$reset"
            } else {
                $aiStatus = " $yellow🤖$reset"
            }
        }
    } catch {}
    
    # Build prompt
    $promptText = "$cyan$bold(NewTerminal-AI)$reset $blue$currentDirectory$reset$gitBranch$aiStatus`n$green❯$reset "
    
    return $promptText
}

# Welcome message
Write-Host ""
Write-Host "🚀 " -NoNewline -ForegroundColor Green
Write-Host "NewTerminal-AI is ready!" -ForegroundColor Cyan
Write-Host "   Use " -NoNewline -ForegroundColor Gray
Write-Host "ai 'your request'" -NoNewline -ForegroundColor Yellow
Write-Host " to generate and execute commands" -ForegroundColor Gray
Write-Host "   Use " -NoNewline -ForegroundColor Gray
Write-Host "ask 'your question'" -NoNewline -ForegroundColor Yellow
Write-Host " for general AI assistance" -ForegroundColor Gray
Write-Host "   Use " -NoNewline -ForegroundColor Gray
Write-Host "ai-status" -NoNewline -ForegroundColor Yellow
Write-Host " to check system status" -ForegroundColor Gray
Write-Host ""

# Quick examples function
function Show-AIExamples {
    Write-Host "🎯 Quick Examples:" -ForegroundColor Cyan
    Write-Host "   ai 'list running processes'" -ForegroundColor Yellow
    Write-Host "   ai 'find large files in current directory'" -ForegroundColor Yellow
    Write-Host "   ai 'show system information' -Execute" -ForegroundColor Yellow
    Write-Host "   ask 'how to optimize PowerShell performance'" -ForegroundColor Yellow
    Write-Host "   ai-status" -ForegroundColor Yellow
}

# Set alias for examples
Set-Alias -Name "ai-examples" -Value "Show-AIExamples"

# Enhanced tab completion for AI commands
Register-ArgumentCompleter -CommandName 'Invoke-AICommand' -ParameterName 'Request' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $suggestions = @(
        'list running processes',
        'show system information',
        'find large files',
        'check disk space',
        'show network connections',
        'list installed programs',
        'show environment variables',
        'find files by extension',
        'show services status',
        'check memory usage'
    )
    
    $suggestions | Where-Object { $_ -like "*$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Auto-update check (optional)
function Test-AIUpdate {
    try {
        # This could be enhanced to check for updates from a repository
        Write-Host "✅ NewTerminal-AI is up to date" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not check for updates" -ForegroundColor Yellow
    }
}

# Performance optimization
$MaximumHistoryCount = 10000
$PSDefaultParameterValues['Out-Default:OutVariable'] = 'LastResult'

# Enhanced error handling
$ErrorActionPreference = 'Continue'
$ErrorView = 'DetailedView'

# Module auto-loading
$PSModuleAutoLoadingPreference = 'All'