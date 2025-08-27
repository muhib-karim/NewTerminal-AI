# NewTerminal-AI v1.0.0 Release

## 🚀 What's New

- **Custom AI Assistant**: Native PowerShell module that replaces Shell Genie with better compatibility
- **Smart Model Detection**: Automatically detects existing AI models (Ollama, LM Studio) to avoid unnecessary downloads
- **Multi-Platform Support**: Installation scripts for Windows, Linux, and macOS
- **Enhanced Safety**: Built-in command validation and execution safety checks
- **Comprehensive Testing**: Full test suite to validate installation and functionality

## 📦 Installation

### Windows
```powershell
# Download and run the Windows installer
iwr -useb https://raw.githubusercontent.com/your-repo/NewTerminal-AI/main/install-windows.ps1 | iex
```

### Linux/macOS
```bash
# Download and run the Unix installer
curl -fsSL https://raw.githubusercontent.com/your-repo/NewTerminal-AI/main/install-linux-macos.sh | bash
```

## 🧪 Testing

Run the test suite to validate your installation:
```powershell
./test-installation.ps1
```

## 📋 What's Included

- `install-windows.ps1` - Windows installation script
- `install-linux-macos.sh` - Linux/macOS installation script
- `NewTerminal-AI.psm1` - Core PowerShell module
- `Microsoft.PowerShell_profile.ps1` - PowerShell profile configuration
- `test-installation.ps1` - Comprehensive test suite
- `README.md` - Full documentation
- `media/` - Screenshots and demo assets

## 🔧 System Requirements

- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 10GB free space
- **OS**: Windows 10+, Linux, or macOS
- **PowerShell**: 5.1+ (Windows) or PowerShell Core 7+ (cross-platform)

## 🐛 Known Issues

- Shell Genie compatibility issues resolved by using custom AI module
- Unicode characters replaced with ASCII for better terminal compatibility

## 🤝 Support

For issues, questions, or contributions, please visit our GitHub repository.

---

**Happy AI-powered terminal experience!** 🤖✨