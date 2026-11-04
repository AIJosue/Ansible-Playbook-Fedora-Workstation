#!/bin/bash
# ==============================================================================
# Setup User Environment
# Interactive Post-Install Utility for Fedora Workstation Users
# ==============================================================================
# This interactive utility allows individual users to configure developer and
# terminal tools on-demand without enforcing system-wide modifications.
#
# Supported Sections & Tools (Sorted into Logical Categories):
# [Onboarding & Automation]
# 1. Core User Onboarding Sequence (Stages 1-10 with interactive batch checkbox selection)
# 2. ujust / Universal Blue Task Runner integration (interactive recipe runner)
#
# [Developer Environments & Package Managers]
# 3. Homebrew Environment & PATH Configuration
# 4. Pixi Package Manager (https://pixi.sh)
# 5. TLDR Cache & Terminal Utilities Refresh (tldr, bat, fonts, man-db, git-lfs)
# 6. Distrobox — Ubuntu toolbox container (quay.io/toolbx/ubuntu-toolbox:latest)
# 7. User Flatpak Remotes (Flathub & Fedora OCI user remotes with checkbox selection)
#
# [AppImage Hub & Local AI Tools]
# 8. Unified AppImage Hub & Local AI Engines (15+ tools, models, launchers with batch checkbox selection)
# 9. Compact & Configure Portable AppImages (--appimage-portable-config/home with checkbox selection)
#
# [Virtualization & Android Emulation]
# 10. Fedora Waydroid Setup Wizard (Initialization, libndk, Widevine, multi-window, and APKs with checkbox selection)
# 11. Virtualization & VM Management (Libvirt autostart/ports/XML and Vagrant Ubuntu/YunoHost)
#
# [Hardware & System Utilities]
# 12. Gamepad, Joystick & VR udev Rules Configuration
# 13. PipeWire Audio Redirection (multi-user network/local streaming)
# 14. System Cleanup & Benchmarks (Podman prune, Snap snapshots, disk I/O, Unigine Superposition with checkbox selection)
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
    echo -e "Please execute this script as your regular user (e.g. 'sandbox' or 'admin')."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_repo_root() {
    local candidate
    for candidate in \
        "$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)" \
        "$HOME/Code/Terminal/Ansible-Playbook-Fedora-Workstation" \
        "$HOME/Ansible-Playbook-Fedora-Workstation"; do
        if [ -n "$candidate" ] && [ -d "$candidate/tasks" ] && [ -f "$candidate/local.yml" ]; then
            echo "$candidate"
            return 0
        fi
    done
    cd "$SCRIPT_DIR/.." 2>/dev/null && pwd
}

REPO_ROOT="$(resolve_repo_root)"
SUDO_CMD=""

require_sudo() {
    local reason="${1:-perform administrative tasks}"
    SUDO_CMD=""
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo -e "${RED}Error: sudo is required to ${reason}.${NC}"
            return 1
        fi
        if ! sudo -v; then
            echo -e "${RED}Error: sudo authentication failed.${NC}"
            return 1
        fi
        SUDO_CMD="sudo"
    fi
    return 0
}

ensure_shell_rc_line() {
    local pattern="$1"
    local comment="$2"
    local line="$3"

    if ! grep -q "$pattern" "$HOME/.bashrc" 2>/dev/null; then
        {
            echo ""
            echo "# $comment"
            echo "$line"
        } >> "$HOME/.bashrc"
        echo -e "${GREEN}✓ Added $comment hook to ~/.bashrc${NC}"
    else
        echo -e "${YELLOW}• $comment already configured in ~/.bashrc${NC}"
    fi

    if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
        touch "$HOME/.zshrc"
        if ! grep -q "$pattern" "$HOME/.zshrc" 2>/dev/null; then
            {
                echo ""
                echo "# $comment"
                echo "$line"
            } >> "$HOME/.zshrc"
            echo -e "${GREEN}✓ Added $comment hook to ~/.zshrc${NC}"
        fi
    fi
}

# FZF-enabled single item selector with fallback to basic select
fzf_select_menu() {
    local prompt="$1"
    local title="${2:-Selection}"
    shift 2
    local options=("$@")

    if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
        local choice
        choice=$(printf "%s\n" "${options[@]}" | fzf \
            --prompt="$prompt ❯ " \
            --border="rounded" \
            --border-label=" $title " \
            --pointer="❯" \
            --marker="✓" \
            --layout=reverse \
            --height=50% \
            --cycle \
            --color="border:#555555,header:bold:white,prompt:#00afff,pointer:#5fd7ff,marker:#5fd700")
        echo "$choice"
    else
        local sel
        select sel in "${options[@]}"; do
            [ -n "$sel" ] && { echo "$sel"; break; }
        done
    fi
}

# FZF-driven action menu for rich submenus with descriptions and live preview pane
fzf_action_menu() {
    local title="$1"
    local prompt="${2:-Action}"
    shift 2
    local items=("$@")

    if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
        local choice
        choice=$(printf "%b\n" "${items[@]}" | fzf \
            --delimiter="\t" \
            --with-nth=2 \
            --accept-nth=1 \
            --preview='echo -e "\n  \033[1;36m{2}\033[0m\n\n  \033[0;37m{3}\033[0m"' \
            --preview-window="right,45%,border-left,wrap" \
            --border="rounded" \
            --border-label=" $title " \
            --prompt="$prompt ❯ " \
            --pointer="❯" \
            --marker="✓" \
            --height=65% \
            --layout=reverse \
            --color="border:#555555,header:bold:white,prompt:#00afff,pointer:#5fd7ff,marker:#5fd700")
        echo "$choice"
    else
        return 99 # Signal caller to use terminal fallback
    fi
}

# FZF-driven confirmation prompt (Yes/No dialog)
fzf_confirm() {
    local question="$1"
    local default_ans="${2:-Y}" # Y or N

    if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
        local options
        if [ "$default_ans" = "Y" ] || [ "$default_ans" = "y" ]; then
            options=("Yes (proceed)" "No (cancel)")
        else
            options=("No (cancel)" "Yes (proceed)")
        fi
        local sel
        sel=$(printf "%s\n" "${options[@]}" | fzf \
            --border="rounded" \
            --border-label=" Confirm " \
            --prompt="$question ❯ " \
            --pointer="❯" \
            --height=20% \
            --layout=reverse \
            --color="border:#555555,header:bold:white,prompt:#00afff,pointer:#5fd7ff")
        [[ "$sel" =~ ^Yes ]] && return 0
        return 1
    else
        read -rp "$question [$default_ans]: " ans
        ans="${ans:-$default_ans}"
        [[ "$ans" =~ ^[Yy]$ ]] && return 0
        return 1
    fi
}

# Shared interactive checkbox menu selector.
# Leverages fzf with multi-selection if available; falls back to standard terminal prompt.
# Populates/updates global CB_SELECTED=() array for CB_ITEMS=().
# Returns: 0 = Run selected, 1 = Cancel/Back, 2 = Extra action (C)
checkbox_menu_select() {
    local title="$1"
    local subtitle="$2"
    local run_label="${3:-RUN selected tasks}"
    local cancel_label="${4:-Back to Main Menu}"
    local color="${5:-$BLUE}"
    local extra_label="${6:-}"
    local i token idx all_set new_state any_selected valid choice mark

    # If fzf is installed and running in an interactive terminal, use fzf multi-select UI
    if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
        local fzf_header="[Tab]: Toggle | [Ctrl-A]: Select All | [Ctrl-D]: Deselect All | [Enter]: ${run_label}"
        [ -n "$extra_label" ] && fzf_header+=" | [Ctrl-X]: ${extra_label}"
        fzf_header+=" | [Esc]: ${cancel_label}"

        local fzf_input=""
        for i in "${!CB_ITEMS[@]}"; do
            fzf_input+="$(printf "%02d\t%s\n" "$i" "${CB_ITEMS[i]}")"
        done

        local fzf_opts=(
            "-m"
            "--delimiter=\t"
            "--with-nth=2"
            "--accept-nth=1"
            "--border"
            "--border-label= ${title} "
            "--header=${fzf_header}"
            "--layout=reverse"
            "--height=65%"
            "--expect=ctrl-x,esc"
        )

        # Pre-select active items
        local preselect=()
        for i in "${!CB_SELECTED[@]}"; do
            [ "${CB_SELECTED[i]}" -eq 1 ] && preselect+=("${CB_ITEMS[i]}")
        done

        local out_lines
        out_lines="$(echo -n "$fzf_input" | fzf "${fzf_opts[@]}")"
        local fzf_status=$?

        # Process key triggers from fzf --expect
        local key_pressed
        key_pressed="$(echo "$out_lines" | head -n 1)"
        local selected_indices
        selected_indices="$(echo "$out_lines" | tail -n +2)"

        if [ "$key_pressed" = "esc" ] || [ $fzf_status -ne 0 ]; then
            return 1
        elif [ "$key_pressed" = "ctrl-x" ] && [ -n "$extra_label" ]; then
            return 2
        fi

        # Reset selection array
        for i in "${!CB_ITEMS[@]}"; do
            CB_SELECTED[i]=0
        done

        any_selected=0
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            idx=$((10#$line))
            CB_SELECTED[idx]=1
            any_selected=1
        done <<< "$selected_indices"

        if [ "$any_selected" -eq 0 ]; then
            echo -e "\n${YELLOW}No items selected.${NC}"
            sleep 1
            return 1
        fi
        return 0
    fi

    # Fallback to standard numbered menu if fzf is not present
    while true; do
        clear
        echo -e "${color}=====================================================${NC}"
        echo -e "${BOLD}       ${title}${NC}"
        echo -e "${color}=====================================================${NC}"
        [ -n "$subtitle" ] && echo -e "$subtitle"
        echo " Toggle items with numbers [1-${#CB_ITEMS[@]}] (e.g. 1 or 1,3)."
        echo -e "${color}-----------------------------------------------------${NC}"

        for i in "${!CB_ITEMS[@]}"; do
            mark=" "
            [ "${CB_SELECTED[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [${GREEN}%s${NC}] %s\n" "$((i + 1))" "$mark" "${CB_ITEMS[i]}"
        done

        echo -e "${color}-----------------------------------------------------${NC}"
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) ${run_label}"
        [ -n "$extra_label" ] && echo "   C) ${extra_label}"
        echo "   0) ${cancel_label}"
        echo -e "${color}=====================================================${NC}"

        read -rp "Enter choice: " choice
        case "$choice" in
            0|[Qq]|back)
                return 1
                ;;
            [Cc])
                if [ -n "$extra_label" ]; then
                    return 2
                fi
                echo -e "${RED}Invalid selection.${NC}"
                sleep 1
                ;;
            [Aa])
                all_set=1
                for i in "${!CB_ITEMS[@]}"; do
                    if [ "${CB_SELECTED[i]}" -eq 0 ]; then
                        all_set=0
                        break
                    fi
                done
                new_state=$((1 - all_set))
                for i in "${!CB_ITEMS[@]}"; do
                    CB_SELECTED[i]=$new_state
                done
                ;;
            [Rr])
                any_selected=0
                for i in "${!CB_ITEMS[@]}"; do
                    if [ "${CB_SELECTED[i]}" -eq 1 ]; then
                        any_selected=1
                        break
                    fi
                done
                if [ "$any_selected" -eq 0 ]; then
                    echo -e "\n${YELLOW}No items selected. Mark at least one with its number.${NC}"
                    sleep 1.5
                    continue
                fi
                return 0
                ;;
            *)
                valid=0
                for token in $(echo "$choice" | tr ',' ' '); do
                    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le "${#CB_ITEMS[@]}" ]; then
                        idx=$((token - 1))
                        CB_SELECTED[idx]=$((1 - CB_SELECTED[idx]))
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

configure_homebrew() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}[1/8] Configuring Homebrew for user: $(whoami)${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
    if [ ! -x "$BREW_PATH" ] && command -v brew >/dev/null 2>&1; then
        BREW_PATH="$(command -v brew)"
    fi

    local SHELLENV_LINE='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

    if [ -x "$BREW_PATH" ]; then
        echo -e "${GREEN}Found Homebrew at: ${BREW_PATH}${NC}"
        ensure_shell_rc_line "linuxbrew.*shellenv" "Homebrew environment" "$SHELLENV_LINE"
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
                ensure_shell_rc_line "linuxbrew.*shellenv" "Homebrew environment" "$SHELLENV_LINE"
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
        ensure_shell_rc_line '\.pixi/bin' "Pixi package manager" 'export PATH="$HOME/.pixi/bin:$PATH"'
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

configure_flatpak_remotes_user() {
    CB_ITEMS=(
        "Flathub Remote (dl.flathub.org/repo/flathub.flatpakrepo)"
        "Fedora Flatpak Remote (oci+https://registry.fedoraproject.org)"
    )
    CB_SELECTED=(1 1)

    checkbox_menu_select \
        "Configure User Flatpak Remotes" \
        " User: $(whoami)" \
        "RUN remote configuration" \
        "Back to Main Menu" || return 0

    echo -e "\n${BOLD}${BLUE}=== Configuring Selected User Flatpak Remotes ===${NC}"
    [ "${CB_SELECTED[0]}" -eq 1 ] && configure_flathub_user
    [ "${CB_SELECTED[1]}" -eq 1 ] && configure_fedora_flatpak_user

    echo -e "\n${GREEN}✓ Flatpak remotes configuration complete!${NC}"
    read -rp "Press Enter to continue..." _
}

disable_pipewire_streaming() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Disable PipeWire Audio Redirection           ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    require_sudo "disable audio redirection" || return 1

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

    echo -e "${YELLOW}Note: PipeWire multi-user audio setup requires administrative privileges.${NC}"
    require_sudo "configure PipeWire audio redirection" || return 1

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
    if [ ! -t 0 ]; then
        enable_pipewire_streaming
        return 0
    fi

    local pw_items=(
        "1\t🔊 Enable / Configure PipeWire Redirection\tRoute audio output across local users or machines via TCP"
        "2\t🔇 Disable / Remove PipeWire Redirection\tRemove audio routes, clean up environment files, and restore defaults"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    local pw_choice
    pw_choice=$(fzf_action_menu "PipeWire Audio Redirection" "Option" "${pw_items[@]}")
    local fzf_status=$?

    if [ $fzf_status -eq 99 ]; then
        echo -e "\n${BLUE}=====================================================${NC}"
        echo -e "${BOLD}       PipeWire Audio Redirection Menu               ${NC}"
        echo -e "${BLUE}=====================================================${NC}"
        echo "  1) Enable / Configure PipeWire Redirection"
        echo "  2) Disable / Remove PipeWire Redirection"
        echo "  0) Back to Main Menu"
        echo -e "${BLUE}-----------------------------------------------------${NC}"
        read -rp "Select an option [0-2]: " pw_choice
    fi

    case "$pw_choice" in
        1) enable_pipewire_streaming ;;
        2) disable_pipewire_streaming ;;
        *) return 0 ;;
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

    echo -e "${YELLOW}Note: Waydroid initialization requires administrative privileges.${NC}"
    require_sudo "configure Waydroid" || return 1

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
    local NDK_SCRIPT="$REPO_ROOT/Scripts/install-libndk.sh"

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
    local WIDEVINE_SCRIPT="$REPO_ROOT/Scripts/install-widevine.sh"

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
    CB_ITEMS=(
        "F-Droid Official Client"
        "Aurora Store (Google Play Client)"
        "Neo Store (Modern F-Droid Client)"
        "SmartDock Desktop Launcher"
        "XtMapper Keymapper"
        "3DMark Android Benchmark (UL Solutions)"
        "MobileRun (via uv, installs to ADB device)"
    )
    CB_SELECTED=(1 1 1 1 1 1 0) # default first 6 checked

    checkbox_menu_select \
        "Select Waydroid APKs / Add-ons to Install" \
        "" \
        "RUN installation on selected apps" \
        "Cancel / Back" || return 0

    echo -e "\n${BOLD}${BLUE}=== Installing Selected Waydroid Add-ons ===${NC}"
    [ "${CB_SELECTED[0]}" -eq 1 ] && install_fdroid_official
    [ "${CB_SELECTED[1]}" -eq 1 ] && install_aurora_store
    [ "${CB_SELECTED[2]}" -eq 1 ] && install_neostore_fdroid
    [ "${CB_SELECTED[3]}" -eq 1 ] && install_smartdock
    [ "${CB_SELECTED[4]}" -eq 1 ] && install_xtmapper
    [ "${CB_SELECTED[5]}" -eq 1 ] && install_3dmark
    [ "${CB_SELECTED[6]}" -eq 1 ] && install_mobilerun
    echo -e "\n${GREEN}${BOLD}[+] Completed installation of selected apps!${NC}"
    read -rp "Press Enter to continue..." _
}

apply_bazzite_waydroid_config() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Install Bazzite Custom Waydroid Files         ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    local SOURCE_DIR="$REPO_ROOT/files/waydroid"

    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "${RED}[ERROR] Source directory not found: $SOURCE_DIR${NC}"
        return 1
    fi

    echo -e "${BLUE}[*] Copying container control scripts to /usr/libexec and /usr/bin...${NC}"
    sudo install -m 0755 "$SOURCE_DIR/waydroid-container-start" /usr/libexec/waydroid-container-start
    sudo install -m 0755 "$SOURCE_DIR/waydroid-container-stop" /usr/libexec/waydroid-container-stop
    sudo install -m 0755 "$SOURCE_DIR/waydroid-container-restart" /usr/libexec/waydroid-container-restart
    sudo install -m 0755 "$SOURCE_DIR/waydroid-fix-controllers" /usr/libexec/waydroid-fix-controllers
    sudo install -m 0755 "$SOURCE_DIR/waydroid-choose-gpu" /usr/bin/waydroid-choose-gpu
    sudo install -m 0755 "$SOURCE_DIR/waydroid-launcher" /usr/bin/waydroid-launcher

    echo -e "${BLUE}[*] Copying launcher defaults to /etc/default/waydroid-launcher...${NC}"
    sudo install -m 0644 "$SOURCE_DIR/waydroid-launcher.default" /etc/default/waydroid-launcher

    echo -e "${BLUE}[*] Installing Polkit policy and rules for unprivileged container control...${NC}"
    sudo mkdir -p /usr/share/polkit-1/actions /usr/share/polkit-1/rules.d
    sudo install -m 0644 "$SOURCE_DIR/org.bazzite.waydroid.policy" /usr/share/polkit-1/actions/org.bazzite.waydroid.policy
    sudo install -m 0644 "$SOURCE_DIR/30-waydroid.rules" /usr/share/polkit-1/rules.d/30-waydroid.rules

    echo -e "${GREEN}[+] Successfully applied Bazzite Waydroid custom files and policies!${NC}"
}

waydroid_troubleshooting_menu() {
    local ts_items=(
        "1\t🚀 Manual Start: Start Container\tsudo waydroid container start"
        "2\t🚀 Manual Start: Start Session\twaydroid session start"
        "3\t🖥️ Launch UI: Full-Screen Mode\twaydroid show-full-ui"
        "4\t🪟 Window Mode: Enable Multi-Window\twaydroid prop set persist.waydroid.multi_windows true"
        "5\t🪟 Window Mode: Disable Multi-Window\twaydroid prop set persist.waydroid.multi_windows false"
        "6\t🛑 Stop Session & Container\tCleanly stop waydroid session and LXC container"
        "7\t🧹 Reinstall / Full Cleanup\tCompletely reset and wipe Waydroid images and data"
        "8\t📖 View Manual Startup & Reinstall Guide\tDisplay troubleshooting information and manual commands"
        "0\t🚪 Back to Waydroid Menu\tReturn to previous menu"
    )

    while true; do
        local ts_choice
        ts_choice=$(fzf_action_menu "Waydroid Troubleshooting & Maintenance" "Troubleshoot" "${ts_items[@]}")
        local fzf_status=$?

        if [ $fzf_status -eq 99 ]; then
            clear
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       Waydroid Troubleshooting & Maintenance        ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "  ${BOLD}1)${NC} Manual Start: Start Container (sudo waydroid container start)"
            echo -e "  ${BOLD}2)${NC} Manual Start: Start Session (waydroid session start)"
            echo -e "  ${BOLD}3)${NC} Launch UI: Full-Screen Mode (waydroid show-full-ui)"
            echo -e "  ${BOLD}4)${NC} Window Mode: Enable Multi-Window Mode"
            echo -e "  ${BOLD}5)${NC} Window Mode: Disable Multi-Window (Full-Screen Default)"
            echo -e "  ${BOLD}6)${NC} Stop Session & Container (Clean Shutdown)"
            echo -e "  ${BOLD}7)${NC} Reinstall / Full Cleanup (Wipe and Reset Waydroid Data)"
            echo -e "  ${BOLD}8)${NC} View Manual Startup & Reinstall Guide (Troubleshooting Info)"
            echo -e "  ${BOLD}0)${NC} Back to Waydroid Menu"
            echo -e "${BLUE}=====================================================${NC}"
            read -rp "Select an option [0-8]: " ts_choice
        fi

        case "$ts_choice" in
            1)
                echo -e "\n${BLUE}[*] Starting Waydroid container (root)...${NC}"
                sudo waydroid container start
                ;;
            2)
                echo -e "\n${BLUE}[*] Starting Waydroid user session...${NC}"
                echo -e "${YELLOW}[i] Note: Keep this running. When 'Android with user 0 is ready' appears, launch apps from menu or show UI.${NC}"
                waydroid session start
                ;;
            3)
                echo -e "\n${BLUE}[*] Launching Waydroid in full-screen mode...${NC}"
                waydroid show-full-ui
                ;;
            4)
                echo -e "\n${BLUE}[*] Enabling Waydroid multi-window mode...${NC}"
                waydroid prop set persist.waydroid.multi_windows true
                echo -e "${GREEN}[+] persist.waydroid.multi_windows set to true.${NC}"
                if fzf_confirm "Restart session now to apply?" "N"; then
                    echo -e "${BLUE}[*] Stopping session...${NC}"
                    waydroid session stop 2>/dev/null || true
                    echo -e "${GREEN}[+] Session stopped. Launch an app from the applications menu to start in multi-window mode.${NC}"
                fi
                ;;
            5)
                echo -e "\n${BLUE}[*] Disabling multi-window mode...${NC}"
                waydroid prop set persist.waydroid.multi_windows false
                echo -e "${GREEN}[+] persist.waydroid.multi_windows set to false.${NC}"
                if fzf_confirm "Restart session now to apply?" "N"; then
                    echo -e "${BLUE}[*] Stopping session...${NC}"
                    waydroid session stop 2>/dev/null || true
                    echo -e "${GREEN}[+] Session stopped.${NC}"
                fi
                ;;
            6)
                echo -e "\n${BLUE}[*] Stopping Waydroid session and container...${NC}"
                waydroid session stop 2>/dev/null || true
                sudo waydroid container stop 2>/dev/null || true
                echo -e "${GREEN}[+] Waydroid session and container stopped.${NC}"
                ;;
            7)
                echo -e "\n${RED}=====================================================${NC}"
                echo -e "${RED}${BOLD}  WARNING: REINSTALL & WIPE WAYDROID DATA            ${NC}"
                echo -e "${RED}=====================================================${NC}"
                echo "This will:"
                echo "  1. Stop Waydroid session and container"
                echo "  2. Optionally remove waydroid package via dnf"
                echo "  3. Remove data dirs: /var/lib/waydroid, /home/.waydroid,"
                echo "     ~/waydroid, ~/.share/waydroid, ~/.local/share/applications/*aydroid*,"
                echo "     and ~/.local/share/waydroid"
                echo -e "${RED}-----------------------------------------------------${NC}"
                if ! fzf_confirm "Are you sure you want to proceed?" "N"; then
                    echo -e "${YELLOW}Aborted.${NC}"
                    read -rp "Press Enter to continue..." _
                    continue
                fi

                echo -e "\n${BLUE}[*] Step 1: Stopping session and container...${NC}"
                waydroid session stop 2>/dev/null || true
                sudo waydroid container stop 2>/dev/null || true

                if fzf_confirm "Remove waydroid package via dnf?" "N"; then
                    echo -e "${BLUE}[*] Removing waydroid package...${NC}"
                    sudo dnf remove -y waydroid
                fi

                echo -e "${BLUE}[*] Step 2: Cleaning up Waydroid state and rootfs directories...${NC}"
                sudo rm -rf /var/lib/waydroid /home/.waydroid
                rm -rf "$HOME/waydroid" "$HOME/.share/waydroid" "$HOME/.local/share/waydroid"
                rm -f "$HOME/.local/share/applications/"*aydroid* 2>/dev/null || true

                echo -e "${GREEN}[+] Cleanup complete! You can reinstall or re-initialize Waydroid now.${NC}"
                echo -e "${YELLOW}[i] If you removed the package, a system reboot is recommended before reinstalling.${NC}"
                ;;
            8)
                clear
                echo -e "${BLUE}=====================================================${NC}"
                echo -e "${BOLD}       Waydroid Troubleshooting & Manual Setup Guide ${NC}"
                echo -e "${BLUE}=====================================================${NC}"
                cat << 'EOF'
Manually Starting Waydroid:
---------------------------
To start Waydroid without systemctl:

1. Start container first (in terminal 1):
     sudo waydroid container start

2. Start session (without sudo, in terminal 2):
     waydroid session start

3. Once "Android with user 0 is ready" appears:
   - Launch app from application menu, or
   - Launch full-screen mode:
       waydroid show-full-ui

Multi-Window Mode:
------------------
1. Set property while session is running:
     waydroid prop set persist.waydroid.multi_windows true
2. Restart session:
     waydroid session stop
3. Launch an app; it will open in multi-window mode.

Reinstalling / Complete Reset:
------------------------------
1. Stop session and container:
     waydroid session stop
     sudo waydroid container stop

2. (Optional) Remove package:
     sudo dnf remove waydroid   # on Fedora (or apt remove on Debian/Ubuntu)
     sudo reboot

3. Wipe data directories:
     sudo rm -rf /var/lib/waydroid /home/.waydroid
     rm -rf ~/waydroid ~/.share/waydroid ~/.local/share/waydroid
     rm -f ~/.local/share/applications/*aydroid*

4. Run launcher setup wizard again to re-init:
     ./Scripts/launcher.sh --waydroid
EOF
                ;;
            *)
                break
                ;;
        esac
        echo ""
        read -rp "Press Enter to continue..." _
    done
}

fedora_waydroid_setup_wizard() {
    local w_items=(
        "1\t📦 Select & Install APKs / Add-ons\tCheckbox multi-selector for F-Droid, Aurora, SmartDock, 3DMark, etc."
        "2\t🚀 Run Full Waydroid Setup\tAutomated pipeline: Initialize images, install libndk, and install Widevine"
        "3\t📱 Initialize Waydroid Container\tRun waydroid init (GAPPS or Vanilla image selection)"
        "4\t⚙️  Manage libndk ARM Translation\tInstall or remove native ARM/ARM64 bridge for AMD/Intel"
        "5\t🔒 Manage Widevine DRM\tInstall or remove Google Widevine L3 DRM support"
        "6\t🛡️  Deploy Bazzite Custom Files\tInstall container control scripts, defaults, and Polkit rules"
        "7\t🎮 GPU Selection\tConfigure primary render node and GPU switching (waydroid-choose-gpu)"
        "8\t🕹️  Fix Controller Events\tSync Steam/controller inputs via uevents"
        "9\t👆 Toggle Fake Touch\tToggle persist.waydroid.fake_touch for touchscreen simulation"
        "10\t📲 Install Single APK / Add-on\tInteractive selector for individual tools and benchmarks"
        "11\t🔧 Troubleshooting & Maintenance\tSession startup, multi-window toggles, clean reinstall"
        "0\t🚪 Back to Main Menu\tReturn to primary launcher menu"
    )

    while true; do
        local w_choice
        w_choice=$(fzf_action_menu "Fedora Waydroid Setup Wizard" "Waydroid" "${w_items[@]}")
        local fzf_status=$?

        if [ $fzf_status -eq 99 ]; then
            clear
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       Fedora Waydroid Setup Wizard                  ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "  ${BOLD}1)${NC} ${BOLD}Select & Install APKs / Add-ons (Checkbox Menu)${NC}"
            echo -e "  ${BOLD}2)${NC} Run Full Waydroid Setup (Init + libndk + Widevine)"
            echo -e "${BLUE}-----------------------------------------------------${NC}"
            echo -e "  ${BOLD}3)${NC} Initialize Waydroid (Images, Service, GAPPS/Vanilla)"
            echo -e "  ${BOLD}4)${NC} Install / Manage libndk ARM Translation"
            echo -e "  ${BOLD}5)${NC} Install / Manage Widevine DRM"
            echo -e "  ${BOLD}6)${NC} Deploy Bazzite Custom Waydroid Files (Scripts, Defaults, Polkit)"
            echo -e "  ${BOLD}7)${NC} GPU Selection (Multi-GPU / Render Node)"
            echo -e "  ${BOLD}8)${NC} Fix Controller Events (Steam/Gamepad Input Sync)"
            echo -e "  ${BOLD}9)${NC} Toggle Fake Touch (waydroid prop set persist.waydroid.fake_touch)"
            echo -e "  ${BOLD}10)${NC} Install Single APK / Add-on (F-Droid, Aurora, 3DMark, etc.)"
            echo -e "${BLUE}-----------------------------------------------------${NC}"
            echo -e "  ${BOLD}11)${NC} Troubleshooting & Maintenance (Manual Start, Multi-Window, Reinstall)"
            echo -e "  ${BOLD}0)${NC} Back to Main Menu"
            echo -e "${BLUE}=====================================================${NC}"
            read -rp "Select an option [0-11]: " w_choice
        fi

        case "$w_choice" in
            1)
                install_all_waydroid_apps
                ;;
            2)
                run_waydroid_init_wizard
                if [[ -f "$REPO_ROOT/Scripts/install-libndk.sh" ]]; then
                    sudo "$REPO_ROOT/Scripts/install-libndk.sh" install
                fi
                if [[ -f "$REPO_ROOT/Scripts/install-widevine.sh" ]]; then
                    sudo "$REPO_ROOT/Scripts/install-widevine.sh" install
                fi
                ;;
            3)
                run_waydroid_init_wizard
                ;;
            4)
                manage_libndk
                ;;
            5)
                manage_widevine
                ;;
            6)
                apply_bazzite_waydroid_config
                read -rp "Press Enter to continue..." _
                ;;
            7)
                if [ -x "/usr/bin/waydroid-choose-gpu" ]; then
                    sudo /usr/bin/waydroid-choose-gpu
                else
                    echo -e "${YELLOW}[!] /usr/bin/waydroid-choose-gpu not found. Deploying Bazzite custom files now...${NC}"
                    apply_bazzite_waydroid_config
                    sudo /usr/bin/waydroid-choose-gpu
                fi
                read -rp "Press Enter to continue..." _
                ;;
            8)
                if [ -x "/usr/libexec/waydroid-fix-controllers" ]; then
                    sudo /usr/libexec/waydroid-fix-controllers
                    echo -e "${GREEN}[+] Controller uevents triggered successfully.${NC}"
                else
                    echo add | sudo tee /sys/devices/virtual/input/input*/event*/uevent >/dev/null 2>&1 || true
                    echo -e "${GREEN}[+] Fallback controller uevents triggered.${NC}"
                fi
                read -rp "Press Enter to continue..." _
                ;;
            9)
                local cur_ft
                cur_ft=$(waydroid prop get persist.waydroid.fake_touch 2>/dev/null || echo "not set")
                echo -e "Current fake_touch setting: ${BOLD}$cur_ft${NC}"
                if [ "$cur_ft" = "1" ] || [ "$cur_ft" = "true" ]; then
                    waydroid prop set persist.waydroid.fake_touch 0
                    echo -e "${YELLOW}[*] Set persist.waydroid.fake_touch = 0 (Disabled)${NC}"
                else
                    waydroid prop set persist.waydroid.fake_touch 1
                    echo -e "${GREEN}[*] Set persist.waydroid.fake_touch = 1 (Enabled)${NC}"
                fi
                read -rp "Press Enter to continue..." _
                ;;
            10)
                local apk_items=(
                    "1\tF-Droid (Official APK)\tOfficial Free and Open Source Android App Repository"
                    "2\tAurora Store (Google Play Client)\tDownload Google Play apps anonymously without Google account"
                    "3\tNeo Store (Modern F-Droid Client)\tModern Material You design client for F-Droid repositories"
                    "4\tSmartDock (Desktop UI / Dock)\tDesktop-style navigation dock and taskbar for Waydroid"
                    "5\tXtMapper (Keymapper / Controller)\tMap gamepad and keyboard inputs for Android games"
                    "6\t3DMark (Android Benchmark APK)\tGraphics & gaming benchmark from UL Solutions"
                    "7\tMobileRun (via uv, installs to ADB device)\tFast automation and test harness for Android apps"
                    "0\tBack\tReturn to Waydroid menu"
                )
                local apk_choice
                apk_choice=$(fzf_action_menu "Install Single Waydroid APK" "APK" "${apk_items[@]}")
                case "$apk_choice" in
                    1) install_fdroid_official ;;
                    2) install_aurora_store ;;
                    3) install_neostore_fdroid ;;
                    4) install_smartdock ;;
                    5) install_xtmapper ;;
                    6) install_3dmark ;;
                    7) install_mobilerun ;;
                    *) ;;
                esac
                ;;
            11)
                waydroid_troubleshooting_menu
                ;;
            0|[Qq]|back)
                break
                ;;
            *)
                echo -e "\n${RED}Invalid option: '$w_choice'.${NC}"
                ;;
        esac
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
    CB_ITEMS=(
        "Podman system prune (containers, networks, dangling images)"
        "Podman system prune ALL (-a --volumes: unused images & volumes)"
        "Remove saved Snap snapshots"
        "Folder read/write benchmark (direct I/O dd test)"
        "Download & Setup Unigine Superposition Benchmark (.run)"
    )
    CB_SELECTED=(1 0 1 0 0)

    checkbox_menu_select \
        "System Cleanup & Benchmark" \
        "" \
        "RUN selected cleanup & benchmark tasks" \
        "Back to Main Menu" || return 0

    echo -e "\n${BOLD}${BLUE}=== Executing Selected Cleanup & Benchmark Tasks ===${NC}"
    [ "${CB_SELECTED[0]}" -eq 1 ] && prune_podman
    [ "${CB_SELECTED[1]}" -eq 1 ] && prune_podman_all
    [ "${CB_SELECTED[2]}" -eq 1 ] && forget_snap_snapshots
    [ "${CB_SELECTED[3]}" -eq 1 ] && benchmark_folder
    [ "${CB_SELECTED[4]}" -eq 1 ] && install_unigine_superposition

    echo -e "\n${GREEN}✓ Cleanup and benchmark tasks completed!${NC}"
    read -rp "Press Enter to continue..." _
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
    vm="$(fzf_select_menu "Select VM to autostart" "Libvirt VMs" "${vms[@]}" "Cancel")"
    [ -z "$vm" ] || [ "$vm" = "Cancel" ] && return 0
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
    local dir="$HOME/Platforms/Virtualization/kvm-qemu"
    [ -n "$(ls "$dir"/*.xml 2>/dev/null)" ] || dir="$REPO_ROOT/VMs"
    local xmls=("$dir"/*.xml)
    if [ ! -f "${xmls[0]}" ]; then
        echo -e "${YELLOW}• No VM XML files found in $dir.${NC}"
        return 0
    fi

    CB_ITEMS=()
    CB_SELECTED=()
    local i
    for i in "${!xmls[@]}"; do
        CB_ITEMS[i]="$(basename "${xmls[i]}")"
        CB_SELECTED[i]=1
    done

    checkbox_menu_select \
        "Define Libvirt VMs from XML" \
        " Source directory: $dir" \
        "RUN define on selected XMLs" \
        "Cancel / Back" || return 0

    local to_define=()
    for i in "${!xmls[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_define+=("${xmls[i]}")
    done

    echo -e "\n${BLUE}Defining ${#to_define[@]} VM(s)...${NC}"
    local f
    for f in "${to_define[@]}"; do
        sudo virsh define "$f" && echo -e "${GREEN}✓ Defined $(basename "$f").${NC}"
    done
    read -rp "Press Enter to return..." _
}

start_default_libvirt_network() {
    if ! command -v virsh >/dev/null 2>&1; then
        echo -e "${RED}Error: 'virsh' is not installed.${NC}"
        return 1
    fi
    echo -e "${BLUE}[*] Starting and autostarting libvirt 'default' network...${NC}"
    sudo virsh net-start default 2>/dev/null || true
    sudo virsh net-autostart default 2>/dev/null || true

    if sudo virsh net-info default 2>/dev/null; then
        echo -e "${GREEN}✓ Libvirt 'default' network configured and verified.${NC}"
    else
        echo -e "${YELLOW}• Unable to query 'default' network info.${NC}"
    fi
}

list_virt_builder_templates() {
    if ! command -v virt-builder >/dev/null 2>&1; then
        echo -e "${RED}Error: 'virt-builder' is not installed.${NC}"
        echo -e "${YELLOW}Install it with: sudo dnf install libguestfs-tools-c${NC}"
        return 1
    fi
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Available virt-builder OS Templates           ${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    virt-builder --list
}

build_virt_builder_vm() {
    if ! command -v virt-builder >/dev/null 2>&1; then
        echo -e "${RED}Error: 'virt-builder' is not installed.${NC}"
        echo -e "${YELLOW}Install it with: sudo dnf install libguestfs-tools-c${NC}"
        return 1
    fi

    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Build VM Image with virt-builder              ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local my_arch
    my_arch="$(uname -m)"

    # Common / Popular templates for quick selection
    local popular_templates=(
        "debian-12:Debian 12 (bookworm)"
        "debian-13:Debian 13 (trixie)"
        "fedora-41:Fedora 41 Server"
        "fedora-42:Fedora 42 Server"
        "ubuntu-20.04:Ubuntu 20.04 (focal)"
        "centosstream-9:CentOS Stream 9"
        "alma-8.5:AlmaLinux 8.5"
        "opensuse-tumbleweed:openSUSE Tumbleweed"
    )

    echo -e "${BOLD}Select an OS template:${NC}"
    local i
    for i in "${!popular_templates[@]}"; do
        local t_id="${popular_templates[i]%%:*}"
        local t_desc="${popular_templates[i]#*:}"
        printf "  %d) %-22s (%s)\n" "$((i + 1))" "$t_id" "$t_desc"
    done
    echo "  M) Browse & select from ALL available templates ($my_arch)"
    echo "  C) Custom template name (enter manually)"
    echo "  0) Cancel"
    echo -e "${BLUE}-----------------------------------------------------${NC}"

    local os_template=""
    while true; do
        read -rp "Select template [1-${#popular_templates[@]}, M, C, 0] (default: 1): " t_choice
        t_choice="${t_choice:-1}"
        case "$t_choice" in
            0|[Qq]|back) return 0 ;;
            [Cc])
                read -rp "Enter exact template name: " os_template
                [ -n "$os_template" ] && break
                ;;
            [Mm])
                echo -e "${BLUE}Fetching full template list for $my_arch...${NC}"
                local all_templates=()
                mapfile -t all_templates < <(virt-builder --list 2>/dev/null | awk -v arch="$my_arch" '{print $1 "\t" $0}')
                if [ "${#all_templates[@]}" -eq 0 ]; then
                    echo -e "${YELLOW}No templates found for $my_arch. Please enter manually.${NC}"
                    read -rp "Template name: " os_template
                    [ -n "$os_template" ] && break
                else
                    if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
                        local sel_line
                        sel_line="$(printf "%s\n" "${all_templates[@]}" | fzf \
                            --delimiter="\t" \
                            --with-nth=2 \
                            --accept-nth=1 \
                            --prompt="Template > " \
                            --border \
                            --border-label=" All virt-builder Templates ($my_arch) " \
                            --layout=reverse \
                            --height=60%)"
                        if [ -n "$sel_line" ]; then
                            os_template="$sel_line"
                            break
                        fi
                    else
                        local tmpl_names=()
                        mapfile -t tmpl_names < <(virt-builder --list 2>/dev/null | awk -v arch="$my_arch" '$2 == arch {print $1}')
                        echo -e "${BOLD}Select a template from full list:${NC}"
                        select sel_tmpl in "${tmpl_names[@]}" "Cancel"; do
                            [ "$sel_tmpl" = "Cancel" ] && return 0
                            if [ -n "$sel_tmpl" ]; then
                                os_template="$sel_tmpl"
                                break 2
                            fi
                        done
                    fi
                fi
                ;;
            *)
                if [[ "$t_choice" =~ ^[0-9]+$ ]] && [ "$t_choice" -ge 1 ] && [ "$t_choice" -le "${#popular_templates[@]}" ]; then
                    local sel_entry="${popular_templates[$((t_choice - 1))]}"
                    os_template="${sel_entry%%:*}"
                    break
                else
                    echo -e "${RED}Invalid selection.${NC}"
                fi
                ;;
        esac
    done

    echo -e "${GREEN}✓ Selected template: $os_template${NC}\n"

    # Destination and sizing
    local default_img_name="${os_template}-vm.qcow2"
    read -rp "Output image name (under /var/lib/libvirt/images) [default: $default_img_name]: " img_name
    img_name="${img_name:-$default_img_name}"

    local output_path="/var/lib/libvirt/images/$img_name"

    read -rp "Disk size [default: 20G]: " disk_size
    disk_size="${disk_size:-20G}"

    # Root Password options
    echo -e "\n${BOLD}Root Password Configuration:${NC}"
    echo "  1) Auto-generate a secure random password (printed on completion)"
    echo "  2) Enter custom root password"
    echo "  3) Disable root password (SSH key only)"
    read -rp "Select password option [1-3] (default: 1): " pwd_choice
    pwd_choice="${pwd_choice:-1}"

    local root_pwd_arg=""
    case "$pwd_choice" in
        2)
            read -s -rp "Enter root password: " custom_pwd
            echo ""
            read -s -rp "Confirm root password: " custom_pwd_confirm
            echo ""
            if [ "$custom_pwd" != "$custom_pwd_confirm" ]; then
                echo -e "${RED}Error: Passwords do not match.${NC}"
                return 1
            fi
            if [ -n "$custom_pwd" ]; then
                root_pwd_arg="password:$custom_pwd"
            else
                root_pwd_arg="generate"
            fi
            ;;
        3)
            root_pwd_arg="disabled"
            ;;
        *)
            root_pwd_arg="generate"
            ;;
    esac

    # SSH key injection
    local default_ssh_key="$HOME/.ssh/id_rsa.pub"
    [ ! -f "$default_ssh_key" ] && [ -f "$HOME/.ssh/id_ed25519.pub" ] && default_ssh_key="$HOME/.ssh/id_ed25519.pub"
    read -rp "SSH public key to inject into root [default: $default_ssh_key, or 'none']: " ssh_key
    ssh_key="${ssh_key:-$default_ssh_key}"

    require_sudo "write VM image to /var/lib/libvirt/images" || return 1
    sudo mkdir -p /var/lib/libvirt/images

    local builder_args=(
        "$os_template"
        "--output" "$output_path"
        "--format" "qcow2"
        "--size" "$disk_size"
        "--root-password" "$root_pwd_arg"
    )

    if [ "$ssh_key" != "none" ] && [ -f "$ssh_key" ]; then
        builder_args+=("--ssh-inject" "root:file:$ssh_key")
    fi

    echo -e "\n${BLUE}[*] Building VM with virt-builder...${NC}"
    echo -e "    Template: $os_template"
    echo -e "    Target:   $output_path"
    echo -e "    Size:     $disk_size"
    echo -e "    Password: $root_pwd_arg"
    [ "$ssh_key" != "none" ] && echo -e "    SSH Key:  $ssh_key"
    echo ""

    sudo virt-builder "${builder_args[@]}"

    if [ -f "$output_path" ]; then
        echo -e "\n${GREEN}=====================================================${NC}"
        echo -e "${BOLD}       VM Image Built Successfully!                  ${NC}"
        echo -e "${GREEN}=====================================================${NC}"
        echo -e "Image Path: ${CYAN}$output_path${NC}"
        echo -e "\n${BLUE}To import and run this VM immediately via virt-install:${NC}"
        echo -e "  sudo virt-install --name ${img_name%.*} --ram 2048 --vcpus 2 --disk path=$output_path --import --network network=default\n"
    else
        echo -e "\n${RED}Error: Failed to create $output_path${NC}"
        return 1
    fi
}

configure_libvirt() {
    local l_items=(
        "1\t🌐 Start & Autostart Default Network\tEnsure virbr0 default network is running and autostarts on boot"
        "2\t📋 List Available OS Templates\tView full repository of virt-builder pre-built cloud OS images"
        "3\t🏗️  Build VM Image with virt-builder\tQuickly spin up custom Fedora, Debian, Ubuntu, CentOS QCOW2 disks"
        "4\t🚀 Autostart a VM at boot\tConfigure virsh autostart for existing guest domains"
        "5\t🛡️  Forward ports to VMs\tOpen guest/host ports in firewalld libvirt zone"
        "6\t📄 Define VMs from XML\tDefine Android, Linux, Windows libvirt domains from template XMLs"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    while true; do
        local l_choice
        l_choice=$(fzf_action_menu "Libvirt VM Helpers" "Libvirt" "${l_items[@]}")
        local fzf_status=$?

        if [ $fzf_status -eq 99 ]; then
            echo -e "\n${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       Libvirt VM Helpers                            ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo "  1) Start & Autostart Default Network (default)"
            echo "  2) List Available OS Templates (virt-builder --list)"
            echo "  3) Build VM Image with virt-builder"
            echo "  4) Autostart a VM at boot"
            echo "  5) Forward ports to VMs (libvirt firewalld zone)"
            echo "  6) Define VMs from XML (Android, Linux, Windows)"
            echo "  0) Back to Main Menu"
            echo -e "${BLUE}-----------------------------------------------------${NC}"
            read -rp "Select an option [0-6]: " l_choice
        fi

        case "$l_choice" in
            1) start_default_libvirt_network ;;
            2) list_virt_builder_templates ;;
            3) build_virt_builder_vm ;;
            4) autostart_libvirt_vm ;;
            5) forward_libvirt_ports ;;
            6) define_libvirt_vms ;;
            *) return 0 ;;
        esac
    done
}

manage_vagrant_vm() {
    local name="$1"
    local dir="$HOME/Platforms/Virtualization/vagrant/$name"
    if ! command -v vagrant >/dev/null 2>&1; then
        echo -e "${RED}Error: 'vagrant' is not installed.${NC}"
        return 1
    fi
    if [ ! -f "$dir/Vagrantfile" ]; then
        echo -e "${RED}Error: $dir/Vagrantfile not found. Run the playbook first.${NC}"
        return 1
    fi

    local vg_actions=(
        "1\t▶️  Start VM\tvagrant up --provider libvirt"
        "2\t⏹️  Stop VM\tvagrant halt"
        "3\tℹ️  Status\tvagrant status"
        "4\t🔑 SSH into VM\tvagrant ssh"
        "5\t🗑️  Destroy VM\tvagrant destroy -f"
        "0\t🚪 Back\tReturn to Vagrant menu"
    )

    while true; do
        local v_choice
        v_choice=$(fzf_action_menu "Vagrant VM: $name" "Action" "${vg_actions[@]}")
        local fzf_status=$?

        if [ $fzf_status -eq 99 ]; then
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
        fi

        case "$v_choice" in
            1) (cd "$dir" && vagrant up --provider libvirt) ;;
            2) (cd "$dir" && vagrant halt) ;;
            3) (cd "$dir" && vagrant status) ;;
            4) (cd "$dir" && vagrant ssh) ;;
            5)
                if fzf_confirm "Destroy '$name' VM and its disk?" "N"; then
                    (cd "$dir" && vagrant destroy -f)
                fi
                ;;
            *) return 0 ;;
        esac
    done
}

configure_vagrant() {
    local vg_items=(
        "1\t🐧 Ubuntu 24.04 Desktop VM\tManage Noble Numbat developer workstation box"
        "2\t🌐 YunoHost Server VM\tManage Debian self-hosting application server box"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    while true; do
        local vg_choice
        vg_choice=$(fzf_action_menu "Vagrant VMs" "Vagrant" "${vg_items[@]}")
        local fzf_status=$?

        if [ $fzf_status -eq 99 ]; then
            echo -e "\n${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       Vagrant VMs                                   ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo "  1) Ubuntu"
            echo "  2) YunoHost"
            echo "  0) Back to Main Menu"
            echo -e "${BLUE}-----------------------------------------------------${NC}"
            read -rp "Select an option [0-2]: " vg_choice
        fi

        case "$vg_choice" in
            1) manage_vagrant_vm ubuntu ;;
            2) manage_vagrant_vm yunohost ;;
            *) return 0 ;;
        esac
    done
}

manage_virtualization() {
    local vm_items=(
        "1\t🌐 Start & Autostart Default Network\tsudo virsh net-start & net-autostart default (virbr0)"
        "2\t📋 List Available OS Templates\tvirt-builder --list"
        "3\t🏗️  Build VM Image with virt-builder\tCreate bootable OS qcow2 with root password & SSH injection"
        "4\t📄 Define Libvirt VMs from XML\tParse VMs/*.xml for Android, Linux, and Windows"
        "5\t🚀 Autostart Libvirt VM at boot\tConfigure domain to start with system boot"
        "6\t🛡️  Forward Ports to Libvirt VMs\tConfigure firewalld libvirt zone"
        "7\t🐧 Manage Vagrant Ubuntu 24.04\tControl Ubuntu developer desktop VM"
        "8\t🌐 Manage Vagrant YunoHost Server\tControl YunoHost server VM"
        "0\t🚪 Back to Main Menu\tReturn to primary launcher menu"
    )

    while true; do
        local vm_choice
        vm_choice=$(fzf_action_menu "Virtualization & VM Management" "Virtualization" "${vm_items[@]}")
        local fzf_status=$?

        if [ $fzf_status -eq 99 ]; then
            clear
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       Virtualization & VM Management                ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "  ${BOLD}1)${NC} Start & Autostart Default Network (virsh net-start default)"
            echo -e "  ${BOLD}2)${NC} List Available OS Templates (virt-builder --list)"
            echo -e "  ${BOLD}3)${NC} Build VM Image with virt-builder"
            echo -e "  ${BOLD}4)${NC} Define Libvirt VMs from XML (Android, Linux, Windows)"
            echo -e "  ${BOLD}5)${NC} Autostart Libvirt VM at boot"
            echo -e "  ${BOLD}6)${NC} Forward Ports to Libvirt VMs (firewalld libvirt zone)"
            echo -e "  ${BOLD}7)${NC} Manage Vagrant Ubuntu 24.04 Desktop VM"
            echo -e "  ${BOLD}8)${NC} Manage Vagrant YunoHost Server VM"
            echo -e "  ${BOLD}0)${NC} Back to Main Menu"
            echo -e "${BLUE}=====================================================${NC}"
            read -rp "Select an option [0-8]: " vm_choice
        fi

        case "$vm_choice" in
            1) start_default_libvirt_network ;;
            2) list_virt_builder_templates ;;
            3) build_virt_builder_vm ;;
            4) define_libvirt_vms ;;
            5) autostart_libvirt_vm ;;
            6) forward_libvirt_ports ;;
            7) manage_vagrant_vm ubuntu ;;
            8) manage_vagrant_vm yunohost ;;
            *) return 0 ;;
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

    CB_ITEMS=()
    CB_SELECTED=()
    local urls=()
    local name url
    while IFS=$'\t' read -r name url; do
        [ -z "$name" ] && continue
        CB_ITEMS+=("$name")
        urls+=("$url")
        CB_SELECTED+=(0)
    done <<< "$asset_lines"

    if [ "${#CB_ITEMS[@]}" -eq 0 ]; then
        echo -e "${YELLOW}• No assets found.${NC}"
        return 0
    fi

    checkbox_menu_select \
        "Select Prism llama.cpp Binaries to Install" \
        " Destination: $dest_dir" \
        "RUN download and installation on selected binaries" \
        "Cancel / Back" || return 0

    local to_download=()
    local i
    for i in "${!CB_ITEMS[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_download+=("$i")
    done

    echo -e "\n${BLUE}Downloading and extracting ${#to_download[@]} binary asset(s)...${NC}"
    for i in "${to_download[@]}"; do
        download_and_extract_prism_single_asset "${CB_ITEMS[i]}" "${urls[i]}"
    done

    echo -e "\n${GREEN}✓ Selected binaries installed in: $dest_dir${NC}"
    read -rp "Press Enter to continue..." _
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

    echo -e "${BLUE}Fetching latest release assets for LostRuins/koboldcpp...${NC}"
    local asset_lines
    asset_lines="$(fetch_koboldcpp_release_assets)"
    if [ -z "$asset_lines" ]; then
        echo -e "${RED}Error: Failed to fetch assets from LostRuins/koboldcpp.${NC}"
        return 1
    fi

    CB_ITEMS=()
    CB_SELECTED=()
    local urls=()
    local name url
    while IFS=$'\t' read -r name url; do
        [ -z "$name" ] && continue
        CB_ITEMS+=("$name")
        urls+=("$url")
        CB_SELECTED+=(0)
    done <<< "$asset_lines"

    if [ "${#CB_ITEMS[@]}" -eq 0 ]; then
        echo -e "${YELLOW}• No Linux binary assets found.${NC}"
        return 0
    fi

    checkbox_menu_select \
        "Select KoboldCpp Binaries to Download" \
        " Source: https://github.com/LostRuins/koboldcpp\n Destination: $dest_dir" \
        "RUN download on selected binaries" \
        "Back to Main Menu" || return 0

    local to_download=()
    local i
    for i in "${!CB_ITEMS[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_download+=("$i")
    done

    echo -e "\n${BLUE}Downloading ${#to_download[@]} binary asset(s) to $dest_dir...${NC}"
    for i in "${to_download[@]}"; do
        download_koboldcpp_single_binary "${CB_ITEMS[i]}" "${urls[i]}"
    done

    echo -e "\n${GREEN}✓ Selected binaries installed directly to: $dest_dir${NC}"
    read -rp "Press Enter to continue..." _
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

    echo -e "${BLUE}Fetching latest release assets for mudler/LocalAI...${NC}"
    local asset_lines
    asset_lines="$(fetch_localai_release_assets)"
    if [ -z "$asset_lines" ]; then
        echo -e "${RED}Failed to fetch release assets from GitHub API.${NC}"
        echo -e "${YELLOW}Please verify internet connection or check GitHub rate limits.${NC}"
        read -rp "Press Enter to return to menu..." _
        return 1
    fi

    CB_ITEMS=()
    CB_SELECTED=()
    local urls=()
    local asset_name asset_url
    while IFS=$'\t' read -r asset_name asset_url; do
        [ -z "$asset_name" ] && continue
        CB_ITEMS+=("$asset_name")
        urls+=("$asset_url")
        CB_SELECTED+=(0)
    done <<< "$asset_lines"

    checkbox_menu_select \
        "Select LocalAI Binaries / Launchers" \
        " Source: https://github.com/mudler/LocalAI\n Destination: $dest_dir" \
        "RUN download on selected assets" \
        "Back to Main Menu" || return 0

    local to_download=()
    local i
    for i in "${!CB_ITEMS[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_download+=("$i")
    done

    echo -e "\n${BLUE}Downloading ${#to_download[@]} asset(s) to $dest_dir...${NC}"
    for i in "${to_download[@]}"; do
        download_localai_single_asset "${CB_ITEMS[i]}" "${urls[i]}"
    done

    echo -e "\n${GREEN}✓ Selected LocalAI assets installed directly to: $dest_dir${NC}"
    read -rp "Press Enter to continue..." _
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

install_deepseek_harness_desktop_deb_distrobox() {
    local container_name="ubuntu-toolbox"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/deepseek_harness_downloads"
    mkdir -p "$cache_dir"

    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD} Install DeepSeek Harness Desktop (.deb) into Distrobox${NC}"
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

    echo -e "${BLUE}[*] Fetching latest DeepSeek Harness Desktop .deb release from GitHub...${NC}"
    local deb_info
    deb_info=$(python3 -c "
import urllib.request, json, sys
repo = 'dsh-tauri/deepseek-harness-desktop'
try:
    url = f'https://api.github.com/repos/{repo}/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.loads(r.read().decode())
    # Prioritize standard amd64 .deb over bundle
    for a in d.get('assets', []):
        name = a.get('name', '')
        url = a.get('browser_download_url', '')
        if name.lower().endswith('.deb') and 'amd64' in name.lower() and 'bundle' not in name.lower():
            print(f'{name}\t{url}')
            sys.exit(0)
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
        deb_url="https://github.com/dsh-tauri/deepseek-harness-desktop/releases/download/v0.25.2/Deepseek.Harness.Desktop_0.25.2_amd64.deb"
        deb_name="Deepseek.Harness.Desktop_0.25.2_amd64.deb"
    fi

    local target_file="$cache_dir/$deb_name"
    echo -e "${BLUE}[*] Downloading ${deb_name}...${NC}"
    if ! curl -fLC - --progress-bar -o "$target_file" "$deb_url"; then
        echo -e "${RED}[ERROR] Failed to download DeepSeek Harness Desktop .deb from $deb_url${NC}"
        return 1
    fi

    echo -e "\n${BLUE}[*] Installing ${deb_name} into '${container_name}' container via apt...${NC}"
    if distrobox enter "${container_name}" -- sudo apt-get update && \
       distrobox enter "${container_name}" -- sudo apt-get install -y "$target_file"; then
        echo -e "\n${BLUE}[*] Exporting DeepSeek Harness Desktop app and binary to host...${NC}"
        distrobox enter "${container_name}" -- distrobox-export --app deepseek-harness-desktop 2>/dev/null || true
        distrobox enter "${container_name}" -- distrobox-export --bin /usr/bin/deepseek-harness-desktop --export-path "$HOME/.local/bin" 2>/dev/null || true
        echo -e "${GREEN}✓ DeepSeek Harness Desktop (.deb) installed and exported successfully from Distrobox!${NC}"
    else
        echo -e "${RED}[ERROR] Failed to install DeepSeek Harness Desktop .deb inside distrobox container.${NC}"
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
    CB_ITEMS=(
        "Install OpenClaw CLI & Gateway Service on Host (https://openclaw.ai/install-cli.sh)"
        "Install Latest OpenClaw (.deb) into Ubuntu Distrobox & Export to Host"
    )
    CB_SELECTED=(1 1)

    checkbox_menu_select \
        "Install OpenClaw (CLI, Service & Distrobox Deb)" \
        " Source: https://github.com/openclaw/openclaw/releases" \
        "RUN selected installation steps" \
        "Back to Main Menu" || return 0

    echo -e "\n${BOLD}${BLUE}=== Executing OpenClaw Installation ===${NC}"
    [ "${CB_SELECTED[0]}" -eq 1 ] && install_openclaw_cli_gateway
    [ "${CB_SELECTED[1]}" -eq 1 ] && install_openclaw_deb_distrobox

    echo -e "\n${GREEN}✓ OpenClaw tasks finished.${NC}"
    read -rp "Press Enter to continue..." _
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

install_devpod() {
    download_devpod_cli
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

install_deepseek_harness_desktop() {
    install_deepseek_harness_desktop_deb_distrobox
}

# Unified AppImage Hub
appimage_hub_menu() {
    local hub_items=(
        "Bionic (LM Studio Agent)"
        "Darktable (Photography & RAW Developer)"
        "DeepSeek Harness Desktop (Distrobox .deb)"
        "DeepSeek Harness Web (Pixi env & dsh web in ~/AppImages)"
        "DevPod CLI (loft-sh/devpod binary into ~/.local/bin)"
        "Eden (Nintendo Switch Emulator)"
        "Jan (Open-source ChatGPT Alternative)"
        "KoboldCpp (Standalone llama.cpp & UI)"
        "LMMS (Music Production Suite)"
        "LocalAI (Multi-model local AI runtime)"
        "MuseScore Studio (Music Notation & Scoring)"
        "OpenClaw (CLI, Gateway & Distrobox .deb)"
        "Prism llama.cpp (Pre-compiled LLM inference binaries)"
        "QtScrcpy (Android Screen Mirror & Control)"
        "Unsloth (Fast LLM Finetuning & Studio)"
    )
    local hub_sel=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
    local rc

    while true; do
        CB_ITEMS=("${hub_items[@]}")
        CB_SELECTED=("${hub_sel[@]}")
        checkbox_menu_select \
            "AppImage Hub & Local AI Engines" \
            " Target Directory: $HOME/AppImages" \
            "RUN Download for Selected AppImages & AI Tools" \
            "Back to Main Menu" \
            "$BLUE" \
            "Compact & Configure Portable AppImages"
        rc=$?
        hub_sel=("${CB_SELECTED[@]}")

        if [ "$rc" -eq 1 ]; then
            return 0
        elif [ "$rc" -eq 2 ]; then
            run_appimage_compact
            continue
        fi

        echo -e "\n${BOLD}${BLUE}=== Downloading Selected AppImages & AI Tools ===${NC}"
        [ "${hub_sel[0]}" -eq 1 ] && install_bionic_appimage
        [ "${hub_sel[1]}" -eq 1 ] && install_darktable_appimage
        [ "${hub_sel[2]}" -eq 1 ] && install_deepseek_harness_desktop
        [ "${hub_sel[3]}" -eq 1 ] && setup_deepseek_harness
        [ "${hub_sel[4]}" -eq 1 ] && install_devpod
        [ "${hub_sel[5]}" -eq 1 ] && install_eden_appimage
        [ "${hub_sel[6]}" -eq 1 ] && install_jan_appimage
        [ "${hub_sel[7]}" -eq 1 ] && install_koboldcpp
        [ "${hub_sel[8]}" -eq 1 ] && install_lmms_appimage
        [ "${hub_sel[9]}" -eq 1 ] && install_localai
        [ "${hub_sel[10]}" -eq 1 ] && install_musescore_appimage
        [ "${hub_sel[11]}" -eq 1 ] && install_openclaw
        [ "${hub_sel[12]}" -eq 1 ] && install_prism_llamacpp
        [ "${hub_sel[13]}" -eq 1 ] && install_qtscrcpy_appimage
        [ "${hub_sel[14]}" -eq 1 ] && install_unsloth_appimage

        echo -e "\n${GREEN}${BOLD}[+] Selected AppImage & AI installations complete!${NC}"
        read -rp "Press Enter to continue..." _
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

    CB_ITEMS=()
    CB_SELECTED=()
    local i
    for i in "${!appimages[@]}"; do
        CB_ITEMS[i]="$(basename "${appimages[i]}")"
        CB_SELECTED[i]=0
    done

    checkbox_menu_select \
        "Compact & Configure Portable AppImages" \
        "" \
        "RUN on selected AppImages" \
        "Cancel / Back" || return 0

    local to_process=()
    for i in "${!appimages[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_process+=("${appimages[i]}")
    done

    echo -e "\n${BLUE}Processing ${#to_process[@]} selected AppImage(s)...${NC}"
    local count=0
    local appimage fname
    for appimage in "${to_process[@]}"; do
        [ -f "$appimage" ] || continue
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
}

run_ujust() {
    if ! command -v ujust >/dev/null 2>&1 && [ ! -x "/usr/bin/ujust" ]; then
        echo -e "${YELLOW}Notice: 'ujust' is not found at /usr/bin/ujust.${NC}"
        echo -e "ujust is provisioned system-wide via Ansible (tasks/ujust.yml)."
        echo -e "Run the playbook to install it: ${CYAN}sudo ansible-playbook local.yml${NC}"
        return 1
    fi

    local ujust_bin
    ujust_bin="$(command -v ujust 2>/dev/null || echo "/usr/bin/ujust")"

    local uj_items=(
        "1\t🎯 Interactive Recipe Selector\tLaunch ujust with fzf fuzzy recipe selector (ujust --choose)"
        "2\t📋 List All Available Recipes\tDisplay list of system and user defined ujust tasks"
        "3\t✨ Configure Terminal Bling\tRun ublue-bling configuration assistant"
        "4\t⌨️  Run Custom ujust Command\tExecute specific recipe with optional flags"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    while true; do
        local uj_choice
        uj_choice=$(fzf_action_menu "ujust / Universal Blue Task Runner" "ujust" "${uj_items[@]}")
        local fzf_status=$?

        if [ $fzf_status -eq 99 ]; then
            clear
            echo -e "${BLUE}=====================================================${NC}"
            echo -e "${BOLD}       ujust / Universal Blue Task Runner            ${NC}"
            echo -e "${BLUE}=====================================================${NC}"
            echo -e " Binary: ${GREEN}$ujust_bin${NC}"
            echo -e "${BLUE}-----------------------------------------------------${NC}"
            echo -e "  ${BOLD}1)${NC} Interactive Recipe Selector (ujust --choose)"
            echo -e "  ${BOLD}2)${NC} List All Available Recipes (ujust)"
            echo -e "  ${BOLD}3)${NC} Configure Terminal Bling (ublue-bling)"
            echo -e "  ${BOLD}4)${NC} Run Custom ujust Command"
            echo -e "  ${BOLD}0)${NC} Back to Main Menu"
            echo -e "${BLUE}=====================================================${NC}"
            read -rp "Select an option [0-4]: " uj_choice
        fi

        case "$uj_choice" in
            1)
                "$ujust_bin" --choose
                ;;
            2)
                "$ujust_bin"
                ;;
            3)
                if command -v ublue-bling >/dev/null 2>&1 || [ -x "/usr/bin/ublue-bling" ]; then
                    local bling_bin
                    bling_bin="$(command -v ublue-bling 2>/dev/null || echo "/usr/bin/ublue-bling")"
                    "$bling_bin"
                else
                    echo -e "${YELLOW}ublue-bling script not found in /usr/bin.${NC}"
                fi
                ;;
            4)
                read -rp "Enter ujust recipe name and arguments (e.g. 'install-brew'): " recipe_args
                if [ -n "$recipe_args" ]; then
                    # shellcheck disable=SC2086
                    "$ujust_bin" $recipe_args
                fi
                ;;
            *)
                return 0
                ;;
        esac
        echo ""
        read -rp "Press Enter to continue..." _
    done
}

configure_udev_rules() {
    echo -e "\n${BLUE}=====================================================${NC}"
    echo -e "${BOLD}       Configure Gamepad, Joystick & VR udev Rules   ${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    local UDEV_DIR="$REPO_ROOT/files/udev"

    if [ ! -d "$UDEV_DIR" ]; then
        echo -e "${RED}[ERROR] udev source directory not found: $UDEV_DIR${NC}"
        return 1
    fi

    local rules=("$UDEV_DIR"/*.rules)
    if [ ${#rules[@]} -eq 0 ] || [ ! -e "${rules[0]}" ]; then
        echo -e "${RED}[ERROR] No udev rule files found in $UDEV_DIR${NC}"
        return 1
    fi

    echo -e "${BLUE}[*] Found ${#rules[@]} udev rule file(s) in $UDEV_DIR${NC}"
    echo -e "${YELLOW}Note: Installing udev rules requires administrator privileges.${NC}"
    require_sudo "install udev rules to /etc/udev/rules.d/" || return 1

    echo -e "${BLUE}[*] Ensuring /etc/udev/rules.d exists...${NC}"
    sudo mkdir -p /etc/udev/rules.d

    echo -e "${BLUE}[*] Installing udev rules...${NC}"
    for rule in "${rules[@]}"; do
        local rname
        rname="$(basename "$rule")"
        sudo install -m 0644 "$rule" "/etc/udev/rules.d/$rname"
        echo -e "  ${GREEN}✓${NC} $rname"
    done

    echo -e "${BLUE}[*] Reloading and triggering udev rules...${NC}"
    if command -v udevadm >/dev/null 2>&1; then
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        echo -e "${GREEN}✓ udev rules reloaded and triggered successfully!${NC}"
    else
        echo -e "${YELLOW}Warning: 'udevadm' command not found. Rules copied but not reloaded.${NC}"
    fi

    echo -e "${GREEN}✓ Successfully deployed gamepad, joystick, and VR udev rules.${NC}"
}

run_all() {
    CB_ITEMS=(
        "Homebrew Environment & PATH Configuration"
        "Pixi Package Manager (pixi.sh)"
        "TLDR Cache & Terminal Utilities Refresh"
        "Ubuntu Distrobox Container Setup"
        "User Flatpak Remotes (Flathub & Fedora OCI)"
        "Gamepad, Joystick & VR udev Rules Configuration"
        "Bazzite Waydroid Custom Files & Polkit Configuration"
        "Waydroid Multi-Window Mode (persist.waydroid.multi_windows)"
        "Waydroid Subsystem Setup (Images & ARM/libndk/Widevine Setup)"
        "PipeWire Multi-User Audio Redirection"
    )
    CB_SELECTED=(1 1 1 1 1 1 1 1 0 0)

    # If non-interactive execution (e.g. CLI flag --all or piped), run default full suite automatically
    if [ ! -t 0 ]; then
        echo -e "\n${BOLD}${BLUE}=== Running Default Non-Interactive Onboarding Sequence ===${NC}"
        configure_homebrew
        install_pixi
        update_terminal_utilities
        setup_distrobox
        configure_flathub_user
        configure_fedora_flatpak_user
        configure_udev_rules
        apply_bazzite_waydroid_config 2>/dev/null || true
        waydroid prop set persist.waydroid.multi_windows true 2>/dev/null || true
        echo -e "\n${GREEN}${BOLD}All non-interactive onboarding steps completed!${NC}\n"
        return 0
    fi

    checkbox_menu_select \
        "Core User Onboarding Sequence [Checkbox Menu]" \
        " Press 'R' to run selected onboarding steps sequentially." \
        "RUN Selected Onboarding Steps" \
        "Cancel / Back to Main Menu" \
        "$CYAN" || return 0

    echo -e "\n${BOLD}${BLUE}=== Executing Selected Onboarding Sequence ===${NC}"
    [ "${CB_SELECTED[0]}" -eq 1 ] && configure_homebrew
    [ "${CB_SELECTED[1]}" -eq 1 ] && install_pixi
    [ "${CB_SELECTED[2]}" -eq 1 ] && update_terminal_utilities
    [ "${CB_SELECTED[3]}" -eq 1 ] && setup_distrobox
    if [ "${CB_SELECTED[4]}" -eq 1 ]; then
        configure_flathub_user
        configure_fedora_flatpak_user
    fi
    [ "${CB_SELECTED[5]}" -eq 1 ] && configure_udev_rules
    [ "${CB_SELECTED[6]}" -eq 1 ] && apply_bazzite_waydroid_config
    if [ "${CB_SELECTED[7]}" -eq 1 ]; then
        echo -e "\n${BLUE}[*] Configuring Waydroid Multi-Window Mode...${NC}"
        if command -v waydroid >/dev/null 2>&1; then
            waydroid prop set persist.waydroid.multi_windows true
            echo -e "${GREEN}[+] persist.waydroid.multi_windows enabled.${NC}"
        else
            echo -e "${YELLOW}[!] 'waydroid' command not yet installed; skipped setting property.${NC}"
        fi
    fi
    [ "${CB_SELECTED[8]}" -eq 1 ] && setup_waydroid
    [ "${CB_SELECTED[9]}" -eq 1 ] && configure_pipewire_streaming

    echo -e "\n${GREEN}${BOLD}Selected onboarding steps have been successfully executed!${NC}\n"
    read -rp "Press Enter to continue..." _
}

show_help() {
    cat <<'EOF'
Usage: launcher.sh [FLAG]

Flags:
  --all                           Core User Onboarding Sequence (checkbox menu)
  --ujust                         Access ujust / Universal Blue Task Runner
  --brew                          Configure Homebrew Environment & PATH
  --pixi                          Install Pixi Package Manager
  --terminal                      Update TLDR & Terminal Utilities Cache
  --distrobox                     Create Ubuntu Distrobox Container
  --flatpaks, --flatpak-remotes   Configure User Flatpak Remotes (checkbox menu)
  --flathub                       Add Flathub User Remote
  --fedora-flatpak                Add Fedora OCI User Remote
  --appimages, --appimage-hub     Unified AppImage Hub & Local AI Engines
  --compact                       Compact & Configure Portable AppImages
  --bionic | --darktable | --eden | --jan | --lmms | --musescore | --qtscrcpy | --unsloth
  --dsh-desktop, --dsh-deb        Install DeepSeek Harness Desktop (.deb) into Distrobox
  --deepseek, --dsh               Install DeepSeek Harness Web
  --devpod                        Install DevPod CLI
  --koboldcpp, --kobold           Install KoboldCpp Standalone Binary
  --localai, --local-ai           Install LocalAI Binary / AppImage
  --openclaw                      Install OpenClaw (CLI, Service & Distrobox .deb)
  --prism, --llamacpp             Install Prism llama.cpp Binaries
  --waydroid                      Fedora Waydroid Setup Wizard
  --waydroid-troubleshoot, --waydroid-fix  Waydroid Troubleshooting & Maintenance
  --vm, --vms, --virtualization   Virtualization & VM Management
  --libvirt                       Libvirt VM Helpers
  --libvirt-net, --net-default    Start & Autostart Libvirt Default Network
  --virt-builder-list, --templates List Available virt-builder OS Templates
  --virt-builder, --build-vm      Build VM Image with virt-builder
  --vagrant                       Vagrant VMs Menu
  --udev, --udev-rules            Configure Gamepad, Joystick & VR udev Rules
  --pipewire                      Configure PipeWire Audio Redirection
  --cleanup                       System Cleanup & Storage Benchmarks
  --superposition, --unigine      Download & Setup Unigine Superposition Benchmark
  -h, --help                      Show this help message
EOF
}

# Non-interactive CLI flag handling
if [ $# -gt 0 ]; then
    case "$1" in
        --all)                          run_all ;;
        --ujust)                        run_ujust ;;
        --brew)                         configure_homebrew ;;
        --pixi)                         install_pixi ;;
        --terminal)                     update_terminal_utilities ;;
        --distrobox)                    setup_distrobox ;;
        --flathub)                      configure_flathub_user ;;
        --fedora-flatpak)               configure_fedora_flatpak_user ;;
        --flatpaks|--flatpak-remotes)   configure_flatpak_remotes_user ;;
        --pipewire)                     configure_pipewire_streaming ;;
        --waydroid)                     setup_waydroid ;;
        --waydroid-troubleshoot|--waydroid-fix) waydroid_troubleshooting_menu ;;
        --cleanup)                      cleanup_system ;;
        --superposition|--unigine)      install_unigine_superposition ;;
        --vm|--vms|--virtualization)    manage_virtualization ;;
        --libvirt)                      configure_libvirt ;;
        --libvirt-net|--net-default)    start_default_libvirt_network ;;
        --virt-builder-list|--templates) list_virt_builder_templates ;;
        --virt-builder|--build-vm)      build_virt_builder_vm ;;
        --vagrant)                      configure_vagrant ;;
        --appimages|--appimage-hub)     appimage_hub_menu ;;
        --compact)                      run_appimage_compact ;;
        --bionic)                       install_bionic_appimage ;;
        --darktable)                    install_darktable_appimage ;;
        --eden)                         install_eden_appimage ;;
        --jan)                          install_jan_appimage ;;
        --lmms)                         install_lmms_appimage ;;
        --musescore)                    install_musescore_appimage ;;
        --qtscrcpy)                     install_qtscrcpy_appimage ;;
        --unsloth)                      install_unsloth_appimage ;;
        --dsh-desktop|--dsh-deb)        install_deepseek_harness_desktop_deb_distrobox ;;
        --deepseek|--dsh)               setup_deepseek_harness ;;
        --prism|--llamacpp)             install_prism_llamacpp ;;
        --koboldcpp|--kobold)           install_koboldcpp ;;
        --localai|--local-ai)           install_localai ;;
        --openclaw)                     install_openclaw ;;
        --devpod)                       install_devpod ;;
        --udev|--udev-rules)            configure_udev_rules ;;
        -h|--help)                      show_help ;;
        *)
            echo -e "${RED}Unknown flag: $1${NC}" >&2
            show_help >&2
            exit 1
            ;;
    esac
    exit $?
fi

# Interactive Menu Loop
while true; do
    choice=""
    if command -v fzf >/dev/null 2>&1 && [ -t 0 ]; then
        local_menu_entries=(
            "1\t🚀 Core User Onboarding Sequence\tRun essential onboarding tasks: Homebrew, Pixi, Distrobox, Flatpaks, udev rules, and Waydroid"
            "2\t⚡ ujust / Universal Blue Task Runner\tAccess ujust recipes, list tasks, run bling setups, or execute custom system tasks"
            "3\t🍺 Configure Homebrew & PATH\tConfigure Linuxbrew environment and shell rc paths (~/.bashrc, ~/.zshrc)"
            "4\t📦 Install Pixi Package Manager\tInstall or update the ultra-fast Conda-compatible package manager (pixi.sh)"
            "5\t📖 Refresh TLDR & Terminal Caches\tUpdate tldr pages, rebuild bat syntax themes, refresh font caches, and update man-db"
            "6\t📦 Setup Ubuntu Distrobox Container\tCreate or recreate an Ubuntu 24.04 toolbox container for Debian software"
            "7\t📦 User Flatpak Remotes (Flathub & Fedora)\tConfigure user-level Flathub and Fedora OCI remotes without root access"
            "8\t🤖 AppImage Hub & Local AI Engines\tDownload and manage 15+ local AI models, LLM runtimes, and creative apps"
            "9\t🗜️  Compact & Configure Portable AppImages\tOptimize AppImages with portable config/home dirs and run auto-updaters"
            "10\t📱 Fedora Waydroid Setup Wizard\tAndroid container subsystem with ARM translation (libndk), GAPPS, and multi-window"
            "11\t🖥️  Virtualization & VM Management\tManage Libvirt networks, autostart VMs, virt-builder OS templates, and Vagrant"
            "12\t🎮 Gamepad, Joystick & VR udev Rules\tDeploy hardware input rules to /etc/udev/rules.d for Steam, VR, and controllers"
            "13\t🔊 PipeWire Audio Redirection\tMulti-user low-latency network audio streaming between sender and receiver"
            "14\t🧹 System Cleanup & Benchmarks\tClean container caches, snapshot storage, disk benchmarks, and Unigine GPU bench"
            "0\t🚪 Exit Launcher\tQuit setup utility"
        )

        choice=$(printf "%b\n" "${local_menu_entries[@]}" | fzf \
            --delimiter="\t" \
            --with-nth=2 \
            --accept-nth=1 \
            --preview='echo -e "\n  \033[1;36m{2}\033[0m\n\n  \033[0;37m{3}\033[0m"' \
            --preview-window="right,45%,border-left,wrap" \
            --border="rounded" \
            --border-label=" Fedora Workstation Control Center " \
            --header="User: $(whoami)  •  Host: $(hostname)  •  Shell: ${SHELL:-bash}  •  [Enter] Launch  [Esc] Exit" \
            --prompt="Search Action ❯ " \
            --pointer="❯" \
            --marker="✓" \
            --height=75% \
            --layout=reverse \
            --color="border:#555555,header:bold:white,prompt:#00afff,pointer:#5fd7ff,marker:#5fd700")

        local fzf_status=$?
        if [ $fzf_status -ne 0 ] || [ -z "$choice" ]; then
            choice=0
        fi
    else
        clear
        echo -e "${CYAN}===================================================================${NC}"
        echo -e "${BOLD}          Fedora Workstation - User Environment Launcher           ${NC}"
        echo -e "${CYAN}===================================================================${NC}"
        echo -e " User: ${GREEN}$(whoami)${NC} | Host: ${GREEN}$(hostname)${NC} | Shell: ${GREEN}${SHELL:-bash}${NC}"
        echo -e "${CYAN}-------------------------------------------------------------------${NC}"
        echo -e " ${BOLD}[Onboarding & Automation]${NC}"
        echo -e "   ${BOLD}1)${NC} ${BOLD}Core User Onboarding Sequence [Checkbox Menu]${NC}"
        echo -e "   ${BOLD}2)${NC} Access ujust / Universal Blue Task Runner"
        echo ""
        echo -e " ${BOLD}[Developer Environments & Package Managers]${NC}"
        echo -e "   ${BOLD}3)${NC} Configure Homebrew Environment & PATH"
        echo -e "   ${BOLD}4)${NC} Install Pixi Package Manager (pixi.sh)"
        echo -e "   ${BOLD}5)${NC} Update TLDR Cache & Terminal Utilities Refresh"
        echo -e "   ${BOLD}6)${NC} Create Ubuntu Distrobox Container"
        echo -e "   ${BOLD}7)${NC} Configure User Flatpak Remotes (Flathub & Fedora) [Checkbox]"
        echo ""
        echo -e " ${BOLD}[AppImage Hub & Local AI Tools]${NC}"
        echo -e "   ${BOLD}8)${NC} ${BOLD}AppImage Hub & Local AI Engines (15+ Tools & Models) [Checkbox]${NC}"
        echo -e "   ${BOLD}9)${NC} Compact & Configure Portable AppImages (--appimage-portable-*) [Checkbox]"
        echo ""
        echo -e " ${BOLD}[Virtualization & Android Emulation]${NC}"
        echo -e "  ${BOLD}10)${NC} Fedora Waydroid Setup Wizard (Subsystems, APKs & Fixes) [Checkbox]"
        echo -e "  ${BOLD}11)${NC} Virtualization & VM Management (Libvirt & Vagrant)"
        echo ""
        echo -e " ${BOLD}[Hardware & System Utilities]${NC}"
        echo -e "  ${BOLD}12)${NC} Configure Gamepad, Joystick & VR udev Rules"
        echo -e "  ${BOLD}13)${NC} Configure PipeWire Audio Redirection (Multi-User Streaming)"
        echo -e "  ${BOLD}14)${NC} System Cleanup & Storage Benchmarks (Podman, Snap, Disk) [Checkbox]"
        echo -e "${CYAN}-------------------------------------------------------------------${NC}"
        echo -e "   ${BOLD}0)${NC} Exit"
        echo -e "${CYAN}===================================================================${NC}"
        read -rp "Select an option [0-14]: " choice
    fi

    case "$choice" in
        1) run_all ;;
        2) run_ujust ;;
        3) configure_homebrew ;;
        4) install_pixi ;;
        5) update_terminal_utilities ;;
        6) setup_distrobox ;;
        7) configure_flatpak_remotes_user ;;
        8) appimage_hub_menu ;;
        9) run_appimage_compact ;;
        10) fedora_waydroid_setup_wizard ;;
        11) manage_virtualization ;;
        12) configure_udev_rules ;;
        13) configure_pipewire_streaming ;;
        14) cleanup_system ;;
        0|[Qq]|exit)
            echo -e "\n${GREEN}Exiting setup. You can run this script again anytime!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option: '$choice'. Please enter 0-14.${NC}"
            ;;
    esac
    echo ""
    read -rp "Press Enter to return to the menu..." _
done
