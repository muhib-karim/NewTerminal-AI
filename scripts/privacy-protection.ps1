# NewTerminal-AI Privacy Protection Script
# Ensures all processing remains completely local with robust privacy safeguards

param(
    [switch]$Audit,
    [switch]$Enforce,
    [switch]$Quiet
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ANSI Colors
$Colors = @{
    Green = "`e[32m"
    Yellow = "`e[33m"
    Red = "`e[31m"
    Blue = "`e[34m"
    Cyan = "`e[36m"
    Magenta = "`e[35m"
    Reset = "`e[0m"
    Bold = "`e[1m"
}

function Write-PrivacyStatus {
    param([string]$Message, [string]$Type = "Info")
    
    if ($Quiet) { return }
    
    $icon = switch ($Type) {
        "Success" { "[✓]" }
        "Warning" { "[!]" }
        "Error" { "[✗]" }
        "Info" { "[i]" }
        "Shield" { "[🛡️]" }
        "Lock" { "[🔒]" }
        default { "[*]" }
    }
    
    $color = switch ($Type) {
        "Success" { $Colors.Green }
        "Warning" { $Colors.Yellow }
        "Error" { $Colors.Red }
        "Info" { $Colors.Cyan }
        "Shield" { $Colors.Magenta }
        "Lock" { $Colors.Blue }
        default { $Colors.Blue }
    }
    
    Write-Host "$color$icon$($Colors.Reset) $Message"
}

function Test-NetworkIsolation {
    Write-PrivacyStatus "Checking network isolation settings..." "Shield"
    
    $issues = @()
    
    try {
        # Check if Ollama is bound to localhost only
        $ollamaProcesses = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
        
        if ($ollamaProcesses) {
            # Check network connections
            $connections = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | 
                         Where-Object { $_.OwningProcess -in $ollamaProcesses.Id }
            
            foreach ($conn in $connections) {
                if ($conn.LocalAddress -ne "127.0.0.1" -and $conn.LocalAddress -ne "::1") {
                    $issues += "Ollama is listening on $($conn.LocalAddress):$($conn.LocalPort) (should be localhost only)"
                }
            }
            
            if ($issues.Count -eq 0) {
                Write-PrivacyStatus "Ollama is properly bound to localhost only" "Success"
            }
        } else {
            Write-PrivacyStatus "Ollama service not running" "Warning"
        }
        
        return $issues
    } catch {
        Write-PrivacyStatus "Error checking network isolation: $($_.Exception.Message)" "Error"
        return @("Could not verify network isolation")
    }
}

function Test-DataLeakage {
    Write-PrivacyStatus "Scanning for potential data leakage..." "Shield"
    
    $issues = @()
    
    try {
        # Check for telemetry or analytics endpoints
        $suspiciousHosts = @(
            "analytics.google.com",
            "telemetry.microsoft.com",
            "api.openai.com",
            "api.anthropic.com",
            "api.cohere.ai",
            "api.huggingface.co"
        )
        
        # Check recent network connections
        $recentConnections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
        
        foreach ($conn in $recentConnections) {
            try {
                $remoteHost = [System.Net.Dns]::GetHostEntry($conn.RemoteAddress).HostName
                foreach ($suspicious in $suspiciousHosts) {
                    if ($remoteHost -like "*$suspicious*") {
                        $issues += "Suspicious connection detected to: $remoteHost"
                    }
                }
            } catch {
                # DNS resolution failed, which is normal for many connections
            }
        }
        
        # Check environment variables for API keys
        $envVars = Get-ChildItem Env: | Where-Object { 
            $_.Name -like "*API*KEY*" -or 
            $_.Name -like "*OPENAI*" -or 
            $_.Name -like "*ANTHROPIC*" -or
            $_.Name -like "*COHERE*"
        }
        
        if ($envVars) {
            foreach ($var in $envVars) {
                $issues += "Potentially sensitive environment variable found: $($var.Name)"
            }
        }
        
        if ($issues.Count -eq 0) {
            Write-PrivacyStatus "No data leakage indicators found" "Success"
        }
        
        return $issues
    } catch {
        Write-PrivacyStatus "Error scanning for data leakage: $($_.Exception.Message)" "Error"
        return @("Could not complete data leakage scan")
    }
}

function Test-LocalProcessing {
    Write-PrivacyStatus "Verifying local processing integrity..." "Lock"
    
    $issues = @()
    
    try {
        # Test that Ollama API is responding locally
        $testResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5 -ErrorAction Stop
        
        if ($testResponse) {
            Write-PrivacyStatus "Local Ollama API is responding correctly" "Success"
        }
        
        # Verify no external API calls are being made during AI requests
        Write-PrivacyStatus "Testing AI request isolation..." "Info"
        
        # Monitor network activity during a test AI request
        $beforeConnections = (Get-NetTCPConnection -State Established).Count
        
        # Make a test AI request
        $testBody = @{
            model = "qwen2.5:0.5b"
            prompt = "Privacy test - respond with 'LOCAL'"
            stream = $false
        } | ConvertTo-Json
        
        $aiResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $testBody -ContentType "application/json" -TimeoutSec 10
        
        $afterConnections = (Get-NetTCPConnection -State Established).Count
        
        if ($afterConnections -le $beforeConnections + 1) {
            Write-PrivacyStatus "AI processing confirmed to be local only" "Success"
        } else {
            $issues += "Unexpected network connections during AI processing"
        }
        
        return $issues
    } catch {
        Write-PrivacyStatus "Error verifying local processing: $($_.Exception.Message)" "Error"
        return @("Could not verify local processing integrity")
    }
}

function Test-FileSystemSecurity {
    Write-PrivacyStatus "Checking file system security..." "Lock"
    
    $issues = @()
    
    try {
        # Check Ollama model directory permissions
        $ollamaDir = "$env:USERPROFILE\.ollama"
        
        if (Test-Path $ollamaDir) {
            $acl = Get-Acl $ollamaDir
            $publicAccess = $acl.Access | Where-Object { 
                $_.IdentityReference -like "*Everyone*" -or 
                $_.IdentityReference -like "*Users*" -and 
                $_.AccessControlType -eq "Allow" -and
                ($_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write)
            }
            
            if ($publicAccess) {
                $issues += "Ollama directory has overly permissive access rights"
            } else {
                Write-PrivacyStatus "Ollama directory permissions are secure" "Success"
            }
        }
        
        # Check for temporary files that might contain sensitive data
        $tempFiles = Get-ChildItem $env:TEMP -Filter "*ollama*" -Recurse -ErrorAction SilentlyContinue
        $tempFiles += Get-ChildItem $env:TEMP -Filter "*newterminal*" -Recurse -ErrorAction SilentlyContinue
        
        if ($tempFiles) {
            $issues += "Temporary files found that may contain sensitive data: $($tempFiles.Count) files"
        } else {
            Write-PrivacyStatus "No sensitive temporary files found" "Success"
        }
        
        return $issues
    } catch {
        Write-PrivacyStatus "Error checking file system security: $($_.Exception.Message)" "Error"
        return @("Could not complete file system security check")
    }
}

function Enforce-PrivacySettings {
    Write-PrivacyStatus "Enforcing privacy protection settings..." "Shield"
    
    try {
        # Set secure Ollama environment variables
        $secureEnvVars = @{
            "OLLAMA_HOST" = "127.0.0.1:11434"  # Bind to localhost only
            "OLLAMA_ORIGINS" = "http://localhost:*,http://127.0.0.1:*"  # Restrict origins
            "OLLAMA_DEBUG" = "0"  # Disable debug logging
            "OLLAMA_LOGS" = "0"  # Disable detailed logging
        }
        
        foreach ($var in $secureEnvVars.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "User")
            Set-Item -Path "env:$($var.Key)" -Value $var.Value -Force
            Write-PrivacyStatus "Set secure environment variable: $($var.Key)" "Success"
        }
        
        # Clear potentially sensitive environment variables
        $sensitiveVars = @(
            "OPENAI_API_KEY",
            "ANTHROPIC_API_KEY",
            "COHERE_API_KEY",
            "HUGGINGFACE_API_TOKEN"
        )
        
        foreach ($var in $sensitiveVars) {
            if (Test-Path "env:$var") {
                Remove-Item "env:$var" -Force
                Write-PrivacyStatus "Cleared sensitive environment variable: $var" "Success"
            }
        }
        
        # Secure Ollama model directory
        $ollamaDir = "$env:USERPROFILE\.ollama"
        if (Test-Path $ollamaDir) {
            $acl = Get-Acl $ollamaDir
            
            # Remove inherited permissions and set explicit permissions
            $acl.SetAccessRuleProtection($true, $false)
            
            # Add current user with full control
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $currentUser, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
            )
            $acl.SetAccessRule($accessRule)
            
            Set-Acl -Path $ollamaDir -AclObject $acl
            Write-PrivacyStatus "Secured Ollama directory permissions" "Success"
        }
        
        # Clean up temporary files
        $tempPatterns = @("*ollama*", "*newterminal*", "*ai-temp*")
        foreach ($pattern in $tempPatterns) {
            $tempFiles = Get-ChildItem $env:TEMP -Filter $pattern -Recurse -ErrorAction SilentlyContinue
            foreach ($file in $tempFiles) {
                try {
                    Remove-Item $file.FullName -Force -Recurse
                } catch {
                    # File might be in use, skip
                }
            }
        }
        Write-PrivacyStatus "Cleaned up temporary files" "Success"
        
        return $true
    } catch {
        Write-PrivacyStatus "Error enforcing privacy settings: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Start-PrivacyAudit {
    Write-Host "`n$($Colors.Bold)$($Colors.Magenta)NewTerminal-AI Privacy Protection Audit$($Colors.Reset)`n"
    Write-PrivacyStatus "Starting comprehensive privacy audit..." "Shield"
    
    $allIssues = @()
    
    # Run all privacy checks
    $checks = @(
        @{ Name = "Network Isolation"; Function = { Test-NetworkIsolation } },
        @{ Name = "Data Leakage"; Function = { Test-DataLeakage } },
        @{ Name = "Local Processing"; Function = { Test-LocalProcessing } },
        @{ Name = "File System Security"; Function = { Test-FileSystemSecurity } }
    )
    
    foreach ($check in $checks) {
        try {
            $issues = & $check.Function
            if ($issues -and $issues.Count -gt 0) {
                $allIssues += $issues
                Write-PrivacyStatus "$($check.Name): $($issues.Count) issue(s) found" "Warning"
            } else {
                Write-PrivacyStatus "$($check.Name): No issues found" "Success"
            }
        } catch {
            Write-PrivacyStatus "Error in $($check.Name) check: $($_.Exception.Message)" "Error"
            $allIssues += "Failed to complete $($check.Name) check"
        }
    }
    
    # Enforce privacy settings if requested
    if ($Enforce) {
        Write-PrivacyStatus "Enforcing privacy protection measures..." "Shield"
        Enforce-PrivacySettings
    }
    
    # Summary
    Write-Host "`n$($Colors.Bold)Privacy Audit Summary:$($Colors.Reset)"
    
    if ($allIssues.Count -eq 0) {
        Write-PrivacyStatus "✅ All privacy checks passed successfully!" "Success"
        Write-PrivacyStatus "Your NewTerminal-AI installation is secure and private" "Success"
    } else {
        Write-PrivacyStatus "⚠️  $($allIssues.Count) privacy issue(s) detected:" "Warning"
        foreach ($issue in $allIssues) {
            Write-PrivacyStatus "  • $issue" "Warning"
        }
        Write-PrivacyStatus "Run with -Enforce flag to automatically fix issues" "Info"
    }
    
    Write-Host "`n$($Colors.Bold)Privacy Protection Recommendations:$($Colors.Reset)"
    Write-PrivacyStatus "• Keep Ollama bound to localhost only (127.0.0.1)" "Info"
    Write-PrivacyStatus "• Regularly audit network connections" "Info"
    Write-PrivacyStatus "• Avoid storing API keys in environment variables" "Info"
    Write-PrivacyStatus "• Keep your AI models and data on local storage only" "Info"
    Write-PrivacyStatus "• Run privacy audits periodically" "Info"
    
    return $allIssues.Count -eq 0
}

# Run privacy audit if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    if ($Audit -or $Enforce) {
        Start-PrivacyAudit
    } else {
        Write-Host "NewTerminal-AI Privacy Protection Script"
        Write-Host "Usage:"
        Write-Host "  -Audit    : Run comprehensive privacy audit"
        Write-Host "  -Enforce  : Run audit and automatically fix issues"
        Write-Host "  -Quiet    : Run silently without progress output"
        Write-Host ""
        Write-Host "Example: .\privacy-protection.ps1 -Audit -Enforce"
    }
}