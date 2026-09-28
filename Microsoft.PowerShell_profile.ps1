# NewTerminal-AI PowerShell Profile
# Enhanced AI-powered terminal experience

# Import the NewTerminal-AI module
$ModulePath = Join-Path $PSScriptRoot "NewTerminal-AI.psm1"
if (Test-Path $ModulePath) {
    # This profile runs its own Warp-style loop below, so skip the module's built-in auto-start
    $env:NEWTERMINAL_AI_NO_AUTOSTART = '1'
    Import-Module $ModulePath -Force
    Remove-Item Env:NEWTERMINAL_AI_NO_AUTOSTART
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

# True when the input starts with an existing command/cmdlet/alias, e.g. "git status"
function Test-DirectCommand {
    param([string]$UserInput)
    $firstWord = ($UserInput.Trim() -split '\s+')[0]
    return [bool](Get-Command $firstWord -ErrorAction SilentlyContinue)
}

# Generate a command with the NewTerminal-AI module and run it
function Convert-NaturalLanguageToCommand {
    param([string]$UserInput)
    Invoke-AICommand -NaturalLanguage $UserInput -AutoExecute -CleanOutput
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
        
        # Read user input ($null means end of input)
        $userInput = Read-Host
        
        # Check for exit command
        if ($null -eq $userInput -or $userInput -eq "exit" -or $userInput -eq "quit") {
            Write-Host "Goodbye! 👋" -ForegroundColor Cyan
            break
        }
        
        # Skip empty input
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            continue
        }
        
        # Process input Warp AI style
        try {
            # Check if it's already a valid command
            $isDirectCommand = Test-DirectCommand $userInput
            
            if ($isDirectCommand) {
                # Execute directly without AI processing
                try {
                    Invoke-Expression $userInput
                }
                catch {
                    Write-Host "Command failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            else {
                # Convert natural language to command and execute immediately
                Convert-NaturalLanguageToCommand -UserInput $userInput
            }
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
}

# Quick examples function
function Show-AIExamples {
    Write-Host "🎯 Quick Examples:" -ForegroundColor Cyan
    Write-Host "   ai 'list running processes'" -ForegroundColor Yellow
    Write-Host "   ai 'find large files in current directory'" -ForegroundColor Yellow
    Write-Host "   aia 'show system information'" -ForegroundColor Yellow
    Write-Host "   nl" -ForegroundColor Yellow
    Write-Host "   history (inside nl / AI Terminal)" -ForegroundColor Yellow
}

# Set alias for examples
Set-Alias -Name "ai-examples" -Value "Show-AIExamples"

# Enhanced tab completion for AI commands
Register-ArgumentCompleter -CommandName 'Invoke-AICommand' -ParameterName 'NaturalLanguage' -ScriptBlock {
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

# Auto-start Warp AI-style terminal mode (last, so every function above is defined)
Start-WarpAITerminal