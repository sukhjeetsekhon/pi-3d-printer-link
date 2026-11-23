#!/usr/bin/env bash
# ==============================================================================
# lib/tailscale.sh - Tailscale Subnet Router Installation & Provisioning
# ==============================================================================

ensure_tailscale_installed() {
    if ! command -v tailscale &>/dev/null; then
        log_warn "Tailscale is not installed. Installing Tailscale now..."
        curl -fsSL https://tailscale.com/install.sh | sh
        systemctl enable --now tailscaled
        log_success "Tailscale installed and daemon started."
    else
        log_info "Tailscale is already installed ($(tailscale version | head -n 1))."
    fi
}

configure_tailscale_subnet_router() {
    local subnet="${1:-192.168.4.0/24}"

    ensure_tailscale_installed

    log_info "Configuring Tailscale Subnet Router advertising route ${COLOR_WHITE}$subnet${COLOR_RESET}..."
    echo -e "${COLOR_CYAN}If Tailscale is not logged in, you will see a login URL below. Open it in your browser.${COLOR_RESET}"
    echo ""

    tailscale up --advertise-routes="$subnet" --accept-routes --reset

    echo ""
    log_success "Tailscale route advertised: $subnet"
    echo -e "${COLOR_YELLOW}${COLOR_BOLD}[IMPORTANT - FINAL STEP IN TAILSCALE ADMIN CONSOLE]:${COLOR_RESET}"
    echo -e "1. Go to your Tailscale Admin Console: ${COLOR_WHITE}https://login.tailscale.com/admin/machines${COLOR_RESET}"
    echo -e "2. Find this Raspberry Pi machine."
    echo -e "3. Click ${COLOR_BOLD}'Edit route settings'${COLOR_RESET} and check/approve ${COLOR_BOLD}$subnet${COLOR_RESET}."
    echo -e "4. On your Laptop, ensure Tailscale is connected with 'Use Tailscale subnets' enabled."
}

get_tailscale_status() {
    if command -v tailscale &>/dev/null; then
        tailscale status 2>/dev/null || echo "Tailscale daemon stopped or logged out"
    else
        echo "Tailscale not installed"
    fi
}
