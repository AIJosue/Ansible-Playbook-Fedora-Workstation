# vim: set ft=make :

# Configure Bluefin-CLI Terminal Experience with Brew
[group('System')]
[no-exit-message]
bluefin-cli:
    #!/usr/bin/env bash
    set -e
    BLING_SRC_DIR="/usr/share/ublue-os/bling"
    BLING_SCRIPT="bling.sh"
    SHELL_NAME="$(basename "${SHELL}")"
    case "${SHELL_NAME}" in
        fish)
            BLING_SCRIPT="bling.fish"
            TARGET_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
            ;;
        zsh)
            TARGET_FILE="${ZDOTDIR:-$HOME}/.zshrc"
            ;;
        bash)
            TARGET_FILE="${HOME}/.bashrc"
            ;;
        *)
            echo "Unknown shell: ${SHELL_NAME}"
            exit 1
            ;;
    esac
    BLING_WAS_INSTALLED=1
    if [ -f "${TARGET_FILE}" ] && grep -q "source ${BLING_SRC_DIR}/${BLING_SCRIPT}" "${TARGET_FILE}" 2>/dev/null; then
        BLING_WAS_INSTALLED=0
    fi
    ublue-bling
    if [ "${BLING_WAS_INSTALLED}" -ne 0 ]; then
        if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
            brew bundle --file=/usr/share/ublue-os/homebrew/cli.Brewfile
        elif command -v brew >/dev/null 2>&1; then
            brew bundle --file=/usr/share/ublue-os/homebrew/cli.Brewfile
        else
            echo "Homebrew not found. Please install Homebrew to install bluefin-cli packages."
        fi
    fi
