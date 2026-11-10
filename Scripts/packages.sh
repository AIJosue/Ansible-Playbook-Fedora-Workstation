#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
mkdir -p "${LOG_DIR}" 2>/dev/null || true
LOG_FILE="${LOG_DIR}/packages_$(date +%Y%m%d_%H%M%S).log"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    fi
fi

# Prepare logging to both log file and system package log if writable
if [ "$(id -u)" -eq 0 ] || [ -w /var/log/packages.log ] 2>/dev/null; then
    exec > >(tee -a "${LOG_FILE}" /var/log/packages.log) 2>&1
else
    exec > >(tee -a "${LOG_FILE}") 2>&1
fi

echo "Starting package installation. Logging to ${LOG_FILE}..."

# Core tools, virtualization, development libraries, shells, and utilities
$SUDO dnf install -y --skip-unavailable --skip-broken \
    @virtualization @development-tools \
    7zip android-tools binwalk bleachbit btrfs-assistant calibre conda corectrl DisplayCAL distrobox encapsule fastfetch fish fzf gnome-disk-utility gtk3-devel gum just libva-utils p7zip p7zip-plugins pidgin pidgin-otr ptyxis rclone restic snapd sqlite strace switcheroo-control tldr tmux unzip uv waydroid xterm zsh \
    google-chrome-stable microsoft-edge-stable \
    clementine \
    clang cmake gh git-lfs godot nix nix-daemon nodejs \
    prusa-slicer \
    kate kdegraphics-thumbnailers kdeplasma-addons 'kio*' kmousetool krename krdc krusader ktimer kcron kclock dolphin-plugins ksystemlog kompare \
    '*-sound-theme' plasma-mobile-sounds '*-kde-kvantum' '*-gtk-theme' '*-kde-theme' arc-kde qtcurve materia-kde '*-icon-theme' plasma-browser-integration 'fedora-*-*-kde' '*-plasma-applet' aurorae 'sddm-*' \
    buildah flatpak-builder skopeo \
    ansible 'ansible-collection*' gnome-boxes virt-manager virt-bootstrap nbdkit 'libguestfs*' 'podman*' podman-compose podman-docker podman-machine podman-remote podman-tui swtpm qemu-img \
    'cockpit-*' \
    fail2ban fail2ban-firewalld fail2ban-systemd \
    wireguard-tools nmap-ncat \
    zoom \
    google-noto-fonts-all google-noto-color-emoji-fonts rsms-inter-fonts \
    boundary packer terraform terraform-ls terraform-stacks-cli 'vagrant*' waypoint \
    ffmpegthumbnailer || true

if [ -n "$SUDO" ]; then
    $SUDO touch /var/log/packages.log 2>/dev/null || true
else
    touch /var/log/packages.log 2>/dev/null || true
fi

echo "Package installation completed."
exit 0
