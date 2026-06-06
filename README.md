# dot-files — v2.0

this are my arch-hyprland dot-files.

note: a setup script is also included in the repo for easier installation.

## Contents

### Window Manager
| Config | Location |
|--------|----------|
| Hyprland | `.config/hypr/hyprland.lua` |
| Waybar | `.config/waybar/` |
| Fuzzel (app launcher) | `.config/fuzzel/fuzzel.ini` |
| Foot (terminal) | `.config/foot/foot.ini` |

### Waybar Modules
| Module | What it does |
|--------|-------------|
| `custom/mouse-battery` | Battery % from CX Wireless dongle (HID) |
| `custom/mouse-usb` | USB cable charging detection (green `` + %) |
| `custom/headset-battery` | Earphones/headset battery via upower |
| `custom/bluetooth` | Bluetooth status (on/off/connected) — click opens `bluetoothctl` |
| `custom/memory` | RAM usage — orange > 30%, pastel red > 8 GiB |
| `cpu` | Usage % — light red > 60% |
| `custom/clock` | Clock — turns red 23:00–09:00 (screen-free reminder) |

Color states:
- **CPU** > 60% → light red (`#e57373`)
- **Memory** > 30% → orange (`#ef934d`), > 8 GiB → pastel red (`#f0a0a0`)
- **Mouse battery** < 30% → pastel red (`#f0a0a0`)
- **Mouse USB** connected → pastel green (`#81c784`)
- **Headset** < 30% → pastel red (`#f0a0a0`)
- **Bluetooth** on/idle → white, connected → accent, off → gray

### Mouse Battery (generic HID mouse)
| File | Purpose |
|------|---------|
| `waybar/scripts/mouse-battery.c` | Reads battery from wireless dongle via hidraw |
| `waybar/scripts/mouse-usb-battery.c` | Reads battery from USB cable via hidraw |
| `waybar/scripts/mouse-usb.sh` | Waybar module — shows ` XX%` in green when USB connected |
| `waybar/scripts/peripherals.sh` | Waybar module script (mouse + headset battery) |
| `etc/udev/rules.d/99-mouse-battery.rules` | Grants hidraw access (owner: CX dongle 373b:1085 + USB 3554:f58f) |

The C programs send a HID report and parse battery level. The udev rule sets `MODE="0666"` so non-root users can read it. In [Owner] mode the udev rule uses the maintainer's device IDs; in Custom mode you can auto-detect yours.

### Ranger (file manager)
`ranger/colorschemes/mauve.py` — custom colorscheme matching the accent purple (`#cba6f7`).

`ranger/rifle.conf` — opens images with `imv`, videos/audio with `mpv`, text/code with `nvim`.

`ranger/rc.conf` — hidden files visible, mauve colorscheme enabled.

### Helium-Adapt Theme
`local/share/helium-theme/manifest.json` — dark theme for Helium browser (`#0f0f0f` background, `#cba6f7` accent).

To install: open `helium://extensions`, enable Developer mode, click **Load unpacked**, and point to `.local/share/helium-theme/`.

### Stylus CSS
`stylus/stylus-chrome-extension.css` — forces `JetBrainsMono Nerd Font` and disables rounded corners on all websites. Import into the **Stylus** browser extension, set to apply on **All URLs**.

### Desktop Entries
Hidden system apps (`NoDisplay=true`): Avahi, Foot, xgps, ranger, nvidia-settings, mpv, qv4l2, qvidcap.

Custom launchers (open in new Helium window via `--new-window`):
- **ATK Hub** — `hub.atk.pro`
- **GitHub** — `github.com`
- **Proton Mail** — `mail.proton.me`
- **PW** — `pw.live/study-v2`
- **opencode** — runs the opencode CLI in foot

### GTK
| File | Purpose |
|------|---------|
| `gtk-3.0/settings.ini` | Dark theme, JetBrainsMono Nerd Font |
| `gtk-3.0/gtk.css` | Font fallback for Chromium browsers |
| `gtk-4.0/settings.ini` | Dark theme (GTK4) |

---

## Setup

Run `./setup.sh` and choose a mode:

### Mode 1 — Custom (for anyone)
1. Pick an accent color (or keep the default purple `#cba6f7`)
2. Select which web app desktop entries to install
3. Interactive menu for core configs, mouse, headset

### Mode 2 — [Owner] (rifat's fast full restore)
Skips all prompts — applies purple accent, installs all apps, configures mouse + headset in one go.

### Menu Options (Custom mode)

| Option | What it does |
|--------|-------------|
| **1** — Core configs | Copies configs, applies accent, installs selected web apps |
| **2** — Mouse battery | Creates udev rule (sudo), compiles both C binaries |
| **3** — Headset | Makes peripherals.sh executable |
| **4** — All of the above | Runs 1 + 2 + 3 |
| **q** | Quit |

### Can it break anything?

- **Configs:** Your existing configs get **overwritten**. Back them up first.
- **Udev rule:** Creates a new file in `/etc/udev/rules.d/` — won't remove existing ones.
- **That's it.** No services restarted, no packages installed, nothing deleted.

### After running

1. Reload Helium-Adapt theme in Helium (helium://extensions)
2. Import stylus/stylus-chrome-extension.css into Stylus
3. Reboot or relogin to pick up GTK/font changes

### Required Packages

**NVIDIA SETUP**

``sudo pacman -S nvidia-open-dkms linux-zen-headers nvidia-utils lib32-nvidia-utils libva-nvidia-driver`` 

*add "nvidia nvidia_modeset nvidia_uvm nvidia_drm" in MODESET() in /etc/mkinitcpio.conf and then do mkinitcpio -P"

**PIPEWIRE SETUP**

``sudo pacman -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber``

``systemctl --user enable --now pipewire wireplumber``

**BLUETOOTH SETUP**

``sudo pacman -S bluez bluez-utils``

``sudo systemctl enable --now bluetooth``

**FONTS**

``sudo pacman -S ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd``

**DE AND ESSENTIALS**

``sudo pacman -S hyprland fuzzel foot waybar awww hyprpolkitagent ranger cliphist mako xdg-desktop-portal-hyprland``

``systemctl --user enable --now hyprpolkitagent``

``systemctl --user enable --now mako ``


**BROWSER**

``yay -S helium-browser bin``

**LOGIN MANAGER**

``sudo pacman -S greetd greetd-tuigreet``

``sudo systemctl enable --now greetd``

**ACCESSORIES**

``yay -S bibata-cursor-theme papirus-icon-theme``

### FIXES

bluetooth module will not show if u dont chmod +x the ~/.config/waybar/scripts/bluetooth.sh file




