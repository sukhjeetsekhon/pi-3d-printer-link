#!/usr/bin/env bash
# ==============================================================================
# lib/diagnostics.sh - Status Dashboard & Bambu P1S Port Health Checks
# ==============================================================================

find_printer_ip() {
    # Check dnsmasq leases if standard NetworkManager shared AP is used
    local leases_files=(
        "/var/lib/misc/dnsmasq.leases"
        "/var/lib/NetworkManager/dnsmasq-*.leases"
    )
    for lf in ${leases_files[@]}; do
        if [[ -f "$lf" ]]; then
            local cand=$(awk '{print $3}' "$lf" | tail -n 1)
            if [[ -n "$cand" ]]; then
                echo "$cand"
                return
            fi
        fi
    done

    # Fallback to ARP / ip neigh in 192.168.4.0/24
    local neigh=$(ip neigh show | grep "192.168.4." | grep -v "FAILED" | awk '{print $1}' | head -n 1)
    if [[ -n "$neigh" ]]; then
        echo "$neigh"
        return
    fi

    # Default assumed static IP if printer was manually bound
    echo "192.168.4.10"
}

check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-2}"

    if command -v nc &>/dev/null; then
        nc -z -w "$timeout" "$host" "$port" 2>/dev/null
        return $?
    elif command -v timeout &>/dev/null; then
        timeout "$timeout" bash -c "</dev/tcp/$host/$port" 2>/dev/null
        return $?
    else
        return 1
    fi
}

test_printer_connectivity() {
    local target_ip="${1:-$(find_printer_ip)}"
    echo -e "${COLOR_CYAN}${COLOR_BOLD}=== Bambu Lab P1S Port Connectivity Test ===${COLOR_RESET}"
    echo -e "Target Printer IP: ${COLOR_WHITE}${COLOR_BOLD}$target_ip${COLOR_RESET}"
    echo ""

    # Ping test
    if ping -c 2 -W 2 "$target_ip" &>/dev/null; then
        echo -e "  ICMP Ping:               ${COLOR_GREEN}[ONLINE / RESPONDING]${COLOR_RESET}"
    else
        echo -e "  ICMP Ping:               ${COLOR_YELLOW}[NO RESPONSE (Normal if ICMP blocked)]${COLOR_RESET}"
    fi

    # MQTT Port 8883 (SSL)
    if check_port "$target_ip" 8883; then
        echo -e "  Port 8883 (MQTTS/Control): ${COLOR_GREEN}[OPEN / REACHABLE]${COLOR_RESET}"
    else
        echo -e "  Port 8883 (MQTTS/Control): ${COLOR_RED}[CLOSED / UNREACHABLE]${COLOR_RESET}"
    fi

    # FTPS Port 990 (Print file upload)
    if check_port "$target_ip" 990; then
        echo -e "  Port 990 (FTPS/Prints):   ${COLOR_GREEN}[OPEN / REACHABLE]${COLOR_RESET}"
    else
        echo -e "  Port 990 (FTPS/Prints):   ${COLOR_RED}[CLOSED / UNREACHABLE]${COLOR_RESET}"
    fi

    # Camera Port 6000
    if check_port "$target_ip" 6000; then
        echo -e "  Port 6000 (Chamber Cam):  ${COLOR_GREEN}[OPEN / REACHABLE]${COLOR_RESET}"
    else
        echo -e "  Port 6000 (Chamber Cam):  ${COLOR_YELLOW}[CLOSED (Camera active only when streaming)]${COLOR_RESET}"
    fi
    echo ""
}

show_status_dashboard() {
    print_banner
    echo -e "${COLOR_CYAN}${COLOR_BOLD}=== Network & Link Dashboard ===${COLOR_RESET}"
    echo ""

    # 1. Uplink Status
    echo -e "${COLOR_WHITE}${COLOR_BOLD}[1] Campus Uplink Connection:${COLOR_RESET}"
    local uplink_status=$(nmcli -t -f NAME,DEVICE,STATE c show --active | grep -E "pi-link-uplink|wlan0|eth0" | head -n 1)
    if [[ -n "$uplink_status" ]]; then
        local c_name=$(echo "$uplink_status" | cut -d: -f1)
        local c_dev=$(echo "$uplink_status" | cut -d: -f2)
        local c_ip=$(ip -4 addr show dev "$c_dev" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
        echo -e "  Status:    ${COLOR_GREEN}Connected${COLOR_RESET} (${c_name} on ${c_dev})"
        echo -e "  IP:        ${COLOR_WHITE}${c_ip:-Unknown}${COLOR_RESET}"
    else
        echo -e "  Status:    ${COLOR_RED}Disconnected / Inactive${COLOR_RESET}"
    fi
    echo ""

    # 2. Hotspot Status
    echo -e "${COLOR_WHITE}${COLOR_BOLD}[2] 2.4GHz Printer Hotspot:${COLOR_RESET}"
    local ap_status=$(nmcli -t -f NAME,DEVICE,STATE c show --active | grep "pi-link-hotspot")
    if [[ -n "$ap_status" ]]; then
        local ap_dev=$(echo "$ap_status" | cut -d: -f2)
        echo -e "  Status:    ${COLOR_GREEN}Broadcasting${COLOR_RESET} on interface ${ap_dev}"
        echo -e "  Gateway:   ${COLOR_WHITE}192.168.4.1${COLOR_RESET} (SSID: Bambu-Pi-Link)"
        local printer_ip=$(find_printer_ip)
        echo -e "  Bambu P1S: ${COLOR_CYAN}${printer_ip}${COLOR_RESET}"
    else
        echo -e "  Status:    ${COLOR_YELLOW}Hotspot Inactive${COLOR_RESET}"
    fi
    echo ""

    # 3. Tailscale Subnet Router Status
    echo -e "${COLOR_WHITE}${COLOR_BOLD}[3] Tailscale Subnet Router:${COLOR_RESET}"
    if command -v tailscale &>/dev/null; then
        local ts_ip=$(tailscale ip -4 2>/dev/null)
        if [[ -n "$ts_ip" ]]; then
            echo -e "  Tailscale: ${COLOR_GREEN}Online${COLOR_RESET} (Pi Tailscale IP: ${COLOR_WHITE}$ts_ip${COLOR_RESET})"
            echo -e "  Routes:    Advertising ${COLOR_WHITE}192.168.4.0/24${COLOR_RESET}"
        else
            echo -e "  Tailscale: ${COLOR_YELLOW}Installed but not logged in${COLOR_RESET}"
        fi
    else
        echo -e "  Tailscale: ${COLOR_RED}Not installed${COLOR_RESET}"
    fi
    echo ""

    # 4. Printer Port Status
    local target_ip=$(find_printer_ip)
    test_printer_connectivity "$target_ip"
}
