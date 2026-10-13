# Pester tests for NewTerminal-AI.psm1
# Run with: Invoke-Pester -Path ./tests
# No Ollama server is required: network calls are mocked.

BeforeAll {
    $env:NEWTERMINAL_AI_NO_AUTOSTART = '1'
    $script:ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'NewTerminal-AI.psm1'
    Import-Module $script:ModulePath -Force
}

AfterAll {
    Remove-Module NewTerminal-AI -Force -ErrorAction SilentlyContinue
    Remove-Item Env:NEWTERMINAL_AI_NO_AUTOSTART -ErrorAction SilentlyContinue
}

Describe 'Module import' {
    It 'imports without starting the interactive REPL when NEWTERMINAL_AI_NO_AUTOSTART is set' {
        Get-Module NewTerminal-AI | Should -Not -BeNullOrEmpty
    }

    It 'exports <Name>' -TestCases @(
        @{ Name = 'Invoke-AICommand' }
        @{ Name = 'Invoke-AICommandAuto' }
        @{ Name = 'Start-NLMode' }
        @{ Name = 'Start-AITerminal' }
        @{ Name = 'Test-OllamaConnection' }
        @{ Name = 'Show-CommandHistory' }
        @{ Name = 'Clear-CommandHistory' }
        @{ Name = 'Get-ContextInfo' }
    ) {
        param($Name)
        (Get-Command -Module NewTerminal-AI -Name $Name -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }

    It 'exports alias <Alias> -> <Target>' -TestCases @(
        @{ Alias = 'ai';  Target = 'Invoke-AICommand' }
        @{ Alias = 'aia'; Target = 'Invoke-AICommandAuto' }
        @{ Alias = 'nl';  Target = 'Start-NLMode' }
    ) {
        param($Alias, $Target)
        (Get-Alias -Name $Alias).ResolvedCommandName | Should -Be $Target
    }

    It 'does not export internal helpers' {
        Get-Command -Module NewTerminal-AI -Name 'Invoke-OllamaAPI' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}

Describe 'Configuration via environment variables' {
    AfterEach {
        Remove-Item Env:NEWTERMINAL_AI_MODEL, Env:NEWTERMINAL_AI_OLLAMA_URL -ErrorAction SilentlyContinue
        Import-Module $script:ModulePath -Force
    }

    It 'defaults to llama3.2:1b on localhost:11434' {
        Import-Module $script:ModulePath -Force
        InModuleScope NewTerminal-AI {
            $script:OllamaModel | Should -Be 'llama3.2:1b'
            $script:OllamaBaseUrl | Should -Be 'http://localhost:11434'
        }
    }

    It 'honours NEWTERMINAL_AI_MODEL and NEWTERMINAL_AI_OLLAMA_URL' {
        $env:NEWTERMINAL_AI_MODEL = 'phi3:mini'
        $env:NEWTERMINAL_AI_OLLAMA_URL = 'http://ollama.internal:8080/'
        Import-Module $script:ModulePath -Force
        InModuleScope NewTerminal-AI {
            $script:OllamaModel | Should -Be 'phi3:mini'
            $script:OllamaBaseUrl | Should -Be 'http://ollama.internal:8080'
        }
    }
}

Describe 'ConvertTo-CleanCommand' {
    It 'returns <Expected> for <Name>' -TestCases @(
        @{ Name = 'plain command';          Response = 'Get-Date';                                Expected = 'Get-Date' }
        @{ Name = 'surrounding whitespace'; Response = "  Get-Process `n";                        Expected = 'Get-Process' }
        @{ Name = 'fenced block';           Response = "``````powershell`nGet-ChildItem`n``````"; Expected = 'Get-ChildItem' }
        @{ Name = 'bare fence, CRLF';       Response = "``````\`r`nGet-Service`r`n``````";       Expected = 'Get-Service' }
        @{ Name = 'empty string';           Response = '';                                        Expected = '' }
    ) {
        param($Response, $Expected)
        InModuleScope NewTerminal-AI -Parameters @{ R = $Response; E = $Expected } {
            param($R, $E)
            ConvertTo-CleanCommand -Response $R | Should -BeExactly $E
        }
    }
}

Describe 'Test-CommandSafety' {
    It 'flags dangerous command: <Command>' -TestCases @(
        @{ Command = 'rm -rf /' }
        @{ Command = 'Remove-Item -Path C:\ -Recurse -Force' }
        @{ Command = 'Remove-Item -Recurse -Force C:\Windows' }
        @{ Command = 'del /s /q c:\' }
        @{ Command = 'format c:' }
        @{ Command = 'Stop-Computer' }
        @{ Command = 'Restart-Computer -Force' }
        @{ Command = 'shutdown /s /t 0' }
        @{ Command = 'reg delete HKLM\Software\Foo /f' }
        @{ Command = 'Remove-Item $env:SystemRoot\System32 -Recurse' }
        @{ Command = 'Remove-Item $env:ProgramFiles\App' }
    ) {
        param($Command)
        InModuleScope NewTerminal-AI -Parameters @{ C = $Command } {
            param($C)
            Test-CommandSafety -Command $C | Should -BeFalse
        }
    }

    It 'allows safe command: <Command>' -TestCases @(
        @{ Command = 'Get-ChildItem' }
        @{ Command = 'Get-Date' }
        @{ Command = 'Get-PSDrive -PSProvider FileSystem' }
        @{ Command = 'New-Item -ItemType File -Name "notes.txt"' }
        @{ Command = 'Remove-Item ./build.log' }
        @{ Command = 'git status' }
    ) {
        param($Command)
        InModuleScope NewTerminal-AI -Parameters @{ C = $Command } {
            param($C)
            Test-CommandSafety -Command $C | Should -BeTrue
        }
    }
}

Describe 'Get-ContextInfo' {
    BeforeEach {
        $dir = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $dir | Out-Null
        Push-Location $dir
    }
    AfterEach { Pop-Location }

    It 'detects a general directory' {
        (Get-ContextInfo).PathType | Should -Be 'General Directory'
    }

    It 'detects a Node.js project' {
        Set-Content package.json '{}'
        (Get-ContextInfo).PathType | Should -Be 'Node.js Project'
    }

    It 'detects a .NET project' {
        Set-Content app.csproj '<Project />'
        (Get-ContextInfo).PathType | Should -Be '.NET Project'
    }

    It 'detects a Python project' {
        Set-Content main.py 'print(1)'
        (Get-ContextInfo).PathType | Should -Be 'Python Project'
    }

    It 'detects a Git repository with its branch and status' -Skip:(-not (Get-Command git -ErrorAction SilentlyContinue)) {
        git init -q -b ci-branch . 2>$null
        Set-Content untracked.txt 'x'
        $ctx = Get-ContextInfo
        $ctx.PathType | Should -Be 'Git Repository'
        $ctx.GitBranch | Should -Be 'ci-branch'
        $ctx.GitStatus | Should -Be 'Modified files present'
    }
}

Describe 'Get-CommandSuggestion' {
    It 'answers "<Question>" locally without calling Ollama' -TestCases @(
        @{ Question = 'what model are you using' }
        @{ Question = 'which model is running' }
        @{ Question = 'What AI model is this?' }
    ) {
        param($Question)
        InModuleScope NewTerminal-AI -Parameters @{ Q = $Question } {
            param($Q)
            Mock Invoke-OllamaAPI { throw 'should not be called' }
            Get-CommandSuggestion -NaturalLanguage $Q | Should -Match 'Current AI Model: llama3\.2:1b'
            Should -Invoke Invoke-OllamaAPI -Times 0 -Exactly
        }
    }

    It 'sends the request and a system prompt to Ollama and trims the reply' {
        InModuleScope NewTerminal-AI {
            Mock Invoke-OllamaAPI { "  Get-Date `n" }
            Get-CommandSuggestion -NaturalLanguage 'show the date' | Should -BeExactly 'Get-Date'
            Should -Invoke Invoke-OllamaAPI -Times 1 -Exactly -ParameterFilter {
                $Prompt -eq 'show the date' -and $SystemPrompt -match 'PowerShell command generator'
            }
        }
    }

    It 'wraps API failures in a descriptive error' {
        InModuleScope NewTerminal-AI {
            Mock Invoke-OllamaAPI { throw 'connection refused' }
            { Get-CommandSuggestion -NaturalLanguage 'list files' } | Should -Throw '*Failed to generate command*connection refused*'
        }
    }
}

Describe 'Invoke-OllamaAPI' {
    It 'posts a non-streaming generate request for the configured model' {
        InModuleScope NewTerminal-AI {
            Mock Invoke-RestMethod { [pscustomobject]@{ response = 'Get-Process' } }
            Invoke-OllamaAPI -Prompt 'list processes' -SystemPrompt 'sys' | Should -Be 'Get-Process'
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $body = $Body | ConvertFrom-Json
                $Uri -eq 'http://localhost:11434/api/generate' -and $Method -eq 'Post' -and
                $body.model -eq 'llama3.2:1b' -and $body.stream -eq $false -and $body.prompt -eq 'list processes'
            }
        }
    }
}

Describe 'Test-OllamaConnection' {
    It 'returns $true when the tags endpoint responds' {
        InModuleScope NewTerminal-AI {
            Mock Invoke-RestMethod { @{ models = @() } }
            Test-OllamaConnection | Should -BeTrue
            Should -Invoke Invoke-RestMethod -ParameterFilter { $Uri -eq 'http://localhost:11434/api/tags' }
        }
    }

    It 'returns $false when the request fails' {
        InModuleScope NewTerminal-AI {
            Mock Invoke-RestMethod { throw 'unreachable' }
            Test-OllamaConnection | Should -BeFalse
        }
    }
}

Describe 'Command history' {
    BeforeEach { InModuleScope NewTerminal-AI { $script:UserHistory = @() } }

    It 'keeps only the last 50 entries' {
        InModuleScope NewTerminal-AI {
            1..55 | ForEach-Object { Add-ToHistory -Request "req $_" -Command 'Get-Date' -Executed $true }
            $script:UserHistory.Count | Should -Be 50
            $script:UserHistory[0].Request | Should -Be 'req 6'
            $script:UserHistory[-1].Request | Should -Be 'req 55'
        }
    }

    It 'shows a single history entry' {
        Add-ToHistory -Request 'show the date' -Command 'Get-Date' -Executed $true
        $output = (Show-CommandHistory 6>&1 | Out-String)
        $output | Should -Match "'show the date'"
        $output | Should -Match 'Get-Date'
    }

    It 'clears the history' {
        Add-ToHistory -Request 'x' -Command 'Get-Date' -Executed $true
        Clear-CommandHistory 6>&1 | Out-Null
        InModuleScope NewTerminal-AI { $script:UserHistory.Count | Should -Be 0 }
    }
}

Describe 'Invoke-AICommand' {
    BeforeEach { InModuleScope NewTerminal-AI { $script:UserHistory = @() } }

    It 'stops early when Ollama is not reachable' {
        InModuleScope NewTerminal-AI {
            Mock Test-OllamaConnection { $false }
            Mock Get-CommandSuggestion { 'Get-Date' }
            Invoke-AICommand -NaturalLanguage 'show the date' -AutoExecute -CleanOutput 6>&1 | Out-Null
            Should -Invoke Get-CommandSuggestion -Times 0 -Exactly
        }
    }

    It 'refuses to auto-execute a command flagged as dangerous' {
        InModuleScope NewTerminal-AI {
            Mock Test-OllamaConnection { $true }
            Mock Get-CommandSuggestion { 'Restart-Computer -Force' }
            Mock Invoke-Expression { }
            Invoke-AICommand -NaturalLanguage 'reboot' -AutoExecute -CleanOutput 6>&1 | Out-Null
            Should -Invoke Invoke-Expression -Times 0 -Exactly
            $script:UserHistory[-1].Executed | Should -BeFalse
        }
    }

    It 'auto-executes a safe, de-fenced command and records it' {
        InModuleScope NewTerminal-AI {
            Mock Test-OllamaConnection { $true }
            Mock Get-CommandSuggestion { "``````powershell`nGet-Date`n``````" }
            Mock Invoke-Expression { 'ran' }
            Invoke-AICommand -NaturalLanguage 'show the date' -AutoExecute -CleanOutput 6>&1 | Out-Null
            Should -Invoke Invoke-Expression -Times 1 -Exactly -ParameterFilter { $Command -eq 'Get-Date' }
            $script:UserHistory[-1].Command | Should -Be 'Get-Date'
            $script:UserHistory[-1].Executed | Should -BeTrue
        }
    }
}

Describe 'Interactive REPL' {
    It '<Name> returns when the user types exit' -TestCases @(
        @{ Name = 'Start-AITerminal' }
        @{ Name = 'Start-NLMode' }
    ) {
        param($Name)
        InModuleScope NewTerminal-AI -Parameters @{ N = $Name } {
            param($N)
            $script:reads = 0
            Mock Read-Host {
                $script:reads++
                if ($script:reads -gt 1) { throw 'REPL did not exit' }
                'exit'
            }
            & $N 6>&1 | Out-Null
            $script:reads | Should -Be 1
        }
    }
}
