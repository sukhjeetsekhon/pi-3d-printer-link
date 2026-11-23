#!/usr/bin/env bash
# ==============================================================================
# lib/network.sh - NetworkManager Wi-Fi Client & AP Hotspot Configuration
# ==============================================================================

# List wireless and ethernet interfaces
list_interfaces() {
    ip -br link | awk '{print $1}'
}

list_wifi_interfaces() {
    for iface in $(list_interfaces); do
        if [[ -d "/sys/class/net/$iface/wireless" ]]; then
            echo "$iface"
        fi
    done
}

detect_default_interfaces() {
    local wifi_list=($(list_wifi_interfaces))
    local uplink_cand=""
    local ap_cand=""

    if [[ ${#wifi_list[@]} -ge 2 ]]; then
        uplink_cand="${wifi_list[0]}"
        ap_cand="${wifi_list[1]}"
    elif [[ ${#wifi_list[@]} -eq 1 ]]; then
        uplink_cand="${wifi_list[0]}"
        ap_cand="wlan1"
    else
        uplink_cand="wlan0"
        ap_cand="wlan1"
    fi

    echo "$uplink_cand $ap_cand"
}

# Configure UCSD-PROTECTED (or generic WPA-Enterprise 802.1X PEAP-MSCHAPv2)
configure_enterprise_client() {
    local iface="$1"
    local ssid="${2:-UCSD-PROTECTED}"
    local username="$3"
    local password="$4"
    local conn_name="pi-link-uplink"

    log_info "Configuring WPA2-Enterprise connection on interface ${COLOR_WHITE}$iface${COLOR_RESET} for SSID: ${COLOR_WHITE}$ssid${COLOR_RESET}..."

    # Delete existing connection with this name if present
    nmcli connection delete "$conn_name" 2>/dev/null || true

    nmcli connection add \
        type wifi \
        con-name "$conn_name" \
        ifname "$iface" \
        ssid "$ssid" \
        wifi-sec.key-mgmt wpa-eap \
        802-1x.eap peap \
        802-1x.phase2-auth mschapv2 \
        802-1x.identity "$username" \
        802-1x.password "$password" \
        connection.autoconnect yes

    log_success "Created NetworkManager profile '$conn_name'."
    log_info "Attempting connection to $ssid..."
    if nmcli connection up "$conn_name"; then
        log_success "Successfully connected to $ssid!"
    else
        log_warn "Connection attempt timed out or failed. Profile is saved and will auto-connect when in range."
    fi
}

# Configure 2.4GHz Hotspot for Bambu P1S
configure_printer_hotspot() {
    local iface="$1"
    local ssid="${2:-Bambu-Pi-Link}"
    local psk="${3:-bambulab123}"
    local channel="${4:-6}"
    local conn_name="pi-link-hotspot"

    log_info "Creating 2.4GHz Hotspot on interface ${COLOR_WHITE}$iface${COLOR_RESET}..."
    log_info "SSID: ${COLOR_WHITE}$ssid${COLOR_RESET} | Band: 2.4GHz (Channel $channel) | IP Gateway: 192.168.4.1"

    # Delete existing connection with this name if present
    nmcli connection delete "$conn_name" 2>/dev/null || true

    # Create AP profile with static 192.168.4.1 subnet and shared DHCP
    nmcli connection add \
        type wifi \
        con-name "$conn_name" \
        ifname "$iface" \
        ssid "$ssid" \
        mode ap \
        802-11-wireless.band bg \
        802-11-wireless.channel "$channel" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$psk" \
        ipv4.method shared \
        ipv4.addresses 192.168.4.1/24 \
        connection.autoconnect yes

    log_success "Created Hotspot profile '$conn_name'."
    log_info "Starting hotspot..."
    if nmcli connection up "$conn_name"; then
        log_success "Hotspot '$ssid' is now broadcasting on 2.4GHz!"
    else
        log_error "Failed to bring up hotspot profile. Make sure $iface supports AP mode and is not blocked by rfkill."
    fi
}

teardown_network_profiles() {
    log_info "Removing pi-link NetworkManager profiles..."
    nmcli connection delete "pi-link-hotspot" 2>/dev/null && log_success "Deleted pi-link-hotspot" || true
    nmcli connection delete "pi-link-uplink" 2>/dev/null && log_success "Deleted pi-link-uplink" || true
}
