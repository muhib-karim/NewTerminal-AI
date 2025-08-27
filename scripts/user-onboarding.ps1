# NewTerminal-AI User Onboarding and Troubleshooting Guide
# Interactive guide for new users unfamiliar with terminal commands

param(
    [string]$Mode = "onboarding",
    [switch]$Interactive = $true,
    [switch]$QuickStart = $false
)

# Color scheme for consistent output
$Colors = @{
    Error = 'Red'
    Success = 'Green'
    Warning = 'Yellow'
    Info = 'Blue'
    Highlight = 'Magenta'
    Progress = 'Cyan'
    Text = 'White'
    Accent = 'DarkYellow'
}

# Function to display welcome message
function Show-WelcomeMessage {
    Clear-Host
    Write-Host "=== Welcome to NewTerminal-AI! ===" -ForegroundColor $Colors.Highlight
    Write-Host ""
    Write-Host "🎉 Congratulations! You've successfully installed NewTerminal-AI." -ForegroundColor $Colors.Success
    Write-Host "This guide will help you get started with AI-powered terminal commands." -ForegroundColor $Colors.Text
    Write-Host ""
    Write-Host "What is NewTerminal-AI?" -ForegroundColor $Colors.Info
    Write-Host "• An AI assistant that understands natural language" -ForegroundColor $Colors.Text
    Write-Host "• Converts your requests into terminal commands" -ForegroundColor $Colors.Text
    Write-Host "• Safe execution with confirmation prompts" -ForegroundColor $Colors.Text
    Write-Host "• Works offline - no internet required after setup" -ForegroundColor $Colors.Text
    Write-Host ""
}

# Function to show basic usage examples
function Show-BasicUsage {
    Write-Host "=== Basic Usage ===" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "The main command is: " -NoNewline -ForegroundColor $Colors.Text
    Write-Host "ai 'your request'" -ForegroundColor $Colors.Highlight
    Write-Host ""
    Write-Host "Here are some examples to try:" -ForegroundColor $Colors.Text
    Write-Host ""
    
    $examples = @(
        @{Request = "ai 'show me the current directory'"; Description = "Lists files in current folder"},
        @{Request = "ai 'what is my system information'"; Description = "Shows computer details"},
        @{Request = "ai 'create a new folder called test'"; Description = "Creates a new directory"},
        @{Request = "ai 'find all text files in this folder'"; Description = "Searches for .txt files"},
        @{Request = "ai 'show disk space usage'"; Description = "Displays storage information"},
        @{Request = "ai 'list running processes'"; Description = "Shows active programs"}
    )
    
    foreach ($example in $examples) {
        Write-Host "  " -NoNewline
        Write-Host $example.Request -ForegroundColor $Colors.Accent
        Write-Host "    → $($example.Description)" -ForegroundColor $Colors.Text
        Write-Host ""
    }
}

# Function to demonstrate interactive example
function Start-InteractiveDemo {
    Write-Host "=== Interactive Demo ===" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "Let's try a safe example together!" -ForegroundColor $Colors.Text
    Write-Host ""
    
    if ($Interactive) {
        Write-Host "Press Enter to run: " -NoNewline -ForegroundColor $Colors.Text
        Write-Host "ai 'show me the current directory'" -ForegroundColor $Colors.Accent
        Read-Host
        
        try {
            Write-Host "Running command..." -ForegroundColor $Colors.Progress
            $result = & ai "show me the current directory" 2>&1
            Write-Host "✅ Command executed successfully!" -ForegroundColor $Colors.Success
            Write-Host "Output: $result" -ForegroundColor $Colors.Text
        }
        catch {
            Write-Host "⚠️  Demo command failed. This is normal if AI isn't fully configured yet." -ForegroundColor $Colors.Warning
            Write-Host "The AI will work once you restart your terminal session." -ForegroundColor $Colors.Text
        }
    } else {
        Write-Host "Example: ai 'show me the current directory'" -ForegroundColor $Colors.Accent
        Write-Host "This would list all files and folders in your current location." -ForegroundColor $Colors.Text
    }
    
    Write-Host ""
}

# Function to show safety features
function Show-SafetyFeatures {
    Write-Host "=== Safety Features ===" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "NewTerminal-AI is designed to be safe:" -ForegroundColor $Colors.Text
    Write-Host ""
    Write-Host "🛡️  Confirmation Prompts" -ForegroundColor $Colors.Success
    Write-Host "   • You'll be asked before running potentially dangerous commands" -ForegroundColor $Colors.Text
    Write-Host "   • You can always say 'no' if you're unsure" -ForegroundColor $Colors.Text
    Write-Host ""
    Write-Host "🔍 Command Preview" -ForegroundColor $Colors.Success
    Write-Host "   • See exactly what command will be executed" -ForegroundColor $Colors.Text
    Write-Host "   • Understand what each command does" -ForegroundColor $Colors.Text
    Write-Host ""
    Write-Host "⚠️  Best Practices" -ForegroundColor $Colors.Warning
    Write-Host "   • Start with simple, safe commands" -ForegroundColor $Colors.Text
    Write-Host "   • Always read the suggested command before confirming" -ForegroundColor $Colors.Text
    Write-Host "   • Ask for help if you don't understand something" -ForegroundColor $Colors.Text
    Write-Host ""
}

# Function to show troubleshooting guide
function Show-TroubleshootingGuide {
    Write-Host "=== Troubleshooting Guide ===" -ForegroundColor $Colors.Info
    Write-Host ""
    
    $issues = @(
        @{
            Problem = "AI command not found"
            Solutions = @(
                "Restart your PowerShell session",
                "Run: . `$PROFILE to reload your profile",
                "Check if installation completed successfully"
            )
        },
        @{
            Problem = "AI doesn't respond or gives errors"
            Solutions = @(
                "Check if Ollama service is running: ollama list",
                "Restart Ollama: ollama serve",
                "Verify your AI model is installed: ollama list"
            )
        },
        @{
            Problem = "Commands are slow or timeout"
            Solutions = @(
                "Your AI model might be too large for your system",
                "Try restarting the Ollama service",
                "Check available RAM and close other applications"
            )
        },
        @{
            Problem = "Permission errors"
            Solutions = @(
                "Run PowerShell as Administrator if needed",
                "Check file/folder permissions",
                "Some operations require elevated privileges"
            )
        }
    )
    
    foreach ($issue in $issues) {
        Write-Host "❌ Problem: " -NoNewline -ForegroundColor $Colors.Error
        Write-Host $issue.Problem -ForegroundColor $Colors.Text
        Write-Host "   Solutions:" -ForegroundColor $Colors.Success
        foreach ($solution in $issue.Solutions) {
            Write-Host "   • $solution" -ForegroundColor $Colors.Text
        }
        Write-Host ""
    }
}

# Function to show advanced tips
function Show-AdvancedTips {
    Write-Host "=== Advanced Tips ===" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "Once you're comfortable with basics, try these:" -ForegroundColor $Colors.Text
    Write-Host ""
    
    $advancedTips = @(
        "ai 'find all files larger than 100MB in my downloads'",
        "ai 'show me network connections'",
        "ai 'create a backup of my documents folder'",
        "ai 'monitor system performance'",
        "ai 'clean up temporary files safely'",
        "ai 'show me installed programs'"
    )
    
    foreach ($tip in $advancedTips) {
        Write-Host "  $tip" -ForegroundColor $Colors.Accent
    }
    
    Write-Host ""
    Write-Host "💡 Pro Tips:" -ForegroundColor $Colors.Highlight
    Write-Host "• Be specific in your requests for better results" -ForegroundColor $Colors.Text
    Write-Host "• You can ask for explanations: 'explain what this command does'" -ForegroundColor $Colors.Text
    Write-Host "• Use 'ask' as an alternative to 'ai' command" -ForegroundColor $Colors.Text
    Write-Host ""
}

# Function to show help resources
function Show-HelpResources {
    Write-Host "=== Getting Help ===" -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "Need more help? Here are your options:" -ForegroundColor $Colors.Text
    Write-Host ""
    Write-Host "📚 Built-in Help" -ForegroundColor $Colors.Success
    Write-Host "   • ai 'help me with terminal commands'" -ForegroundColor $Colors.Accent
    Write-Host "   • ai 'explain how to use this AI assistant'" -ForegroundColor $Colors.Accent
    Write-Host ""
    Write-Host "🔧 System Commands" -ForegroundColor $Colors.Success
    Write-Host "   • ollama list - Show installed AI models" -ForegroundColor $Colors.Accent
    Write-Host "   • ollama serve - Start the AI service" -ForegroundColor $Colors.Accent
    Write-Host ""
    Write-Host "📖 Documentation" -ForegroundColor $Colors.Success
    Write-Host "   • Check README.md in the project folder" -ForegroundColor $Colors.Text
    Write-Host "   • Visit the project repository for updates" -ForegroundColor $Colors.Text
    Write-Host ""
}

# Function to run quick start mode
function Start-QuickStart {
    Write-Host "=== Quick Start Guide ===" -ForegroundColor $Colors.Highlight
    Write-Host ""
    Write-Host "1. Basic Command:" -ForegroundColor $Colors.Info
    Write-Host "   ai 'your request in plain English'" -ForegroundColor $Colors.Accent
    Write-Host ""
    Write-Host "2. First Steps:" -ForegroundColor $Colors.Info
    Write-Host "   • ai 'show current directory'" -ForegroundColor $Colors.Text
    Write-Host "   • ai 'what is my system info'" -ForegroundColor $Colors.Text
    Write-Host ""
    Write-Host "3. Safety:" -ForegroundColor $Colors.Info
    Write-Host "   • Always read suggested commands" -ForegroundColor $Colors.Text
    Write-Host "   • Confirm before executing" -ForegroundColor $Colors.Text
    Write-Host ""
    Write-Host "4. Help:" -ForegroundColor $Colors.Info
    Write-Host "   • ai 'help me with commands'" -ForegroundColor $Colors.Text
    Write-Host "   • Run this guide again anytime" -ForegroundColor $Colors.Text
    Write-Host ""
}

# Function to create a cheat sheet file
function New-CheatSheet {
    $cheatSheetContent = @"
# NewTerminal-AI Cheat Sheet

## Basic Commands
- ai 'your request'          - Main AI command
- ask 'your request'         - Alternative alias

## Common Examples
- ai 'show current directory'        - List files and folders
- ai 'what is my system info'        - Display system information
- ai 'create folder called test'     - Make a new directory
- ai 'find text files here'          - Search for .txt files
- ai 'show disk space'               - Display storage usage
- ai 'list running programs'         - Show active processes

## Safety Tips
- Always read the suggested command before confirming
- Start with simple, safe commands
- You can always say 'no' if unsure

## Troubleshooting
- If 'ai' command not found: Restart PowerShell
- If AI doesn't respond: Check 'ollama list'
- If commands are slow: Restart 'ollama serve'

## Getting Help
- ai 'help me with terminal commands'
- ai 'explain what this command does'
- Run: .\user-onboarding.ps1 for this guide

## System Commands
- ollama list        - Show installed AI models
- ollama serve       - Start AI service
- . `$PROFILE         - Reload PowerShell profile

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    $cheatSheetPath = "NewTerminal-AI-CheatSheet.txt"
    Set-Content -Path $cheatSheetPath -Value $cheatSheetContent -Encoding UTF8
    Write-Host "📄 Cheat sheet saved to: $cheatSheetPath" -ForegroundColor $Colors.Success
    Write-Host "   You can reference this file anytime!" -ForegroundColor $Colors.Text
}

# Main function to handle different modes
function Start-UserOnboarding {
    param([string]$OnboardingMode)
    
    switch ($OnboardingMode.ToLower()) {
        "onboarding" {
            Show-WelcomeMessage
            if ($Interactive) {
                Write-Host "Press Enter to continue..." -ForegroundColor $Colors.Progress
                Read-Host
            }
            
            Show-BasicUsage
            if ($Interactive) {
                Write-Host "Press Enter to continue..." -ForegroundColor $Colors.Progress
                Read-Host
            }
            
            Start-InteractiveDemo
            if ($Interactive) {
                Write-Host "Press Enter to continue..." -ForegroundColor $Colors.Progress
                Read-Host
            }
            
            Show-SafetyFeatures
            if ($Interactive) {
                Write-Host "Press Enter to continue..." -ForegroundColor $Colors.Progress
                Read-Host
            }
            
            Show-AdvancedTips
            Show-HelpResources
            New-CheatSheet
            
            Write-Host ""
            Write-Host "🎉 Onboarding complete! You're ready to use NewTerminal-AI." -ForegroundColor $Colors.Success
            Write-Host "Start with simple commands and explore gradually." -ForegroundColor $Colors.Text
        }
        "troubleshooting" {
            Show-TroubleshootingGuide
        }
        "quickstart" {
            Start-QuickStart
        }
        "cheatsheet" {
            New-CheatSheet
        }
        default {
            Write-Host "Available modes: onboarding, troubleshooting, quickstart, cheatsheet" -ForegroundColor $Colors.Warning
        }
    }
}

# Execute the main function
if ($QuickStart) {
    Start-UserOnboarding -OnboardingMode "quickstart"
} else {
    Start-UserOnboarding -OnboardingMode $Mode
}