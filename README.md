# 🚀 NewTerminal

Local AI for your terminal. NewTerminal pairs Ollama with Shell Genie so you can type natural language and get the exact shell command back — fully offline after the first model pull.

[![Release](https://img.shields.io/github/v/release/muhibalkarim/NewTerminal?label=release)](https://github.com/muhibalkarim/NewTerminal/releases) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) ![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20Windows-blue)

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
Download the latest release ZIP and run the cross-platform installer.

### Linux/macOS
```bash
curl -L https://github.com/muhibalkarim/NewTerminal/releases/latest/download/newterminal-v1.0.zip -o newterminal.zip
unzip newterminal.zip
cd newterminal-v1.0
./install-any.sh
```

### Windows (PowerShell)
```powershell
Invoke-WebRequest https://github.com/muhibalkarim/NewTerminal/releases/latest/download/newterminal-v1.0.zip -OutFile newterminal.zip
Expand-Archive newterminal.zip -DestinationPath .
cd newterminal-v1.0
./install-any.sh
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
