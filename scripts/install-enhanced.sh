#!/bin/bash
set -e

# Enhanced NewTerminal-AI Installation Script for Linux/macOS
# Features: System analysis, progress tracking, ETA calculations, and user-friendly interface

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Progress tracking variables
START_TIME=$(date +%s)
TOTAL_STEPS=8
CURRENT_STEP=0

# Function to display colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to update progress
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percentage=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local eta=0
    
    if [ $CURRENT_STEP -gt 0 ]; then
        local avg_time_per_step=$((elapsed / CURRENT_STEP))
        local remaining_steps=$((TOTAL_STEPS - CURRENT_STEP))
        eta=$((remaining_steps * avg_time_per_step))
    fi
    
    local eta_formatted=$(printf "%02d:%02d" $((eta / 60)) $((eta % 60)))
    print_colored $CYAN "    Progress: ${percentage}% | ETA: ${eta_formatted}"
}

# Function to analyze system configuration
analyze_system() {
    print_colored $BLUE "\n=== NewTerminal-AI Enhanced Installation ==="
    print_colored $WHITE "Analyzing your system configuration..."
    
    # Detect OS
    if [[ "$(uname)" == "Darwin" ]]; then
        OS="macOS"
        RAM_BYTES=$(sysctl -n hw.memsize)
        RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
        CPU_INFO=$(sysctl -n machdep.cpu.brand_string)
    elif [[ "$(uname)" == "Linux" ]]; then
        OS="Linux"
        RAM_GB=$(free -g | awk '/Mem:/ {print $2}')
        CPU_INFO=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    else
        print_colored $RED "Unsupported OS. This script supports Linux and macOS only."
        exit 1
    fi
    
    # Display system information
    print_colored $WHITE "\nSystem Information:"
    print_colored $CYAN "   • Operating System: $OS"
    print_colored $CYAN "   • RAM: ${RAM_GB} GB"
    print_colored $CYAN "   • CPU: $CPU_INFO"
    
    # Select AI model based on RAM
    if [ "$RAM_GB" -lt 4 ]; then
        MODEL="phi3:mini"
        MODEL_SIZE="2.3GB"
        MODEL_DESC="Lightweight model for systems with limited RAM"
    elif [ "$RAM_GB" -lt 8 ]; then
        MODEL="llama3.2:3b"
        MODEL_SIZE="2.0GB"
        MODEL_DESC="Balanced model for mid-range systems"
    elif [ "$RAM_GB" -lt 16 ]; then
        MODEL="mistral:7b"
        MODEL_SIZE="4.1GB"
        MODEL_DESC="Advanced model for high-performance systems"
    else
        MODEL="llama3.1:8b"
        MODEL_SIZE="4.7GB"
        MODEL_DESC="Premium model for high-end systems"
    fi
    
    print_colored $GREEN "\nSelected AI Model: $MODEL"
    print_colored $CYAN "   • Size: $MODEL_SIZE"
    print_colored $CYAN "   • Description: $MODEL_DESC"
    
    print_colored $YELLOW "\nInstallation will proceed in $TOTAL_STEPS steps..."
    sleep 2
}

# Function to check prerequisites
check_prerequisites() {
    print_colored $BLUE "\n[1/$TOTAL_STEPS] Checking Prerequisites"
    print_colored $WHITE "    Verifying system requirements..."
    update_progress
    
    local missing_deps=()
    
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # Check for Python
    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        missing_deps+=("python3")
    fi
    
    # Check for pip
    if ! command -v pip3 >/dev/null 2>&1 && ! command -v pip >/dev/null 2>&1; then
        missing_deps+=("pip")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_colored $RED "Missing dependencies: ${missing_deps[*]}"
        print_colored $YELLOW "Please install the missing dependencies and run the script again."
        exit 1
    fi
    
    print_colored $GREEN "All prerequisites satisfied"
}

# Function to install Ollama
install_ollama() {
    print_colored $BLUE "\n[2/$TOTAL_STEPS] Installing Ollama"
    print_colored $WHITE "    Setting up Ollama AI runtime..."
    update_progress
    
    if command -v ollama >/dev/null 2>&1; then
        print_colored $GREEN "Ollama already installed"
    else
        print_colored $CYAN "Downloading and installing Ollama..."
        if curl -fsSL https://ollama.com/install.sh | sh; then
            print_colored $GREEN "Ollama installed successfully"
        else
            print_colored $RED "Failed to install Ollama"
            exit 1
        fi
    fi
}

# Function to start Ollama service
start_ollama_service() {
    print_colored $BLUE "\n[3/$TOTAL_STEPS] Starting Ollama Service"
    print_colored $WHITE "    Initializing AI runtime..."
    update_progress
    
    # Start Ollama in background if not running
    if ! pgrep -f "ollama serve" > /dev/null; then
        print_colored $CYAN "Starting Ollama service..."
        nohup ollama serve > /dev/null 2>&1 &
        sleep 3
    fi
    
    print_colored $GREEN "Ollama service is running"
}

# Function to download AI model
download_ai_model() {
    print_colored $BLUE "\n[4/$TOTAL_STEPS] Downloading AI Model"
    print_colored $WHITE "    Installing $MODEL ($MODEL_SIZE)..."
    update_progress
    
    print_colored $CYAN "This may take several minutes depending on your internet speed..."
    
    if ollama pull "$MODEL" 2>&1; then
        print_colored $GREEN "Model downloaded successfully"
    else
        print_colored $RED "Failed to download model"
        exit 1
    fi
}

# Function to install Shell Genie
install_shell_genie() {
    print_colored $BLUE "\n[5/$TOTAL_STEPS] Installing Shell Genie"
    print_colored $WHITE "    Setting up natural language interface..."
    update_progress
    
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --upgrade shell-genie --quiet
    elif command -v pip >/dev/null 2>&1; then
        pip install --upgrade shell-genie --quiet
    else
        print_colored $RED "Error: pip not found"
        exit 1
    fi
    
    print_colored $GREEN "Shell Genie installed successfully"
}

# Function to configure Shell Genie
configure_shell_genie() {
    print_colored $BLUE "\n[6/$TOTAL_STEPS] Configuring AI Integration"
    print_colored $WHITE "    Setting up model configuration..."
    update_progress
    
    mkdir -p ~/.config/shell-genie
    cat > ~/.config/shell-genie/config.yaml <<EOF
model: $MODEL
provider: ollama
EOF
    
    print_colored $GREEN "Shell Genie configured for model: $MODEL"
}

# Function to setup shell integration
setup_shell_integration() {
    print_colored $BLUE "\n[7/$TOTAL_STEPS] Setting Up Shell Integration"
    print_colored $WHITE "    Configuring terminal aliases..."
    update_progress
    
    # Setup for Bash
    if [ -f ~/.bashrc ]; then
        if ! grep -q "alias ai=" ~/.bashrc 2>/dev/null; then
            echo "" >> ~/.bashrc
            echo "# NewTerminal-AI aliases" >> ~/.bashrc
            echo "alias ai='genie'" >> ~/.bashrc
            echo "alias ask='genie'" >> ~/.bashrc
        fi
    fi
    
    # Setup for Zsh
    if [ -f ~/.zshrc ]; then
        if ! grep -q "alias ai=" ~/.zshrc 2>/dev/null; then
            echo "" >> ~/.zshrc
            echo "# NewTerminal-AI aliases" >> ~/.zshrc
            echo "alias ai='genie'" >> ~/.zshrc
            echo "alias ask='genie'" >> ~/.zshrc
        fi
    fi
    
    # Setup for Fish shell
    if command -v fish >/dev/null 2>&1; then
        mkdir -p ~/.config/fish/functions
        cat > ~/.config/fish/functions/ai.fish <<'EOF'
function ai
    genie $argv
end
EOF
        cat > ~/.config/fish/functions/ask.fish <<'EOF'
function ask
    genie $argv
end
EOF
    fi
    
    print_colored $GREEN "Shell integration configured"
}

# Function to finalize installation
finalize_installation() {
    print_colored $BLUE "\n[8/$TOTAL_STEPS] Finalizing Installation"
    print_colored $WHITE "    Completing setup..."
    update_progress
    
    # Calculate total installation time
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    local total_formatted=$(printf "%02d:%02d" $((total_time / 60)) $((total_time % 60)))
    
    print_colored $GREEN "\n=== Installation Complete! ==="
    
    print_colored $WHITE "\nGetting Started:"
    print_colored $CYAN "   1. Restart your terminal session (or run: source ~/.bashrc)"
    print_colored $CYAN "   2. Use 'ai' command followed by your request"
    print_colored $CYAN "   3. Example: ai 'list all files in current directory'"
    
    print_colored $WHITE "\nAvailable Commands:"
    print_colored $CYAN "   • ai 'your request'     - Main AI assistant"
    print_colored $CYAN "   • ask 'your request'    - Alternative alias"
    print_colored $CYAN "   • genie 'your request'  - Direct Shell Genie access"
    
    print_colored $WHITE "\nTroubleshooting:"
    print_colored $CYAN "   • If AI doesn't respond: Check if Ollama service is running"
    print_colored $CYAN "   • For model issues: Run 'ollama list' to see available models"
    print_colored $CYAN "   • For help: Visit the project repository or documentation"
    
    print_colored $WHITE "\nSystem Integration:"
    print_colored $CYAN "   • AI model optimized for your hardware configuration"
    print_colored $CYAN "   • Natural language interface for terminal commands"
    print_colored $CYAN "   • Safe execution with confirmation prompts"
    
    print_colored $WHITE "\nTry these examples:"
    print_colored $YELLOW "   ai 'show system information'"
    print_colored $YELLOW "   ai 'find large files in downloads folder'"
    print_colored $YELLOW "   ai 'create a backup of my documents'"
    
    print_colored $MAGENTA "\nTotal installation time: $total_formatted"
}

# Main installation function
main() {
    analyze_system
    check_prerequisites
    install_ollama
    start_ollama_service
    download_ai_model
    install_shell_genie
    configure_shell_genie
    setup_shell_integration
    finalize_installation
}

# Run main installation
main