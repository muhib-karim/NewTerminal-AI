#!/bin/bash

# Universal NewTerminal-AI Installation Script
# Automatically detects platform and runs the appropriate enhanced installer

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to detect platform and run appropriate installer
main() {
    print_colored $BLUE "=== NewTerminal-AI Universal Installer ==="
    print_colored $WHITE "Detecting your platform..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Detect platform
    case "$(uname -s)" in
        Darwin*)
            PLATFORM="macOS"
            INSTALLER="$SCRIPT_DIR/install-enhanced.sh"
            ;;
        Linux*)
            PLATFORM="Linux"
            INSTALLER="$SCRIPT_DIR/install-enhanced.sh"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            PLATFORM="Windows"
            INSTALLER="$SCRIPT_DIR/install-enhanced.ps1"
            ;;
        *)
            print_colored $RED "Unsupported platform: $(uname -s)"
            print_colored $YELLOW "This installer supports Windows, macOS, and Linux only."
            exit 1
            ;;
    esac
    
    print_colored $GREEN "Platform detected: $PLATFORM"
    
    # Check if the appropriate installer exists
    if [ ! -f "$INSTALLER" ]; then
        print_colored $RED "Error: Enhanced installer not found at $INSTALLER"
        print_colored $YELLOW "Please ensure all installation files are present."
        exit 1
    fi
    
    print_colored $CYAN "Running enhanced installer for $PLATFORM..."
    sleep 1
    
    # Run the appropriate installer
    case "$PLATFORM" in
        "Windows")
            if command -v powershell >/dev/null 2>&1; then
                powershell -ExecutionPolicy Bypass -File "$INSTALLER"
            elif command -v pwsh >/dev/null 2>&1; then
                pwsh -ExecutionPolicy Bypass -File "$INSTALLER"
            else
                print_colored $RED "Error: PowerShell not found"
                print_colored $YELLOW "Please install PowerShell to continue."
                exit 1
            fi
            ;;
        "macOS"|"Linux")
            # Make sure the script is executable
            chmod +x "$INSTALLER"
            bash "$INSTALLER"
            ;;
    esac
}

# Run main function
main "$@"