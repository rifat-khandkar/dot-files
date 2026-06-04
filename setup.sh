#!/bin/bash

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║        dotfiles v2.0 setup        ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${NC}"

# --------------------------------------------------
# Parse hex color & apply as accent
ACCENT=""
apply_accent() {
    local hex="$1"
    hex="${hex#"#"}"
    hex="${hex,,}"
    # Convert to RGB 0-1000 for ranger curses
    local r=$(( 16#${hex:0:2} * 1000 / 255 ))
    local g=$(( 16#${hex:2:2} * 1000 / 255 ))
    local b=$(( 16#${hex:4:2} * 1000 / 255 ))

    echo -e "${GREEN}[*]${NC} Applying accent #${hex} to configs..."

    sed -i "s/#cba6f7/#${hex}/g" ~/.config/waybar/style.css
    sed -i "s/#cba6f7/ ${hex}/g" ~/.config/foot/foot.ini
    sed -i "s/cba6f7ff/${hex}ff/g" ~/.config/fuzzel/fuzzel.ini
    sed -i "s/cba6f7/${hex}/g" ~/.config/fuzzel/fuzzel.ini
    sed -i "s/curses.init_color(ACCENT, [0-9]*, [0-9]*, [0-9]*)/curses.init_color(ACCENT, $r, $g, $b)/" \
        ~/.config/ranger/colorschemes/mauve.py

    echo -e "${GREEN}[✓]${NC} Accent applied"
}

# --------------------------------------------------
# Web app selection
pick_webapps() {
    local apps=("atkhub" "github" "protonmail" "opencode" "pw")
    local names=("ATK Hub" "GitHub" "Proton Mail" "opencode" "PW")
    local keep=()

    echo -e "\n${CYAN}[?]${NC} Select web app desktop entries to install:"
    for i in "${!apps[@]}"; do
        read -rp "  ${names[$i]} [Y/n]: " yn
        case "$yn" in
            n|N|no|NO) ;;
            *) keep+=("${apps[$i]}") ;;
        esac
    done

    # Remove unselected desktop entries after copy
    for f in ~/.local/share/applications/*.desktop; do
        base=$(basename "$f" .desktop)
        keepit=false
        for k in "${keep[@]}"; do
            [ "$k" = "$base" ] && keepit=true && break
        done
        case "$base" in
            avahi-discover|bssh|bvnc|foot|footclient|foot-server|mpv|nvidia-settings|qv4l2|qvidcap|ranger|xgps|xgpsspeed)
                # System apps — keep with NoDisplay=true (already set)
                ;;
            *)
                if ! $keepit; then
                    rm -f "$f"
                    echo -e "  ${YELLOW}→${NC} Removed $base.desktop"
                fi
                ;;
        esac
    done
}

# --------------------------------------------------
restore_core() {
    echo -e "\n${GREEN}[*]${NC} Restoring configs..."
    cp -r config/* ~/.config/ 2>/dev/null
    cp -r local/* ~/.local/ 2>/dev/null
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    echo -e "${GREEN}[✓]${NC} Configs restored"

    # Apply custom accent if set
    if [ -n "$ACCENT" ]; then
        apply_accent "$ACCENT"
    fi

    # Let user pick web apps
    pick_webapps
}

# --------------------------------------------------
setup_mouse() {
    echo -e "\n${CYAN}[?]${NC} Looking for a wireless mouse via hidraw..."
    devices=$(find /dev/input/by-id/ -name "*hidraw*" 2>/dev/null)
    if [ -z "$devices" ]; then
        echo -e "${YELLOW}[!]${NC} No hidraw devices found — no mouse dongle detected. Skipping."
        return
    fi
    echo "  Found:"
    echo "$devices" | sed 's/^/    /'
    echo ""
    echo -e "${CYAN}[?]${NC} Do you want to:"
    echo "  1) Auto-detect & create udev rule for mouse battery"
    echo -e "  2) Use rifat's mouse rules (CX dongle + USB cable)"
    echo "  3) Skip mouse battery setup"
    read -rp "  Choose [1-3]: " m
    case "$m" in
        1)
            for d in $devices; do
                real=$(readlink -f "$d")
                id=$(udevadm info -a -n "$real" 2>/dev/null | grep -E 'ATTRS{idVendor}|ATTRS{idProduct}' | head -2 | tr -d '\n')
                vendor=$(echo "$id" | grep -oP 'idVendor=="\K[^"]+')
                product=$(echo "$id" | grep -oP 'idProduct=="\K[^"]+')
                if [ -n "$vendor" ] && [ -n "$product" ]; then
                    rule="SUBSYSTEM==\"hidraw\", ATTRS{idVendor}==\"$vendor\", ATTRS{idProduct}==\"$product\", MODE=\"0666\""
                    echo "$rule" | sudo tee /etc/udev/rules.d/99-mouse-battery.rules >/dev/null
                    echo -e "${GREEN}[✓]${NC} Created udev rule for $vendor:$product"
                    break
                fi
            done
            ;;
        2)
            rule='SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373b", ATTRS{idProduct}=="1085", MODE="0666"\nSUBSYSTEM=="hidraw", ATTRS{idVendor}=="3554", ATTRS{idProduct}=="f58f", MODE="0666"'
            echo -e "$rule" | sudo tee /etc/udev/rules.d/99-mouse-battery.rules >/dev/null
            echo -e "${GREEN}[✓]${NC} Applied rifat's mouse rules (dongle 373b:1085 + USB 3554:f58f)"
            ;;
        3)
            echo "  Skipping mouse battery."
            return
            ;;
    esac

    sudo udevadm control --reload-rules && sudo udevadm trigger

    if command -v gcc &>/dev/null; then
        gcc -O2 -o ~/.config/waybar/scripts/mouse-battery ~/.config/waybar/scripts/mouse-battery.c 2>/dev/null
        chmod +x ~/.config/waybar/scripts/mouse-battery
        echo -e "${GREEN}[✓]${NC} Compiled mouse-battery binary (dongle)"
        gcc -O2 -o ~/.config/waybar/scripts/mouse-usb-battery ~/.config/waybar/scripts/mouse-usb-battery.c 2>/dev/null
        chmod +x ~/.config/waybar/scripts/mouse-usb-battery
        echo -e "${GREEN}[✓]${NC} Compiled mouse-usb-battery binary (USB cable)"
    else
        echo -e "${YELLOW}[!]${NC} gcc not found — install base-devel and re-run to compile mouse battery readers"
    fi
    chmod +x ~/.config/waybar/scripts/mouse-usb.sh 2>/dev/null
    chmod +x ~/.config/waybar/scripts/clock.sh 2>/dev/null
    chmod +x ~/.config/waybar/scripts/memory.sh 2>/dev/null
}

# --------------------------------------------------
setup_peripherals() {
    echo -e "\n${CYAN}[?]${NC} Enable headset/earphones battery monitoring?"
    echo "  Reads battery from upower (default awk pattern matches 'headset')."
    echo "  1) Yes"
    echo -e "  2) Skip"
    read -rp "  Choose [1-2]: " e
    case "$e" in
        1)
            chmod +x ~/.config/waybar/scripts/peripherals.sh
            echo -e "${GREEN}[✓]${NC} peripherals.sh is executable"
            echo -e "${YELLOW}[i]${NC} If your device name differs, edit the awk pattern in peripherals.sh"
            ;;
        2)
            echo "  Skipping peripherals."
            ;;
    esac
}

# --------------------------------------------------
setup_owner() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}[owner] rifat's full restore${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    ACCENT="cba6f7"
    restore_core
    setup_mouse
    setup_peripherals
    echo -e "\n${GREEN}[✓]${NC} Owner restore complete."
    echo -e "  ${YELLOW}→${NC} Reload theme in Helium (helium://extensions)"
    echo -e "  ${YELLOW}→${NC} Import stylus/stylus-chrome-extension.css into Stylus"
    echo -e "  ${YELLOW}→${NC} Reboot or relogin to pick up GTK/font changes"
}

# --------------------------------------------------
menu() {
    echo ""
    echo -e "  ${CYAN}1${NC}  — Restore core configs only"
    echo -e "  ${CYAN}2${NC}  — Setup mouse battery (dongle + USB)"
    echo -e "  ${CYAN}3${NC}  — Setup headset battery"
    echo -e "  ${CYAN}4${NC}  — Do all of the above"
    echo -e "  ${CYAN}q${NC}  — Quit"
    echo ""
    read -rp "  Choose [1-4/q]: " choice
    case "$choice" in
        1) restore_core ;;
        2) setup_mouse ;;
        3) setup_peripherals ;;
        4) restore_core; setup_mouse; setup_peripherals ;;
        q|Q) echo "  Bye."; exit 0 ;;
        *) echo "  Invalid."; menu ;;
    esac
}

# --------------------------------------------------
# Mode selection
echo -e "  Choose setup mode:"
echo -e "  ${CYAN}1${NC}  — Custom (interactive — accent, web apps, etc.)"
echo -e "  ${CYAN}2${NC}  — ${GREEN}[Owner]${NC} rifat's full restore (purple accent, all apps, fast)"
echo ""
read -rp "  Choose [1-2]: " mode
echo ""

if [ "$mode" = "2" ]; then
    setup_owner
else
    # Custom mode: accent color
    echo -e "${CYAN}[?]${NC} Use rifat's purple accent (#cba6f7) or your own?"
    echo "  1) Keep purple (#cba6f7)"
    echo -e "  2) Enter your own hex color"
    read -rp "  Choose [1-2]: " a
    if [ "$a" = "2" ]; then
        read -rp "  Enter hex color (e.g. aaaaaa or #ff6600): " usercolor
        usercolor="${usercolor#"#"}"

        # Validate: must be 6 hex chars
        if [[ "$usercolor" =~ ^[0-9a-fA-F]{6}$ ]]; then
            ACCENT="${usercolor,,}"
            echo -e "${GREEN}[✓]${NC} Using accent #$ACCENT"
        else
            echo -e "${YELLOW}[!]${NC} Invalid hex. Falling back to purple."
            ACCENT="cba6f7"
        fi
    else
        ACCENT="cba6f7"
    fi

    menu
fi

echo -e "\n${GREEN}  Done.${NC}"
