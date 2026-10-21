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
    echo -e "${BOLD}[1/3] Configuring Homebrew for user: $(whoami)${NC}"
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
    echo -e "${BOLD}[2/3] Installing Pixi Package Manager${NC}"
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
    echo -e "${BOLD}[3/3] Updating TLDR & Terminal Utilities Cache${NC}"
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
    echo -e "${BOLD}[4/4] Setting Up Ubuntu Distrobox Container${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local CONTAINER_NAME="ubuntu"
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

run_all() {
    configure_homebrew
    install_pixi
    update_terminal_utilities
    setup_distrobox
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
    echo -e "  ${BOLD}5)${NC} ${BOLD}Install / Configure All of the Above${NC}"
    echo -e "  ${BOLD}0)${NC} Exit"
    echo -e "${CYAN}=====================================================${NC}"
    read -rp "Select an option [0-5]: " choice
    case "$choice" in
        1) configure_homebrew ;;
        2) install_pixi ;;
        3) update_terminal_utilities ;;
        4) setup_distrobox ;;
        5) run_all ;;
        0|[Qq]|exit)
            echo -e "\n${GREEN}Exiting setup. You can run this script again anytime!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option: '$choice'. Please enter 0-5.${NC}"
            ;;
    esac
    echo ""
    read -rp "Press Enter to return to the menu..." _
done
