# Runs PSScriptAnalyzer over the repository.
# - Every *.ps1 / *.psm1 file must be free of Error-severity findings.
# - The main module must also be free of Warning-severity findings, except the
#   rules excluded below, which conflict with how an interactive terminal tool works.
#   Exits non-zero when findings are reported.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
    throw "PSScriptAnalyzer is not installed. Run: Install-Module PSScriptAnalyzer -Scope CurrentUser"
}

$moduleSettings = @{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',                        # coloured interactive output is the UI
        'PSAvoidUsingInvokeExpression',                 # executing the generated command is the core feature
        'PSUseShouldProcessForStateChangingFunctions',  # in-memory history helpers only
        'PSUseBOMForUnicodeEncodedFile'                 # UTF-8 without BOM is intentional for cross-platform use
    )
}

$findings = @()
$findings += Invoke-ScriptAnalyzer -Path $root -Recurse -Severity Error
$findings += Invoke-ScriptAnalyzer -Path (Join-Path $root 'NewTerminal-AI.psm1') -Settings $moduleSettings

if ($findings.Count -gt 0) {
    $findings | Format-Table ScriptName, Line, Severity, RuleName, Message -AutoSize | Out-String -Width 250 | Write-Output
    Write-Error "PSScriptAnalyzer reported $($findings.Count) finding(s)."
    exit 1
}

Write-Output "PSScriptAnalyzer: no findings."
