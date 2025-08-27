@echo off
REM NewTerminal-AI Quick Installer for Windows
REM This batch file runs the PowerShell installation script with proper execution policy

echo.
echo ========================================
echo  NewTerminal-AI Quick Installer
echo ========================================
echo.
echo This will install:
echo - Ollama (AI model runtime)
echo - Optimal AI model (qwen2.5:0.5b)
echo - NewTerminal-AI PowerShell module
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

echo.
echo Starting installation...
echo.

REM Run PowerShell script with bypass execution policy
powershell.exe -ExecutionPolicy Bypass -File "%~dp0scripts\install-enhanced-auto.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  Installation completed successfully!
    echo ========================================
    echo.
    echo To start using NewTerminal-AI:
    echo 1. Open PowerShell
    echo 2. Type: warp
    echo 3. Start using natural language commands!
    echo.
) else (
    echo.
    echo ========================================
    echo  Installation failed!
    echo ========================================
    echo.
    echo Please check the error messages above.
    echo You may need to run this as Administrator.
    echo.
)

echo Press any key to exit...
pause >nul