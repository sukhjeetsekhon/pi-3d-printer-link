#!/usr/bin/env bash
# ==============================================================================
# lib/esp_flasher.sh - ESP32-C5 ESP-Hosted Flashing & Setup Utility
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ensure_python_esptool() {
    if ! command -v python3 &>/dev/null; then
        log_info "Installing python3 and pip..."
        apt-get update && apt-get install -y python3 python3-pip python3-serial python3-setuptools
    fi

    if ! python3 -m esptool --help &>/dev/null; then
        log_info "Installing esptool via pip..."
        python3 -m pip install --break-system-packages esptool pyserial 2>/dev/null || \
            pip install esptool pyserial 2>/dev/null || \
            apt-get install -y esptool
    fi
}

detect_esp_serial_port() {
    for port in /dev/ttyACM* /dev/ttyUSB*; do
        if [[ -e "$port" ]]; then
            echo "$port"
            return
        fi
    done
    echo ""
}

run_esp_flash_wizard() {
    ensure_python_esptool

    local port=$(detect_esp_serial_port)
    echo -e "${COLOR_CYAN}${COLOR_BOLD}=== XIAO Seeed Studio ESP32-C5 Flasher ===${COLOR_RESET}"
    if [[ -z "$port" ]]; then
        log_warn "No USB serial device detected in /dev/ttyACM* or /dev/ttyUSB*."
        read -p "Enter serial port manually (e.g. /dev/ttyACM0, COM11): " port
    else
        log_info "Auto-detected serial device: ${COLOR_WHITE}$port${COLOR_RESET}"
        read -p "Use this port? [Y/n]: " confirm
        if [[ "$confirm" =~ ^[Nn] ]]; then
            read -p "Enter custom serial port: " port
        fi
    fi

    log_info "Probing chip on $port..."
    python3 "$SCRIPT_DIR/firmware/esp32c5/flash_esp32c5.py" --port "$port" --probe

    echo ""
    echo -e "${COLOR_WHITE}${COLOR_BOLD}Flashing Options:${COLOR_RESET}"
    echo "1) Flash Pre-compiled ESP-Hosted-NG firmware binary (Dual-band Wi-Fi USB Dongle)"
    echo "2) Custom firmware binary"
    echo "3) Probe / Read chip info only"
    read -p "Select option [1-3]: " opt

    case "$opt" in
        1)
            local bin_url="https://github.com/espressif/esp-hosted/releases/latest"
            log_info "ESP-Hosted binary flasher selected."
            log_info "For detailed firmware builds and instructions, see firmware/esp32c5/README.md."
            read -p "Enter path to ESP-Hosted firmware .bin file: " custom_bin
            if [[ -f "$custom_bin" ]]; then
                python3 "$SCRIPT_DIR/firmware/esp32c5/flash_esp32c5.py" --port "$port" --flash "$custom_bin"
            else
                log_error "File not found: $custom_bin"
            fi
            ;;
        2)
            read -p "Enter full path to binary: " custom_bin
            read -p "Enter flash offset [default: 0x0]: " offset
            offset="${offset:-0x0}"
            python3 "$SCRIPT_DIR/firmware/esp32c5/flash_esp32c5.py" --port "$port" --flash "$custom_bin" --offset "$offset"
            ;;
        3)
            log_success "Probe completed."
            ;;
        *)
            log_warn "Invalid selection."
            ;;
    esac
}
