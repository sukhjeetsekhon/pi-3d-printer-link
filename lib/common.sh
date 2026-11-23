#!/usr/bin/env bash
# ==============================================================================
# lib/common.sh - Common Utilities, Logging & UI for pi-link
# ==============================================================================

# ANSI color codes
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_RED="\033[1;31m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_CYAN="\033[1;36m"
COLOR_WHITE="\033[1;37m"

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1" >&2
}

print_banner() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    cat << "EOF"
  ____  _       _     _       _    
 |  _ \(_)     | |   (_)_ __ | | __
 | |_) | |_____| |   | | '_ \| |/ /
 |  __/| |_____| |___| | | | |   < 
 |_|   |_|     |_____|_|_| |_|_|\_\
      Bambu P1S <-> Pi 5 <-> Campus Link
EOF
    echo -e "${COLOR_RESET}"
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This action requires root privileges. Please run with sudo: sudo pi-link $1"
        exit 1
    fi
}

check_dependencies() {
    local missing=()
    for cmd in nmcli iptables ip sysctl tailscale; do
        if ! command -v "$cmd" &> /dev/null; then
            if [[ "$cmd" == "tailscale" ]]; then
                # Tailscale can be installed by our installer
                continue
            fi
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing required packages: ${missing[*]}"
        log_info "Installing missing packages via apt..."
        apt-get update && apt-get install -y "${missing[@]}"
    fi
}
