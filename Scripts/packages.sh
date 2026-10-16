#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/packages_$(date +%Y%m%d_%H%M%S).log"

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "Starting package installation. Logging to ${LOG_FILE}..."

dnf install -y --skip-unavailable \
    @virtualization \
    7zip android-tools bleachbit btrfs-assistant calibre conda corectrl DisplayCAL distrobox fastfetch fish gnome-disk-utility gtk3-devel libva-utils pidgin pidgin-otr snapd strace tldr tmux uv zsh \
    google-chrome-stable microsoft-edge-stable \
    clementine \
    clang cmake gh git-lfs godot nix nix-daemon nodejs ollama \
    prusa-slicer \
    kate kdegraphics-thumbnailers kdeplasma-addons 'kio*' kmousetool krename krdc krusader ktimer kcron kclock dolphin-plugins ksystemlog kompare \
    '*-sound-theme' plasma-mobile-sounds '*-kde-kvantum' '*-gtk-theme' '*-kde-theme' arc-kde qtcurve materia-kde '*-icon-theme' plasma-browser-integration '*-plasma-applet' aurorae 'sddm-*' \
    buildah flatpak-builder skopeo \
    ansible 'ansible-collection*' gnome-boxes virt-manager nbdkit 'incus-*' 'libguestfs*' 'podman*' podman-compose podman-docker podman-machine podman-remote podman-tui swtpm qemu-img \
    'cockpit-*' \
    fail2ban fail2ban-firewalld fail2ban-systemd \
    wireguard-tools nmap-ncat \
    zoom \
    google-noto-fonts-all google-noto-color-emoji-fonts rsms-inter-fonts \
    boundary packer terraform terraform-ls terraform-stacks-cli vagrant vagrant-libvirt vagrant-cachier vagrant-sshfs vagrant-hostmanager vagrant-registration waypoint \
    ffmpegthumbnailer

# Install / update Pinokio to the latest release
echo "Checking latest Pinokio release..."
PINOKIO_API_URL=$(curl -sL https://api.github.com/repos/pinokiocomputer/pinokio/releases/latest | grep -o 'https://github.com/pinokiocomputer/pinokio/releases/download/[^"]*/Pinokio-[^"]*\.x86_64\.rpm' | head -n 1)

if [ -n "$PINOKIO_API_URL" ]; then
    PINOKIO_DOWNLOAD_URL="$PINOKIO_API_URL"
else
    PINOKIO_TAG=$(curl -sIL https://github.com/pinokiocomputer/pinokio/releases/latest | grep -i "^location:" | sed -E "s|.*/tag/([^/]+)|\1|" | tr -d "\r\n")
    PINOKIO_VERSION="${PINOKIO_TAG#v}"
    PINOKIO_DOWNLOAD_URL="https://github.com/pinokiocomputer/pinokio/releases/download/${PINOKIO_TAG}/Pinokio-${PINOKIO_VERSION}.x86_64.rpm"
fi

if [ -n "$PINOKIO_DOWNLOAD_URL" ]; then
    PINOKIO_LATEST_VER=$(echo "$PINOKIO_DOWNLOAD_URL" | sed -E 's|.*/Pinokio-([0-9A-Za-z.-]+)\.x86_64\.rpm|\1|')
    PINOKIO_INSTALLED_VER=$(rpm -q --queryformat '%{VERSION}' Pinokio 2>/dev/null || true)
    if [ "$PINOKIO_INSTALLED_VER" != "$PINOKIO_LATEST_VER" ]; then
        echo "Installing Pinokio $PINOKIO_LATEST_VER (currently installed: ${PINOKIO_INSTALLED_VER:-none})..."
        dnf install -y --nogpgcheck "$PINOKIO_DOWNLOAD_URL"
    else
        echo "Pinokio is already at the latest version ($PINOKIO_INSTALLED_VER)."
    fi
fi

exit 0
