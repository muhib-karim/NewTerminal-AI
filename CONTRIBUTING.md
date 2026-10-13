# Contributing to NewTerminal-AI 🤝

Thank you for your interest in contributing to NewTerminal-AI! We welcome contributions from developers of all skill levels. This guide will help you get started.

## 🚀 Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/NewTerminal-AI.git
   cd NewTerminal-AI
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes** and test them
5. **Submit a pull request**

## 🛠️ Development Setup

### Prerequisites
- **Windows**: PowerShell 5.0+, Git
- **macOS/Linux**: Bash/Zsh, Git
- [Ollama](https://ollama.ai) installed and running
- A suitable AI model (e.g., `llama3.2:1b`)

### Local Development

1. **Install dependencies**:
   ```bash
   # Install Ollama if not already installed
   # Windows: Download from ollama.ai
   # macOS: brew install ollama
   # Linux: curl -fsSL https://ollama.ai/install.sh | sh
   
   # Pull a development model
   ollama pull llama3.2:1b
   ```

2. **Test the module** (Windows):
   ```powershell
   Import-Module .\NewTerminal-AI-fixed.psm1 -Force
   aia "test command"
   ```

3. **Test the shell script** (macOS/Linux):
   ```bash
   chmod +x scripts/NewTerminal-AI.sh
   ./scripts/NewTerminal-AI.sh aia "test command"
   ```

## 📋 Contribution Guidelines

### Code Style

#### PowerShell
- Use **PascalCase** for function names
- Use **camelCase** for variable names
- Include **comment-based help** for all functions
- Follow **PowerShell best practices**
- Use **Write-Host** with colors for user-facing output

#### Shell Scripts
- Use **snake_case** for function and variable names
- Include **function documentation**
- Follow **POSIX compliance** where possible
- Use **proper error handling** with `set -e`
- Include **color output** for better UX

#### General
- **Consistent indentation** (4 spaces for PowerShell, 2 spaces for shell)
- **Clear, descriptive variable names**
- **Comprehensive error handling**
- **User-friendly error messages**

### Commit Messages

Use the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(ai): add support for custom AI models
fix(windows): resolve PowerShell execution policy issue
docs(readme): update installation instructions
```

## 🧪 Testing

### Manual Testing Checklist

Before submitting a PR, please test:

#### Core Functionality
- [ ] `aia "list files"` - Auto-execution works
- [ ] `ai "create test file"` - Interactive mode works
- [ ] `nl` - Natural language mode starts and responds
- [ ] Command history functionality
- [ ] Error handling for invalid commands
- [ ] Safety checks for dangerous commands

#### Cross-Platform (if applicable)
- [ ] Windows PowerShell functionality
- [ ] macOS Bash/Zsh functionality
- [ ] Linux Bash/Zsh functionality
- [ ] Installation scripts work correctly

#### Edge Cases
- [ ] Ollama not running
- [ ] Invalid AI model
- [ ] Network connectivity issues
- [ ] Large command outputs
- [ ] Special characters in commands

### Automated Testing

We're working on automated tests. For now, please:
1. Test your changes manually
2. Verify existing functionality still works
3. Test on multiple platforms if possible

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment details**:
   - OS and version
   - PowerShell/Shell version
   - Ollama version
   - AI model being used

2. **Steps to reproduce**:
   - Exact commands used
   - Expected behavior
   - Actual behavior

3. **Error messages**:
   - Full error output
   - Screenshots if helpful

4. **Additional context**:
   - Recent changes to system
   - Other relevant software

## 💡 Feature Requests

We love new ideas! When suggesting features:

1. **Check existing issues** to avoid duplicates
2. **Describe the problem** you're trying to solve
3. **Propose a solution** with examples
4. **Consider the impact** on existing users
5. **Think about implementation** complexity

## 🏗️ Architecture Overview

### Project Structure
```
NewTerminal-AI/
├── NewTerminal-AI-fixed.psm1    # Main PowerShell module
├── scripts/
│   ├── NewTerminal-AI.sh         # Unix shell script
│   ├── install-windows.ps1       # Windows installer
│   └── install-unix.sh           # Unix installer
├── docs/                         # Documentation
├── examples/                     # Usage examples
├── releases/                     # Release packages
├── README.md                     # Main documentation
├── CONTRIBUTING.md               # This file
└── LICENSE                       # MIT license
```

### Key Components

#### PowerShell Module (`NewTerminal-AI-fixed.psm1`)
- **Invoke-AICommand**: Core AI interaction function
- **Invoke-AICommandAuto**: Auto-execution wrapper
- **Start-NLMode**: Natural language interactive mode
- **Safety checks**: Command validation and user confirmation

#### Unix Shell Script (`scripts/NewTerminal-AI.sh`)
- **Cross-platform compatibility** for macOS and Linux
- **Equivalent functionality** to PowerShell module
- **POSIX-compliant** where possible

## 🎯 Priority Areas

We're especially looking for contributions in:

1. **Cross-platform compatibility**
   - Testing on different OS versions
   - Shell compatibility improvements
   - Installation script enhancements

2. **AI model optimization**
   - Support for new models
   - Performance improvements
   - Memory usage optimization

3. **User experience**
   - Better error messages
   - Improved command suggestions
   - Enhanced safety features

4. **Documentation**
   - Usage examples
   - Troubleshooting guides
   - Video tutorials

5. **Testing**
   - Automated test suite
   - Integration tests
   - Performance benchmarks

## 📚 Resources

- [PowerShell Documentation](https://docs.microsoft.com/powershell)
- [Bash Scripting Guide](https://tldp.org/LDP/Bash-Beginners-Guide/html/)
- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Conventional Commits](https://www.conventionalcommits.org/)

## 🤔 Questions?

If you have questions about contributing:

1. **Check the [Issues](https://github.com/muhib-karim/NewTerminal-AI/issues)** for existing discussions
2. **Open an [Issue](https://github.com/muhib-karim/NewTerminal-AI/issues/new)** for general questions
3. **Join our community** (links coming soon)

## 🙏 Recognition

All contributors will be:
- **Listed in our README** contributors section
- **Mentioned in release notes** for their contributions
- **Invited to our contributors' channel** (coming soon)

Thank you for helping make NewTerminal-AI better for everyone! 🚀