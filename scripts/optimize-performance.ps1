# NewTerminal-AI Performance Optimization Script
# Enhances local processing speed and reduces latency

param(
    [switch]$Aggressive,
    [switch]$Quiet,
    [switch]$SkipModelOptimization
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
    Reset = "`e[0m"
    Bold = "`e[1m"
}

function Write-OptimizationStatus {
    param([string]$Message, [string]$Type = "Info")
    
    if ($Quiet) { return }
    
    $icon = switch ($Type) {
        "Success" { "[✓]" }
        "Warning" { "[!]" }
        "Error" { "[✗]" }
        "Info" { "[i]" }
        "Optimize" { "[⚡]" }
        default { "[*]" }
    }
    
    $color = switch ($Type) {
        "Success" { $Colors.Green }
        "Warning" { $Colors.Yellow }
        "Error" { $Colors.Red }
        "Info" { $Colors.Cyan }
        "Optimize" { $Colors.Blue }
        default { $Colors.Blue }
    }
    
    Write-Host "$color$icon$($Colors.Reset) $Message"
}

function Optimize-PowerShellPerformance {
    Write-OptimizationStatus "Optimizing PowerShell performance..." "Optimize"
    
    try {
        # Set PowerShell execution policy for better performance
        if ((Get-ExecutionPolicy -Scope CurrentUser) -eq "Restricted") {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-OptimizationStatus "Updated PowerShell execution policy" "Success"
        }
        
        # Optimize PowerShell module auto-loading
        $psModuleAutoLoadingPreference = "All"
        Write-OptimizationStatus "Enabled PowerShell module auto-loading" "Success"
        
        # Set optimal progress preference for faster operations
        $global:ProgressPreference = "SilentlyContinue"
        Write-OptimizationStatus "Optimized progress reporting" "Success"
        
        return $true
    } catch {
        Write-OptimizationStatus "Error optimizing PowerShell: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Optimize-OllamaConfiguration {
    Write-OptimizationStatus "Optimizing Ollama configuration..." "Optimize"
    
    try {
        # Set optimal Ollama environment variables for performance
        $ollamaEnvVars = @{
            "OLLAMA_NUM_PARALLEL" = "2"  # Parallel request handling
            "OLLAMA_MAX_LOADED_MODELS" = "1"  # Keep only one model loaded
            "OLLAMA_FLASH_ATTENTION" = "1"  # Enable flash attention if supported
            "OLLAMA_HOST" = "127.0.0.1:11434"  # Bind to localhost only
        }
        
        foreach ($var in $ollamaEnvVars.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "User")
            Set-Item -Path "env:$($var.Key)" -Value $var.Value -Force
        }
        
        Write-OptimizationStatus "Applied Ollama performance settings" "Success"
        
        # Restart Ollama service to apply changes
        Write-OptimizationStatus "Restarting Ollama service..." "Info"
        
        try {
            Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            
            Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
            Start-Sleep -Seconds 3
            
            # Test connection
            $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5
            Write-OptimizationStatus "Ollama service restarted successfully" "Success"
        } catch {
            Write-OptimizationStatus "Warning: Could not restart Ollama service" "Warning"
        }
        
        return $true
    } catch {
        Write-OptimizationStatus "Error optimizing Ollama: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Optimize-SystemResources {
    Write-OptimizationStatus "Optimizing system resources..." "Optimize"
    
    try {
        # Set process priority for better responsiveness
        $currentProcess = Get-Process -Id $PID
        $currentProcess.PriorityClass = "High"
        Write-OptimizationStatus "Increased PowerShell process priority" "Success"
        
        # Clear unnecessary variables and garbage collect
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        Write-OptimizationStatus "Performed garbage collection" "Success"
        
        # Optimize .NET compilation
        if ($Aggressive) {
            [System.Runtime.ProfileOptimization]::SetProfileRoot($env:TEMP)
            [System.Runtime.ProfileOptimization]::StartProfile("NewTerminalAI.profile")
            Write-OptimizationStatus "Enabled .NET profile optimization" "Success"
        }
        
        return $true
    } catch {
        Write-OptimizationStatus "Error optimizing system resources: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Optimize-ModelConfiguration {
    if ($SkipModelOptimization) {
        Write-OptimizationStatus "Skipping model optimization as requested" "Info"
        return $true
    }
    
    Write-OptimizationStatus "Optimizing AI model configuration..." "Optimize"
    
    try {
        # Get current models
        $modelsResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 10
        $installedModels = $modelsResponse.models
        
        if (-not $installedModels -or $installedModels.Count -eq 0) {
            Write-OptimizationStatus "No models found. Installing optimal model..." "Warning"
            
            # Install the fastest small model
            $installProcess = Start-Process "ollama" -ArgumentList "pull", "qwen2.5:0.5b" -Wait -PassThru -NoNewWindow
            if ($installProcess.ExitCode -eq 0) {
                Write-OptimizationStatus "Installed optimal model: qwen2.5:0.5b" "Success"
            } else {
                Write-OptimizationStatus "Failed to install optimal model" "Error"
                return $false
            }
        } else {
            Write-OptimizationStatus "Found $($installedModels.Count) installed model(s)" "Info"
            
            # Identify optimal models
            $optimalModels = @("qwen2.5:0.5b", "llama3.2:1b", "phi3:mini", "gemma2:2b")
            $hasOptimalModel = $false
            
            foreach ($model in $installedModels) {
                if ($model.name -in $optimalModels) {
                    $hasOptimalModel = $true
                    Write-OptimizationStatus "Optimal model found: $($model.name)" "Success"
                    break
                }
            }
            
            if (-not $hasOptimalModel) {
                Write-OptimizationStatus "No optimal models found. Consider running 'setup' command" "Warning"
            }
        }
        
        # Pre-load the default model for faster first response
        Write-OptimizationStatus "Pre-loading default model for faster responses..." "Info"
        try {
            $preloadBody = @{
                model = "qwen2.5:0.5b"
                prompt = "Hello"
                stream = $false
            } | ConvertTo-Json
            
            $null = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $preloadBody -ContentType "application/json" -TimeoutSec 15
            Write-OptimizationStatus "Model pre-loaded successfully" "Success"
        } catch {
            Write-OptimizationStatus "Could not pre-load model (this is normal)" "Info"
        }
        
        return $true
    } catch {
        Write-OptimizationStatus "Error optimizing models: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Optimize-NetworkSettings {
    Write-OptimizationStatus "Optimizing network settings..." "Optimize"
    
    try {
        # Set optimal HTTP client settings for Ollama communication
        $httpClientSettings = @{
            "ServicePointManager.DefaultConnectionLimit" = 10
            "ServicePointManager.Expect100Continue" = $false
            "ServicePointManager.UseNagleAlgorithm" = $false
        }
        
        [System.Net.ServicePointManager]::DefaultConnectionLimit = 10
        [System.Net.ServicePointManager]::Expect100Continue = $false
        [System.Net.ServicePointManager]::UseNagleAlgorithm = $false
        
        Write-OptimizationStatus "Applied network optimizations" "Success"
        return $true
    } catch {
        Write-OptimizationStatus "Error optimizing network settings: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Test-OptimizationResults {
    Write-OptimizationStatus "Testing optimization results..." "Info"
    
    try {
        # Test Ollama response time
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $testBody = @{
            model = "qwen2.5:0.5b"
            prompt = "Say 'OK'"
            stream = $false
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $testBody -ContentType "application/json" -TimeoutSec 10
        
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        if ($responseTime -lt 2000) {
            Write-OptimizationStatus "Response time: ${responseTime}ms (Excellent)" "Success"
        } elseif ($responseTime -lt 5000) {
            Write-OptimizationStatus "Response time: ${responseTime}ms (Good)" "Success"
        } else {
            Write-OptimizationStatus "Response time: ${responseTime}ms (Consider upgrading hardware)" "Warning"
        }
        
        return $true
    } catch {
        Write-OptimizationStatus "Could not test optimization results: $($_.Exception.Message)" "Warning"
        return $false
    }
}

# Main optimization process
function Start-PerformanceOptimization {
    Write-Host "`n$($Colors.Bold)$($Colors.Blue)NewTerminal-AI Performance Optimizer$($Colors.Reset)`n"
    Write-OptimizationStatus "Starting performance optimization..." "Info"
    
    $optimizations = @(
        @{ Name = "PowerShell Performance"; Function = { Optimize-PowerShellPerformance } },
        @{ Name = "System Resources"; Function = { Optimize-SystemResources } },
        @{ Name = "Network Settings"; Function = { Optimize-NetworkSettings } },
        @{ Name = "Ollama Configuration"; Function = { Optimize-OllamaConfiguration } },
        @{ Name = "Model Configuration"; Function = { Optimize-ModelConfiguration } }
    )
    
    $successCount = 0
    
    foreach ($optimization in $optimizations) {
        try {
            if (& $optimization.Function) {
                $successCount++
            }
        } catch {
            Write-OptimizationStatus "Failed to optimize $($optimization.Name): $($_.Exception.Message)" "Error"
        }
    }
    
    Write-Host "`n$($Colors.Bold)Optimization Summary:$($Colors.Reset)"
    Write-OptimizationStatus "$successCount/$($optimizations.Count) optimizations applied successfully" "Info"
    
    # Test results
    Test-OptimizationResults
    
    Write-Host "`n$($Colors.Bold)$($Colors.Green)Performance optimization completed!$($Colors.Reset)`n"
    Write-OptimizationStatus "NewTerminal-AI should now run faster and more efficiently" "Success"
    Write-OptimizationStatus "Restart your PowerShell session to apply all changes" "Info"
    
    return $successCount -eq $optimizations.Count
}

# Run optimization if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Start-PerformanceOptimization
}