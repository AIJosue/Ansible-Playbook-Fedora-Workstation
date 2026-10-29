#!/bin/bash
# ==============================================================================
# Setup User Environment
# Interactive Post-Install Utility for Fedora Workstation Users
# ==============================================================================
# This interactive utility allows individual users to configure developer and
# terminal tools on-demand without enforcing system-wide modifications.
#
# Supported Tools:
# 1. Homebrew Environment & PATH Configuration
# 2. Pixi Package Manager (https://pixi.sh)
# 3. TLDR Cache & Terminal Utilities Refresh (tldr, bat, fonts, man-db, git-lfs)
# 4. Distrobox — Ubuntu toolbox container (quay.io/toolbx/ubuntu-toolbox:latest)
# 5. Flathub Remote for Current User (flatpak remote-add --user)
# 6. Fedora Flatpak Remote for Current User (flatpak remote-add --user)
# 7. PipeWire Audio Redirection (multi-user network/local streaming)
# 8. Fedora Waydroid Setup Wizard (Android container initialization)
# 9. System Cleanup & Benchmark (podman prune, snap snapshots, folder benchmark)
# 10. Libvirt VM Helpers (VM autostart, libvirt zone port forwarding)
# 11. Vagrant VMs (Ubuntu, YunoHost: start, stop, status, ssh, destroy)
# 12. DeepSeek Harness (Pixi environment in ~/AppImages & @deepseek-ai/dsh)
# 13. Prism llama.cpp Binaries (Linux & Android releases in ~/AppImages/prism-llama.cpp)
# 14. KoboldCpp Standalone Binary (Linux releases directly in ~/AppImages)
# 15. LocalAI Binary / AppImage (Linux releases directly in ~/AppImages)
# 16. OpenClaw CLI, Gateway Service & AppImage (openclaw.ai)
# 17. DevPod CLI & Desktop AppImage (loft-sh/devpod)
# 18. AppImages Compact & Portable Setup (--appimage-portable-config/home)
# ==============================================================================

# Formatting Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Ensure this script is run as a regular user, not root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}Warning: Do NOT run this setup script as root!${NC}"
    echo -e "Please execute this script as your regular user (e.g. 'user' or 'admin')."
    exit 1
fi

configure_homebrew() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}[1/8] Configuring Homebrew for user: $(whoami)${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
    if [ ! -x "$BREW_PATH" ] && command -v brew >/dev/null 2>&1; then
        BREW_PATH="$(command -v brew)"
    fi

    if [ -x "$BREW_PATH" ]; then
        echo -e "${GREEN}Found Homebrew at: ${BREW_PATH}${NC}"
        local SHELLENV_LINE='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

        # Ensure .bashrc has shellenv
        if ! grep -q "linuxbrew.*shellenv" "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo "# Homebrew environment" >> "$HOME/.bashrc"
            echo "$SHELLENV_LINE" >> "$HOME/.bashrc"
            echo -e "${GREEN}✓ Added Homebrew shellenv hook to ~/.bashrc${NC}"
        else
            echo -e "${YELLOW}• Homebrew shellenv already configured in ~/.bashrc${NC}"
        fi

        # Ensure .zshrc has shellenv if zsh is present
        if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
            touch "$HOME/.zshrc"
            if ! grep -q "linuxbrew.*shellenv" "$HOME/.zshrc" 2>/dev/null; then
                echo "" >> "$HOME/.zshrc"
                echo "# Homebrew environment" >> "$HOME/.zshrc"
                echo "$SHELLENV_LINE" >> "$HOME/.zshrc"
                echo -e "${GREEN}✓ Added Homebrew shellenv hook to ~/.zshrc${NC}"
            fi
        fi

        # Apply to current subshell
        eval "$($BREW_PATH shellenv)"
        echo -e "${GREEN}✓ Homebrew active:${NC} $(brew --version | head -n 1)"
    else
        echo -e "${YELLOW}Homebrew is not detected at /home/linuxbrew/.linuxbrew/bin/brew.${NC}"
        read -rp "Would you like to install Homebrew now? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Running Homebrew installer...${NC}"
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
                echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
                echo -e "${GREEN}✓ Homebrew installed and configured!${NC}"
            fi
        else
            echo -e "${YELLOW}Skipping Homebrew configuration.${NC}"
        fi
    fi
}

install_pixi() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}[2/8] Installing Pixi Package Manager${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local PIXI_BIN="$HOME/.pixi/bin/pixi"
    if [ -x "$PIXI_BIN" ] || command -v pixi >/dev/null 2>&1; then
        echo -e "${GREEN}Pixi is already installed:${NC} $(pixi --version 2>/dev/null || "$PIXI_BIN" --version)"
        read -rp "Do you want to reinstall/update Pixi? [y/N]: " reinstall_choice
        if [[ ! "$reinstall_choice" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    echo -e "${BLUE}Downloading and running Pixi official installer (https://pixi.sh)...${NC}"
    curl -fsSL https://pixi.sh/install.sh | bash

    # Configure PATH in shell files
    local PIXI_DIR="$HOME/.pixi/bin"
    if [ -d "$PIXI_DIR" ]; then
        export PATH="$PIXI_DIR:$PATH"

        if ! grep -q '\.pixi/bin' "$HOME/.bashrc" 2>/dev/null; then
            echo "" >> "$HOME/.bashrc"
            echo '# Pixi package manager' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.pixi/bin:$PATH"' >> "$HOME/.bashrc"
            echo -e "${GREEN}✓ Added ~/.pixi/bin to ~/.bashrc${NC}"
        fi

        if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
            touch "$HOME/.zshrc"
            if ! grep -q '\.pixi/bin' "$HOME/.zshrc" 2>/dev/null; then
                echo "" >> "$HOME/.zshrc"
                echo '# Pixi package manager' >> "$HOME/.zshrc"
                echo 'export PATH="$HOME/.pixi/bin:$PATH"' >> "$HOME/.zshrc"
                echo -e "${GREEN}✓ Added ~/.pixi/bin to ~/.zshrc${NC}"
            fi
        fi

        echo -e "${GREEN}✓ Pixi successfully installed:${NC} $("$PIXI_DIR/pixi" --version)"
    else
        echo -e "${RED}Error: Pixi directory $PIXI_DIR was not found after install.${NC}"
    fi
}

update_terminal_utilities() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}[3/8] Updating TLDR & Terminal Utilities Cache${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    # 1. Update TLDR pages cache
    if command -v tldr >/dev/null 2>&1; then
        echo -e "${BLUE}Updating TLDR pages cache (tldr --update)...${NC}"
        tldr --update 2>/dev/null || tldr -u 2>/dev/null || echo -e "${YELLOW}TLDR update completed with notices.${NC}"
        echo -e "${GREEN}✓ TLDR documentation cache updated.${NC}"
    else
        echo -e "${YELLOW}• 'tldr' command not found, skipping.${NC}"
    fi

    # 2. Update Bat syntax & theme cache
    if command -v bat >/dev/null 2>&1; then
        echo -e "${BLUE}Updating Bat syntax & theme cache...${NC}"
        bat cache --build 2>/dev/null || true
        echo -e "${GREEN}✓ Bat cache built.${NC}"
    fi

    # 3. Configure Git LFS for user
    if command -v git-lfs >/dev/null 2>&1; then
        echo -e "${BLUE}Configuring Git LFS hooks for user profile...${NC}"
        git lfs install --skip-repo 2>/dev/null || true
        echo -e "${GREEN}✓ Git LFS configured.${NC}"
    fi

    # 4. Refresh font caches
    if command -v fc-cache >/dev/null 2>&1; then
        echo -e "${BLUE}Refreshing font caches (fc-cache)...${NC}"
        fc-cache -f 2>/dev/null || true
        echo -e "${GREEN}✓ Font cache refreshed.${NC}"
    fi

    # 5. Refresh Man database if available
    if command -v mandb >/dev/null 2>&1; then
        echo -e "${BLUE}Updating man database cache...${NC}"
        mandb -q 2>/dev/null || true
        echo -e "${GREEN}✓ Man database refreshed.${NC}"
    fi

    echo -e "${GREEN}✓ All terminal utilities updated successfully!${NC}"
}


setup_distrobox() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}[4/8] Setting Up Ubuntu Distrobox Container${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local CONTAINER_NAME="ubuntu-toolbox"
    local CONTAINER_IMAGE="quay.io/toolbx/ubuntu-toolbox:latest"

    # Verify distrobox is available
    if ! command -v distrobox >/dev/null 2>&1; then
        echo -e "${RED}Error: 'distrobox' is not installed or not in PATH.${NC}"
        echo -e "${YELLOW}Install it with: sudo dnf install distrobox${NC}"
        return 1
    fi

    # Check if a container with this name already exists
    if distrobox list 2>/dev/null | grep -q "^${CONTAINER_NAME}\b\|[[:space:]]${CONTAINER_NAME}[[:space:]]"; then
        echo -e "${YELLOW}• Distrobox container '${CONTAINER_NAME}' already exists.${NC}"
        read -rp "Do you want to replace it? This will stop and remove the existing container. [y/N]: " replace_choice
        if [[ "$replace_choice" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Stopping and removing existing container '${CONTAINER_NAME}'...${NC}"
            distrobox stop --yes "${CONTAINER_NAME}" 2>/dev/null || true
            distrobox rm --yes "${CONTAINER_NAME}" 2>/dev/null || true
        else
            echo -e "${YELLOW}Skipping distrobox setup.${NC}"
            return 0
        fi
    fi

    echo -e "${BLUE}Creating distrobox container '${CONTAINER_NAME}' from ${CONTAINER_IMAGE}...${NC}"
    echo -e "${YELLOW}Note: The image will be pulled on first run — this may take a moment.${NC}"

    if distrobox create \
        --name "${CONTAINER_NAME}" \
        --image "${CONTAINER_IMAGE}" \
        --yes; then
        echo -e "${GREEN}✓ Distrobox container '${CONTAINER_NAME}' created successfully.${NC}"
        echo -e "${BLUE}Initializing container (first-run setup)...${NC}"
        distrobox enter "${CONTAINER_NAME}" -- true 2>/dev/null \
            && echo -e "${GREEN}✓ Container initialized and ready.${NC}" \
            || echo -e "${YELLOW}• Container created — it will finish initializing on first 'distrobox enter ${CONTAINER_NAME}'.${NC}"
    else
        echo -e "${RED}Error: Failed to create distrobox container '${CONTAINER_NAME}'.${NC}"
        return 1
    fi
}

configure_flathub_user() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}[5/8] Adding Flathub Remote (User)${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    if ! command -v flatpak >/dev/null 2>&1; then
        echo -e "${RED}Error: 'flatpak' is not installed or not in PATH.${NC}"
        return 1
    fi

    echo -e "${BLUE}Adding Flathub repository for user: $(whoami)...${NC}"
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        echo -e "${GREEN}✓ Flathub remote added successfully for user.${NC}"
    else
        echo -e "${RED}Error: Failed to add Flathub user remote.${NC}"
        return 1
    fi
}

configure_fedora_flatpak_user() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}[6/8] Adding Fedora Flatpak Remote (User)${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    if ! command -v flatpak >/dev/null 2>&1; then
        echo -e "${RED}Error: 'flatpak' is not installed or not in PATH.${NC}"
        return 1
    fi

    echo -e "${BLUE}Adding Fedora Flatpak repository for user: $(whoami)...${NC}"
    if flatpak remote-add --user --if-not-exists fedora oci+https://registry.fedoraproject.org; then
        echo -e "${GREEN}✓ Fedora Flatpak remote added successfully for user.${NC}"
    else
        echo -e "${RED}Error: Failed to add Fedora Flatpak user remote.${NC}"
        return 1
    fi
}

disable_pipewire_streaming() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Disable PipeWire Audio Redirection           ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local SUDO_CMD=""
    if [ "$EUID" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            if ! sudo -v; then
                echo -e "${RED}Error: sudo authentication failed.${NC}"
                return 1
            fi
            SUDO_CMD="sudo"
        else
            echo -e "${RED}Error: sudo is required to disable audio redirection.${NC}"
            return 1
        fi
    fi

    # 1. Ask for Sender (to remove redirection configs)
    echo -e "${BOLD}[Step 1: The Sound Source / Sender (Transmitter)]${NC}"
    read -rp "Enter username of the SENDER (whose redirection you want to remove) [default: $(whoami)]: " USER_SENDER
    USER_SENDER=${USER_SENDER:-$(whoami)}
    if ! id "$USER_SENDER" &>/dev/null; then
        echo -e "${RED}Error: User '$USER_SENDER' does not exist.${NC}"
        return 1
    fi
    local SENDER_HOME
    SENDER_HOME=$(getent passwd "$USER_SENDER" | cut -d: -f6)

    echo -e "${BLUE}[*] Removing audio redirection from SENDER ($USER_SENDER)...${NC}"

    # Remove from ~/.bashrc
    local BASHRC_FILE="$SENDER_HOME/.bashrc"
    if [[ -f "$BASHRC_FILE" ]]; then
        $SUDO_CMD sed -i '/# Route audio output to/d' "$BASHRC_FILE"
        $SUDO_CMD sed -i '/export PULSE_SERVER=tcp:/d' "$BASHRC_FILE"
        echo -e "${GREEN}✓ Cleaned $USER_SENDER's ~/.bashrc${NC}"
    fi

    # Remove from ~/.profile
    local PROFILE_FILE="$SENDER_HOME/.profile"
    if [[ -f "$PROFILE_FILE" ]]; then
        $SUDO_CMD sed -i '/# Route audio output to/d' "$PROFILE_FILE"
        $SUDO_CMD sed -i '/export PULSE_SERVER=tcp:/d' "$PROFILE_FILE"
        echo -e "${GREEN}✓ Cleaned $USER_SENDER's ~/.profile${NC}"
    fi

    # Remove environment.d config
    local ENV_CONF="$SENDER_HOME/.config/environment.d/pipewire-share.conf"
    if [[ -f "$ENV_CONF" ]]; then
        $SUDO_CMD rm -f "$ENV_CONF"
        echo -e "${GREEN}✓ Removed $ENV_CONF${NC}"
    fi

    # 2. Ask for Receiver (to remove TCP listener config)
    echo ""
    echo -e "${BOLD}[Step 2: The Sound Output / Receiver (Speaker Owner)]${NC}"
    read -rp "Enter username of the RECEIVER (optional, press Enter to skip): " USER_RECEIVER
    if [[ -n "$USER_RECEIVER" ]]; then
        if ! id "$USER_RECEIVER" &>/dev/null; then
            echo -e "${YELLOW}Warning: User '$USER_RECEIVER' not found. Skipping receiver cleanup.${NC}"
        else
            local RECEIVER_HOME
            RECEIVER_HOME=$(getent passwd "$USER_RECEIVER" | cut -d: -f6)
            local TCP_CONF="$RECEIVER_HOME/.config/pipewire/pipewire-pulse.conf.d/tcp-share.conf"
            if [[ -f "$TCP_CONF" ]]; then
                $SUDO_CMD rm -f "$TCP_CONF"
                echo -e "${GREEN}✓ Removed $TCP_CONF${NC}"
            fi

            if $SUDO_CMD systemctl --user -M "${USER_RECEIVER}@" is-active --quiet pipewire-pulse.service 2>/dev/null; then
                $SUDO_CMD systemctl --user -M "${USER_RECEIVER}@" restart pipewire-pulse.service
                echo -e "${GREEN}✓ Restarted pipewire-pulse for $USER_RECEIVER.${NC}"
            fi
        fi
    fi

    echo ""
    echo -e "${GREEN}===================================================================${NC}"
    echo -e "${BOLD} PipeWire Audio Redirection Disabled!${NC}"
    echo -e "${GREEN}===================================================================${NC}"
    echo "Note: If $USER_SENDER is currently logged in, please log out and"
    echo "      back in for desktop environment changes to fully reset."
    echo -e "${GREEN}===================================================================${NC}"
}

enable_pipewire_streaming() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Enable PipeWire Audio Redirection             ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    if [ ! -t 0 ] && [ -z "${USER_RECEIVER:-}" ]; then
        echo -e "${YELLOW}Non-interactive session detected; skipping PipeWire setup (requires user input).${NC}"
        return 0
    fi

    # Needs sudo/root to configure multi-user audio sharing
    local SUDO_CMD=""
    if [ "$EUID" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            echo -e "${YELLOW}Note: PipeWire multi-user audio setup requires administrative privileges.${NC}"
            if ! sudo -v; then
                echo -e "${RED}Error: sudo authentication failed.${NC}"
                return 1
            fi
            SUDO_CMD="sudo"
        else
            echo -e "${RED}Error: sudo is required to configure PipeWire audio redirection.${NC}"
            return 1
        fi
    fi

    cat <<'EOF'
===================================================================
                   PipeWire Audio Redirection
===================================================================
• THE SENDER:
  The user running apps (Firefox, games, mpv, Spotify) who wants
  their sound sent somewhere else.

• THE RECEIVER (SPEAKERS):
  The user who has physical access to the speakers/headphones and
  will actually play the sound out loud.
===================================================================
EOF
    echo ""

    # 1. Receiver (Speaker owner)
    echo -e "${BOLD}[Step 1: The Sound Output / Receiver]${NC}"
    read -rp "Enter username of the user with the WORKING SPEAKERS [default: $(whoami)]: " USER_RECEIVER
    USER_RECEIVER=${USER_RECEIVER:-$(whoami)}
    if ! id "$USER_RECEIVER" &>/dev/null; then
        echo -e "${RED}Error: User '$USER_RECEIVER' does not exist.${NC}"
        return 1
    fi
    local RECEIVER_HOME
    RECEIVER_HOME=$(getent passwd "$USER_RECEIVER" | cut -d: -f6)

    # 2. Sender (Music/App owner)
    echo ""
    echo -e "${BOLD}[Step 2: The Sound Source / Sender]${NC}"
    read -rp "Enter username of the user who wants to TRANSMIT/SEND audio: " USER_SENDER
    if ! id "$USER_SENDER" &>/dev/null; then
        echo -e "${RED}Error: User '$USER_SENDER' does not exist.${NC}"
        return 1
    fi
    local SENDER_HOME
    SENDER_HOME=$(getent passwd "$USER_SENDER" | cut -d: -f6)

    # 3. Connection details
    echo ""
    echo -e "${BOLD}[Step 3: Network Connection]${NC}"
    echo "  - Same PC: use 127.0.0.1"
    echo "  - Over LAN: enter the Receiver's IP address on the local network"
    read -rp "Enter IP address [default: 127.0.0.1]: " BIND_IP
    BIND_IP=${BIND_IP:-127.0.0.1}

    read -rp "Enter port to use [default: 4713]: " BIND_PORT
    BIND_PORT=${BIND_PORT:-4713}

    echo ""
    echo -e "${BLUE}[*] Configuring the RECEIVER ($USER_RECEIVER) to accept incoming audio...${NC}"

    # Configure Receiver PipeWire-Pulse TCP listener
    local CONF_DIR="$RECEIVER_HOME/.config/pipewire/pipewire-pulse.conf.d"
    local CONF_FILE="$CONF_DIR/tcp-share.conf"

    $SUDO_CMD mkdir -p "$CONF_DIR"
    cat <<EOF | $SUDO_CMD tee "$CONF_FILE" >/dev/null
pulse.properties = {
    server.address = [
        "unix:native"
        "tcp:${BIND_IP}:${BIND_PORT}"
    ]
}
EOF

    $SUDO_CMD chown -R "$USER_RECEIVER":"$USER_RECEIVER" "$RECEIVER_HOME/.config/pipewire"

    # Keep the Receiver's background audio service running across logins
    $SUDO_CMD loginctl enable-linger "$USER_RECEIVER" 2>/dev/null || true

    # Restart audio service for Receiver if logged in
    if $SUDO_CMD systemctl --user -M "${USER_RECEIVER}@" is-active --quiet pipewire-pulse.service 2>/dev/null; then
        $SUDO_CMD systemctl --user -M "${USER_RECEIVER}@" restart pipewire-pulse.service
        echo -e "${GREEN}✓ pipewire-pulse restarted for $USER_RECEIVER.${NC}"
    else
        echo -e "${YELLOW}• $USER_RECEIVER is not currently active; configuration will load on next login.${NC}"
    fi

    # Configure Sender environment
    echo ""
    echo -e "${BLUE}[*] Configuring the SENDER ($USER_SENDER) to route audio to $USER_RECEIVER...${NC}"

    local ENV_LINE="export PULSE_SERVER=tcp:${BIND_IP}:${BIND_PORT}"

    # Terminal apps (~/.bashrc)
    local BASHRC_FILE="$SENDER_HOME/.bashrc"
    if $SUDO_CMD grep -Fxq "$ENV_LINE" "$BASHRC_FILE" 2>/dev/null; then
        echo -e "${YELLOW}• Route already set in $USER_SENDER's .bashrc.${NC}"
    else
        echo "" | $SUDO_CMD tee -a "$BASHRC_FILE" >/dev/null
        echo "# Route audio output to $USER_RECEIVER" | $SUDO_CMD tee -a "$BASHRC_FILE" >/dev/null
        echo "$ENV_LINE" | $SUDO_CMD tee -a "$BASHRC_FILE" >/dev/null
        $SUDO_CMD chown "$USER_SENDER":"$USER_SENDER" "$BASHRC_FILE"
        echo -e "${GREEN}✓ Configured $USER_SENDER's ~/.bashrc (Terminal apps)${NC}"
    fi

    # Desktop sessions (~/.profile)
    local PROFILE_FILE="$SENDER_HOME/.profile"
    if $SUDO_CMD grep -Fxq "$ENV_LINE" "$PROFILE_FILE" 2>/dev/null; then
        echo -e "${YELLOW}• Route already set in $USER_SENDER's .profile.${NC}"
    else
        echo "" | $SUDO_CMD tee -a "$PROFILE_FILE" >/dev/null
        echo "# Route audio output to $USER_RECEIVER" | $SUDO_CMD tee -a "$PROFILE_FILE" >/dev/null
        echo "$ENV_LINE" | $SUDO_CMD tee -a "$PROFILE_FILE" >/dev/null
        $SUDO_CMD chown "$USER_SENDER":"$USER_SENDER" "$PROFILE_FILE"
        echo -e "${GREEN}✓ Configured $USER_SENDER's ~/.profile (Login sessions)${NC}"
    fi

    # GUI Desktop Launcher icons (~/.config/environment.d/)
    local ENV_DIR="$SENDER_HOME/.config/environment.d"
    local ENV_CONF="$ENV_DIR/pipewire-share.conf"

    $SUDO_CMD mkdir -p "$ENV_DIR"
    cat <<EOF | $SUDO_CMD tee "$ENV_CONF" >/dev/null
# Route audio output to $USER_RECEIVER
PULSE_SERVER=tcp:${BIND_IP}:${BIND_PORT}
EOF

    $SUDO_CMD chown -R "$USER_SENDER":"$USER_SENDER" "$SENDER_HOME/.config/environment.d"
    echo -e "${GREEN}✓ Configured $USER_SENDER's environment.d (Desktop GUI icons and launchers)${NC}"

    echo ""
    echo -e "${GREEN}===================================================================${NC}"
    echo -e "${BOLD} Setup Complete & Fully Persistent!${NC}"
    echo -e "${GREEN}===================================================================${NC}"
    echo "• RECEIVER ($USER_RECEIVER): Configured to play incoming audio on speakers."
    echo "• SENDER ($USER_SENDER): Configured to direct all sound to $USER_RECEIVER."
    echo ""
    echo "Note: If $USER_SENDER is currently logged in, please log out and"
    echo "      back in once for desktop launcher changes to apply."
    echo -e "${GREEN}===================================================================${NC}"
}

configure_pipewire_streaming() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       PipeWire Audio Redirection Menu               ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo "  1) Enable / Configure PipeWire Redirection"
    echo "  2) Disable / Remove PipeWire Redirection"
    echo "  0) Back to Main Menu"
    echo -e "${BLUE}-----------------------------------------------------${NC}"

    if [ ! -t 0 ]; then
        # Default to enable in non-interactive mode
        enable_pipewire_streaming
        return 0
    fi

    read -rp "Select an option [0-2]: " pw_choice
    case "$pw_choice" in
        1) enable_pipewire_streaming ;;
        2) disable_pipewire_streaming ;;
        0|[Qq]|back) return 0 ;;
        *) echo -e "${RED}Invalid option: '$pw_choice'.${NC}" ;;
    esac
}

run_waydroid_init_wizard() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Waydroid Initialization Wizard                ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    if [ ! -t 0 ]; then
        echo -e "${YELLOW}Non-interactive session detected; skipping Waydroid setup (requires user input).${NC}"
        return 0
    fi

    # Needs sudo/root privileges
    local SUDO_CMD=""
    if [ "$EUID" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            echo -e "${YELLOW}Note: Waydroid initialization requires administrative privileges.${NC}"
            if ! sudo -v; then
                echo -e "${RED}Error: sudo authentication failed.${NC}"
                return 1
            fi
            SUDO_CMD="sudo"
        else
            echo -e "${RED}Error: sudo is required to configure Waydroid.${NC}"
            return 1
        fi
    fi

    local SYSTEM_OTA="https://ota.waydro.id/system"
    local VENDOR_OTA="https://ota.waydro.id/vendor"

    # 1. Official Fedora Repository Check & Install
    echo -e "${BLUE}[*] Checking Waydroid package...${NC}"
    if ! rpm -q waydroid &>/dev/null; then
        echo -e "${YELLOW}[!] Waydroid is not installed.${NC}"
        read -rp "Install waydroid from Fedora's official repos now? [Y/n]: " INSTALL_CONFIRM
        INSTALL_CONFIRM="${INSTALL_CONFIRM:-Y}"

        if [[ "$INSTALL_CONFIRM" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}[*] Installing waydroid and sqlite via dnf...${NC}"
            $SUDO_CMD dnf install -y waydroid sqlite
        else
            echo -e "${RED}[-] Cannot proceed without installing waydroid.${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}[+] Waydroid is already installed from official repos.${NC}"
    fi

    echo ""

    # 2. Interactive Selection: Google Play vs Vanilla
    echo -e "${BOLD}Choose Android system image:${NC}"
    echo "  1) GAPPS   - Includes Google Play Store & Google Mobile Services"
    echo "  2) VANILLA - Clean open-source LineageOS (No Google services)"
    echo ""

    local SYSTEM_TYPE="GAPPS"
    while true; do
        read -rp "Select an option [1-2] (default: 1): " CHOICE
        CHOICE="${CHOICE:-1}"
        case "$CHOICE" in
            1)
                SYSTEM_TYPE="GAPPS"
                break
                ;;
            2)
                SYSTEM_TYPE="VANILLA"
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1 or 2.${NC}"
                ;;
        esac
    done

    echo ""
    echo -e "${GREEN}[*] Selected build: ${SYSTEM_TYPE}${NC}"

    # 3. Interactive Force/Wipe Option
    local FORCE_FLAG=""
    if [[ -d "/var/lib/waydroid/images" && "$($SUDO_CMD ls -A /var/lib/waydroid/images 2>/dev/null)" ]]; then
        echo ""
        echo -e "${YELLOW}[!] Existing Waydroid images detected in /var/lib/waydroid/images.${NC}"
        read -rp "Do you want to force wipe and re-download images? [y/N]: " FORCE_CHOICE
        FORCE_CHOICE="${FORCE_CHOICE:-N}"
        if [[ "$FORCE_CHOICE" =~ ^[Yy]$ ]]; then
            FORCE_FLAG="-f"
        fi
    fi

    # 4. Stop service if active
    if systemctl is-active --quiet waydroid-container 2>/dev/null; then
        echo -e "${BLUE}[*] Stopping running container daemon...${NC}"
        $SUDO_CMD systemctl stop waydroid-container
    fi

    # 5. Initialize Waydroid
    echo ""
    echo -e "${BLUE}[*] Initializing Waydroid (${SYSTEM_TYPE})...${NC}"
    echo -e "${BLUE}[*] Pulling from official OTA endpoints...${NC}"

    $SUDO_CMD waydroid init \
        -s "${SYSTEM_TYPE}" \
        -c "${SYSTEM_OTA}" \
        -v "${VENDOR_OTA}" \
        ${FORCE_FLAG}

    # 6. Service Management
    echo ""
    echo -e "${BLUE}[*] Enabling and starting waydroid-container.service...${NC}"
    $SUDO_CMD systemctl enable --now waydroid-container

    echo ""
    echo -e "${GREEN}==================================================${NC}"
    echo -e "${BOLD}          Waydroid Initialized Successfully!      ${NC}"
    echo -e "${GREEN}==================================================${NC}"

    # 7. Post-install guidance for GAPPS
    if [[ "${SYSTEM_TYPE}" == "GAPPS" ]]; then
        local REAL_USER="${SUDO_USER:-$USER}"
        cat <<EOF

[!] GOOGLE PLAY CERTIFICATION REQUIRED:
Because Waydroid runs in an LXC container, Google requires registering
the virtual Android ID to access the Play Store.

1. Launch Waydroid as your regular user ($REAL_USER):
     waydroid session start

2. In another terminal, fetch your device ID:
     sudo waydroid shell 'sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select value from main where name=\"android_id\";"'

3. Copy the numeric ID and register it here:
     https://www.google.com/android/uncertified

4. Wait 5-10 minutes, restart the session, and sign in.
EOF
    else
        cat <<EOF

You can launch Waydroid anytime from your app launcher or by running:
    waydroid session start
    waydroid show-full-ui
EOF
    fi
}

manage_libndk() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local NDK_SCRIPT="$SCRIPT_DIR/install-libndk.sh"

    if [[ ! -f "$NDK_SCRIPT" ]]; then
        echo -e "${RED}[ERROR] libndk script not found at: $NDK_SCRIPT${NC}"
        return 1
    fi

    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Waydroid libndk ARM Translation Setup         ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo "  1) Install libndk Translation"
    echo "  2) Uninstall libndk Translation"
    echo "  0) Return to Waydroid Menu"
    echo -e "${BLUE}-----------------------------------------------------${NC}"
    read -rp "Select an option [0-2]: " ndk_choice
    case "$ndk_choice" in
        1)
            sudo "$NDK_SCRIPT" install
            ;;
        2)
            sudo "$NDK_SCRIPT" uninstall
            ;;
        0|[Qq]|back)
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option: '$ndk_choice'.${NC}"
            ;;
    esac
}

manage_widevine() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local WIDEVINE_SCRIPT="$SCRIPT_DIR/install-widevine.sh"

    if [[ ! -f "$WIDEVINE_SCRIPT" ]]; then
        echo -e "${RED}[ERROR] Widevine script not found at: $WIDEVINE_SCRIPT${NC}"
        return 1
    fi

    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}          Waydroid Widevine DRM Setup                ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo "  1) Install Widevine DRM"
    echo "  2) Uninstall Widevine DRM"
    echo "  0) Return to Waydroid Menu"
    echo -e "${BLUE}-----------------------------------------------------${NC}"
    read -rp "Select an option [0-2]: " wv_choice
    case "$wv_choice" in
        1)
            sudo "$WIDEVINE_SCRIPT" install
            ;;
        2)
            sudo "$WIDEVINE_SCRIPT" uninstall
            ;;
        0|[Qq]|back)
            return 0
            ;;
        *)
            echo -e "${RED}Invalid option: '$wv_choice'.${NC}"
            ;;
    esac
}

fetch_latest_fdroid_apk_url() {
    local pkg_id="$1"
    python3 -c "
import urllib.request, json, sys
pkg = sys.argv[1]
try:
    url = f'https://f-droid.org/api/v1/packages/{pkg}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=12) as r:
        d = json.loads(r.read().decode())
    sug = d.get('suggestedVersionCode')
    for p in d.get('packages', []):
        if p.get('versionCode') == sug and p.get('apkName'):
            print(f'https://f-droid.org/repo/{p.get(\"apkName\")}')
            sys.exit(0)
    print(f'https://f-droid.org/repo/{pkg}_{sug}.apk')
except Exception:
    sys.exit(1)
" "$pkg_id"
}

fetch_latest_github_apk_url() {
    local repo="$1"
    python3 -c "
import urllib.request, json, sys
repo = sys.argv[1]
try:
    url = f'https://api.github.com/repos/{repo}/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=12) as r:
        d = json.loads(r.read().decode())
    for a in d.get('assets', []):
        if a.get('name', '').endswith('.apk'):
            print(a.get('browser_download_url'))
            sys.exit(0)
    print(f'https://github.com/{repo}/releases/latest/download/app-release.apk')
except Exception:
    print(f'https://github.com/{repo}/releases/latest/download/app-release.apk')
" "$repo"
}

download_and_install_apk() {
    local app_name="$1"
    local download_url="$2"
    local dest_filename="$3"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waydroid_downloads"

    mkdir -p "$cache_dir"
    local target_apk="$cache_dir/$dest_filename"

    echo -e "\n${BLUE}[*] Resolving & downloading latest ${app_name}...${NC}"
    echo -e "    URL: ${download_url}"

    if ! curl -fLC - --progress-bar -o "$target_apk" "$download_url"; then
        echo -e "${RED}[ERROR] Failed to download ${app_name} from ${download_url}${NC}"
        return 1
    fi

    echo -e "${GREEN}[+] Successfully downloaded ${app_name}.${NC}"

    # Verify if waydroid container is available to install
    if command -v waydroid &>/dev/null; then
        echo -e "${BLUE}[*] Installing ${dest_filename} into Waydroid container...${NC}"
        if waydroid app install "$target_apk"; then
            echo -e "${GREEN}[+] ${app_name} installed into Waydroid successfully!${NC}"
        else
            echo -e "${YELLOW}[!] 'waydroid app install' returned non-zero.${NC}"
            echo -e "    The APK is saved at: ${target_apk}"
            echo -e "    You can install it manually inside Waydroid session using:"
            echo -e "    waydroid app install \"${target_apk}\""
        fi
    else
        echo -e "${YELLOW}[!] waydroid command not found. APK saved at: ${target_apk}${NC}"
    fi
}

install_fdroid_official() {
    download_and_install_apk "F-Droid Official Client" "https://f-droid.org/F-Droid.apk" "F-Droid.apk"
}

install_aurora_store() {
    local url
    url=$(fetch_latest_fdroid_apk_url "com.aurora.store" 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        url="https://f-droid.org/repo/com.aurora.store_76.apk"
    fi
    download_and_install_apk "Aurora Store" "$url" "AuroraStore.apk"
}

install_neostore_fdroid() {
    local url
    url=$(fetch_latest_fdroid_apk_url "com.machiav3lli.fdroid" 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        url="https://f-droid.org/repo/com.machiav3lli.fdroid_1303.apk"
    fi
    download_and_install_apk "Neo Store (Modern F-Droid Client)" "$url" "NeoStore.apk"
}

install_smartdock() {
    local url
    url=$(fetch_latest_fdroid_apk_url "cu.axel.smartdock" 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        url="https://f-droid.org/repo/cu.axel.smartdock_1150.apk"
    fi
    download_and_install_apk "SmartDock Desktop Launcher" "$url" "SmartDock.apk"
}

install_mobilerun() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}          MobileRun Setup (via uv)                   ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    if ! command -v uv >/dev/null 2>&1; then
        echo -e "${RED}Error: 'uv' is not installed or not in PATH.${NC}"
        echo -e "${YELLOW}Install uv with: sudo dnf install uv   or   curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
        return 1
    fi

    echo -e "${BLUE}[*] Installing mobilerun tool using uv...${NC}"
    uv tool install mobilerun

    # Ensure ~/.local/bin is in PATH for current subshell
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if command -v mobilerun >/dev/null 2>&1 || [ -x "$HOME/.local/bin/mobilerun" ]; then
        local MR_BIN
        MR_BIN="$(command -v mobilerun 2>/dev/null || echo "$HOME/.local/bin/mobilerun")"
        echo -e "${GREEN}✓ mobilerun is installed.${NC}"

        if command -v adb >/dev/null 2>&1; then
            echo -e "\n${BLUE}[*] Checking connected ADB devices...${NC}"
            adb devices -l
        fi

        echo ""
        echo -e "${YELLOW}Note: 'mobilerun setup' installs its helper components to one of your connected ADB devices.${NC}"
        read -rp "Run 'mobilerun setup' now? [Y/n]: " run_mr_setup
        run_mr_setup="${run_mr_setup:-Y}"
        if [[ "$run_mr_setup" =~ ^[Yy]$ ]]; then
            "$MR_BIN" setup
        else
            echo -e "${YELLOW}Skipped running setup. Run '$MR_BIN setup' when your ADB target is connected.${NC}"
        fi
    else
        echo -e "${RED}Error: mobilerun binary not found after installation.${NC}"
        return 1
    fi
}

install_xtmapper() {
    local url
    url=$(fetch_latest_github_apk_url "Xtr126/XtMapper" 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        url="https://github.com/Xtr126/XtMapper/releases/download/v2.5.0/app-release.apk"
    fi
    download_and_install_apk "XtMapper Keymapper" "$url" "XtMapper.apk"
}

install_3dmark() {
    download_and_install_apk "3DMark Android Benchmark" "https://benchmarks.ul.com/downloads/3DMark.apk" "3DMark.apk"
}

install_all_waydroid_apps() {
    local apps=(
        "F-Droid Official Client"
        "Aurora Store (Google Play Client)"
        "Neo Store (Modern F-Droid Client)"
        "SmartDock Desktop Launcher"
        "XtMapper Keymapper"
        "3DMark Android Benchmark (UL Solutions)"
        "MobileRun (via uv, installs to ADB device)"
    )

    local selected=(1 1 1 1 1 1 0) # default first 6 checked
    local i

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Select Waydroid APKs / Add-ons to Install     ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Toggle items with their number (checkbox [X] / [ ])."
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        for i in "${!apps[@]}"; do
            local mark=" "
            [ "${selected[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${apps[i]}"
        done

        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) RUN installation on selected apps"
        echo "   0) Cancel / Back"
        echo -e "${BLUE}=====================================================${NC}"

        read -rp "Enter choice: " choice
        case "$choice" in
            0|[Qq]|back)
                return 0
                ;;
            [Aa])
                local all_set=1
                for i in "${!apps[@]}"; do
                    if [ "${selected[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                local new_state=$((1 - all_set))
                for i in "${!apps[@]}"; do
                    selected[i]=$new_state
                done
                ;;
            [Rr])
                local any_selected=0
                for i in "${!apps[@]}"; do
                    if [ "${selected[i]}" -eq 1 ]; then
                        any_selected=1
                        break
                    fi
                done

                if [ "$any_selected" -eq 0 ]; then
                    echo -e "\n${YELLOW}No apps selected. Mark at least one with its number.${NC}"
                    sleep 1.5
                    continue
                fi

                echo -e "\n${BOLD}${BLUE}=== Installing Selected Waydroid Add-ons ===${NC}"
                [ "${selected[0]}" -eq 1 ] && install_fdroid_official
                [ "${selected[1]}" -eq 1 ] && install_aurora_store
                [ "${selected[2]}" -eq 1 ] && install_neostore_fdroid
                [ "${selected[3]}" -eq 1 ] && install_smartdock
                [ "${selected[4]}" -eq 1 ] && install_xtmapper
                [ "${selected[5]}" -eq 1 ] && install_3dmark
                [ "${selected[6]}" -eq 1 ] && install_mobilerun
                echo -e "\n${GREEN}${BOLD}[+] Completed installation of selected apps!${NC}"
                read -rp "Press Enter to continue..." _
                return 0
                ;;
            *)
                local valid=0
                for token in $(echo "$choice" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#apps[@]}" ]; then
                        local idx=$((token - 1))
                        selected[idx]=$((1 - selected[idx]))
                        valid=1
                    fi
                done
                if [ "$valid" -eq 0 ]; then
                    echo -e "${RED}Invalid selection.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

fedora_waydroid_setup_wizard() {
    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Fedora Waydroid Setup Wizard                  ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "  ${BOLD}1)${NC} Initialize Waydroid (Images, Service, GAPPS/Vanilla)"
        echo -e "  ${BOLD}2)${NC} Install / Manage libndk ARM Translation"
        echo -e "  ${BOLD}3)${NC} Install / Manage Widevine DRM"
        echo -e "  ${BOLD}4)${NC} Run Full Waydroid Setup (Init + libndk + Widevine)"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo -e "  ${BOLD}5)${NC} Download & Install F-Droid (Official APK)"
        echo -e "  ${BOLD}6)${NC} Download & Install Aurora Store (Google Play Client)"
        echo -e "  ${BOLD}7)${NC} Download & Install Neo Store (Modern F-Droid Client)"
        echo -e "  ${BOLD}8)${NC} Download & Install SmartDock (Desktop Desktop UI / Dock)"
        echo -e "  ${BOLD}9)${NC} Download & Install XtMapper (Keymapper / Controller)"
        echo -e " ${BOLD}10)${NC} Download & Install 3DMark (Android Benchmark APK)"
        echo -e " ${BOLD}11)${NC} Setup MobileRun (via uv, installs to ADB device)"
        echo -e " ${BOLD}12)${NC} ${BOLD}Select & Install APKs / Add-ons (Checkbox Menu)${NC}"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo -e "  ${BOLD}0)${NC} Back to Main Menu"
        echo -e "${BLUE}=====================================================${NC}"
        read -rp "Select an option [0-12]: " w_choice
        case "$w_choice" in
            1)
                run_waydroid_init_wizard
                ;;
            2)
                manage_libndk
                ;;
            3)
                manage_widevine
                ;;
            4)
                run_waydroid_init_wizard
                local SCRIPT_DIR
                SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
                if [[ -f "$SCRIPT_DIR/install-libndk.sh" ]]; then
                    sudo "$SCRIPT_DIR/install-libndk.sh" install
                fi
                if [[ -f "$SCRIPT_DIR/install-widevine.sh" ]]; then
                    sudo "$SCRIPT_DIR/install-widevine.sh" install
                fi
                ;;
            5)
                install_fdroid_official
                ;;
            6)
                install_aurora_store
                ;;
            7)
                install_neostore_fdroid
                ;;
            8)
                install_smartdock
                ;;
            9)
                install_xtmapper
                ;;
            10)
                install_3dmark
                ;;
            11)
                install_mobilerun
                ;;
            12)
                install_all_waydroid_apps
                ;;
            0|[Qq]|back)
                break
                ;;
            *)
                echo -e "\n${RED}Invalid option: '$w_choice'. Please enter 0-12.${NC}"
                ;;
        esac
        echo ""
        read -rp "Press Enter to return to Waydroid menu..." _
    done
}

setup_waydroid() {
    fedora_waydroid_setup_wizard "$@"
}

prune_podman() {
    if ! command -v podman >/dev/null 2>&1; then
        echo -e "${RED}Error: 'podman' is not installed.${NC}"
        return 1
    fi
    echo -e "${BLUE}Running podman system prune...${NC}"
    podman system prune
}

prune_podman_all() {
    if ! command -v podman >/dev/null 2>&1; then
        echo -e "${RED}Error: 'podman' is not installed.${NC}"
        return 1
    fi
    echo -e "${YELLOW}This removes ALL unused images and volumes.${NC}"
    read -rp "Continue? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || return 0
    podman system prune -a --volumes
}

forget_snap_snapshots() {
    if ! command -v snap >/dev/null 2>&1; then
        echo -e "${YELLOW}• 'snap' not found, skipping.${NC}"
        return 0
    fi
    echo -e "${BLUE}Removing saved snap snapshots...${NC}"
    sudo snap saved | awk 'NR>1 {print $1}' | xargs -r -n 1 sudo snap forget
    echo -e "${GREEN}✓ Snap snapshots removed.${NC}"
}

benchmark_folder() {
    local dir testfile
    read -rp "Folder to benchmark [default: $HOME]: " dir
    dir="${dir:-$HOME}"
    if [ ! -d "$dir" ] || [ ! -w "$dir" ]; then
        echo -e "${RED}Error: '$dir' is not a writable directory.${NC}"
        return 1
    fi
    testfile="$(mktemp -p "$dir" .benchmark.XXXXXX)" || return 1
    echo "Write: $(dd if=/dev/zero of="$testfile" bs=1G count=1 oflag=direct 2>&1 | tail -n 1 | awk -F', ' '{print $NF}')"
    echo "Read:  $(dd if="$testfile" of=/dev/null bs=1G count=1 iflag=direct 2>&1 | tail -n 1 | awk -F', ' '{print $NF}')"
    rm -f "$testfile"
}

fetch_latest_unigine_superposition_url() {
    python3 -c "
import urllib.request, re, sys

url = 'https://benchmark.unigine.com/superposition'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, timeout=12) as resp:
        html = resp.read().decode('utf-8', errors='ignore')
        matches = re.findall(r'https?://[^\s\"\'<>]+Unigine_Superposition-[0-9.]+\.run', html)
        if matches:
            # Sort version descending if multiple found
            print(sorted(set(matches), reverse=True)[0])
            sys.exit(0)
except Exception:
    pass

print('https://assets.unigine.com/d/Unigine_Superposition-1.1.run')
"
}

install_unigine_superposition() {
    local target_dir="$HOME/Benchmarks/Unigine"
    mkdir -p "$target_dir"

    echo -e "\n${BLUE}[*] Resolving latest Unigine Superposition Linux release...${NC}"
    local download_url
    download_url="$(fetch_latest_unigine_superposition_url)"
    local filename
    filename="$(basename "$download_url")"
    local dest_file="$target_dir/$filename"

    echo -e "    Found: ${GREEN}${filename}${NC}"
    echo -e "    URL:   ${download_url}"
    echo -e "    Dest:  ${dest_file}"

    if [ -f "$dest_file" ]; then
        read -rp "File $dest_file already exists. Re-download? [y/N]: " redownload
        if [[ ! "$redownload" =~ ^[Yy]$ ]]; then
            chmod +x "$dest_file"
            echo -e "${GREEN}[+] Installer is executable at: ${dest_file}${NC}"
            echo -e "    Run with: ${dest_file}"
            return 0
        fi
    fi

    echo -e "\n${BLUE}[*] Downloading ${filename} (~1.5GB)...${NC}"
    if curl -fLC - --progress-bar -o "$dest_file" "$download_url"; then
        chmod +x "$dest_file"
        echo -e "${GREEN}[+] Successfully downloaded and set executable: ${dest_file}${NC}"
        echo -e "    To install/run Superposition Benchmark:"
        echo -e "    ${dest_file}"
    else
        echo -e "${RED}[ERROR] Failed to download Unigine Superposition from ${download_url}${NC}"
        return 1
    fi
}

cleanup_system() {
    while true; do
        echo -e "\n${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       System Cleanup & Benchmark                    ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo "  1) Podman prune (unused containers, networks, dangling images)"
        echo "  2) Podman prune ALL (-a --volumes)"
        echo "  3) Remove saved snap snapshots"
        echo "  4) Folder read/write benchmark"
        echo "  5) Download & Setup Unigine Superposition Benchmark (.run)"
        echo "  0) Back to Main Menu"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        read -rp "Select an option [0-5]: " c_choice
        case "$c_choice" in
            1) prune_podman ;;
            2) prune_podman_all ;;
            3) forget_snap_snapshots ;;
            4) benchmark_folder ;;
            5) install_unigine_superposition ;;
            0|[Qq]|back) return 0 ;;
            *) echo -e "${RED}Invalid option: '$c_choice'.${NC}" ;;
        esac
    done
}

autostart_libvirt_vm() {
    if ! command -v virsh >/dev/null 2>&1; then
        echo -e "${RED}Error: 'virsh' is not installed.${NC}"
        return 1
    fi
    local vms vm
    mapfile -t vms < <(sudo virsh list --all --name | sed '/^$/d')
    if [ "${#vms[@]}" -eq 0 ]; then
        echo -e "${YELLOW}• No libvirt VMs found.${NC}"
        return 0
    fi
    echo -e "${BOLD}Select VM to autostart:${NC}"
    select vm in "${vms[@]}" "Cancel"; do
        [ "$vm" = "Cancel" ] && return 0
        [ -n "$vm" ] && break
    done
    sudo virsh autostart "$vm" && echo -e "${GREEN}✓ '$vm' will start at boot.${NC}"
}

forward_libvirt_ports() {
    if ! command -v firewall-cmd >/dev/null 2>&1; then
        echo -e "${RED}Error: 'firewall-cmd' (firewalld) is not installed.${NC}"
        return 1
    fi
    echo -e "${BOLD}Guests live in the firewalld 'libvirt' zone (bridge virbr0).${NC}"
    echo "Ports must be opened there for guest <-> host traffic."
    echo "  1) Default: dynamic ports 49152-65535 (TCP + UDP)"
    echo "  2) Custom port or range"
    echo "  0) Cancel"
    read -rp "Select an option [0-2]: " p_choice
    local ports=()
    case "$p_choice" in
        1) ports=("49152-65535/tcp" "49152-65535/udp") ;;
        2)
            read -rp "Port or range (e.g. 8080 or 5000-5100): " port
            if ! [[ "$port" =~ ^[0-9]+(-[0-9]+)?$ ]]; then
                echo -e "${RED}Invalid port: '$port'.${NC}"
                return 1
            fi
            ports=("$port/tcp" "$port/udp")
            ;;
        *) return 0 ;;
    esac
    local p
    for p in "${ports[@]}"; do
        sudo firewall-cmd --permanent --zone=libvirt --add-port="$p" || return 1
    done
    sudo firewall-cmd --reload && echo -e "${GREEN}✓ Opened ${ports[*]} in libvirt zone.${NC}"
}

define_libvirt_vms() {
    if ! command -v virsh >/dev/null 2>&1; then
        echo -e "${RED}Error: 'virsh' is not installed.${NC}"
        return 1
    fi
    local dir="$HOME/virtualization/kvm-qemu"
    local repo_dir
    repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../VMs" 2>/dev/null && pwd)"
    [ -n "$(ls "$dir"/*.xml 2>/dev/null)" ] || dir="$repo_dir"
    local xmls=("$dir"/*.xml)
    if [ ! -f "${xmls[0]}" ]; then
        echo -e "${YELLOW}• No VM XML files found in $dir.${NC}"
        return 0
    fi

    local selected=()
    local i
    for i in "${!xmls[@]}"; do
        selected[i]=1 # default all selected
    done

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Define Libvirt VMs from XML                   ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Source directory: $dir"
        echo " Toggle XMLs to define with their number (checkbox [X] / [ ])."
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        for i in "${!xmls[@]}"; do
            local mark=" "
            [ "${selected[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "$(basename "${xmls[i]}")"
        done

        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) RUN define on selected XMLs"
        echo "   0) Cancel / Back"
        echo -e "${BLUE}=====================================================${NC}"

        read -rp "Enter choice: " choice
        case "$choice" in
            0|[Qq]|back)
                return 0
                ;;
            [Aa])
                local all_set=1
                for i in "${!xmls[@]}"; do
                    if [ "${selected[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                local new_state=$((1 - all_set))
                for i in "${!xmls[@]}"; do
                    selected[i]=$new_state
                done
                ;;
            [Rr])
                local to_define=()
                for i in "${!xmls[@]}"; do
                    [ "${selected[i]}" -eq 1 ] && to_define+=("${xmls[i]}")
                done

                if [ "${#to_define[@]}" -eq 0 ]; then
                    echo -e "\n${YELLOW}No XML files selected. Mark at least one.${NC}"
                    sleep 1.5
                    continue
                fi

                echo -e "\n${BLUE}Defining ${#to_define[@]} VM(s)...${NC}"
                local f
                for f in "${to_define[@]}"; do
                    sudo virsh define "$f" && echo -e "${GREEN}✓ Defined $(basename "$f").${NC}"
                done
                read -rp "Press Enter to return..." _
                return 0
                ;;
            *)
                local valid=0
                for token in $(echo "$choice" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#xmls[@]}" ]; then
                        local idx=$((token - 1))
                        selected[idx]=$((1 - selected[idx]))
                        valid=1
                    fi
                done
                if [ "$valid" -eq 0 ]; then
                    echo -e "${RED}Invalid selection.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

configure_libvirt() {
    while true; do
        echo -e "\n${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Libvirt VM Helpers                            ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo "  1) Autostart a VM at boot"
        echo "  2) Forward ports to VMs (libvirt firewalld zone)"
        echo "  3) Define VMs from XML (Android, Linux, Windows)"
        echo "  0) Back to Main Menu"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        read -rp "Select an option [0-3]: " l_choice
        case "$l_choice" in
            1) autostart_libvirt_vm ;;
            2) forward_libvirt_ports ;;
            3) define_libvirt_vms ;;
            0|[Qq]|back) return 0 ;;
            *) echo -e "${RED}Invalid option: '$l_choice'.${NC}" ;;
        esac
    done
}

manage_vagrant_vm() {
    local name="$1"
    local dir="$HOME/virtualization/vagrant/$name"
    if ! command -v vagrant >/dev/null 2>&1; then
        echo -e "${RED}Error: 'vagrant' is not installed.${NC}"
        return 1
    fi
    if [ ! -f "$dir/Vagrantfile" ]; then
        echo -e "${RED}Error: $dir/Vagrantfile not found. Run the playbook first.${NC}"
        return 1
    fi
    while true; do
        echo -e "\n${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Vagrant VM: $name${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo "  1) Start (vagrant up --provider libvirt)"
        echo "  2) Stop (vagrant halt)"
        echo "  3) Status"
        echo "  4) SSH into VM"
        echo "  5) Destroy (vagrant destroy -f)"
        echo "  0) Back"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        read -rp "Select an option [0-5]: " v_choice
        case "$v_choice" in
            1) (cd "$dir" && vagrant up --provider libvirt) ;;
            2) (cd "$dir" && vagrant halt) ;;
            3) (cd "$dir" && vagrant status) ;;
            4) (cd "$dir" && vagrant ssh) ;;
            5)
                read -rp "Destroy '$name' VM and its disk? [y/N]: " confirm
                [[ "$confirm" =~ ^[Yy]$ ]] && (cd "$dir" && vagrant destroy -f)
                ;;
            0|[Qq]|back) return 0 ;;
            *) echo -e "${RED}Invalid option: '$v_choice'.${NC}" ;;
        esac
    done
}

configure_vagrant() {
    while true; do
        echo -e "\n${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Vagrant VMs                                   ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo "  1) Ubuntu"
        echo "  2) YunoHost"
        echo "  0) Back to Main Menu"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        read -rp "Select an option [0-2]: " vg_choice
        case "$vg_choice" in
            1) manage_vagrant_vm ubuntu ;;
            2) manage_vagrant_vm yunohost ;;
            0|[Qq]|back) return 0 ;;
            *) echo -e "${RED}Invalid option: '$vg_choice'.${NC}" ;;
        esac
    done
}

setup_deepseek_harness() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Install DeepSeek Harness (dsh)                ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local appimages_dir="$HOME/AppImages"
    mkdir -p "$appimages_dir"

    # Ensure pixi is available
    local pixi_bin
    pixi_bin="$(command -v pixi 2>/dev/null || echo "$HOME/.pixi/bin/pixi")"
    if [ ! -x "$pixi_bin" ]; then
        echo -e "${YELLOW}Pixi not found. Running Pixi setup first...${NC}"
        install_pixi
        pixi_bin="$(command -v pixi 2>/dev/null || echo "$HOME/.pixi/bin/pixi")"
    fi

    # Initialize pixi environment in $HOME/AppImages if not already present
    if [ -x "$pixi_bin" ]; then
        if [ ! -f "$appimages_dir/pixi.toml" ]; then
            echo -e "${BLUE}Initializing Pixi environment in $appimages_dir...${NC}"
            (cd "$appimages_dir" && "$pixi_bin" init --format toml . 2>/dev/null || "$pixi_bin" init .)
            echo -e "${GREEN}✓ Pixi environment initialized in $appimages_dir.${NC}"
        else
            echo -e "${GREEN}✓ Pixi environment already exists in $appimages_dir.${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: Pixi is not executable; proceeding with npx installation directly.${NC}"
    fi

    # Ensure npx / nodejs is available
    if ! command -v npx >/dev/null 2>&1; then
        echo -e "${RED}Error: 'npx' is not found. Please ensure Node.js is installed.${NC}"
        return 1
    fi

    echo -e "${BLUE}Installing DeepSeek Harness via npx in $appimages_dir...${NC}"
    (cd "$appimages_dir" && npx -y @deepseek-ai/dsh web --no-open)

    echo -e "${GREEN}✓ DeepSeek Harness installation finished in $appimages_dir.${NC}"
}

fetch_prism_llamacpp_release_assets() {
    python3 -c "
import urllib.request, json, sys
repo = 'PrismML-Eng/llama.cpp'
target = sys.argv[1] if len(sys.argv) > 1 else 'all'
try:
    url = f'https://api.github.com/repos/{repo}/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.loads(r.read().decode())
    assets = d.get('assets', [])
    filtered = []
    for a in assets:
        name = a.get('name', '')
        url = a.get('browser_download_url', '')
        is_android = 'android' in name
        is_linux = any(x in name for x in ['linux', 'ubuntu']) and not any(x in name for x in ['win', 'macos', 'xcframework'])
        if target == 'android' and is_android:
            filtered.append(f'{name}\t{url}')
        elif target == 'linux' and is_linux:
            filtered.append(f'{name}\t{url}')
        elif target == 'all' and (is_android or is_linux):
            filtered.append(f'{name}\t{url}')
    print('\n'.join(filtered))
except Exception as e:
    sys.exit(1)
" "$1"
}

download_and_extract_prism_single_asset() {
    local name="$1"
    local url="$2"
    local dest_dir="$HOME/AppImages/prism-llama.cpp"
    mkdir -p "$dest_dir"

    local target_archive="$dest_dir/$name"
    local extract_folder="${name%.tar.gz}"
    extract_folder="${extract_folder%.zip}"
    local sub_dir="$dest_dir/$extract_folder"

    echo -e "\n${BLUE}[*] Downloading $name...${NC}"
    curl -fL --progress-bar -o "$target_archive" "$url"

    mkdir -p "$sub_dir"
    echo -e "${BLUE}[*] Extracting to $sub_dir...${NC}"
    if [[ "$name" == *.tar.gz ]]; then
        tar -xzf "$target_archive" -C "$sub_dir"
    elif [[ "$name" == *.zip ]]; then
        unzip -q -o "$target_archive" -d "$sub_dir"
    fi

    find "$sub_dir" -type f -exec chmod +x {} + 2>/dev/null || true
    rm -f "$target_archive"
    echo -e "${GREEN}✓ Successfully installed: $sub_dir${NC}"
}

download_and_extract_prism_assets() {
    local target_type="$1"
    local dest_dir="$HOME/AppImages/prism-llama.cpp"
    mkdir -p "$dest_dir"

    echo -e "${BLUE}Fetching latest release assets for PrismML-Eng/llama.cpp...${NC}"
    local asset_lines
    asset_lines="$(fetch_prism_llamacpp_release_assets "$target_type")"
    if [ -z "$asset_lines" ]; then
        echo -e "${RED}Error: Failed to fetch assets or none matched target '${target_type}'.${NC}"
        return 1
    fi

    local names=()
    local urls=()
    while IFS=$'\t' read -r name url; do
        [ -z "$name" ] && continue
        names+=("$name")
        urls+=("$url")
    done <<< "$asset_lines"

    if [ "${#names[@]}" -eq 0 ]; then
        echo -e "${YELLOW}• No assets found.${NC}"
        return 0
    fi

    local selected=()
    local i
    for i in "${!names[@]}"; do
        selected[i]=0
    done

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Select Prism llama.cpp Binaries to Install     ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Destination: $dest_dir"
        echo " Toggle binaries with their number (checkbox [X] / [ ])."
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        for i in "${!names[@]}"; do
            local mark=" "
            [ "${selected[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${names[i]}"
        done

        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) RUN download and installation on selected binaries"
        echo "   0) Cancel / Back"
        echo -e "${BLUE}=====================================================${NC}"

        read -rp "Enter choice: " choice
        case "$choice" in
            0|[Qq]|back)
                return 0
                ;;
            [Aa])
                local all_set=1
                for i in "${!names[@]}"; do
                    if [ "${selected[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                local new_state=$((1 - all_set))
                for i in "${!names[@]}"; do
                    selected[i]=$new_state
                done
                ;;
            [Rr])
                local to_download=()
                for i in "${!names[@]}"; do
                    [ "${selected[i]}" -eq 1 ] && to_download+=("$i")
                done

                if [ "${#to_download[@]}" -eq 0 ]; then
                    echo -e "\n${YELLOW}No binaries selected. Mark at least one with its number.${NC}"
                    sleep 1.5
                    continue
                fi

                echo -e "\n${BLUE}Downloading and extracting ${#to_download[@]} binary asset(s)...${NC}"
                for i in "${to_download[@]}"; do
                    download_and_extract_prism_single_asset "${names[i]}" "${urls[i]}"
                done

                echo -e "\n${GREEN}✓ Selected binaries installed in: $dest_dir${NC}"
                read -rp "Press Enter to continue..." _
                return 0
                ;;
            *)
                local valid=0
                for token in $(echo "$choice" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#names[@]}" ]; then
                        local idx=$((token - 1))
                        selected[idx]=$((1 - selected[idx]))
                        valid=1
                    fi
                done
                if [ "$valid" -eq 0 ]; then
                    echo -e "${RED}Invalid selection.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

install_prism_llamacpp() {
    while true; do
        echo -e "\n${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Install Prism llama.cpp Binaries (AppImages)  ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Source: https://github.com/PrismML-Eng/llama.cpp"
        echo " Destination: $HOME/AppImages/prism-llama.cpp"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "  1) Choose from ALL Linux & Android binaries"
        echo "  2) Choose from Linux binaries only (CUDA, Vulkan, ROCm, SYCL, CPU)"
        echo "  3) Choose from Android binaries only (ARM64)"
        echo "  0) Back to Main Menu"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        read -rp "Select an option [0-3]: " prism_choice
        case "$prism_choice" in
            1) download_and_extract_prism_assets "all" ;;
            2) download_and_extract_prism_assets "linux" ;;
            3) download_and_extract_prism_assets "android" ;;
            0|[Qq]|back) return 0 ;;
            *) echo -e "${RED}Invalid option: '$prism_choice'.${NC}" ;;
        esac
    done
}

fetch_koboldcpp_release_assets() {
    python3 -c "
import urllib.request, json, sys
repo = 'LostRuins/koboldcpp'
try:
    url = f'https://api.github.com/repos/{repo}/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.loads(r.read().decode())
    assets = d.get('assets', [])
    filtered = []
    for a in assets:
        name = a.get('name', '')
        url = a.get('browser_download_url', '')
        # Only select Linux standalone binaries (exclude windows .exe and mac)
        if 'linux' in name.lower() and not name.endswith('.exe'):
            filtered.append(f'{name}\t{url}')
    print('\n'.join(filtered))
except Exception:
    sys.exit(1)
"
}

download_koboldcpp_single_binary() {
    local name="$1"
    local url="$2"
    local dest_dir="$HOME/AppImages"
    mkdir -p "$dest_dir"

    local target_file="$dest_dir/$name"
    echo -e "\n${BLUE}[*] Downloading $name directly to $dest_dir...${NC}"
    curl -fL --progress-bar -o "$target_file" "$url"
    chmod +x "$target_file"
    echo -e "${GREEN}✓ Successfully installed executable to: $target_file${NC}"
}

install_koboldcpp() {
    local dest_dir="$HOME/AppImages"
    mkdir -p "$dest_dir"

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Install KoboldCpp Standalone Binary           ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Source: https://github.com/LostRuins/koboldcpp"
        echo " Destination: $dest_dir"
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        echo -e "${BLUE}Fetching latest release assets for LostRuins/koboldcpp...${NC}"
        local asset_lines
        asset_lines="$(fetch_koboldcpp_release_assets)"
        if [ -z "$asset_lines" ]; then
            echo -e "${RED}Error: Failed to fetch assets from LostRuins/koboldcpp.${NC}"
            return 1
        fi

        local names=()
        local urls=()
        while IFS=$'\t' read -r name url; do
            [ -z "$name" ] && continue
            names+=("$name")
            urls+=("$url")
        done <<< "$asset_lines"

        if [ "${#names[@]}" -eq 0 ]; then
            echo -e "${YELLOW}• No Linux binary assets found.${NC}"
            return 0
        fi

        local selected=()
        local i
        for i in "${!names[@]}"; do
            selected[i]=0
        done

        while true; do
            clear
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       Select KoboldCpp Binaries to Download         ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo " Destination: $dest_dir"
            echo " Toggle binaries with their number (checkbox [X] / [ ])."
            echo -e "${BLUE}-----------------------------------------------------${NC}"

            for i in "${!names[@]}"; do
                local mark=" "
                [ "${selected[i]}" -eq 1 ] && mark="X"
                printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${names[i]}"
            done

            echo -e "${BLUE}-----------------------------------------------------${NC}"
            echo "   A) Toggle Select ALL / NONE"
            echo "   R) RUN download on selected binaries"
            echo "   0) Back to Main Menu"
            echo -e "${BLUE}=====================================================${NC}"

            read -rp "Enter choice: " k_choice
            case "$k_choice" in
                0|[Qq]|back)
                    return 0
                    ;;
                [Aa])
                    local all_set=1
                    for i in "${!names[@]}"; do
                        if [ "${selected[i]}" -eq 0 ]; then
                            all_set=0
                            break
                        fi
                    done
                    local new_state=$((1 - all_set))
                    for i in "${!names[@]}"; do
                        selected[i]=$new_state
                    done
                    ;;
                [Rr])
                    local to_download=()
                    for i in "${!names[@]}"; do
                        [ "${selected[i]}" -eq 1 ] && to_download+=("$i")
                    done

                    if [ "${#to_download[@]}" -eq 0 ]; then
                        echo -e "\n${YELLOW}No binaries selected. Mark at least one with its number.${NC}"
                        sleep 1.5
                        continue
                    fi

                    echo -e "\n${BLUE}Downloading ${#to_download[@]} binary asset(s) to $dest_dir...${NC}"
                    for i in "${to_download[@]}"; do
                        download_koboldcpp_single_binary "${names[i]}" "${urls[i]}"
                    done

                    echo -e "\n${GREEN}✓ Selected binaries installed directly to: $dest_dir${NC}"
                    read -rp "Press Enter to continue..." _
                    return 0
                    ;;
                *)
                    local valid=0
                    for token in $(echo "$k_choice" | tr ',' ' '); do
                        if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#names[@]}" ]; then
                            local idx=$((token - 1))
                            selected[idx]=$((1 - selected[idx]))
                            valid=1
                        fi
                    done
                    if [ "$valid" -eq 0 ]; then
                        echo -e "${RED}Invalid selection.${NC}"
                        sleep 1
                    fi
                    ;;
            esac
        done
    done
}

fetch_localai_release_assets() {
    python3 -c "
import urllib.request, json, sys
repo = 'mudler/LocalAI'
try:
    url = f'https://api.github.com/repos/{repo}/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.loads(r.read().decode())
    assets = d.get('assets', [])
    filtered = []
    for a in assets:
        name = a.get('name', '')
        url = a.get('browser_download_url', '')
        lower = name.lower()
        if ('linux' in lower or 'appimage' in lower) and not lower.endswith(('.exe', '.sha256', '.sig', '.txt', '.md', '.source.tar.gz')):
            filtered.append(f'{name}\t{url}')
    print('\n'.join(filtered))
except Exception:
    sys.exit(1)
"
}

download_localai_single_asset() {
    local name="$1"
    local url="$2"
    local dest_dir="$HOME/AppImages"
    mkdir -p "$dest_dir"

    local target_file="$dest_dir/$name"
    echo -e "\n${BLUE}[*] Downloading $name directly to $dest_dir...${NC}"
    curl -fL --progress-bar -o "$target_file" "$url"

    if [[ "$name" == *.tar.xz ]] || [[ "$name" == *.tar.gz ]]; then
        echo -e "${BLUE}[*] Extracting $name into $dest_dir...${NC}"
        tar -xf "$target_file" -C "$dest_dir"
        echo -e "${GREEN}✓ Successfully unpacked: $target_file${NC}"
    else
        chmod +x "$target_file"
        echo -e "${GREEN}✓ Successfully installed executable to: $target_file${NC}"
    fi
}

install_localai() {
    local dest_dir="$HOME/AppImages"
    mkdir -p "$dest_dir"

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Install LocalAI Binary / AppImage             ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Source: https://github.com/mudler/LocalAI"
        echo " Destination: $dest_dir"
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        echo -e "${BLUE}Fetching latest release assets for mudler/LocalAI...${NC}"
        local asset_lines
        asset_lines="$(fetch_localai_release_assets)"
        if [ -z "$asset_lines" ]; then
            echo -e "${RED}Failed to fetch release assets from GitHub API.${NC}"
            echo -e "${YELLOW}Please verify internet connection or check GitHub rate limits.${NC}"
            read -rp "Press Enter to return to menu..." _
            return 1
        fi

        local names=()
        local urls=()
        while IFS=$'\t' read -r asset_name asset_url; do
            [ -n "$asset_name" ] && names+=("$asset_name") && urls+=("$asset_url")
        done <<< "$asset_lines"

        local selected=()
        for _ in "${names[@]}"; do
            selected+=(0)
        done

        while true; do
            clear
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       Select LocalAI Binaries / Launchers           ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo " Destination: $dest_dir"
            echo " Toggle items with number(s) (e.g. 1 or 1,2)."
            echo -e "${BLUE}-----------------------------------------------------${NC}"

            for i in "${!names[@]}"; do
                local mark=" "
                [ "${selected[i]}" -eq 1 ] && mark="X"
                printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${names[i]}"
            done

            echo -e "${BLUE}-----------------------------------------------------${NC}"
            echo "   A) Toggle Select ALL / NONE"
            echo "   R) RUN download on selected assets"
            echo "   0) Back to Main Menu"
            echo -e "${BLUE}=====================================================${NC}"

            read -rp "Enter choice: " l_choice
            case "$l_choice" in
                0|[Qq]|back)
                    return 0
                    ;;
                [Aa])
                    local all_set=1
                    for i in "${!names[@]}"; do
                        if [ "${selected[i]}" -eq 0 ]; then
                            all_set=0
                            break
                        fi
                    done
                    local new_state=$((1 - all_set))
                    for i in "${!names[@]}"; do
                        selected[i]=$new_state
                    done
                    ;;
                [Rr])
                    local to_download=()
                    for i in "${!names[@]}"; do
                        [ "${selected[i]}" -eq 1 ] && to_download+=("$i")
                    done

                    if [ "${#to_download[@]}" -eq 0 ]; then
                        echo -e "\n${YELLOW}No assets selected. Mark at least one with its number.${NC}"
                        sleep 1.5
                        continue
                    fi

                    echo -e "\n${BLUE}Downloading ${#to_download[@]} asset(s) to $dest_dir...${NC}"
                    for i in "${to_download[@]}"; do
                        download_localai_single_asset "${names[i]}" "${urls[i]}"
                    done

                    echo -e "\n${GREEN}✓ Selected LocalAI assets installed directly to: $dest_dir${NC}"
                    read -rp "Press Enter to continue..." _
                    return 0
                    ;;
                *)
                    local valid=0
                    for token in $(echo "$l_choice" | tr ',' ' '); do
                        if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#names[@]}" ]; then
                            local idx=$((token - 1))
                            selected[idx]=$((1 - selected[idx]))
                            valid=1
                        fi
                    done
                    if [ "$valid" -eq 0 ]; then
                        echo -e "${RED}Invalid selection.${NC}"
                        sleep 1
                    fi
                    ;;
            esac
        done
    done
}

install_openclaw_deb_distrobox() {
    local container_name="ubuntu-toolbox"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/openclaw_downloads"
    mkdir -p "$cache_dir"

    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Install OpenClaw (.deb) into Distrobox         ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    if ! command -v distrobox >/dev/null 2>&1; then
        echo -e "${RED}Error: 'distrobox' is not installed.${NC}"
        return 1
    fi

    # Ensure container exists or prompt to create
    if ! distrobox list 2>/dev/null | grep -q "^${container_name}\b\|[[:space:]]${container_name}[[:space:]]"; then
        echo -e "${YELLOW}• Distrobox container '${container_name}' does not exist.${NC}"
        read -rp "Create '${container_name}' container now? [Y/n]: " cr_choice
        cr_choice="${cr_choice:-Y}"
        if [[ "$cr_choice" =~ ^[Yy]$ ]]; then
            setup_distrobox || return 1
        else
            echo -e "${RED}[-] Cannot install .deb without target distrobox container.${NC}"
            return 1
        fi
    fi

    echo -e "${BLUE}[*] Fetching latest OpenClaw .deb release from GitHub...${NC}"
    local deb_info
    deb_info=$(python3 -c "
import urllib.request, json, sys
repo = 'openclaw/openclaw'
try:
    url = f'https://api.github.com/repos/{repo}/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.loads(r.read().decode())
    for a in d.get('assets', []):
        name = a.get('name', '')
        url = a.get('browser_download_url', '')
        if name.lower().endswith('.deb') and 'amd64' in name.lower():
            print(f'{name}\t{url}')
            sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(1)
")

    local deb_name deb_url
    if [ -n "$deb_info" ]; then
        IFS=$'\t' read -r deb_name deb_url <<< "$deb_info"
    else
        echo -e "${YELLOW}Could not resolve latest .deb from GitHub API. Using fallback URL...${NC}"
        deb_url="https://github.com/openclaw/openclaw/releases/download/v2026.10.9/OpenClaw-2026.10.9-amd64.deb"
        deb_name="OpenClaw-2026.10.9-amd64.deb"
    fi

    local target_file="$cache_dir/$deb_name"
    echo -e "${BLUE}[*] Downloading ${deb_name}...${NC}"
    if ! curl -fLC - --progress-bar -o "$target_file" "$deb_url"; then
        echo -e "${RED}[ERROR] Failed to download OpenClaw .deb from $deb_url${NC}"
        return 1
    fi

    echo -e "\n${BLUE}[*] Installing ${deb_name} into '${container_name}' container via apt...${NC}"
    if distrobox enter "${container_name}" -- sudo apt-get update && \
       distrobox enter "${container_name}" -- sudo apt-get install -y "$target_file"; then
        echo -e "\n${BLUE}[*] Exporting OpenClaw desktop app and binary to host...${NC}"
        distrobox enter "${container_name}" -- distrobox-export --app openclaw 2>/dev/null || true
        distrobox enter "${container_name}" -- distrobox-export --bin /usr/bin/openclaw --export-path "$HOME/.local/bin" 2>/dev/null || true
        echo -e "${GREEN}✓ OpenClaw (.deb) installed and exported successfully from Distrobox!${NC}"
    else
        echo -e "${RED}[ERROR] Failed to install OpenClaw .deb inside distrobox container.${NC}"
        return 1
    fi
}

install_openclaw_cli_gateway() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Installing OpenClaw CLI & Gateway Service     ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    echo " Source: https://openclaw.ai/install-cli.sh"
    echo -e "${BLUE}-----------------------------------------------------${NC}"

    echo -e "${BLUE}[*] Running OpenClaw CLI installer...${NC}"
    curl -fsSL https://openclaw.ai/install-cli.sh | bash

    export PATH="$HOME/.openclaw/bin:$PATH"

    if [ -x "$HOME/.openclaw/bin/openclaw" ]; then
        echo -e "\n${BLUE}[*] Installing OpenClaw Gateway service...${NC}"
        "$HOME/.openclaw/bin/openclaw" gateway install || true

        echo -e "\n${BLUE}[*] Checking OpenClaw Gateway status...${NC}"
        "$HOME/.openclaw/bin/openclaw" gateway status || true

        echo -e "${GREEN}✓ OpenClaw CLI and Gateway service setup complete.${NC}"
    else
        echo -e "${YELLOW}Notice: $HOME/.openclaw/bin/openclaw not found or not executable.${NC}"
    fi
}

install_openclaw() {
    local options=(
        "Install OpenClaw CLI & Gateway Service on Host (https://openclaw.ai/install-cli.sh)"
        "Install Latest OpenClaw (.deb) into Ubuntu Distrobox & Export to Host"
    )
    local selected=(1 1)

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Install OpenClaw (CLI, Service & Distrobox Deb) ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Source: https://github.com/openclaw/openclaw/releases"
        echo " Toggle options with numbers [1-${#options[@]}]."
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        for i in "${!options[@]}"; do
            local mark=" "
            [ "${selected[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${options[i]}"
        done

        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) RUN selected installation steps"
        echo "   0) Back to Main Menu"
        echo -e "${BLUE}=====================================================${NC}"

        read -rp "Enter choice: " oc_choice
        case "$oc_choice" in
            0|[Qq]|back)
                return 0
                ;;
            [Aa])
                local all_set=1
                for i in "${!options[@]}"; do
                    if [ "${selected[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                local new_state=$((1 - all_set))
                for i in "${!options[@]}"; do
                    selected[i]=$new_state
                done
                ;;
            [Rr])
                local any_selected=0
                for i in "${!options[@]}"; do
                    if [ "${selected[i]}" -eq 1 ]; then
                        any_selected=1
                        break
                    fi
                done

                if [ "$any_selected" -eq 0 ]; then
                    echo -e "\n${YELLOW}No options selected. Select at least one.${NC}"
                    sleep 1.5
                    continue
                fi

                echo -e "\n${BOLD}${BLUE}=== Executing OpenClaw Installation ===${NC}"
                [ "${selected[0]}" -eq 1 ] && install_openclaw_cli_gateway
                [ "${selected[1]}" -eq 1 ] && install_openclaw_deb_distrobox

                echo -e "\n${GREEN}✓ OpenClaw tasks finished.${NC}"
                read -rp "Press Enter to continue..." _
                return 0
                ;;
            *)
                for token in $(echo "$oc_choice" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#options[@]}" ]; then
                        local idx=$((token - 1))
                        selected[idx]=$((1 - selected[idx]))
                    fi
                done
                ;;
        esac
    done
}

download_devpod_cli() {
    local target_arch
    case "$(uname -m)" in
        x86_64)  target_arch="amd64" ;;
        aarch64|arm64) target_arch="arm64" ;;
        *)
            echo -e "${RED}Unsupported architecture: $(uname -m)${NC}"
            return 1
            ;;
    esac

    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    local dest_file="$install_dir/devpod"

    echo -e "\n${BLUE}[*] Fetching latest DevPod CLI release...${NC}"
    local download_url=""
    local tag=""
    if command -v curl &>/dev/null; then
        local release_json
        release_json="$(curl -fsSL https://api.github.com/repos/loft-sh/devpod/releases/latest 2>/dev/null || true)"
        tag="$(echo "$release_json" | grep -m1 '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
        download_url="$(echo "$release_json" | grep "browser_download_url" | grep "devpod-linux-${target_arch}\"" | head -n 1 | cut -d '"' -f 4)"
    fi

    # Fallback to direct releases/latest/download URL
    if [ -z "$download_url" ]; then
        download_url="https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-${target_arch}"
    fi

    local ver_label="${tag:-latest}"
    echo -e "${BLUE}[*] Downloading DevPod CLI ($ver_label, ${target_arch}) to $dest_file...${NC}"
    if curl -fsSL -L "$download_url" -o "$dest_file"; then
        chmod +x "$dest_file"
        echo -e "${GREEN}✓ Installed DevPod CLI: $dest_file${NC}"

        # Ensure ~/.local/bin is in PATH for current session and shell config
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            echo -e "${YELLOW}• Note: Added ~/.local/bin to current PATH.${NC}"
        fi
        "$dest_file" version 2>/dev/null || true
    else
        echo -e "${RED}✗ Failed to download DevPod CLI from $download_url${NC}"
        return 1
    fi
}

download_devpod_appimage() {
    local appimages_dir="$HOME/AppImages"
    mkdir -p "$appimages_dir"

    local target_file="$appimages_dir/DevPod_linux_amd64.AppImage"

    echo -e "\n${BLUE}[*] Fetching latest DevPod AppImage release...${NC}"
    local download_url=""
    local tag=""
    if command -v curl &>/dev/null; then
        local release_json
        release_json="$(curl -fsSL https://api.github.com/repos/loft-sh/devpod/releases/latest 2>/dev/null || true)"
        tag="$(echo "$release_json" | grep -m1 '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
        download_url="$(echo "$release_json" | grep "browser_download_url" | grep "DevPod_linux_amd64\.AppImage\"" | head -n 1 | cut -d '"' -f 4)"
    fi

    # Fallback to direct releases/latest/download URL
    if [ -z "$download_url" ]; then
        download_url="https://github.com/loft-sh/devpod/releases/latest/download/DevPod_linux_amd64.AppImage"
    fi

    local ver_label="${tag:-latest}"
    echo -e "${BLUE}[*] Downloading DevPod AppImage ($ver_label) to $target_file...${NC}"
    if curl -fsSL -L "$download_url" -o "$target_file"; then
        chmod +x "$target_file"
        echo -e "${GREEN}✓ Downloaded DevPod AppImage: $target_file${NC}"

        # Configure portable config and home directories
        echo -e "    Setting up portable config and home..."
        (cd "$appimages_dir" && ./"DevPod_linux_amd64.AppImage" --appimage-portable-config 2>/dev/null || true)
        (cd "$appimages_dir" && ./"DevPod_linux_amd64.AppImage" --appimage-portable-home 2>/dev/null || true)
    else
        echo -e "${RED}✗ Failed to download DevPod AppImage from $download_url${NC}"
        return 1
    fi
}

install_devpod() {
    local options=(
        "DevPod CLI binary into ~/.local/bin (latest release, auto-detect arch)"
        "DevPod Desktop AppImage into ~/AppImages (latest release, amd64)"
    )

    local selected=(1 1)
    local dp_choice

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Install DevPod (Loft Labs Latest Release)     ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Toggle items with their number (checkbox [X] / [ ])."
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        for i in "${!options[@]}"; do
            local mark=" "
            [ "${selected[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${options[i]}"
        done

        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) RUN installation for selected items"
        echo "   0) Cancel / Back"
        echo -e "${BLUE}=====================================================${NC}"

        read -rp "Enter choice: " dp_choice
        case "$dp_choice" in
            0|[Qq]|back)
                return 0
                ;;
            [Aa])
                local all_set=1
                for i in "${!options[@]}"; do
                    if [ "${selected[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                local new_state=$((1 - all_set))
                for i in "${!options[@]}"; do
                    selected[i]=$new_state
                done
                ;;
            [Rr])
                local total_selected=0
                for i in "${!options[@]}"; do
                    [ "${selected[i]}" -eq 1 ] && total_selected=$((total_selected + 1))
                done

                if [ "$total_selected" -eq 0 ]; then
                    echo -e "\n${YELLOW}No items selected. Select at least one item.${NC}"
                    sleep 1.5
                    continue
                fi

                echo -e "\n${BOLD}${BLUE}=== Executing DevPod Installation ===${NC}"
                [ "${selected[0]}" -eq 1 ] && download_devpod_cli
                [ "${selected[1]}" -eq 1 ] && download_devpod_appimage

                echo -e "\n${GREEN}✓ DevPod tasks finished.${NC}"
                read -rp "Press Enter to continue..." _
                return 0
                ;;
            *)
                for token in $(echo "$dp_choice" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#options[@]}" ]; then
                        local idx=$((token - 1))
                        selected[idx]=$((1 - selected[idx]))
                    fi
                done
                ;;
        esac
    done
}

download_and_install_single_appimage() {
    local name="$1"
    local download_url="$2"
    local filename="$3"
    local appimages_dir="$HOME/AppImages"
    mkdir -p "$appimages_dir"

    if [ -z "$download_url" ] || [ "$download_url" == "None" ]; then
        echo -e "${RED}[!] Could not resolve latest download URL for $name.${NC}"
        return 1
    fi

    local target_path="$appimages_dir/$filename"
    echo -e "\n${BLUE}[*] Downloading latest ${name}...${NC}"
    echo -e "    URL:  ${download_url}"
    echo -e "    Dest: ${target_path}"

    if curl -fLC - --progress-bar -o "$target_path" "$download_url"; then
        chmod +x "$target_path"
        echo -e "${GREEN}[+] Successfully downloaded and set executable: ${target_path}${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] Failed to download ${name} from ${download_url}${NC}"
        return 1
    fi
}

fetch_github_appimage_url() {
    local repo="$1"
    local regex="$2"
    python3 -c "
import urllib.request, json, re, sys

headers = {'User-Agent': 'Mozilla/5.0'}
repo = sys.argv[1]
pattern = re.compile(sys.argv[2], re.IGNORECASE)
url = f'https://api.github.com/repos/{repo}/releases/latest'

try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=12) as r:
        data = json.loads(r.read().decode())
        for a in data.get('assets', []):
            name = a.get('name', '')
            if pattern.search(name):
                print(a.get('browser_download_url'))
                sys.exit(0)
except Exception:
    pass
sys.exit(1)
" "$repo" "$regex"
}

# --- AppImage Fetchers ---

fetch_latest_bionic_url() {
    curl -sI "https://lmstudio.ai/download/bionic/latest/linux/x64" \
        | awk 'tolower($1) == "location:" {print $2}' \
        | tr -d '\r'
}

fetch_latest_darktable_appimage_url() {
    fetch_github_appimage_url "darktable-org/darktable" 'Darktable-.*x86_64\.AppImage$'
}

fetch_latest_eden_appimage_url() {
    python3 -c "
import urllib.request, json, re, sys

headers = {'User-Agent': 'Mozilla/5.0'}
try:
    req = urllib.request.Request('https://git.eden-emu.dev/api/v1/repos/eden-emu/eden/releases/latest', headers=headers)
    with urllib.request.urlopen(req, timeout=12) as r:
        data = json.loads(r.read().decode())
        pattern = re.compile(r'Eden-Linux-.*amd64-clang-pgo\.AppImage$', re.IGNORECASE)
        for a in data.get('assets', []):
            if pattern.search(a.get('name', '')):
                print(a.get('browser_download_url'))
                sys.exit(0)
except Exception:
    pass
sys.exit(1)
"
}

fetch_latest_jan_appimage_url() {
    fetch_github_appimage_url "janhq/jan" 'Jan_.*amd64\.AppImage$'
}

fetch_latest_lmms_appimage_url() {
    fetch_github_appimage_url "LMMS/lmms" 'lmms-.*linux-x86_64\.AppImage$'
}

fetch_latest_musescore_appimage_url() {
    fetch_github_appimage_url "musescore/MuseScore" 'MuseScore-Studio-.*x86_64\.AppImage$'
}

fetch_latest_qtscrcpy_appimage_url() {
    fetch_github_appimage_url "barry-ran/QtScrcpy" 'QtScrcpy-ubuntu-x64-.*\.AppImage$'
}

fetch_latest_unsloth_appimage_url() {
    python3 -c "
import urllib.request, json, sys

headers = {'User-Agent': 'Mozilla/5.0'}
try:
    req = urllib.request.Request('https://github.com/unslothai/unsloth/releases/latest/download/latest.json', headers=headers)
    with urllib.request.urlopen(req, timeout=12) as r:
        d = json.loads(r.read().decode())
        u = d.get('platforms', {}).get('linux-x86_64', {}).get('url')
        if u:
            print(u)
            sys.exit(0)
except Exception:
    pass
sys.exit(1)
" 2>/dev/null || echo "https://github.com/unslothai/unsloth/releases/latest/download/Unsloth-Desktop-Linux.AppImage"
}

fetch_latest_deepseek_harness_desktop_url() {
    fetch_github_appimage_url "dsh-tauri/deepseek-harness-desktop" 'Deepseek\.Harness\.Desktop_.*amd64\.AppImage$'
}

# --- AppImage Installers ---

install_bionic_appimage() {
    local url
    url="$(fetch_latest_bionic_url)"
    local fn="bionic.appimage"
    download_and_install_single_appimage "Bionic (LM Studio Agent)" "$url" "$fn"
}

install_darktable_appimage() {
    local url
    url="$(fetch_latest_darktable_appimage_url)"
    local fn="darktable.appimage"
    download_and_install_single_appimage "Darktable" "$url" "$fn"
}

install_eden_appimage() {
    local url
    url="$(fetch_latest_eden_appimage_url)"
    local fn="eden.appimage"
    download_and_install_single_appimage "Eden Nintendo Switch Emulator" "$url" "$fn"
}

install_jan_appimage() {
    local url
    url="$(fetch_latest_jan_appimage_url)"
    local fn="jan.appimage"
    download_and_install_single_appimage "Jan AI Desktop" "$url" "$fn"
}

install_lmms_appimage() {
    local url
    url="$(fetch_latest_lmms_appimage_url)"
    local fn="lmms.appimage"
    download_and_install_single_appimage "LMMS Digital Audio Workstation" "$url" "$fn"
}

install_musescore_appimage() {
    local url
    url="$(fetch_latest_musescore_appimage_url)"
    local fn="musescore_studio.appimage"
    download_and_install_single_appimage "MuseScore Studio" "$url" "$fn"
}

install_qtscrcpy_appimage() {
    local url
    url="$(fetch_latest_qtscrcpy_appimage_url)"
    local fn="qtscrcpy.appimage"
    download_and_install_single_appimage "QtScrcpy (Android Display & Control)" "$url" "$fn"
}

install_unsloth_appimage() {
    local url
    url="$(fetch_latest_unsloth_appimage_url)"
    local fn="unsloth.appimage"
    download_and_install_single_appimage "Unsloth AI Studio" "$url" "$fn"
}

install_deepseek_harness_appimage() {
    local url
    url="$(fetch_latest_deepseek_harness_desktop_url)"
    local fn="deepseek-harness-desktop.appimage"
    download_and_install_single_appimage "DeepSeek Harness Desktop" "$url" "$fn"
}

# Unified AppImage Hub
appimage_hub_menu() {
    local apps=(
        "Bionic (LM Studio Agent)"
        "Darktable (Photography & RAW Developer)"
        "DeepSeek Harness Desktop (DSH GUI)"
        "DevPod (Client-only developer environments)"
        "Eden (Nintendo Switch Emulator)"
        "Jan (Open-source ChatGPT Alternative)"
        "KoboldCpp (Standalone llama.cpp & UI)"
        "LMMS (Music Production Suite)"
        "LocalAI (Multi-model local AI runtime)"
        "MuseScore Studio (Music Notation & Scoring)"
        "Prism llama.cpp (Pre-compiled LLM inference binaries)"
        "QtScrcpy (Android Screen Mirror & Control)"
        "Unsloth (Fast LLM Finetuning & Studio)"
    )

    local selected=(0 0 0 0 0 0 0 0 0 0 0 0 0)
    local i

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}         AppImage Hub & Local AI Engines             ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Target Directory: $HOME/AppImages"
        echo " Toggle items with their number (checkbox [X] / [ ])."
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        for i in "${!apps[@]}"; do
            local mark=" "
            [ "${selected[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${apps[i]}"
        done

        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) RUN Download for Selected AppImages"
        echo "   C) Compact & Configure Portable AppImages"
        echo "   0) Back to Main Menu"
        echo -e "${BLUE}=====================================================${NC}"

        read -rp "Enter choice: " choice
        case "$choice" in
            0|[Qq]|back)
                return 0
                ;;
            [Aa])
                local all_set=1
                for i in "${!apps[@]}"; do
                    if [ "${selected[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                local new_state=$((1 - all_set))
                for i in "${!apps[@]}"; do
                    selected[i]=$new_state
                done
                ;;
            [Cc])
                run_appimage_compact
                ;;
            [Rr])
                local any_selected=0
                for i in "${!apps[@]}"; do
                    if [ "${selected[i]}" -eq 1 ]; then
                        any_selected=1
                        break
                    fi
                done

                if [ "$any_selected" -eq 0 ]; then
                    echo -e "\n${YELLOW}No AppImages selected. Mark at least one with its number.${NC}"
                    sleep 1.5
                    continue
                fi

                echo -e "\n${BOLD}${BLUE}=== Downloading Selected AppImages ===${NC}"
                [ "${selected[0]}" -eq 1 ] && install_bionic_appimage
                [ "${selected[1]}" -eq 1 ] && install_darktable_appimage
                [ "${selected[2]}" -eq 1 ] && install_deepseek_harness_appimage
                [ "${selected[3]}" -eq 1 ] && download_devpod_appimage
                [ "${selected[4]}" -eq 1 ] && install_eden_appimage
                [ "${selected[5]}" -eq 1 ] && install_jan_appimage
                [ "${selected[6]}" -eq 1 ] && install_koboldcpp
                [ "${selected[7]}" -eq 1 ] && install_lmms_appimage
                [ "${selected[8]}" -eq 1 ] && install_localai
                [ "${selected[9]}" -eq 1 ] && install_musescore_appimage
                [ "${selected[10]}" -eq 1 ] && install_prism_llamacpp
                [ "${selected[11]}" -eq 1 ] && install_qtscrcpy_appimage
                [ "${selected[12]}" -eq 1 ] && install_unsloth_appimage

                echo -e "\n${GREEN}${BOLD}[+] Selected AppImage installations complete!${NC}"
                read -rp "Press Enter to continue..." _
                ;;
            *)
                local valid=0
                for token in $(echo "$choice" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#apps[@]}" ]; then
                        local idx=$((token - 1))
                        selected[idx]=$((1 - selected[idx]))
                        valid=1
                    fi
                done
                if [ "$valid" -eq 0 ]; then
                    echo -e "${RED}Invalid selection.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

run_appimage_compact() {
    local appimages_dir="$HOME/AppImages"
    if [ ! -d "$appimages_dir" ]; then
        echo -e "${YELLOW}• Directory $appimages_dir does not exist.${NC}"
        return 0
    fi

    shopt -s nullglob nocaseglob
    local appimages=("$appimages_dir"/*.appimage)
    shopt -u nullglob nocaseglob

    if [ "${#appimages[@]}" -eq 0 ]; then
        echo -e "${YELLOW}• No .AppImage files found in $appimages_dir.${NC}"
        return 0
    fi

    # Initialize selection state array (all default to unselected 0)
    local selected=()
    local i
    for i in "${!appimages[@]}"; do
        selected[i]=0
    done

    while true; do
        clear
        echo -e "${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       Compact & Configure Portable AppImages        ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo " Toggle items with their number (checkbox [X] / [ ])."
        echo -e "${BLUE}-----------------------------------------------------${NC}"

        for i in "${!appimages[@]}"; do
            local mark=" "
            [ "${selected[i]}" -eq 1 ] && mark="X"
            local fname
            fname="$(basename "${appimages[i]}")"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "$fname"
        done

        echo -e "${BLUE}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) RUN on selected AppImages"
        echo "   0) Cancel / Back"
        echo -e "${BLUE}=====================================================${NC}"

        read -rp "Enter choice: " input
        case "$input" in
            0|[Qq]|back)
                return 0
                ;;
            [Aa])
                # Check if all are currently selected
                local all_set=1
                for i in "${!appimages[@]}"; do
                    if [ "${selected[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                local new_state=$((1 - all_set))
                for i in "${!appimages[@]}"; do
                    selected[i]=$new_state
                done
                ;;
            [Rr])
                local to_process=()
                for i in "${!appimages[@]}"; do
                    [ "${selected[i]}" -eq 1 ] && to_process+=("${appimages[i]}")
                done

                if [ "${#to_process[@]}" -eq 0 ]; then
                    echo -e "\n${YELLOW}No AppImages selected. Mark at least one with its number.${NC}"
                    sleep 1.5
                    continue
                fi

                echo -e "\n${BLUE}Processing ${#to_process[@]} selected AppImage(s)...${NC}"
                local count=0
                local appimage
                for appimage in "${to_process[@]}"; do
                    [ -f "$appimage" ] || continue
                    local fname
                    fname="$(basename "$appimage")"
                    echo -e "\n${CYAN}[*] Processing $fname...${NC}"
                    chmod +x "$appimage" 2>/dev/null || true

                    if [ -x "$appimages_dir/appimageupdatetool.AppImage" ] && [ "$fname" != "appimageupdatetool.AppImage" ]; then
                        echo -e "    Checking updates with appimageupdatetool..."
                        (cd "$appimages_dir" && ./"appimageupdatetool.AppImage" "$fname" 2>/dev/null || true)
                    fi

                    echo -e "    Setting up portable config and home..."
                    (cd "$appimages_dir" && ./"$fname" --appimage-portable-config 2>/dev/null || true)
                    (cd "$appimages_dir" && ./"$fname" --appimage-portable-home 2>/dev/null || true)
                    count=$((count + 1))
                done

                echo -e "\n${GREEN}✓ Finished processing $count AppImage(s).${NC}"
                read -rp "Press Enter to return..." _
                return 0
                ;;
            *)
                # Support single numbers or space/comma separated list: e.g. 1 3 4
                local valid=0
                for token in $(echo "$input" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#appimages[@]}" ]; then
                        local idx=$((token - 1))
                        selected[idx]=$((1 - selected[idx]))
                        valid=1
                    fi
                done
                if [ "$valid" -eq 0 ]; then
                    echo -e "${RED}Invalid selection.${NC}"
                    sleep 1
                fi
                ;;
        esac
    done
}

run_all() {
    configure_homebrew
    install_pixi
    update_terminal_utilities
    setup_distrobox
    configure_flathub_user
    configure_fedora_flatpak_user
    configure_pipewire_streaming
    setup_waydroid
    echo -e "\n${GREEN}${BOLD}All setup steps have been completed!${NC}\n"
}

# Non-interactive CLI flag handling
if [ "$1" == "--all" ]; then
    run_all
    exit 0
elif [ "$1" == "--brew" ]; then
    configure_homebrew
    exit 0
elif [ "$1" == "--pixi" ]; then
    install_pixi
    exit 0
elif [ "$1" == "--terminal" ]; then
    update_terminal_utilities
    exit 0
elif [ "$1" == "--distrobox" ]; then
    setup_distrobox
    exit 0
elif [ "$1" == "--flathub" ]; then
    configure_flathub_user
    exit 0
elif [ "$1" == "--fedora-flatpak" ]; then
    configure_fedora_flatpak_user
    exit 0
elif [ "$1" == "--pipewire" ]; then
    configure_pipewire_streaming
    exit 0
elif [ "$1" == "--waydroid" ]; then
    setup_waydroid
    exit 0
elif [ "$1" == "--cleanup" ]; then
    cleanup_system
    exit 0
elif [ "$1" == "--superposition" ] || [ "$1" == "--unigine" ]; then
    install_unigine_superposition
    exit 0
elif [ "$1" == "--libvirt" ]; then
    configure_libvirt
    exit 0
elif [ "$1" == "--vagrant" ]; then
    configure_vagrant
    exit 0
elif [ "$1" == "--appimages" ] || [ "$1" == "--appimage-hub" ]; then
    appimage_hub_menu
    exit 0
elif [ "$1" == "--bionic" ]; then
    install_bionic_appimage
    exit 0
elif [ "$1" == "--darktable" ]; then
    install_darktable_appimage
    exit 0
elif [ "$1" == "--eden" ]; then
    install_eden_appimage
    exit 0
elif [ "$1" == "--jan" ]; then
    install_jan_appimage
    exit 0
elif [ "$1" == "--lmms" ]; then
    install_lmms_appimage
    exit 0
elif [ "$1" == "--musescore" ]; then
    install_musescore_appimage
    exit 0
elif [ "$1" == "--qtscrcpy" ]; then
    install_qtscrcpy_appimage
    exit 0
elif [ "$1" == "--unsloth" ]; then
    install_unsloth_appimage
    exit 0
elif [ "$1" == "--deepseek" ] || [ "$1" == "--dsh" ]; then
    setup_deepseek_harness
    exit 0
elif [ "$1" == "--prism" ] || [ "$1" == "--llamacpp" ]; then
    install_prism_llamacpp
    exit 0
elif [ "$1" == "--koboldcpp" ] || [ "$1" == "--kobold" ]; then
    install_koboldcpp
    exit 0
elif [ "$1" == "--localai" ] || [ "$1" == "--local-ai" ]; then
    install_localai
    exit 0
elif [ "$1" == "--openclaw" ]; then
    install_openclaw
    exit 0
elif [ "$1" == "--devpod" ]; then
    install_devpod
    exit 0
elif [ "$1" == "--compact" ]; then
    run_appimage_compact
    exit 0
fi

# Interactive Menu Loop
while true; do
    clear
    echo -e "${CYAN}=====================================================${NC}"
    echo -e "${BOLD}       Fedora Workstation - User Environment Setup   ${NC}"
    echo -e "${CYAN}=====================================================${NC}"
    echo -e " User: ${GREEN}$(whoami)${NC} | Host: ${GREEN}$(hostname)${NC}"
    echo -e "${CYAN}-----------------------------------------------------${NC}"
    echo -e "  ${BOLD}1)${NC} Configure Homebrew Environment & PATH"
    echo -e "  ${BOLD}2)${NC} Install Pixi Package Manager (pixi.sh)"
    echo -e "  ${BOLD}3)${NC} Update TLDR Cache & Terminal Utilities"
    echo -e "  ${BOLD}4)${NC} Create Ubuntu Distrobox Container"
    echo -e "  ${BOLD}5)${NC} Add Flathub Remote (User)"
    echo -e "  ${BOLD}6)${NC} Add Fedora Flatpak Remote (User)"
    echo -e "  ${BOLD}7)${NC} Configure PipeWire Audio Redirection"
    echo -e "  ${BOLD}8)${NC} Fedora Waydroid Setup Wizard"
    echo -e "  ${BOLD}9)${NC} System Cleanup & Benchmark"
    echo -e "  ${BOLD}10)${NC} Libvirt VM Helpers (autostart, port forwarding)"
    echo -e "  ${BOLD}11)${NC} Vagrant VMs (Ubuntu, YunoHost)"
    echo -e "  ${BOLD}12)${NC} ${BOLD}AppImage Hub & Local AI Engines (Bionic, Eden, Jan, etc.)${NC}"
    echo -e "  ${BOLD}13)${NC} Install DeepSeek Harness (Pixi env & dsh web)"
    echo -e "  ${BOLD}14)${NC} Install Prism llama.cpp Binaries (AppImages)"
    echo -e "  ${BOLD}15)${NC} Install KoboldCpp Standalone Binary (AppImages)"
    echo -e "  ${BOLD}16)${NC} Install LocalAI Binary / AppImage (AppImages)"
    echo -e "  ${BOLD}17)${NC} Install OpenClaw (CLI, Gateway & Distrobox .deb)"
    echo -e "  ${BOLD}18)${NC} Install DevPod (CLI & Desktop AppImage)"
    echo -e "  ${BOLD}19)${NC} Compact & Configure Portable AppImages (--appimage-portable-*)"
    echo -e "  ${BOLD}20)${NC} ${BOLD}Install / Configure Items 1-8${NC}"
    echo -e "  ${BOLD}0)${NC} Exit"
    echo -e "${CYAN}=====================================================${NC}"
    read -rp "Select an option [0-20]: " choice
    case "$choice" in
        1) configure_homebrew ;;
        2) install_pixi ;;
        3) update_terminal_utilities ;;
        4) setup_distrobox ;;
        5) configure_flathub_user ;;
        6) configure_fedora_flatpak_user ;;
        7) configure_pipewire_streaming ;;
        8) fedora_waydroid_setup_wizard ;;
        9) cleanup_system ;;
        10) configure_libvirt ;;
        11) configure_vagrant ;;
        12) appimage_hub_menu ;;
        13) setup_deepseek_harness ;;
        14) install_prism_llamacpp ;;
        15) install_koboldcpp ;;
        16) install_localai ;;
        17) install_openclaw ;;
        18) install_devpod ;;
        19) run_appimage_compact ;;
        20) run_all ;;
        0|[Qq]|exit)
            echo -e "\n${GREEN}Exiting setup. You can run this script again anytime!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option: '$choice'. Please enter 0-20.${NC}"
            ;;
    esac
    echo ""
    read -rp "Press Enter to return to the menu..." _
done
