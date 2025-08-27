#!/bin/bash

# NewTerminal-AI Universal Installation Script
# Supports Linux, macOS, and WSL

set -e

echo "=== NewTerminal-AI Universal Installer ==="

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)
        PLATFORM="linux"
        ;;
    Darwin*)
        PLATFORM="macos"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        PLATFORM="windows"
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

echo "Detected platform: $PLATFORM ($ARCH)"

# Function to detect available AI models
detect_ai_models() {
    echo "Scanning for existing AI models..."
    
    # Check Ollama models
    if command -v ollama >/dev/null 2>&1; then
        echo "Checking Ollama models..."
        if ollama list 2>/dev/null | grep -q "NAME"; then
            echo "Found Ollama models:"
            ollama list | tail -n +2 | while read -r line; do
                model_name=$(echo "$line" | awk '{print $1}')
                model_size=$(echo "$line" | awk '{print $3}')
                echo "  - $model_name ($model_size)"
            done
            return 0
        fi
    fi
    
    # Check LM Studio models
    LM_STUDIO_PATHS=(
        "$HOME/.cache/lm-studio/models"
        "$HOME/Library/Application Support/LMStudio/models"
        "$HOME/.local/share/LMStudio/models"
    )
    
    for path in "${LM_STUDIO_PATHS[@]}"; do
        if [ -d "$path" ]; then
            echo "Checking LM Studio models in $path..."
            find "$path" -name "*.gguf" -type f 2>/dev/null | while read -r model; do
                model_name=$(basename "$model" .gguf)
                model_size=$(du -h "$model" | cut -f1)
                echo "  - $model_name (LM Studio, $model_size)"
            done
        fi
    done
    
    return 1
}

# Install Ollama if not present
install_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        echo "Installing Ollama..."
        case "$PLATFORM" in
            linux)
                curl -fsSL https://ollama.com/install.sh | sh
                ;;
            macos)
                if command -v brew >/dev/null 2>&1; then
                    brew install ollama
                else
                    echo "Please install Homebrew first or download Ollama from https://ollama.com"
                    exit 1
                fi
                ;;
            *)
                echo "Please install Ollama manually from https://ollama.com"
                exit 1
                ;;
        esac
    else
        echo "Ollama is already installed."
    fi
}

# Detect system RAM and select appropriate model
detect_ram_and_model() {
    case "$PLATFORM" in
        linux)
            RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
            ;;
        macos)
            RAM_BYTES=$(sysctl -n hw.memsize)
            RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
            ;;
        *)
            RAM_GB=8  # Default assumption
            ;;
    esac
    
    echo "Detected RAM: ${RAM_GB}GB"
    
    if [ "$RAM_GB" -lt 4 ]; then
        MODEL="phi3:mini"
    elif [ "$RAM_GB" -lt 8 ]; then
        MODEL="llama3.2:3b"
    else
        MODEL="mistral:7b"
    fi
    
    echo "Selected model: $MODEL"
}

# Main installation process
main() {
    # Check for existing models first
    if detect_ai_models; then
        echo "Found existing AI models. Skipping model download."
        # Use the first available model
        if command -v ollama >/dev/null 2>&1; then
            EXISTING_MODEL=$(ollama list | tail -n +2 | head -n 1 | awk '{print $1}')
            if [ -n "$EXISTING_MODEL" ]; then
                MODEL="$EXISTING_MODEL"
                echo "Using existing model: $MODEL"
            fi
        fi
    else
        echo "No existing AI models found."
        install_ollama
        detect_ram_and_model
        
        echo "Downloading AI model (this may take several minutes)..."
        ollama pull "$MODEL"
        echo "Model downloaded successfully."
    fi
    
    # Setup NewTerminal-AI module
    echo "Setting up NewTerminal-AI..."
    
    # Create config directory
    mkdir -p "$HOME/.newterminal-ai"
    
    # Write config
    cat > "$HOME/.newterminal-ai/config.yaml" << EOF
model: $MODEL
provider: ollama
EOF
    
    # Setup shell integration
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        bash)
            PROFILE_FILE="$HOME/.bashrc"
            ;;
        zsh)
            PROFILE_FILE="$HOME/.zshrc"
            ;;
        fish)
            PROFILE_FILE="$HOME/.config/fish/config.fish"
            ;;
        *)
            PROFILE_FILE="$HOME/.profile"
            ;;
    esac
    
    # Add AI function to shell profile
    if ! grep -q "NewTerminal-AI" "$PROFILE_FILE" 2>/dev/null; then
        cat >> "$PROFILE_FILE" << 'EOF'

# NewTerminal-AI Integration
ai() {
    if [ -z "$1" ]; then
        echo "Usage: ai 'your request'"
        return 1
    fi
    
    local config_file="$HOME/.newterminal-ai/config.yaml"
    local model="llama3.2:3b"
    
    if [ -f "$config_file" ]; then
        model=$(grep "^model:" "$config_file" | cut -d' ' -f2)
    fi
    
    local prompt="You are a helpful command-line assistant. Generate only the command needed for: $1. Respond with just the command, no explanations."
    
    echo "🤖 Generating command..."
    local command=$(ollama run "$model" "$prompt" 2>/dev/null | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -n "$command" ]; then
        echo "💡 Suggested command: $command"
        echo -n "Execute this command? [y/N]: "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            eval "$command"
        fi
    else
        echo "❌ Could not generate a command for your request."
    fi
}
EOF
        echo "Shell integration added to $PROFILE_FILE"
    else
        echo "Shell integration already exists."
    fi
    
    echo "✅ Installation complete!"
    echo "Usage: ai 'your request'"
    echo "Example: ai 'show running processes'"
    echo ""
    echo "Please restart your terminal or run: source $PROFILE_FILE"
}

# Run main installation
main