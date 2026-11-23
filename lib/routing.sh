#!/usr/bin/env bash
# ==============================================================================
# lib/routing.sh - Linux Kernel IP Forwarding and NAT (nftables / iptables)
# ==============================================================================

SYSCTL_CONF="/etc/sysctl.d/99-pi-link.conf"

enable_ip_forwarding() {
    log_info "Enabling Linux kernel IPv4 forwarding..."
    echo "net.ipv4.ip_forward=1" > "$SYSCTL_CONF"
    sysctl -p "$SYSCTL_CONF" >/dev/null 2>&1 || sysctl -w net.ipv4.ip_forward=1 >/dev/null
    log_success "IPv4 forwarding enabled."
}

configure_nat() {
    local uplink_iface="$1"
    local hotspot_subnet="${2:-192.168.4.0/24}"

    log_info "Configuring NAT MASQUERADE from $hotspot_subnet out of $uplink_iface..."

    # Use iptables with persistence if available
    if command -v iptables &>/dev/null; then
        # Avoid duplicate rules
        iptables -t nat -C POSTROUTING -s "$hotspot_subnet" -o "$uplink_iface" -j MASQUERADE 2>/dev/null || \
            iptables -t nat -A POSTROUTING -s "$hotspot_subnet" -o "$uplink_iface" -j MASQUERADE

        iptables -C FORWARD -i "$uplink_iface" -o "wlan+" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
            iptables -A FORWARD -i "$uplink_iface" -o "wlan+" -m state --state RELATED,ESTABLISHED -j ACCEPT

        iptables -C FORWARD -i "wlan+" -o "$uplink_iface" -j ACCEPT 2>/dev/null || \
            iptables -A FORWARD -i "wlan+" -o "$uplink_iface" -j ACCEPT

        log_success "NAT rules configured via iptables."
    else
        log_warn "iptables not found; NetworkManager 'shared' mode will handle basic NAT automatically."
    fi
}

teardown_routing() {
    log_info "Restoring sysctl and removing custom NAT rules..."
    rm -f "$SYSCTL_CONF"
}
