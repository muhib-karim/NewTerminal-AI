# NewTerminal-AI 🚀

**Transform your terminal into an intelligent command-line assistant powered by local AI models.**

NewTerminal-AI brings the power of large language models directly to your command line, enabling natural language interactions for system administration, development tasks, and everyday terminal operations.

## ✨ Features

- 🧠 **Local AI Processing** - No data leaves your machine
- 🔍 **Smart Model Detection** - Automatically finds and uses existing AI models
- 💾 **Multi-Provider Support** - Works with Ollama, LM Studio, and more
- 🖥️ **Cross-Platform** - Windows, macOS, and Linux support
- ⚡ **Intelligent Caching** - Avoids redundant downloads
- 🛡️ **Safety First** - Command confirmation and validation
- 🎯 **Context Aware** - Understands your system and environment

## 🚀 Quick Start

### Windows (PowerShell)

```powershell
# One-line installation
iwr -useb https://raw.githubusercontent.com/your-repo/NewTerminal-AI/main/scripts/install.ps1 | iex

# Or download and run locally
git clone https://github.com/your-repo/NewTerminal-AI.git
cd NewTerminal-AI
.\scripts\install.ps1
```

### Linux/macOS

```bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/your-repo/NewTerminal-AI/main/scripts/install-multiplatform.sh | bash

# Or download and run locally
git clone https://github.com/your-repo/NewTerminal-AI.git
cd NewTerminal-AI
chmod +x scripts/install-multiplatform.sh
./scripts/install-multiplatform.sh
```

## 💡 Usage Examples

Once installed, use the `ai` command followed by your request:

```bash
# System monitoring
ai "show me running processes using high CPU"
ai "check disk space on all drives"
ai "find large files in current directory"

# Development tasks
ai "create a git branch called feature-auth"
ai "install nodejs dependencies"
ai "run tests in watch mode"

# File operations
ai "compress all .log files in this folder"
ai "find all Python files modified today"
ai "backup this directory to external drive"

# Network operations
ai "check if port 8080 is open"
ai "show network connections"
ai "ping google and show response time"
```

## 🔧 Advanced Configuration

### Model Selection

NewTerminal-AI automatically selects the best model based on your system:

- **4GB RAM or less**: `phi3:mini` (lightweight, fast)
- **4-8GB RAM**: `llama3.2:3b` (balanced performance)
- **8GB+ RAM**: `mistral:7b` (high capability)

### Custom Configuration

Create `~/.newterminal-ai/config.yaml` to customize behavior:

```yaml
# Model configuration
model: llama3.2:3b
provider: ollama

# Safety settings
confirm_dangerous_commands: true
allow_sudo: false

# Output preferences
verbose: false
show_reasoning: true
```

### Supported AI Providers

- **Ollama** - Primary provider, automatic installation
- **LM Studio** - Automatically detected if installed
- **OpenAI API** - Configure with API key
- **Anthropic Claude** - Configure with API key

## 🧪 Testing Your Installation

Run the comprehensive test suite:

```powershell
# Windows
.\tests\test-installation.ps1

# With verbose output
.\tests\test-installation.ps1 -Verbose

# Skip model functionality test (faster)
.\tests\test-installation.ps1 -SkipModelDownload
```

```bash
# Linux/macOS
./tests/test-installation.sh
```

## 📁 Project Structure

```
NewTerminal-AI/
├── scripts/                 # Installation scripts
│   ├── install.ps1         # Windows PowerShell installer
│   ├── install-multiplatform.sh  # Unix installer
│   └── user-onboarding.ps1 # User setup wizard
├── tests/                   # Test suites
│   ├── test-installation.ps1
│   └── test-functionality.sh
├── docs/                    # Documentation
│   ├── README.md
│   ├── CONTRIBUTING.md
│   └── PROJECT_STATUS.md
├── assets/                  # Media and resources
│   └── media/
├── releases/                # Release packages
├── NewTerminal-AI.psm1     # PowerShell module
├── Microsoft.PowerShell_profile.ps1  # Profile template
└── LICENSE
```

## 🛠️ Development

### Prerequisites

- PowerShell 5.1+ (Windows) or PowerShell Core 7+ (Cross-platform)
- Ollama or compatible AI provider
- Git

### Building from Source

```bash
git clone https://github.com/your-repo/NewTerminal-AI.git
cd NewTerminal-AI

# Run tests
./tests/test-installation.ps1

# Install in development mode
./scripts/install.ps1 -Development
```

### Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 🔒 Privacy & Security

- **Local Processing**: All AI processing happens on your machine
- **No Data Collection**: We don't collect or transmit your commands
- **Command Validation**: Dangerous commands require confirmation
- **Open Source**: Full transparency in our codebase

## 📊 System Requirements

### Minimum Requirements
- **RAM**: 4GB (8GB recommended)
- **Storage**: 10GB free space
- **OS**: Windows 10+, macOS 10.15+, or Linux (Ubuntu 18.04+)

### Recommended Requirements
- **RAM**: 16GB or more
- **Storage**: 50GB free space (for multiple models)
- **CPU**: Multi-core processor
- **GPU**: NVIDIA GPU with CUDA support (optional, for faster inference)

## 🚨 Troubleshooting

### Common Issues

**"Ollama not found" error**
```bash
# Ensure Ollama is in PATH
echo $PATH  # Linux/macOS
$env:PATH   # Windows

# Restart terminal after installation
```

**Model download fails**
```bash
# Check internet connection
ping ollama.com

# Check available disk space
df -h  # Linux/macOS
Get-PSDrive  # Windows
```

**AI command not recognized**
```bash
# Reload PowerShell profile
. $PROFILE

# Or restart terminal
```

### Getting Help

- 📖 Check our [documentation](docs/)
- 🐛 Report bugs on [GitHub Issues](https://github.com/your-repo/NewTerminal-AI/issues)
- 💬 Join our [Discord community](https://discord.gg/your-invite)
- 📧 Email support: support@newterminal-ai.com

## 📈 Roadmap

- [ ] **GUI Interface** - Desktop application for non-technical users
- [ ] **Plugin System** - Extensible architecture for custom commands
- [ ] **Cloud Sync** - Sync preferences across devices
- [ ] **Team Features** - Shared configurations and commands
- [ ] **Advanced Analytics** - Usage insights and optimization
- [ ] **Voice Interface** - Speech-to-command functionality

## 🏆 Acknowledgments

- [Ollama](https://ollama.com/) - Local AI model runtime
- [LM Studio](https://lmstudio.ai/) - AI model management
- [PowerShell](https://github.com/PowerShell/PowerShell) - Cross-platform shell
- [Bash](https://www.gnu.org/software/bash/) - Unix shell

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=your-repo/NewTerminal-AI&type=Date)](https://star-history.com/#your-repo/NewTerminal-AI&Date)

---

**Made with ❤️ by the NewTerminal-AI team**

[Website](https://newterminal-ai.com) • [Documentation](docs/) • [GitHub](https://github.com/your-repo/NewTerminal-AI) • [Discord](https://discord.gg/your-invite)
