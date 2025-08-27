# NewTerminal-AI Installation Test Suite
# Comprehensive testing for Windows PowerShell installation

param(
    [switch]$Verbose,
    [switch]$SkipModelDownload
)

$ErrorActionPreference = "Stop"
$TestResults = @()

# Test result tracking
function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [string]$Details = ""
    )
    
    $TestResults += [PSCustomObject]@{
        Test = $TestName
        Passed = $Passed
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
    }
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status - $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    if ($Verbose -and $Details) {
        Write-Host "    Details: $Details" -ForegroundColor DarkGray
    }
}

# Test 1: Check if Ollama is installed and running
function Test-OllamaInstallation {
    try {
        $ollamaVersion = ollama --version 2>$null
        if ($ollamaVersion) {
            Add-TestResult "Ollama Installation" $true "Version: $ollamaVersion"
            return $true
        } else {
            Add-TestResult "Ollama Installation" $false "Ollama command not found"
            return $false
        }
    } catch {
        Add-TestResult "Ollama Installation" $false "Error checking Ollama: $($_.Exception.Message)"
        return $false
    }
}

# Test 2: Check if Ollama service is running
function Test-OllamaService {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Add-TestResult "Ollama Service" $true "Service is running on port 11434"
            return $true
        } else {
            Add-TestResult "Ollama Service" $false "Service not responding"
            return $false
        }
    } catch {
        Add-TestResult "Ollama Service" $false "Cannot connect to Ollama service: $($_.Exception.Message)"
        return $false
    }
}

# Test 3: Check available models
function Test-AvailableModels {
    try {
        $models = ollama list 2>$null
        if ($models -and $models.Count -gt 1) {
            $modelCount = ($models | Measure-Object).Count - 1  # Subtract header
            Add-TestResult "Available Models" $true "Found $modelCount models" $models
            return $true
        } else {
            Add-TestResult "Available Models" $false "No models found"
            return $false
        }
    } catch {
        Add-TestResult "Available Models" $false "Error listing models: $($_.Exception.Message)"
        return $false
    }
}

# Test 4: Test model functionality
function Test-ModelFunctionality {
    try {
        $models = ollama list 2>$null
        if ($models -and $models.Count -gt 1) {
            $firstModel = ($models | Select-Object -Skip 1 | Select-Object -First 1) -split '\s+' | Select-Object -First 1
            
            Write-Host "Testing model: $firstModel" -ForegroundColor Cyan
            $testPrompt = "Say 'Hello World' in exactly two words."
            
            # Use a timeout for the model test
            $job = Start-Job -ScriptBlock {
                param($model, $prompt)
                ollama run $model $prompt
            } -ArgumentList $firstModel, $testPrompt
            
            $result = Wait-Job $job -Timeout 30
            if ($result) {
                $output = Receive-Job $job
                Remove-Job $job
                
                if ($output -and $output.ToString().Trim()) {
                    Add-TestResult "Model Functionality" $true "Model responded successfully" "Output: $($output.ToString().Trim())"
                    return $true
                } else {
                    Add-TestResult "Model Functionality" $false "Model did not respond"
                    return $false
                }
            } else {
                Remove-Job $job -Force
                Add-TestResult "Model Functionality" $false "Model test timed out after 30 seconds"
                return $false
            }
        } else {
            Add-TestResult "Model Functionality" $false "No models available to test"
            return $false
        }
    } catch {
        Add-TestResult "Model Functionality" $false "Error testing model: $($_.Exception.Message)"
        return $false
    }
}

# Test 5: Check NewTerminal-AI module
function Test-NewTerminalAIModule {
    try {
        $modulePath = Join-Path $PSScriptRoot "..\NewTerminal-AI.psm1"
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force -ErrorAction Stop
            
            # Check if AI function is available
            if (Get-Command "Invoke-AICommand" -ErrorAction SilentlyContinue) {
                Add-TestResult "NewTerminal-AI Module" $true "Module loaded successfully"
                return $true
            } else {
                Add-TestResult "NewTerminal-AI Module" $false "AI command not available after import"
                return $false
            }
        } else {
            Add-TestResult "NewTerminal-AI Module" $false "Module file not found at $modulePath"
            return $false
        }
    } catch {
        Add-TestResult "NewTerminal-AI Module" $false "Error loading module: $($_.Exception.Message)"
        return $false
    }
}

# Test 6: Check PowerShell profile configuration
function Test-PowerShellProfile {
    try {
        $profilePath = $PROFILE.CurrentUserAllHosts
        if (Test-Path $profilePath) {
            $profileContent = Get-Content $profilePath -Raw
            if ($profileContent -match "NewTerminal-AI") {
                Add-TestResult "PowerShell Profile" $true "Profile configured with NewTerminal-AI"
                return $true
            } else {
                Add-TestResult "PowerShell Profile" $false "Profile exists but not configured for NewTerminal-AI"
                return $false
            }
        } else {
            Add-TestResult "PowerShell Profile" $false "PowerShell profile not found"
            return $false
        }
    } catch {
        Add-TestResult "PowerShell Profile" $false "Error checking profile: $($_.Exception.Message)"
        return $false
    }
}

# Test 7: Test AI command integration
function Test-AICommandIntegration {
    try {
        # Test if 'ai' alias/function works
        if (Get-Command "ai" -ErrorAction SilentlyContinue) {
            Add-TestResult "AI Command Integration" $true "'ai' command is available"
            return $true
        } else {
            Add-TestResult "AI Command Integration" $false "'ai' command not found"
            return $false
        }
    } catch {
        Add-TestResult "AI Command Integration" $false "Error testing AI command: $($_.Exception.Message)"
        return $false
    }
}

# Test 8: System requirements check
function Test-SystemRequirements {
    try {
        # Check RAM
        $RAM_GB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        
        # Check disk space
        $diskSpace = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
        $freeSpaceGB = [math]::Round($diskSpace.FreeSpace / 1GB)
        
        $requirements = @()
        if ($RAM_GB -ge 4) {
            $requirements += "RAM: ${RAM_GB}GB (OK)"
        } else {
            $requirements += "RAM: ${RAM_GB}GB (Warning: Minimum 4GB recommended)"
        }
        
        if ($freeSpaceGB -ge 10) {
            $requirements += "Disk: ${freeSpaceGB}GB free (OK)"
        } else {
            $requirements += "Disk: ${freeSpaceGB}GB free (Warning: Minimum 10GB recommended)"
        }
        
        Add-TestResult "System Requirements" $true ($requirements -join ", ")
        return $true
    } catch {
        Add-TestResult "System Requirements" $false "Error checking system requirements: $($_.Exception.Message)"
        return $false
    }
}

# Main test execution
function Run-AllTests {
    Write-Host "=== NewTerminal-AI Installation Test Suite ===" -ForegroundColor Cyan
    Write-Host "Starting comprehensive testing..." -ForegroundColor Yellow
    Write-Host ""
    
    # Run all tests
    Test-SystemRequirements
    Test-OllamaInstallation
    Test-OllamaService
    Test-AvailableModels
    
    if (-not $SkipModelDownload) {
        Test-ModelFunctionality
    } else {
        Add-TestResult "Model Functionality" $true "Skipped (SkipModelDownload flag set)"
    }
    
    Test-NewTerminalAIModule
    Test-PowerShellProfile
    Test-AICommandIntegration
    
    # Generate summary
    Write-Host ""
    Write-Host "=== Test Summary ===" -ForegroundColor Cyan
    
    $passedTests = ($TestResults | Where-Object { $_.Passed }).Count
    $totalTests = $TestResults.Count
    $failedTests = $totalTests - $passedTests
    
    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    
    if ($failedTests -gt 0) {
        Write-Host ""
        Write-Host "Failed Tests:" -ForegroundColor Red
        $TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  - $($_.Test): $($_.Message)" -ForegroundColor Red
        }
    }
    
    # Export detailed results
    $resultsPath = Join-Path $PSScriptRoot "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $TestResults | ConvertTo-Json -Depth 3 | Out-File $resultsPath -Encoding UTF8
    Write-Host ""
    Write-Host "Detailed results saved to: $resultsPath" -ForegroundColor Gray
    
    return ($failedTests -eq 0)
}

# Run the tests
$success = Run-AllTests

if ($success) {
    Write-Host ""
    Write-Host "🎉 All tests passed! NewTerminal-AI is ready to use." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Some tests failed. Please check the issues above." -ForegroundColor Red
    exit 1
}