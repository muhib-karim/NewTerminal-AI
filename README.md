# 🚀 NewTerminal-AI

Local AI for your terminal. NewTerminal-AI pairs Ollama with Shell Genie so you can type natural language and get the exact shell command back — fully offline after the first model pull.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) ![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20Windows-blue)

---

## ✨ Features
- Works on Linux, macOS, and Windows
- Auto-detects RAM and picks a lightweight local model
- Ask in natural language, get back a precise command
- One-line install, no manual setup
- Stays private: runs locally with Ollama

## 🧠 How it works
- Uses Ollama to run small LLMs locally
- Uses Shell Genie to translate your intent into shell commands

## 📦 Install
Clone or download this repository and run the cross-platform installer.

### Linux/macOS
```bash
git clone <repository-url>
cd NewTerminal-AI
./install-any.sh
```

### Windows (PowerShell)
```powershell
git clone <repository-url>
cd NewTerminal-AI
.\install.ps1
```

## 🎯 Usage
- Linux/macOS: genie "list all docker containers"
- Windows (PowerShell): ai "your request"
- Fish shell: press Ctrl+Space to open an inline AI prompt

## 🧩 Models and RAM selection
- < 4 GB: phi-3-mini-4k
- 4–7 GB: llama3.2:3b
- ≥ 8 GB: mistral:7b

## 🛠 Requirements
- Internet only for first model pull
- Python 3 with pip available in PATH

## 📸 Demo
Add screenshots/GIFs under the media/ folder. They will be included in releases.

## 🤝 Contributing
Issues and PRs are welcome. Please open an issue to propose changes.

## 📄 License
MIT — see LICENSE.
