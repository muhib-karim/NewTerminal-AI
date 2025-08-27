#!/bin/bash
echo "Detecting operating system..."
OS_TYPE="$(uname)"
if [[ "$OS_TYPE" == "Linux" ]] || [[ "$OS_TYPE" == "Darwin" ]]; then
    chmod +x install.sh
    ./install.sh
else
    powershell.exe -ExecutionPolicy Bypass -File install.ps1
fi
