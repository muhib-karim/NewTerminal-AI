#!/bin/bash

# AI Terminal - Cross-Platform Installation Script
# Compatible with macOS and Linux

set -e

echo "🤖 AI Terminal - Cross-Platform Installation"
echo "==========================================="

# Check if PowerShell is installed
if ! command -v pwsh &> /dev/null; then
    echo "❌ PowerShell Core (pwsh) is required but not installed."
    echo "📦 Installing PowerShell Core..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install --cask powershell
        else
            echo "❌ Homebrew not found. Please install PowerShell Core manually:"
            echo "   https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-macos"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian: use the Microsoft repository matching this distribution and release
            . /etc/os-release
            wget -q "https://packages.microsoft.com/config/${ID}/${VERSION_ID}/packages-microsoft-prod.deb"
            sudo dpkg -i packages-microsoft-prod.deb
            sudo apt-get update
            sudo apt-get install -y powershell
            rm packages-microsoft-prod.deb
        elif command -v yum &> /dev/null; then
            # RHEL/CentOS
            curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
            sudo yum install -y powershell
        else
            echo "❌ Unsupported Linux distribution. Please install PowerShell Core manually:"
            echo "   https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux"
            exit 1
        fi
    else
        echo "❌ Unsupported operating system: $OSTYPE"
        exit 1
    fi
fi

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is required but not installed."
    echo "📦 Installing Ollama..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install ollama
        else
            curl -fsSL https://ollama.ai/install.sh | sh
        fi
    else
        # Linux
        curl -fsSL https://ollama.ai/install.sh | sh
    fi
fi

# Start Ollama service
echo "🚀 Starting Ollama service..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - start as background service
    ollama serve &
    sleep 3
else
    # Linux - check if systemd is available
    if command -v systemctl &> /dev/null; then
        sudo systemctl start ollama 2>/dev/null || {
            echo "Starting Ollama manually..."
            ollama serve &
            sleep 3
        }
    else
        ollama serve &
        sleep 3
    fi
fi

# Pull required model
echo "📥 Downloading AI model (llama3.2:3b)..."
ollama pull llama3.2:3b

# Create profile directory
PROFILE_DIR="$HOME/.config/powershell"
mkdir -p "$PROFILE_DIR"

# Install AI Terminal module
echo "📦 Installing AI Terminal module..."
MODULE_DIR="$HOME/.local/share/powershell/Modules/AITerminal"
mkdir -p "$MODULE_DIR"
# When piped through "curl | bash" there is no local checkout, so download the module instead
MODULE_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)/NewTerminal-AI.psm1"
MODULE_URL="https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/NewTerminal-AI.psm1"
if [[ -f "$MODULE_SOURCE" ]]; then
    cp "$MODULE_SOURCE" "$MODULE_DIR/AITerminal.psm1"
else
    curl -fsSL "$MODULE_URL" -o "$MODULE_DIR/AITerminal.psm1"
fi

# Add auto-load to the PowerShell profile without overwriting existing profile content
PROFILE_PATH="$PROFILE_DIR/Microsoft.PowerShell_profile.ps1"
if ! grep -qs "Import-Module AITerminal" "$PROFILE_PATH"; then
    printf '\n# AI Terminal Auto-Load\nImport-Module AITerminal\n' >> "$PROFILE_PATH"
fi

# Create launcher script
LAUNCHER_PATH="/usr/local/bin/ai-terminal"
sudo tee "$LAUNCHER_PATH" > /dev/null << 'EOF'
#!/bin/bash
# AI Terminal Launcher
if ! pgrep -f "ollama serve" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve &
    sleep 2
fi
pwsh -NoExit -Command "Import-Module AITerminal"
EOF

sudo chmod +x "$LAUNCHER_PATH"

echo "✅ Installation complete!"
echo ""
echo "🚀 Usage:"
echo "   ai-terminal    # Start AI Terminal"
echo "   pwsh           # Start PowerShell with AI Terminal loaded"
echo ""
echo "💡 The AI Terminal will start automatically in natural language mode."
echo "   Just describe what you want to do in plain English!"