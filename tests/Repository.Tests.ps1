# Consistency checks across the installers, module, workflows and file encodings.

BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    $env:NEWTERMINAL_AI_NO_AUTOSTART = '1'
    Remove-Item Env:NEWTERMINAL_AI_MODEL -ErrorAction SilentlyContinue
}

BeforeDiscovery {
    $root = Split-Path $PSScriptRoot -Parent
    # releases/ is an archived snapshot and is not maintained
    $script:PowerShellFiles = Get-ChildItem -Path $root -Recurse -File -Include *.ps1, *.psm1 |
        Where-Object { $_.FullName -notmatch '[\\/](releases|\.git)[\\/]' } |
        ForEach-Object { @{ Path = $_.FullName; Name = [IO.Path]::GetRelativePath($root, $_.FullName) } }
}

Describe 'PowerShell sources' {
    It '<Name> parses without errors' -ForEach $PowerShellFiles {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }

    It '<Name> loads in Windows PowerShell 5.1 (ASCII or UTF-8 with BOM)' -ForEach $PowerShellFiles {
        # Windows PowerShell 5.1 reads BOM-less files as ANSI, which garbles emoji into quote characters
        $bytes = [IO.File]::ReadAllBytes($Path)
        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        $isAscii = -not ($bytes | Where-Object { $_ -gt 0x7F })
        ($hasBom -or $isAscii) | Should -BeTrue
    }

    It 'install.ps1 is plain ASCII without a BOM so "irm | iex" works in every PowerShell' {
        $bytes = [IO.File]::ReadAllBytes((Join-Path $RepoRoot 'install.ps1'))
        @($bytes | Where-Object { $_ -gt 0x7F }).Count | Should -Be 0
    }
}

Describe 'Installers match the module' {
    BeforeAll {
        $moduleSource = Get-Content (Join-Path $RepoRoot 'NewTerminal-AI.psm1') -Raw
        $script:DefaultModel = [regex]::Match($moduleSource, '\$script:OllamaModel = .*else \{ "([^"]+)" \}').Groups[1].Value
    }

    It 'the module has a default model' {
        $DefaultModel | Should -Not -BeNullOrEmpty
    }

    It '<_> pulls the model the module uses by default' -ForEach @('install.ps1', 'install.sh') {
        Get-Content (Join-Path $RepoRoot $_) -Raw | Should -Match ("ollama pull " + [regex]::Escape($DefaultModel))
    }

    It 'the install.ps1 manifest exports every function the module exports' {
        Import-Module (Join-Path $RepoRoot 'NewTerminal-AI.psm1') -Force
        $exported = (Get-Module NewTerminal-AI).ExportedFunctions.Keys
        $installer = Get-Content (Join-Path $RepoRoot 'install.ps1') -Raw
        $listed = [regex]::Match($installer, 'FunctionsToExport = @\(([^)]*)\)').Groups[1].Value -split ',' |
            ForEach-Object { $_.Trim().Trim("'") }
        $exported | Where-Object { $_ -notin $listed } | Should -BeNullOrEmpty
        Remove-Module NewTerminal-AI -Force
    }
}

Describe 'GitHub workflows' {
    It 'release.yml only copies files that exist' {
        $workflow = Get-Content (Join-Path $RepoRoot '.github/workflows/release.yml')
        $sources = $workflow | Where-Object { $_ -match '^\s*cp\s' } | ForEach-Object {
            ($_.Trim() -split '\s+' | Where-Object { $_ -notmatch '^-' })[1]
        }
        $sources | Should -Not -BeNullOrEmpty
        foreach ($source in $sources) {
            Join-Path $RepoRoot $source | Should -Exist
        }
    }
}
