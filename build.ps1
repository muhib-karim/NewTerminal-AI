<#
.SYNOPSIS
    Lint and test NewTerminal-AI with one command.
.EXAMPLE
    pwsh ./build.ps1                # syntax check + PSScriptAnalyzer + Pester
    pwsh ./build.ps1 -Task Test     # Pester only
    pwsh ./build.ps1 -Bootstrap     # install Pester / PSScriptAnalyzer first
#>
param(
    [ValidateSet('All', 'Lint', 'Test')]
    [string]$Task = 'All',
    [switch]$Bootstrap
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
# Importing the module must never start the interactive AI terminal during a build
$env:NEWTERMINAL_AI_NO_AUTOSTART = '1'

if ($Bootstrap) {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module Pester -MinimumVersion 5.5.0 -Scope CurrentUser -Force -SkipPublisherCheck
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
}

# releases/ is an archived snapshot of v2.0.0 and is not linted or tested
$sourceFiles = Get-ChildItem -Path $PSScriptRoot -Recurse -File -Include *.ps1, *.psm1 |
    Where-Object { $_.FullName -notmatch '[\\/](releases|\.git)[\\/]' }

function Invoke-Lint {
    $problems = 0

    foreach ($file in $sourceFiles) {
        $tokens = $null; $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
        foreach ($e in $errors) {
            Write-Host "$($file.Name):$($e.Extent.StartLineNumber): $($e.Message)" -ForegroundColor Red
            $problems++
        }
    }
    Write-Host "PowerShell syntax: $($sourceFiles.Count) files checked"

    if (Get-Command bash -ErrorAction SilentlyContinue) {
        $shellFiles = Get-ChildItem -Path $PSScriptRoot -Recurse -File -Filter *.sh |
            Where-Object { $_.FullName -notmatch '[\\/](releases|\.git)[\\/]' }
        foreach ($file in $shellFiles) {
            bash -n $file.FullName
            if ($LASTEXITCODE -ne 0) { $problems++ }
        }
        Write-Host "bash -n: $($shellFiles.Count) files checked"
    }

    if (Get-Module -ListAvailable PSScriptAnalyzer) {
        $findings = $sourceFiles | ForEach-Object { Invoke-ScriptAnalyzer -Path $_.FullName -Severity Error }
        $findings | Format-Table -AutoSize | Out-String | Write-Host
        $problems += @($findings).Count
        Write-Host "PSScriptAnalyzer (Error severity): $(@($findings).Count) findings"
    } else {
        Write-Host "PSScriptAnalyzer not installed; skipping (use -Bootstrap)" -ForegroundColor Yellow
    }

    if ($problems) { throw "Lint failed with $problems problem(s)" }
}

function Invoke-Test {
    Import-Module Pester -MinimumVersion 5.5.0
    $config = New-PesterConfiguration
    $config.Run.Path = Join-Path $PSScriptRoot 'tests'
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = Join-Path $PSScriptRoot 'testResults.xml'
    $result = Invoke-Pester -Configuration $config
    if ($result.FailedCount -gt 0 -or $result.Result -ne 'Passed') {
        throw "Pester: $($result.FailedCount) test(s) failed"
    }
}

if ($Task -in 'All', 'Lint') { Invoke-Lint }
if ($Task -in 'All', 'Test') { Invoke-Test }
