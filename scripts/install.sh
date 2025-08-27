#!/bin/bash
set -e
echo "=== Installing NewTerminal on Linux/macOS ==="

# Install Ollama
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh || true

# Detect RAM across platforms
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    RAM_BYTES=$(sysctl -n hw.memsize)
    RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
elif [[ "$(uname)" == "Linux" ]]; then
    # Linux
    RAM_GB=$(free -g | awk '/Mem:/ {print $2}')
else
    echo "Unsupported OS. Defaulting to 4GB RAM assumption."
    RAM_GB=4
fi
echo "Detected RAM: $RAM_GB GB"
if [ "$RAM_GB" -lt 4 ]; then
    MODEL="phi-3-mini-4k"
elif [ "$RAM_GB" -lt 8 ]; then
    MODEL="llama3.2:3b"
else
    MODEL="mistral:7b"
fi
echo "Selected AI model: $MODEL"

# Pull the model
echo "Downloading AI model (this may take a few minutes)..."
ollama pull $MODEL

# Install shell-genie
echo "Installing Shell Genie..."
if command -v pip3 >/dev/null 2>&1; then
    pip3 install --upgrade shell-genie
elif command -v pip >/dev/null 2>&1; then
    pip install --upgrade shell-genie
else
    echo "Error: pip not found. Please install Python 3 and pip first."
    exit 1
fi
mkdir -p ~/.config/shell-genie
cat > ~/.config/shell-genie/config.yaml <<EOF
model: $MODEL
provider: ollama
EOF
if command -v fish >/dev/null 2>&1; then
    mkdir -p ~/.config/fish/functions
    cat > ~/.config/fish/functions/genie_prompt.fish <<'EOF2'
function genie_prompt
    read --prompt "AI Command: " query
    set cmd (genie "$query")
    echo -e "\nSuggested: $cmd"
    read --prompt "Run this? (y/n) " yn
    if test "$yn" = "y"
        eval $cmd
    end
end
EOF2
    if ! grep -q "bind \c\  genie_prompt" ~/.config/fish/config.fish 2>/dev/null; then
        echo 'bind \c\  genie_prompt' >> ~/.config/fish/config.fish
    fi
fi
echo "✅ Installation complete! Use 'genie "your request"' or Ctrl+Space in Fish shell."
