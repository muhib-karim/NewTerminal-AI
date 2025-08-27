# NewTerminal-AI 🚀

**Transform your terminal into an intelligent, natural language interface powered by AI**

NewTerminal-AI brings the power of artificial intelligence directly to your command line, allowing you to interact with your system using natural language. Whether you're a beginner learning CLI commands or an expert looking for faster workflows, NewTerminal-AI makes terminal operations intuitive and efficient.

## ✨ Features

### 🎯 Core Functionality
- **Natural Language Commands**: Describe what you want to do in plain English
- **Auto-Execution Mode**: Commands execute automatically with clean, educational output
- **Interactive Mode**: Review and confirm commands before execution
- **Educational Display**: See the actual CLI commands being generated and executed
- **Cross-Platform Support**: Works on Windows (PowerShell), macOS, and Linux

### 🧠 AI-Powered Intelligence
- **Context-Aware**: Understands your current directory and system state
- **Command Safety**: Built-in safety checks for potentially dangerous operations
- **Smart Suggestions**: Generates optimal commands based on your intent
- **Learning-Friendly**: Perfect for users learning command-line operations

### 🎨 Clean Interface
- **Warp AI-Style Output**: Minimal, clean interface focusing on results
- **Color-Coded Responses**: Easy-to-read output with visual indicators
- **Progress Indicators**: Visual feedback during AI processing
- **Error Handling**: Clear, helpful error messages and suggestions

## 🚀 Quick Start

### Windows (PowerShell)
```powershell
# Download and run the installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/NewTerminal-AI/main/scripts/install-windows.ps1" -OutFile "install.ps1"
.\install.ps1
```

### macOS/Linux (Bash/Zsh)
```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/yourusername/NewTerminal-AI/main/scripts/install-unix.sh | bash
```

### Manual Installation
1. Clone this repository
2. Install [Ollama](https://ollama.ai)
3. Run the appropriate installation script from the `scripts/` directory

## 💡 Usage Examples

### Auto-Execute Mode (`aia`)
Perfect for quick tasks and learning:
```bash
# List all files in the current directory
aia "list all files"

# Create a new Python file
aia "create a file called hello.py"

# Find large files
aia "find files larger than 100MB"

# Git operations
aia "commit all changes with message 'update readme'"
```

### Interactive Mode (`ai`)
Review commands before execution:
```bash
# Generate command with confirmation
ai "delete all .tmp files"
# Shows: rm *.tmp
# Prompt: Execute this command? (y/n)
```

### Natural Language Mode (`nl`)
Interactive conversation-style interface:
```bash
nl
# Enters interactive mode
> create a backup of my documents folder
💻 cp -r ~/Documents ~/Documents_backup_$(date +%Y%m%d)
[Command executed successfully]

> what files were created today?
💻 find . -type f -newermt $(date +%Y-%m-%d) -ls
[Lists today's files]
```

## 🛠️ Installation Requirements

### System Requirements
- **Windows**: PowerShell 5.0+ (Windows 10/11)
- **macOS**: macOS 10.15+ with Bash/Zsh
- **Linux**: Any modern distribution with Bash/Zsh
- **Memory**: 4GB RAM minimum, 8GB+ recommended
- **Storage**: 2GB free space for AI models

### Dependencies
- [Ollama](https://ollama.ai) - Local AI model runtime
- Internet connection (for initial setup and model downloads)

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

**Ollama Connection Issues**
```bash
# Check if Ollama is running
ollama list

# Start Ollama service
ollama serve
```

**Command Not Found**
```bash
# Reload your shell configuration
source ~/.bashrc  # Linux/macOS
. $PROFILE        # Windows PowerShell
```

**Model Download Issues**
```bash
# Manually pull the model
ollama pull llama3.2:1b
```

### Getting Help
- 📖 [Documentation](https://github.com/yourusername/NewTerminal-AI/wiki)
- 🐛 [Issue Tracker](https://github.com/yourusername/NewTerminal-AI/issues)
- 💬 [Discussions](https://github.com/yourusername/NewTerminal-AI/discussions)
- 📧 [Email Support](mailto:support@newterminal-ai.com)

## 🌟 Acknowledgments

- [Ollama](https://ollama.ai) for providing the local AI runtime
- [Warp](https://warp.dev) for UI/UX inspiration
- The open-source community for continuous feedback and contributions

## 🔮 Roadmap

- [ ] Plugin system for custom commands
- [ ] Multi-language support
- [ ] Cloud model integration options
- [ ] Advanced scripting capabilities
- [ ] Team collaboration features
- [ ] Performance optimizations
- [ ] Mobile companion app

---

**Made with ❤️ by the NewTerminal-AI Team**

*Transform your terminal experience today!* 🚀