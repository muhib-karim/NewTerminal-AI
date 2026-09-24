# AI Terminal

🤖 **Transform your terminal with natural language AI** - Convert plain English into CLI commands across Windows, macOS, and Linux.

## 🎯 Key Features

### 🧠 Intelligent Natural Language Processing
- **Context-Aware AI**: Understands your current directory, Git status, and project environment
- **Smart Command Generation**: Converts natural language to optimal CLI commands
- **Educational Display**: Shows generated commands for learning and transparency
- **Command History**: Tracks all interactions for reference and learning

### 🛡️ Smart Safety System
- **Automatic Safety Analysis**: Identifies potentially harmful commands
- **Smart Execution**: Auto-runs safe commands, asks confirmation for risky ones
- **Command Preview**: Always shows what will be executed before running
- **Graceful Error Handling**: Clear, helpful error messages and suggestions

### 🌍 Cross-Platform Compatibility
- **Windows**: Native PowerShell integration with auto-start
- **macOS**: PowerShell Core with Homebrew support
- **Linux**: PowerShell Core with package manager integration
- **Consistent Experience**: Same natural language interface across all platforms

### 🔒 Privacy & Performance
- **Local AI Processing**: Uses Ollama for complete privacy
- **No External Dependencies**: All processing happens on your machine
- **Fast Response Times**: Local models provide quick command generation
- **Offline Capable**: Works without internet connection after initial setup

## 🚀 Quick Start

### One-Line Installation

#### Windows (PowerShell 5.0+ or PowerShell Core)
```powershell
# Option 1: Administrator installation (recommended)
irm https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/install.ps1 | iex

# Option 2: User-only installation
irm https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/install.ps1 | iex -ArgumentList "-Force"
```

#### macOS (Homebrew + PowerShell Core)
```bash
# Automatic installation with Homebrew and PowerShell Core
curl -fsSL https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/install.sh | bash
```

#### Linux (Package Manager + PowerShell Core)
```bash
# Ubuntu/Debian
curl -fsSL https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/install.sh | bash

# CentOS/RHEL/Fedora
curl -fsSL https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/install.sh | bash

# Arch Linux
curl -fsSL https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/install.sh | bash
```

### Manual Installation

#### Prerequisites
- **PowerShell 5.0+** (Windows) or **PowerShell Core 6.0+** (macOS/Linux)
- **Ollama** for local AI processing

#### Step-by-Step
```bash
# 1. Clone the repository
git clone https://github.com/yourusername/AI-Terminal.git
cd AI-Terminal

# 2. Run the installation script
# Windows:
.\install.ps1

# macOS/Linux:
./install.sh
```

## 💡 Usage

### Getting Started
After installation, AI Terminal starts automatically in natural language mode:

```
🤖 AI Terminal - Natural Language Interface
Describe what you want to do in plain English. Type 'exit' to quit.

AI> list all files in this directory
💻 Get-ChildItem
    Directory: C:\Users\YourName\Projects
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        12/10/2024   2:30 PM                src
d-----        12/10/2024   1:15 PM                docs
-a----        12/10/2024   3:45 PM           1024 README.md
```

## 📋 Built-in Commands

AI Terminal starts automatically in natural language mode. Simply describe what you want to do!

### Special Commands
| Command | Description |
|---------|-------------|
| `exit` | Exit AI Terminal |
| `history` | Show recent command history |
| `clear` | Clear screen and reset interface |
| `help` | Show available commands and examples |

### Legacy Commands (still available)
| Command | Description |
|---------|-------------|
| `ai "<request>"` | Process single natural language request |
| `aia "<request>"` | Auto-execute mode (legacy) |
| `nl` | Start natural language mode (now default) |

### Natural Language Examples

#### File & Directory Operations
```
AI> create a new folder called projects
💻 New-Item -ItemType Directory -Name "projects"

AI> copy all text files to the backup folder  
💻 Copy-Item *.txt -Destination backup

AI> find files larger than 100MB
💻 Get-ChildItem -Recurse | Where-Object {$_.Length -gt 100MB}
```

#### Git Operations
```
AI> show my git status
💻 git status

AI> commit all changes with message update docs
💻 git add . && git commit -m "update docs"
⚠️  This command may be potentially harmful. Execute? [y/N]:

AI> create a new branch called feature-auth
💻 git checkout -b feature-auth
```

#### System Information
```
AI> show current disk usage
💻 Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}

AI> list running processes
💻 Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
```

## 🛠️ Installation Requirements

### System Requirements

#### Windows
- **OS**: Windows 10 (1903+) or Windows 11
- **PowerShell**: 5.1+ (built-in) or PowerShell Core 7.0+
- **Architecture**: x64 (AMD64)
- **Memory**: 4GB RAM minimum, 8GB+ recommended
- **Storage**: 3GB free space (2GB for AI models + 1GB for dependencies)

#### macOS
- **OS**: macOS 10.15 (Catalina) or later
- **Architecture**: Intel x64 or Apple Silicon (M1/M2)
- **Shell**: Bash, Zsh, or Fish
- **Homebrew**: Automatically installed if not present
- **Memory**: 4GB RAM minimum, 8GB+ recommended
- **Storage**: 3GB free space

#### Linux
- **Distributions**: Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 7+, Fedora 28+, Arch Linux
- **Architecture**: x64 (AMD64) or ARM64
- **Shell**: Bash, Zsh, or Fish
- **Package Manager**: apt, yum, dnf, or pacman
- **Memory**: 4GB RAM minimum, 8GB+ recommended
- **Storage**: 3GB free space

### What the Installation Scripts Do

#### Windows (`install.ps1`)
1. **PowerShell Check**: Verifies PowerShell version compatibility
2. **Ollama Installation**: Downloads and installs Ollama using winget or direct download
3. **Service Setup**: Starts Ollama service and configures auto-start
4. **AI Model**: Downloads `llama3.2:3b` model (2GB)
5. **Module Installation**: Installs AITerminal PowerShell module
6. **Profile Setup**: Configures PowerShell profile for auto-start
7. **Desktop Shortcut**: Creates convenient desktop launcher

#### macOS/Linux (`install.sh`)
1. **PowerShell Core**: Installs PowerShell Core via package manager
2. **Ollama Installation**: Downloads and installs Ollama
3. **Service Setup**: Configures Ollama as system service
4. **AI Model**: Downloads `llama3.2:3b` model (2GB)
5. **Module Installation**: Installs AITerminal PowerShell module
6. **Profile Setup**: Configures PowerShell profile for auto-start
7. **Launcher Script**: Creates `ai-terminal` command for easy access

### Dependencies
- **[Ollama](https://ollama.ai)** - Local AI model runtime (auto-installed)
- **Internet connection** - Required for initial setup and model downloads only

## 🎛️ Configuration

### AI Model Selection
NewTerminal-AI automatically selects the optimal model based on your system:
- **16GB+ RAM**: `phi3:mini` (higher accuracy)
- **8GB+ RAM**: `llama3.2:1b` (balanced performance)
- **4GB+ RAM**: `llama3.2:1b` (lightweight)

### Custom Configuration
Edit the configuration in your installation directory:
- **Windows**: `%USERPROFILE%\.newterminal-ai\`
- **macOS/Linux**: `~/.newterminal-ai/`

## 🔧 Advanced Usage

### Command History
All AI-generated commands are logged for review:
```bash
# View command history (in nl mode)
history

# Clear command history
clear
```

### Safety Features
- **Dangerous Command Detection**: Warns before executing potentially harmful commands
- **Confirmation Prompts**: Interactive mode always asks for confirmation
- **Command Validation**: Checks command syntax before execution
- **Rollback Suggestions**: Provides undo commands when possible

### Integration with Existing Tools
NewTerminal-AI works seamlessly with:
- Git version control
- Package managers (npm, pip, apt, brew, etc.)
- Development tools and IDEs
- System administration utilities
- File management operations

## 📚 Examples and Use Cases

### For Developers
```bash
aia "create a new React project called my-app"
aia "install express and nodemon as dev dependency"
aia "run the development server"
aia "commit changes and push to origin main"
```

### For System Administration
```bash
aia "show disk usage by directory"
aia "find processes using port 3000"
aia "create a backup of nginx configuration"
aia "restart the docker service"
```

### For File Management
```bash
aia "organize photos by date into folders"
aia "compress all log files older than 30 days"
aia "find duplicate files in downloads folder"
aia "sync documents folder to external drive"
```

### For Learning
```bash
aia "show me how to use grep to find text in files"
aia "explain the difference between chmod 755 and 644"
aia "create an example of a bash script with loops"
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Clone your fork
3. Install dependencies
4. Make your changes
5. Test across platforms
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Troubleshooting

#### Verify Installation Success
```powershell
# Check if AI Terminal is working
ai-terminal  # Should start natural language interface

# Or test the module directly
Import-Module AITerminal -Force
nl  # Should start natural language mode
```

#### AI Terminal doesn't start automatically

**Windows:**
```powershell
# Check if module is installed
Get-Module -ListAvailable AITerminal

# Check PowerShell profile
Test-Path $PROFILE
Get-Content $PROFILE | Select-String "AITerminal"

# Manually import if needed
Import-Module AITerminal -Force

# Recreate profile if missing
if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }
Add-Content $PROFILE "Import-Module AITerminal -Force; nl"
```

**macOS/Linux:**
```bash
# Check if PowerShell Core is installed
pwsh --version

# Check if ai-terminal command exists
which ai-terminal

# Manually start if needed
pwsh -c "Import-Module AITerminal -Force; nl"

# Recreate launcher if missing
echo '#!/bin/bash' > ~/.local/bin/ai-terminal
echo 'pwsh -c "Import-Module AITerminal -Force; nl"' >> ~/.local/bin/ai-terminal
chmod +x ~/.local/bin/ai-terminal
```

#### "Ollama not found" or connection errors

**Windows:**
```powershell
# Check if Ollama is running
Get-Process ollama -ErrorAction SilentlyContinue

# Check Ollama service
Get-Service ollama -ErrorAction SilentlyContinue

# Start Ollama manually
Start-Service ollama
# Or if not a service:
ollama serve

# Test Ollama connection
ollama list
```

**macOS/Linux:**
```bash
# Check if Ollama is running
ps aux | grep ollama
sudo systemctl status ollama  # Linux with systemd
brew services list | grep ollama  # macOS with Homebrew

# Start Ollama service
sudo systemctl start ollama  # Linux
brew services start ollama   # macOS
# Or manually:
ollama serve &

# Test Ollama connection
ollama list
```

#### "Model not found" errors
```bash
# Check available models
ollama list

# Pull the required model (2GB download)
ollama pull llama3.2:3b

# Alternative smaller model for low-end systems
ollama pull llama3.2:1b

# Test model
ollama run llama3.2:3b "Hello, test message"
```

#### Installation Issues

**Windows:**
```powershell
# Run as Administrator (recommended)
Start-Process powershell -Verb RunAs
irm https://raw.githubusercontent.com/ai-dev-2024/NewTerminal-AI/main/install.ps1 | iex

# Or force user installation
.\install.ps1 -Force

# Check execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Manual winget installation of Ollama
winget install Ollama.Ollama
```

**macOS:**
```bash
# Check Homebrew installation
brew --version

# Install Homebrew if missing
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Check permissions
sudo chmod +x install.sh

# Manual installation steps
brew install powershell
brew install ollama
```

**Linux:**
```bash
# Ubuntu/Debian - check package manager
sudo apt update
sudo apt install curl wget

# CentOS/RHEL/Fedora
sudo yum update  # or dnf update
sudo yum install curl wget

# Check permissions and run
sudo chmod +x install.sh
./install.sh

# Manual PowerShell installation
# Ubuntu/Debian:
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install powershell
```

**Performance Tips**
- **Faster Models**: Use `llama3.2:1b` for quicker responses on lower-end hardware
- **Memory**: Ensure Ollama has at least 4GB RAM available
- **Storage**: Keep 10GB+ free space for model storage

## 📦 GitHub Repository

**Repository**: [https://github.com/ai-dev-2024/NewTerminal-AI](https://github.com/ai-dev-2024/NewTerminal-AI)

### Quick Links
- 🏠 **Home**: [Repository Main Page](https://github.com/ai-dev-2024/NewTerminal-AI)
- 📋 **Issues**: [Bug Reports & Feature Requests](https://github.com/ai-dev-2024/NewTerminal-AI/issues)
- 💬 **Discussions**: [Community Discussions](https://github.com/ai-dev-2024/NewTerminal-AI/discussions)
- 📚 **Wiki**: [Documentation & Guides](https://github.com/ai-dev-2024/NewTerminal-AI/wiki)
- 🏷️ **Releases**: [Download Latest Version](https://github.com/ai-dev-2024/NewTerminal-AI/releases)
- ⭐ **Star**: [Give us a star if you like the project!](https://github.com/ai-dev-2024/NewTerminal-AI/stargazers)

### Repository Structure
```
NewTerminal-AI/
├── 📄 NewTerminal-AI.psm1    # Main PowerShell module
├── 🪟 install.ps1            # Windows installation script
├── 🐧 install.sh             # macOS/Linux installation script
├── 📖 README.md              # This documentation
├── 📋 CHANGELOG.md           # Version history
├── 🤝 CONTRIBUTING.md        # Contribution guidelines
├── ⚖️ LICENSE                # MIT License
├── 📁 docs/                  # Additional documentation
├── 📁 examples/              # Usage examples
├── 📁 scripts/               # Helper scripts
└── 📁 tests/                 # Test files
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

- 🐛 **Report Bugs**: [Create an issue](https://github.com/ai-dev-2024/NewTerminal-AI/issues)
- 💡 **Suggest Features**: [Start a discussion](https://github.com/ai-dev-2024/NewTerminal-AI/discussions)
- 🔧 **Submit PRs**: See our [Contributing Guide](CONTRIBUTING.md)
- 📖 **Improve Docs**: Help make our documentation better

### Development Setup
```bash
# Clone and setup
git clone https://github.com/yourusername/AI-Terminal.git
cd AI-Terminal

# Test your changes
.\install.ps1 -Force  # Windows
./install.sh          # macOS/Linux
```

## 📊 Project Stats

- 🌟 **Cross-Platform**: Windows, macOS, Linux
- 🔒 **Privacy-First**: 100% local AI processing
- 🚀 **Zero-Config**: Auto-starts in natural language mode
- 📚 **Educational**: Shows CLI commands for learning

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[Ollama](https://ollama.ai)** - Local AI model infrastructure
- **[PowerShell](https://github.com/PowerShell/PowerShell)** - Cross-platform shell
- **Open Source Community** - For inspiration and feedback

---

<div align="center">

**🤖 Transform your terminal experience with natural language AI**

[⭐ Star this repo](https://github.com/yourusername/AI-Terminal) • [🐛 Report Bug](https://github.com/yourusername/AI-Terminal/issues) • [💡 Request Feature](https://github.com/yourusername/AI-Terminal/discussions)

</div>
