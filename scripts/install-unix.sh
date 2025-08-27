#!/bin/bash

# NewTerminal-AI Installation Script for macOS and Linux
# This script installs NewTerminal-AI with Ollama integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.newterminal-ai"
BIN_DIR="$HOME/.local/bin"
SHELL_RC=""

# Detect shell and set RC file
detect_shell() {
    local shell_name=$(basename "$SHELL")
    case "$shell_name" in
        "bash")
            SHELL_RC="$HOME/.bashrc"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                SHELL_RC="$HOME/.bash_profile"
            fi
            ;;
        "zsh")
            SHELL_RC="$HOME/.zshrc"
            ;;
        "fish")
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        *)
            SHELL_RC="$HOME/.profile"
            ;;
    esac
}

# Print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check if curl or wget is available
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Some features may not work properly."
    fi
    
    print_status "System requirements check passed."
}

# Install Ollama if not present
install_ollama() {
    if command -v ollama &> /dev/null; then
        print_status "Ollama is already installed."
        return
    fi
    
    print_status "Installing Ollama..."
    
    if command -v curl &> /dev/null; then
        curl -fsSL https://ollama.ai/install.sh | sh
    else
        print_error "Cannot install Ollama automatically. Please install it manually from https://ollama.ai"
        exit 1
    fi
    
    print_status "Ollama installed successfully."
}

# Install optimal AI model
install_model() {
    print_status "Installing AI model..."
    
    # Start Ollama service if not running
    if ! pgrep -x "ollama" > /dev/null; then
        print_status "Starting Ollama service..."
        ollama serve &
        sleep 5
    fi
    
    # Determine optimal model based on system memory
    local total_memory=$(free -m 2>/dev/null | awk 'NR==2{print $2}' || echo "8192")
    local target_model="llama3.2:1b"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        total_memory=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024)}')
    fi
    
    if (( total_memory >= 16384 )); then
        target_model="phi3:mini"
    elif (( total_memory >= 8192 )); then
        target_model="llama3.2:1b"
    else
        target_model="llama3.2:1b"
    fi
    
    print_status "Installing model: $target_model (System RAM: ${total_memory}MB)"
    
    if ollama pull "$target_model"; then
        print_status "Model $target_model installed successfully."
        
        # Update the model in the script
        sed -i.bak "s/OLLAMA_MODEL=\".*\"/OLLAMA_MODEL=\"$target_model\"/" "$INSTALL_DIR/NewTerminal-AI.sh"
    else
        print_error "Failed to install model $target_model"
        exit 1
    fi
}

# Create installation directory
setup_directories() {
    print_status "Setting up directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
    
    print_status "Directories created successfully."
}

# Download and install NewTerminal-AI
install_newterminal_ai() {
    print_status "Installing NewTerminal-AI..."
    
    # Copy the script to installation directory
    if [[ -f "NewTerminal-AI.sh" ]]; then
        cp "NewTerminal-AI.sh" "$INSTALL_DIR/"
    else
        print_error "NewTerminal-AI.sh not found in current directory"
        exit 1
    fi
    
    # Make it executable
    chmod +x "$INSTALL_DIR/NewTerminal-AI.sh"
    
    # Create symlinks in bin directory
    ln -sf "$INSTALL_DIR/NewTerminal-AI.sh" "$BIN_DIR/aia"
    ln -sf "$INSTALL_DIR/NewTerminal-AI.sh" "$BIN_DIR/ai"
    ln -sf "$INSTALL_DIR/NewTerminal-AI.sh" "$BIN_DIR/nl"
    
    print_status "NewTerminal-AI installed successfully."
}

# Setup shell integration
setup_shell_integration() {
    detect_shell
    
    print_status "Setting up shell integration for $SHELL_RC..."
    
    # Add bin directory to PATH if not already present
    if [[ -f "$SHELL_RC" ]]; then
        if ! grep -q "$BIN_DIR" "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# NewTerminal-AI" >> "$SHELL_RC"
            echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
            
            # Add aliases for convenience
            echo "alias aia='$BIN_DIR/aia'" >> "$SHELL_RC"
            echo "alias ai='$BIN_DIR/ai'" >> "$SHELL_RC"
            echo "alias nl='$BIN_DIR/nl'" >> "$SHELL_RC"
            
            print_status "Shell integration added to $SHELL_RC"
        else
            print_status "Shell integration already exists in $SHELL_RC"
        fi
    else
        print_warning "Could not find shell configuration file: $SHELL_RC"
        print_warning "Please manually add $BIN_DIR to your PATH"
    fi
}

# Test installation
test_installation() {
    print_status "Testing installation..."
    
    # Test if commands are accessible
    if [[ -x "$BIN_DIR/aia" ]]; then
        print_status "✅ aia command installed successfully"
    else
        print_error "❌ aia command not found"
    fi
    
    if [[ -x "$BIN_DIR/ai" ]]; then
        print_status "✅ ai command installed successfully"
    else
        print_error "❌ ai command not found"
    fi
    
    if [[ -x "$BIN_DIR/nl" ]]; then
        print_status "✅ nl command installed successfully"
    else
        print_error "❌ nl command not found"
    fi
    
    # Test Ollama connection
    if ollama list &> /dev/null; then
        print_status "✅ Ollama connection successful"
    else
        print_warning "⚠️  Ollama connection failed. You may need to start Ollama manually."
    fi
}

# Main installation process
main() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    NewTerminal-AI Installer                  ║${NC}"
    echo -e "${CYAN}║              Natural Language Terminal Interface             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    check_requirements
    setup_directories
    install_ollama
    install_model
    install_newterminal_ai
    setup_shell_integration
    test_installation
    
    echo ""
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "${CYAN}1. Restart your terminal or run: source $SHELL_RC${NC}"
    echo -e "${CYAN}2. Try the commands:${NC}"
    echo -e "   ${YELLOW}aia 'list files'${NC}     - Auto-execute commands"
    echo -e "   ${YELLOW}ai 'create file test.txt'${NC} - Generate with confirmation"
    echo -e "   ${YELLOW}nl${NC}                   - Interactive natural language mode"
    echo ""
    echo -e "${GREEN}Enjoy your AI-powered terminal! 🚀${NC}"
}

# Run main function
main "$@"