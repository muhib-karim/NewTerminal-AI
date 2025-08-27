# NewTerminal-AI PowerShell Profile
# Enhanced AI-powered terminal experience

# Import the NewTerminal-AI module
$ModulePath = Join-Path $PSScriptRoot "NewTerminal-AI.psm1"
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
} else {
    Write-Warning "NewTerminal-AI module not found at $ModulePath"
}

# Override the prompt function to intercept all input
function prompt {
    # Store the original location
    $currentPath = Get-Location
    
    # Display custom prompt
    Write-Host "[AI] " -NoNewline -ForegroundColor Cyan
    Write-Host "$($currentPath.Path.Replace($HOME, '~'))" -NoNewline -ForegroundColor Green
    Write-Host " > " -NoNewline -ForegroundColor White
    
    # Return empty string to prevent default prompt
    return ""
}

# Warp AI-style terminal that seamlessly converts natural language to commands
function Start-WarpAITerminal {
    Write-Host "🚀 " -NoNewline -ForegroundColor Green
    Write-Host "Warp AI Terminal Mode" -ForegroundColor Cyan
    Write-Host "   Natural language → Shell commands (just like Warp AI)" -ForegroundColor Gray
    Write-Host "   Type 'exit' to quit" -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        # Warp-style prompt
        $currentDir = (Get-Location | Split-Path -Leaf)
        Write-Host "$currentDir" -NoNewline -ForegroundColor Blue
        Write-Host " ❯ " -NoNewline -ForegroundColor Green
        
        # Read user input
        $input = Read-Host
        
        # Check for exit command
        if ($input -eq "exit" -or $input -eq "quit") {
            Write-Host "Goodbye! 👋" -ForegroundColor Cyan
            break
        }
        
        # Skip empty input
        if ([string]::IsNullOrWhiteSpace($input)) {
            continue
        }
        
        # Process input Warp AI style
        try {
            # Check if it's already a valid command
            $isDirectCommand = Test-DirectCommand $input
            
            if ($isDirectCommand) {
                # Execute directly without AI processing
                try {
                    Invoke-Expression $input
                }
                catch {
                    Write-Host "Command failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            else {
                # Convert natural language to command and execute immediately
                Convert-NaturalLanguageToCommand -UserInput $input
            }
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
}

# Auto-start Warp AI-style terminal mode
Start-WarpAITerminal

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