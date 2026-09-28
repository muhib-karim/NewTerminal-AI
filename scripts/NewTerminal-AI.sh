#!/bin/bash

# NewTerminal-AI - Cross-platform Natural Language Terminal
# Compatible with macOS and Linux

# Configuration
# Override with NEWTERMINAL_AI_MODEL; install-unix.sh rewrites this line to the model it pulled
OLLAMA_MODEL="${NEWTERMINAL_AI_MODEL:-llama3.2:1b}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HISTORY_FILE="$HOME/.newterminal_ai_history"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Check if ollama is installed and running
check_ollama() {
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}❌ Ollama not found. Please install Ollama first.${NC}"
        echo -e "${CYAN}Visit: https://ollama.ai${NC}"
        return 1
    fi
    
    if ! ollama list &> /dev/null; then
        echo -e "${YELLOW}⚠️  Ollama not running${NC}"
        return 1
    fi
    
    return 0
}

# Get command suggestion from AI
get_command_suggestion() {
    local natural_language="$1"
    
    # Check for model queries
    if [[ "$natural_language" =~ (what model|which model|what llm|which llm) ]]; then
        echo "echo 'Current AI Model: $OLLAMA_MODEL'"
        return
    fi
    
    local system_prompt="You are a command-line assistant. Generate ONLY the exact command to execute, no explanations or markdown.

Rules:
- Output ONLY the command, nothing else
- Use appropriate commands for $(uname -s)
- For file operations:
  * Create file: touch filename
  * Write to file: echo 'content' > filename
  * Find files: find . -name 'pattern'
  * Check if file exists: test -f filename && echo 'exists' || echo 'not found'
  * Read file: cat filename
  * Delete file: rm filename
  * Copy file: cp source dest
  * Move/rename: mv source dest
  * List files: ls -la

Examples:
Input: create a file named test.txt
Output: touch test.txt

Input: find file test.txt
Output: find . -name 'test.txt'

Input: list all files
Output: ls -la"
    
    local response=$(ollama run "$OLLAMA_MODEL" "$system_prompt"$'\n\n'"User request: $natural_language" 2>/dev/null)
    
    # Clean up response: drop markdown code fences and blank lines, trim whitespace.
    # (xargs was used before, but it strips quotes and fails on apostrophes.)
    response=$(printf '%s\n' "$response" | sed -e '/^[[:space:]]*```/d' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d')
    
    echo "$response"
}

# Test command safety
test_command_safety() {
    local command="$1"
    
    # Dangerous patterns (POSIX extended regex, matched case-insensitively).
    # A literal pipe must be written as \| - an unescaped | is alternation.
    local dangerous_patterns=(
        '(^|[^[:alnum:]_-])rm[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(-[a-z]*r|--recursive)'
        '(^|[^[:alnum:]_-])rm[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(/|~|\*)([[:space:]]|$)'
        ':\(\)[[:space:]]*\{.*\};[[:space:]]*:'
        '(^|[^[:alnum:]_])mkfs'
        '(^|[^[:alnum:]_])dd[[:space:]].*of=/dev/'
        '>[[:space:]]*/dev/(sd|hd|nvme|disk|mmcblk)'
        '(curl|wget)[[:space:]].*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([[:space:]]|$)'
        '(^|[^[:alnum:]_])(shutdown|reboot|halt|poweroff)([^[:alnum:]_]|$)'
        '(^|[^[:alnum:]_])ch(mod|own|grp)[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-[a-z]*r'
        'git[[:space:]]+push[[:space:]].*(--force|[[:space:]]-f)([[:space:]]|$)'
        'git[[:space:]]+reset[[:space:]]+--hard'
        'git[[:space:]]+clean[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-[a-z]*f'
    )
    
    local restore_nocasematch
    restore_nocasematch=$(shopt -p nocasematch)
    shopt -s nocasematch
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$command" =~ $pattern ]]; then
            $restore_nocasematch
            return 1
        fi
    done
    $restore_nocasematch
    
    return 0
}

# Add to history
add_to_history() {
    local request="$1"
    local command="$2"
    local executed="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Requests may contain private data: keep the history file readable by the owner only
    ( umask 077; echo "[$timestamp] Request: $request | Command: $command | Executed: $executed" >> "$HISTORY_FILE" )
}

# Show command history
show_history() {
    local count=${1:-10}
    
    if [[ -f "$HISTORY_FILE" ]]; then
        echo -e "${YELLOW}Recent Commands:${NC}"
        tail -n "$count" "$HISTORY_FILE" | while read -r line; do
            echo -e "${GRAY}$line${NC}"
        done
    else
        echo -e "${GRAY}No command history found${NC}"
    fi
}

# Auto-execute command
aia() {
    local natural_language="$*"
    
    if [[ -z "$natural_language" ]]; then
        echo -e "${YELLOW}Please provide a command request${NC}"
        return 1
    fi
    
    if ! check_ollama; then
        return 1
    fi
    
    local command=$(get_command_suggestion "$natural_language")
    
    if [[ -z "$command" ]]; then
        echo -e "${RED}❌ Could not understand: '$natural_language'${NC}"
        add_to_history "$natural_language" "" "false"
        return 1
    fi
    
    if ! test_command_safety "$command"; then
        echo -e "${RED}⚠️  Potentially harmful command detected${NC}"
        echo -e "${YELLOW}   $command${NC}"
        add_to_history "$natural_language" "$command" "false"
        return 1
    fi
    
    # Show the command being executed
    echo -e "${CYAN}💻 ${YELLOW}$command${NC}"
    
    # Execute the command
    if eval "$command"; then
        add_to_history "$natural_language" "$command" "true"
    else
        local exit_code=$?
        echo -e "${RED}❌ Exit code: $exit_code${NC}"
        add_to_history "$natural_language" "$command" "false"
        return $exit_code
    fi
}

# Natural language mode
nl() {
    echo -e "${GREEN}🤖 AI Terminal${NC}"
    echo -e "${GRAY}Type commands in natural language. Type 'exit' to quit.${NC}"
    echo ""
    
    local session_commands=0
    
    while true; do
        # Get git branch if in git repo
        local git_branch=""
        if git rev-parse --git-dir &> /dev/null; then
            git_branch=$(git branch --show-current 2>/dev/null)
        fi
        
        # Create prompt
        local prompt=">"
        if [[ -n "$git_branch" ]]; then
            prompt="($git_branch) >"
        fi
        
        echo -ne "${CYAN}$prompt ${NC}"
        # Stop at end of input (Ctrl-D) instead of looping forever
        read -r input || { echo ""; break; }
        
        case "${input,,}" in
            "exit")
                echo -e "${GREEN}👋 Goodbye!${NC}"
                break
                ;;
            "history")
                show_history 10
                continue
                ;;
            "clear")
                clear
                echo -e "${GREEN}🤖 AI Terminal${NC}"
                echo -e "${GRAY}Type commands in natural language. Type 'exit' to quit.${NC}"
                echo ""
                continue
                ;;
            "help")
                echo -e "${YELLOW}Available commands:${NC}"
                echo -e "${CYAN}  exit     - Exit AI terminal${NC}"
                echo -e "${CYAN}  history  - Show command history${NC}"
                echo -e "${CYAN}  clear    - Clear screen${NC}"
                echo -e "${CYAN}  help     - Show this help${NC}"
                echo -e "${GREEN}  Or describe what you want to do!${NC}"
                continue
                ;;
            *)
                if [[ -n "${input// }" ]]; then
                    ((session_commands++))
                    aia "$input"
                    echo ""
                fi
                ;;
        esac
    done
}

# AI command with confirmation
ai() {
    local natural_language="$*"
    
    if [[ -z "$natural_language" ]]; then
        echo -e "${YELLOW}Please provide a command request${NC}"
        return 1
    fi
    
    if ! check_ollama; then
        return 1
    fi
    
    local command=$(get_command_suggestion "$natural_language")
    
    if [[ -z "$command" ]]; then
        echo -e "${RED}❌ Could not understand: '$natural_language'${NC}"
        add_to_history "$natural_language" "" "false"
        return 1
    fi
    
    if ! test_command_safety "$command"; then
        echo -e "${RED}⚠️  Potentially harmful command detected${NC}"
        echo -e "${YELLOW}   $command${NC}"
        add_to_history "$natural_language" "$command" "false"
        return 1
    fi
    
    echo -e "${BLUE}Generated Command:${NC}"
    echo -e "${YELLOW}    $command${NC}"
    echo ""
    
    echo -ne "Execute this command? [y/N/e(dit)]: "
    read -r confirmation
    
    case "${confirmation,,}" in
        "y")
            echo -e "${CYAN}Executing command...${NC}"
            if eval "$command"; then
                echo -e "${GREEN}Command executed successfully${NC}"
                add_to_history "$natural_language" "$command" "true"
            else
                echo -e "${RED}Execution failed${NC}"
                add_to_history "$natural_language" "$command" "false"
            fi
            ;;
        "e")
            echo -ne "${CYAN}Edit command: ${NC}"
            read -r edited_command
            if [[ -n "${edited_command// }" ]]; then
                echo -e "${CYAN}Executing edited command...${NC}"
                if eval "$edited_command"; then
                    echo -e "${GREEN}Edited command executed successfully${NC}"
                    add_to_history "$natural_language" "$edited_command" "true"
                else
                    echo -e "${RED}Execution failed${NC}"
                    add_to_history "$natural_language" "$edited_command" "false"
                fi
            fi
            ;;
        *)
            echo -e "${GRAY}Command cancelled by user${NC}"
            add_to_history "$natural_language" "$command" "false"
            ;;
    esac
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # install-unix.sh links ai, aia and nl to this script: dispatch on the name it was called by
    case "$(basename "$0")" in
        ai|aia|nl) set -- "$(basename "$0")" "$@" ;;
    esac
    case "$1" in
        "nl")
            nl
            ;;
        "aia")
            shift
            aia "$*"
            ;;
        "ai")
            shift
            ai "$*"
            ;;
        "history")
            show_history "${2:-10}"
            ;;
        *)
            echo -e "${GREEN}NewTerminal-AI - Natural Language Terminal${NC}"
            echo -e "${GRAY}Usage:${NC}"
            echo -e "${CYAN}  ./NewTerminal-AI.sh nl          ${GRAY}- Interactive natural language mode${NC}"
            echo -e "${CYAN}  ./NewTerminal-AI.sh aia <text>  ${GRAY}- Auto-execute command${NC}"
            echo -e "${CYAN}  ./NewTerminal-AI.sh ai <text>   ${GRAY}- Generate command with confirmation${NC}"
            echo -e "${CYAN}  ./NewTerminal-AI.sh history     ${GRAY}- Show command history${NC}"
            ;;
    esac
fi