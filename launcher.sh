#!/bin/bash
# ==============================================================================
# Setup User Environment (gum edition)
# Interactive Post-Install Utility for Fedora Workstation Users
# ==============================================================================
# This interactive utility allows individual users to configure developer and
# terminal tools on-demand without enforcing system-wide modifications.
#
# Supported Sections & Tools (Sorted into Logical Categories):
# [Onboarding & Automation]
# 1. Core User Onboarding Sequence (Stages 1-10 with interactive batch checkbox selection)
# 2. Run Entire Fedora Ansible Playbook (--ask-become-pass)
# 3. ujust / Universal Blue Task Runner integration (interactive recipe runner)
#
# [Developer Environments & Package Managers]
# 4. Homebrew Environment & PATH Configuration
# 5. Pixi Package Manager (https://pixi.sh)
# 6. TLDR Cache & Terminal Utilities Refresh (tldr, bat, fonts, man-db, git-lfs)
# 7. Distrobox — Ubuntu toolbox container (quay.io/toolbx/ubuntu-toolbox:latest)
# 8. User Flatpak Remotes (Flathub & Fedora OCI user remotes with checkbox selection)
#
# [AppImage Hub & Local AI Tools]
# 9. Unified AppImage Hub & Local AI Engines (15+ tools, models, launchers with batch checkbox selection)
# 10. Compact & Configure Portable AppImages (--appimage-portable-config/home with checkbox selection)
#
# [Virtualization & Android Emulation]
# 11. Fedora Waydroid Setup Wizard (Initialization, libndk, Widevine, multi-window, and APKs with checkbox selection)
# 12. Virtualization & VM Management (Libvirt autostart/ports/XML and Vagrant Ubuntu/YunoHost)
#
# [Hardware & System Utilities]
# 13. Gamepad, Joystick & VR udev Rules Configuration
# 14. PipeWire Audio Redirection (multi-user network/local streaming)
# 15. System Cleanup & Benchmarks (Podman prune, Snap snapshots, disk I/O, Unigine Superposition with checkbox selection)
# ==============================================================================

# ==============================================================================
# gum UI layer (https://github.com/charmbracelet/gum)
# ------------------------------------------------------------------------------
# Every interactive element of this launcher is rendered with gum. Each gum
# command is wrapped once here so the rest of the script stays declarative:
#
#   gum style   -> ui_banner / ui_hr / ui_ok / ui_dim   (banners, rules, status)
#   gum log     -> ui_info / ui_warn / ui_err            (levelled messages)
#   gum join    -> ui_dashboard                          (logo + info side by side)
#   gum table   -> ui_dashboard / ui_table               (static data tables)
#   gum format  -> ui_markdown / show_help               (markdown rendering)
#   gum pager   -> show_help / ui_pager                  (scrollable text)
#   gum spin    -> ui_spin / ui_spin_fn                  (progress spinners)
#   gum confirm -> ui_confirm / ask_yn                   (yes/no questions)
#   gum input   -> ask_input / ask_password / ui_pause   (text prompts)
#   gum write   -> ask_write                             (multi-line text)
#   gum file    -> ask_file                              (file / directory picker)
#   gum choose  -> ui_choose / ask_menu / gum_action_menu / checkbox_menu_select
#   gum filter  -> ui_filter / gum_action_menu (long lists)
#
# When stdin/stdout is not a terminal (pipes, CI, cron) every wrapper degrades
# to plain text output / read so the script stays scriptable.
# ==============================================================================

# ==============================================================================
# Apple Human Interface Guidelines (HIG) Color System
# Source: https://developer.apple.com/design/human-interface-guidelines/color
# Complete 12 System Colors + 6 System Grays across all 4 HIG contexts:
# Default (Light), Default (Dark), Increased Contrast (Light), Increased Contrast (Dark)
# Configurable via HIG_APPEARANCE={dark|light} and HIG_CONTRAST={standard|high}
# ==============================================================================
HIG_APPEARANCE="${HIG_APPEARANCE:-dark}"
HIG_CONTRAST="${HIG_CONTRAST:-standard}"

# 1. Default Light System Colors & Grays (Apple HIG Specifications)
HIG_RED_LIGHT="#FF383C";    HIG_ORANGE_LIGHT="#FF8D28"; HIG_YELLOW_LIGHT="#FFCC00"
HIG_GREEN_LIGHT="#34C759";  HIG_MINT_LIGHT="#00C8B3";   HIG_TEAL_LIGHT="#00C3D0"
HIG_CYAN_LIGHT="#00C0E8";   HIG_BLUE_LIGHT="#0088FF";   HIG_INDIGO_LIGHT="#6155F5"
HIG_PURPLE_LIGHT="#CB30E0"; HIG_PINK_LIGHT="#FF2D55";   HIG_BROWN_LIGHT="#AC7F5E"
HIG_GRAY_LIGHT="#8E8E93";   HIG_GRAY2_LIGHT="#AEAEB2";  HIG_GRAY3_LIGHT="#C7C7CC"
HIG_GRAY4_LIGHT="#D1D1D6";  HIG_GRAY5_LIGHT="#E5E5EA";  HIG_GRAY6_LIGHT="#F2F2F7"

# 2. Default Dark System Colors & Grays (Apple HIG Specifications)
HIG_RED_DARK="#FF4245";     HIG_ORANGE_DARK="#FF9230";  HIG_YELLOW_DARK="#FFD600"
HIG_GREEN_DARK="#30D158";   HIG_MINT_DARK="#00DAC3";    HIG_TEAL_DARK="#00D2E0"
HIG_CYAN_DARK="#3CD3FE";    HIG_BLUE_DARK="#0091FF";    HIG_INDIGO_DARK="#6D7CFF"
HIG_PURPLE_DARK="#DB34F2";  HIG_PINK_DARK="#FF375F";    HIG_BROWN_DARK="#B78A66"
HIG_GRAY_DARK="#8E8E93";    HIG_GRAY2_DARK="#636366";   HIG_GRAY3_DARK="#48484A"
HIG_GRAY4_DARK="#3A3A3C";   HIG_GRAY5_DARK="#2C2C2E";   HIG_GRAY6_DARK="#1C1C1E"

# 3. Increased Contrast Light System Colors & Grays (Apple HIG Specifications)
HIG_RED_HC_LIGHT="#E9152D";    HIG_ORANGE_HC_LIGHT="#C55300"; HIG_YELLOW_HC_LIGHT="#A16A00"
HIG_GREEN_HC_LIGHT="#008932";  HIG_MINT_HC_LIGHT="#008575";   HIG_TEAL_HC_LIGHT="#008198"
HIG_CYAN_HC_LIGHT="#007EAE";   HIG_BLUE_HC_LIGHT="#1E6EF4";   HIG_INDIGO_HC_LIGHT="#564ADE"
HIG_PURPLE_HC_LIGHT="#B02FC2"; HIG_PINK_HC_LIGHT="#E7124D";   HIG_BROWN_HC_LIGHT="#956D51"
HIG_GRAY_HC_LIGHT="#6C6C70";   HIG_GRAY2_HC_LIGHT="#8E8E93";  HIG_GRAY3_HC_LIGHT="#AEAEB2"
HIG_GRAY4_HC_LIGHT="#BCBCC0";  HIG_GRAY5_HC_LIGHT="#D8D8DC";  HIG_GRAY6_HC_LIGHT="#EBEBF0"

# 4. Increased Contrast Dark System Colors & Grays (Apple HIG Specifications)
HIG_RED_HC_DARK="#FF6165";     HIG_ORANGE_HC_DARK="#FFA056";  HIG_YELLOW_HC_DARK="#FEDF43"
HIG_GREEN_HC_DARK="#4AD968";   HIG_MINT_HC_DARK="#54DFCB";    HIG_TEAL_HC_DARK="#3BDDEC"
HIG_CYAN_HC_DARK="#6DD9FF";    HIG_BLUE_HC_DARK="#5CB8FF";    HIG_INDIGO_HC_DARK="#A7AAFF"
HIG_PURPLE_HC_DARK="#EA8DFF";  HIG_PINK_HC_DARK="#FF8AC4";    HIG_BROWN_HC_DARK="#DBA679"
HIG_GRAY_HC_DARK="#AEAEB2";    HIG_GRAY2_HC_DARK="#7C7C80";   HIG_GRAY3_HC_DARK="#545456"
HIG_GRAY4_HC_DARK="#444446";   HIG_GRAY5_HC_DARK="#363638";   HIG_GRAY6_HC_DARK="#242426"

# Resolve active Apple HIG palette based on HIG_APPEARANCE and HIG_CONTRAST
if [[ "$HIG_APPEARANCE" == "light" && "$HIG_CONTRAST" == "high" ]]; then
    C_RED="$HIG_RED_HC_LIGHT";       C_ORANGE="$HIG_ORANGE_HC_LIGHT"; C_YELLOW="$HIG_YELLOW_HC_LIGHT"
    C_GREEN="$HIG_GREEN_HC_LIGHT";   C_MINT="$HIG_MINT_HC_LIGHT";     C_TEAL="$HIG_TEAL_HC_LIGHT"
    C_CYAN="$HIG_CYAN_HC_LIGHT";     C_BLUE="$HIG_BLUE_HC_LIGHT";     C_INDIGO="$HIG_INDIGO_HC_LIGHT"
    C_PURPLE="$HIG_PURPLE_HC_LIGHT"; C_PINK="$HIG_PINK_HC_LIGHT";     C_BROWN="$HIG_BROWN_HC_LIGHT"
    C_GRAY="$HIG_GRAY_HC_LIGHT";     C_GRAY2="$HIG_GRAY2_HC_LIGHT";   C_GRAY3="$HIG_GRAY3_HC_LIGHT"
    C_GRAY4="$HIG_GRAY4_HC_LIGHT";   C_GRAY5="$HIG_GRAY5_HC_LIGHT";   C_GRAY6="$HIG_GRAY6_HC_LIGHT"
elif [[ "$HIG_APPEARANCE" == "light" ]]; then
    C_RED="$HIG_RED_LIGHT";          C_ORANGE="$HIG_ORANGE_LIGHT";    C_YELLOW="$HIG_YELLOW_LIGHT"
    C_GREEN="$HIG_GREEN_LIGHT";      C_MINT="$HIG_MINT_LIGHT";        C_TEAL="$HIG_TEAL_LIGHT"
    C_CYAN="$HIG_CYAN_LIGHT";        C_BLUE="$HIG_BLUE_LIGHT";        C_INDIGO="$HIG_INDIGO_LIGHT"
    C_PURPLE="$HIG_PURPLE_LIGHT";    C_PINK="$HIG_PINK_LIGHT";        C_BROWN="$HIG_BROWN_LIGHT"
    C_GRAY="$HIG_GRAY_LIGHT";        C_GRAY2="$HIG_GRAY2_LIGHT";      C_GRAY3="$HIG_GRAY3_LIGHT"
    C_GRAY4="$HIG_GRAY4_LIGHT";      C_GRAY5="$HIG_GRAY5_LIGHT";      C_GRAY6="$HIG_GRAY6_LIGHT"
elif [[ "$HIG_CONTRAST" == "high" ]]; then
    C_RED="$HIG_RED_HC_DARK";        C_ORANGE="$HIG_ORANGE_HC_DARK";  C_YELLOW="$HIG_YELLOW_HC_DARK"
    C_GREEN="$HIG_GREEN_HC_DARK";    C_MINT="$HIG_MINT_HC_DARK";      C_TEAL="$HIG_TEAL_HC_DARK"
    C_CYAN="$HIG_CYAN_HC_DARK";      C_BLUE="$HIG_BLUE_HC_DARK";      C_INDIGO="$HIG_INDIGO_HC_DARK"
    C_PURPLE="$HIG_PURPLE_HC_DARK";  C_PINK="$HIG_PINK_HC_DARK";      C_BROWN="$HIG_BROWN_HC_DARK"
    C_GRAY="$HIG_GRAY_HC_DARK";      C_GRAY2="$HIG_GRAY2_HC_DARK";    C_GRAY3="$HIG_GRAY3_HC_DARK"
    C_GRAY4="$HIG_GRAY4_HC_DARK";    C_GRAY5="$HIG_GRAY5_HC_DARK";    C_GRAY6="$HIG_GRAY6_HC_DARK"
else
    C_RED="$HIG_RED_DARK";           C_ORANGE="$HIG_ORANGE_DARK";     C_YELLOW="$HIG_YELLOW_DARK"
    C_GREEN="$HIG_GREEN_DARK";       C_MINT="$HIG_MINT_DARK";         C_TEAL="$HIG_TEAL_DARK"
    C_CYAN="$HIG_CYAN_DARK";         C_BLUE="$HIG_BLUE_DARK";         C_INDIGO="$HIG_INDIGO_DARK"
    C_PURPLE="$HIG_PURPLE_DARK";     C_PINK="$HIG_PINK_DARK";         C_BROWN="$HIG_BROWN_DARK"
    C_GRAY="$HIG_GRAY_DARK";         C_GRAY2="$HIG_GRAY2_DARK";       C_GRAY3="$HIG_GRAY3_DARK"
    C_GRAY4="$HIG_GRAY4_DARK";       C_GRAY5="$HIG_GRAY5_DARK";       C_GRAY6="$HIG_GRAY6_DARK"
fi
C_WHITE="#FFFFFF"; C_BLACK="#000000"

# Semantic Apple HIG Tokens (iOS / iPadOS / macOS Dynamic System Colors)
C_LABEL="$C_WHITE"                         # Primary Label / Control Text Color
C_SECONDARY_LABEL="$C_GRAY"                # Secondary Label Color
C_TERTIARY_LABEL="$C_GRAY2"                # Tertiary Label / Placeholder Text
C_QUATERNARY_LABEL="$C_GRAY3"              # Quaternary Label / Disabled Control Text
C_SEPARATOR="$C_GRAY4"                     # Separator / Grid Color
C_BG_PRIMARY="$C_GRAY6"                    # Primary System Background
C_BG_SECONDARY="$C_GRAY5"                  # Secondary System Grouped Background / Control Background
C_BG_TERTIARY="$C_GRAY4"                   # Tertiary System Background
C_ACCENT="$C_BLUE"                         # Control Accent Color / Selected Content Background
C_FIND_HIGHLIGHT="$C_YELLOW"               # Find Highlight Color
C_LINK="$C_CYAN"                           # Link Color

# gum theming through documented $GUM_<COMMAND>_<FLAG> environment variables
# Selections have explicit background colors per Apple HIG (selectedContentBackgroundColor)
export GUM_CHOOSE_CURSOR_FOREGROUND="$C_WHITE"
export GUM_CHOOSE_CURSOR_BACKGROUND="$C_ACCENT"
export GUM_CHOOSE_HEADER_FOREGROUND="$C_CYAN"
export GUM_CHOOSE_HEADER_BACKGROUND="$C_BG_SECONDARY"
export GUM_CHOOSE_ITEM_FOREGROUND="$C_LABEL"
export GUM_CHOOSE_SELECTED_FOREGROUND="$C_WHITE"
export GUM_CHOOSE_SELECTED_BACKGROUND="$C_INDIGO"
export GUM_CHOOSE_SELECTED_PREFIX=" ✓ "
export GUM_CHOOSE_UNSELECTED_PREFIX=" ○ "
export GUM_CHOOSE_CURSOR_PREFIX=" ❯ "
export GUM_CHOOSE_PADDING="0 1"

export GUM_FILTER_INDICATOR=" ❯ "
export GUM_FILTER_INDICATOR_FOREGROUND="$C_WHITE"
export GUM_FILTER_INDICATOR_BACKGROUND="$C_ACCENT"
export GUM_FILTER_SELECTED_PREFIX=" ✓ "
export GUM_FILTER_SELECTED_PREFIX_FOREGROUND="$C_WHITE"
export GUM_FILTER_SELECTED_PREFIX_BACKGROUND="$C_INDIGO"
export GUM_FILTER_UNSELECTED_PREFIX=" ○ "
export GUM_FILTER_UNSELECTED_PREFIX_FOREGROUND="$C_SECONDARY_LABEL"
export GUM_FILTER_HEADER_FOREGROUND="$C_CYAN"
export GUM_FILTER_HEADER_BACKGROUND="$C_BG_SECONDARY"
export GUM_FILTER_TEXT_FOREGROUND="$C_LABEL"
export GUM_FILTER_CURSOR_TEXT_FOREGROUND="$C_WHITE"
export GUM_FILTER_CURSOR_TEXT_BACKGROUND="$C_ACCENT"
export GUM_FILTER_MATCH_FOREGROUND="$C_BLACK"
export GUM_FILTER_MATCH_BACKGROUND="$C_FIND_HIGHLIGHT"
export GUM_FILTER_PROMPT="🔍 "
export GUM_FILTER_PROMPT_FOREGROUND="$C_CYAN"
export GUM_FILTER_PLACEHOLDER_FOREGROUND="$C_TERTIARY_LABEL"
export GUM_FILTER_PADDING="0 1"

export GUM_INPUT_PROMPT_FOREGROUND="$C_BLUE"
export GUM_INPUT_CURSOR_FOREGROUND="$C_WHITE"
export GUM_INPUT_CURSOR_BACKGROUND="$C_ACCENT"
export GUM_INPUT_HEADER_FOREGROUND="$C_CYAN"
export GUM_INPUT_PLACEHOLDER_FOREGROUND="$C_TERTIARY_LABEL"

export GUM_WRITE_HEADER_FOREGROUND="$C_CYAN"
export GUM_WRITE_CURSOR_FOREGROUND="$C_WHITE"
export GUM_WRITE_CURSOR_BACKGROUND="$C_ACCENT"
export GUM_WRITE_CURSOR_LINE_BACKGROUND="$C_BG_SECONDARY"
export GUM_WRITE_PLACEHOLDER_FOREGROUND="$C_TERTIARY_LABEL"

# Confirm dialog with explicit background colors on selections
export GUM_CONFIRM_PROMPT_FOREGROUND="$C_CYAN"
export GUM_CONFIRM_PROMPT_BACKGROUND="$C_BG_SECONDARY"
export GUM_CONFIRM_SELECTED_BACKGROUND="$C_ACCENT"
export GUM_CONFIRM_SELECTED_FOREGROUND="$C_WHITE"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="$C_BG_TERTIARY"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="$C_LABEL"
export GUM_CONFIRM_PADDING="0 1"

export GUM_SPIN_SPINNER_FOREGROUND="$C_MINT"
export GUM_SPIN_TITLE_FOREGROUND="$C_CYAN"

export GUM_FILE_CURSOR_FOREGROUND="$C_WHITE"
export GUM_FILE_CURSOR_BACKGROUND="$C_ACCENT"
export GUM_FILE_DIRECTORY_FOREGROUND="$C_BLUE"
export GUM_FILE_SELECTED_FOREGROUND="$C_WHITE"
export GUM_FILE_SELECTED_BACKGROUND="$C_INDIGO"
export GUM_FILE_SYMLINK_FOREGROUND="$C_TEAL"
export GUM_FILE_PERMISSIONS_FOREGROUND="$C_SECONDARY_LABEL"
export GUM_FILE_FILE_SIZE_FOREGROUND="$C_BROWN"

export GUM_TABLE_HEADER_FOREGROUND="$C_CYAN"
export GUM_TABLE_HEADER_BACKGROUND="$C_BG_SECONDARY"
export GUM_TABLE_CELL_FOREGROUND="$C_LABEL"
export GUM_TABLE_BORDER_FOREGROUND="$C_SEPARATOR"
export GUM_TABLE_SELECTED_FOREGROUND="$C_WHITE"
export GUM_TABLE_SELECTED_BACKGROUND="$C_ACCENT"

export GUM_PAGER_HELP_FOREGROUND="$C_SECONDARY_LABEL"
export GUM_PAGER_LINE_NUMBER_FOREGROUND="$C_TERTIARY_LABEL"
export GUM_PAGER_MATCH_FOREGROUND="$C_CYAN"
export GUM_PAGER_MATCH_HIGH_FOREGROUND="$C_BLACK"
export GUM_PAGER_MATCH_HIGH_BACKGROUND="$C_FIND_HIGHLIGHT"

# gum is a hard requirement; offer to install it from the Fedora repositories.
ensure_gum() {
    command -v gum >/dev/null 2>&1 && return 0
    echo "The 'gum' CLI (charmbracelet/gum) is required by this launcher." >&2
    if [ -t 0 ] && command -v sudo >/dev/null 2>&1 && command -v dnf >/dev/null 2>&1; then
        local ans
        read -rp "Install gum now via 'sudo dnf install gum'? [Y/n]: " ans
        if [[ "${ans:-Y}" =~ ^[Yy]$ ]]; then
            sudo dnf install -y gum && command -v gum >/dev/null 2>&1 && return 0
        fi
    fi
    echo "Install it with: sudo dnf install gum" >&2
    exit 1
}
ensure_gum

# True when stdin and stderr are terminals. gum draws its TUIs on stderr, so this
# also holds inside $(...) command substitutions where stdout is captured.
ui_tty() { [ -t 0 ] && [ -t 2 ]; }

# Inline coloured fragment for use inside messages: $(ui_c [bold:]fg[:bg] "text")
# Supports all 12 Apple HIG system colors + 6 system grays + semantic tokens.
ui_c() { # [bold:]color[:bg] text
    local spec="$1" txt="$2" fg="" bg="" flags=()
    case "$spec" in
        bold) flags+=(--bold); spec="" ;;
        bold:*) flags+=(--bold); spec="${spec#bold:}" ;;
    esac
    local fg_name="$spec" bg_name=""
    if [[ "$spec" == *:* ]]; then
        fg_name="${spec%%:*}"
        bg_name="${spec#*:}"
    fi
    case "$fg_name" in
        red)          fg="$C_RED" ;;
        orange)       fg="$C_ORANGE" ;;
        yellow)       fg="$C_YELLOW" ;;
        green)        fg="$C_GREEN" ;;
        mint)         fg="$C_MINT" ;;
        teal)         fg="$C_TEAL" ;;
        cyan)         fg="$C_CYAN" ;;
        blue)         fg="$C_BLUE" ;;
        indigo)       fg="$C_INDIGO" ;;
        purple)       fg="$C_PURPLE" ;;
        pink)         fg="$C_PINK" ;;
        brown)        fg="$C_BROWN" ;;
        gray|gray1)   fg="$C_GRAY" ;;
        gray2)        fg="$C_GRAY2" ;;
        gray3)        fg="$C_GRAY3" ;;
        gray4)        fg="$C_GRAY4" ;;
        gray5)        fg="$C_GRAY5" ;;
        gray6)        fg="$C_GRAY6" ;;
        white|label)  fg="$C_WHITE" ;;
        black)        fg="$C_BLACK" ;;
    esac
    case "$bg_name" in
        red)          bg="$C_RED" ;;
        orange)       bg="$C_ORANGE" ;;
        yellow)       bg="$C_YELLOW" ;;
        green)        bg="$C_GREEN" ;;
        mint)         bg="$C_MINT" ;;
        teal)         bg="$C_TEAL" ;;
        cyan)         bg="$C_CYAN" ;;
        blue|accent)  bg="$C_BLUE" ;;
        indigo)       bg="$C_INDIGO" ;;
        purple)       bg="$C_PURPLE" ;;
        pink)         bg="$C_PINK" ;;
        brown)        bg="$C_BROWN" ;;
        gray|gray1)   bg="$C_GRAY" ;;
        gray2)        bg="$C_GRAY2" ;;
        gray3)        bg="$C_GRAY3" ;;
        gray4)        bg="$C_GRAY4" ;;
        gray5|surface) bg="$C_GRAY5" ;;
        gray6|bg)     bg="$C_GRAY6" ;;
    esac
    [ -n "$fg" ] && flags+=(--foreground "$fg")
    [ -n "$bg" ] && flags+=(--background "$bg")
    if [ "${#flags[@]}" -eq 0 ]; then printf '%s' "$txt"; else gum style "${flags[@]}" -- "$txt"; fi
}

# --- gum style / gum log -------------------------------------------------------
ui_banner() { # title [hex-color]
    local color="${2:-$C_BLUE}"
    if ui_tty; then
        gum style --border rounded --border-foreground "$color" --background "$C_BG_SECONDARY" \
            --padding "0 2" --margin "1 0 0 0" --bold --foreground "$C_WHITE" -- "$1"
    else
        printf '\n== %s ==\n' "$1"
    fi
}
ui_hr() { gum style --foreground "$C_SEPARATOR" -- "$(printf '─%.0s' {1..60})"; }
ui_ok()   { gum style --foreground "$C_GREEN" --bold -- "$*"; }
ui_dim()  { gum style --foreground "$C_SECONDARY_LABEL" -- "$*"; }
ui_info() { GUM_LOG_LEVEL_FOREGROUND="$C_CYAN" GUM_LOG_MESSAGE_FOREGROUND="$C_LABEL" gum log --level info -- "$*"; }
ui_warn() { GUM_LOG_LEVEL_FOREGROUND="$C_ORANGE" GUM_LOG_MESSAGE_FOREGROUND="$C_YELLOW" gum log --level warn -- "$*"; }
ui_err()  { GUM_LOG_LEVEL_FOREGROUND="$C_RED" GUM_LOG_MESSAGE_FOREGROUND="$C_PINK" gum log --level error -- "$*" >&2; }

# --- gum format / gum pager ------------------------------------------------------
ui_markdown() { # markdown text as args or stdin
    if [ $# -gt 0 ]; then gum format --type markdown -- "$@"; else gum format --type markdown; fi
}
ui_pager() { # text on stdin
    if ui_tty; then gum pager --soft-wrap; else cat; fi
}

# --- gum table ---------------------------------------------------------------------
ui_table() { # "Col1,Col2" then CSV rows on stdin
    local columns="${1:-Property,Value}"
    if ui_tty; then
        gum table --print --separator "," --columns "$columns" --border rounded \
            --header.foreground "$C_CYAN" --header.background "$C_BG_SECONDARY" \
            --border.foreground "$C_SEPARATOR" --cell.foreground "$C_LABEL" \
            --selected.foreground "$C_WHITE" --selected.background "$C_ACCENT" 2>/dev/null
    else
        printf '%s\n' "$columns"
        cat
    fi
}

# Render a structured top-of-section information table ("Property,Details" by default)
# Usage: ui_info_table ["Col1,Col2"] "Key1,Val1" "Key2,Val2" ...
ui_info_table() {
    local cols="Property,Details"
    if [[ "${1:-}" == *,* ]] && [ $# -gt 1 ] && [[ "$1" =~ ^[A-Za-z0-9_[:space:]]+,[A-Za-z0-9_[:space:]]+$ ]] && [[ "$1" != *":"* ]] && [[ "$1" != *"/"* ]]; then
        cols="$1"
        shift
    fi
    if ui_tty; then
        printf '%s\n' "$@" | ui_table "$cols"
    else
        local row
        for row in "$@"; do
            printf '  %-20s %s\n' "${row%%,*}:" "${row#*,}"
        done
    fi
}

# --- gum spin -----------------------------------------------------------------------
# Run an external command behind a spinner (falls back to a plain run).
ui_spin() { # title cmd args...
    local title="$1"; shift
    if ui_tty; then
        gum spin --spinner dot --title "$title" --show-error -- "$@"
    else
        "$@"
    fi
}
# Run a shell function behind a spinner and print its stdout; keeps its exit code.
ui_spin_fn() { # title function args...
    local title="$1" fn="$2" f tmp rc
    shift 2
    if ! ui_tty; then "$fn" "$@"; return $?; fi
    for f in $(declare -F | awk '{print $3}' | grep -E '^(fetch_|ui_)'); do
        export -f "$f"
    done
    tmp="$(mktemp)"
    gum spin --spinner dot --title "$title" -- bash -c '"$@" > "$0"' "$tmp" "$fn" "$@"
    rc=$?
    cat "$tmp"
    rm -f "$tmp"
    return $rc
}

# --- gum confirm / gum input / gum write / gum file -------------------------------
ui_confirm() { # question [Y|N default] [affirmative] [negative] [selected_bg] -> exit 0 = yes
    local q="$1" d="${2:-Y}" aff="${3:-Confirm}" neg="${4:-Cancel}" sel_bg="${5:-$C_ACCENT}" ans
    # Automatically apply Apple HIG destructive red highlight on destructive prompts
    if [[ "$q" =~ ([Dd]estroy|[Ww]ipe|[Rr]emove|[Dd]elete|[Rr]eplace|[Ff]orce|[Pp]rune) ]] && [ -z "${5:-}" ]; then
        sel_bg="$C_RED"
    fi
    if ui_tty; then
        local def_flag="--default=true"
        [[ "$d" =~ ^[Nn] ]] && def_flag="--default=false"
        gum confirm "$def_flag" \
            --affirmative " $aff " \
            --negative " $neg " \
            --prompt.foreground "$C_CYAN" \
            --prompt.background "$C_BG_SECONDARY" \
            --selected.background "$sel_bg" \
            --selected.foreground "$C_WHITE" \
            --unselected.background "$C_BG_TERTIARY" \
            --unselected.foreground "$C_LABEL" \
            --padding "0 1" \
            -- "$q"
        return $?
    fi
    read -rp "$q [$d]: " ans
    ans="${ans:-$d}"
    [[ "$ans" =~ ^[Yy]$ ]]
}
ask_yn() { # question default(Y|N) variable -> stores Y or N
    local v=N
    ui_confirm "$1" "$2" && v=Y
    printf -v "$3" '%s' "$v"
}
ask_input() { # prompt variable [placeholder]
    local prompt="$1" var="$2" ph="${3:-}" val=""
    prompt="${prompt%: }"
    if [ -z "$ph" ] && [[ "$prompt" =~ \[(default:\ )?([^]]+)\]$ ]]; then
        ph="${BASH_REMATCH[2]}"
        prompt="${prompt% \[*}"
    fi
    if ui_tty; then
        val="$(gum input --header "$prompt" --prompt "❯ " \
            --prompt.foreground "$C_BLUE" \
            --header.foreground "$C_CYAN" \
            --cursor.foreground "$C_WHITE" \
            --cursor.background "$C_ACCENT" \
            --placeholder "${ph:-Type a value and press Enter}" --width 0)" || val=""
    else
        read -rp "$prompt: " val
    fi
    printf -v "$var" '%s' "$val"
}
ask_password() { # prompt variable
    local val=""
    if ui_tty; then
        val="$(gum input --password --header "${1%: }" --prompt "🔒 " \
            --prompt.foreground "$C_ORANGE" \
            --header.foreground "$C_CYAN" \
            --cursor.foreground "$C_WHITE" \
            --cursor.background "$C_ACCENT" \
            --placeholder "Hidden input")" || val=""
    else
        read -s -rp "$1" val
        echo ""
    fi
    printf -v "$2" '%s' "$val"
}
ask_write() { # prompt variable (multi-line; Ctrl+D submits, Esc cancels; newlines are flattened)
    local val=""
    if ui_tty; then
        val="$(gum write --header "${1%: }  (Ctrl+D to submit, Esc to cancel)" \
            --header.foreground "$C_CYAN" \
            --cursor.foreground "$C_WHITE" \
            --cursor.background "$C_ACCENT" \
            --cursor-line.background "$C_BG_SECONDARY" \
            --placeholder "Paste text here..." --height 6 --width 0)" || val=""
    else
        read -rp "$1" val
    fi
    val="${val//$'\n'/}"
    printf -v "$2" '%s' "$val"
}
ask_file() { # prompt variable start-dir [--directory]
    local prompt="$1" var="$2" start="${3:-$HOME}" opt="${4:-}" val=""
    if ui_tty; then
        ui_dim "$prompt (arrows to browse, Enter to pick, Esc to cancel)"
        if [ -n "$opt" ]; then
            val="$(gum file --all --height 12 \
                --cursor.foreground "$C_WHITE" --cursor.background "$C_ACCENT" \
                --selected.foreground "$C_WHITE" --selected.background "$C_INDIGO" \
                "$opt" "$start")" || val=""
        else
            val="$(gum file --all --height 12 \
                --cursor.foreground "$C_WHITE" --cursor.background "$C_ACCENT" \
                --selected.foreground "$C_WHITE" --selected.background "$C_INDIGO" \
                "$start")" || val=""
        fi
    else
        read -rp "$prompt: " val
    fi
    printf -v "$var" '%s' "$val"
}
ui_pause() { # [message]
    local msg="${1:-Press Enter to continue...}"
    if ui_tty; then
        gum input --prompt "" --placeholder "$msg" --no-show-help >/dev/null || true
    else
        read -rp "$msg" _
    fi
}

# --- gum choose / gum filter ------------------------------------------------------
# Single item selector with Apple HIG selection background highlight.
ui_choose() { # header options...
    local header="$1" choice
    shift
    if ui_tty; then
        choice="$(gum choose --header "$header" --height 15 \
            --cursor.foreground "$C_WHITE" --cursor.background "$C_ACCENT" \
            --selected.foreground "$C_WHITE" --selected.background "$C_INDIGO" \
            --header.foreground "$C_CYAN" --header.background "$C_BG_SECONDARY" \
            -- "$@")" || return 1
        [ -n "$choice" ] || return 1
        echo "$choice"
        return 0
    fi
    local sel
    select sel in "$@"; do
        [ -n "$sel" ] && { echo "$sel"; return 0; }
    done
    return 1
}
# Fuzzy finder over arguments with Apple HIG selection background highlight.
ui_filter() { # header options...
    local header="$1" choice
    shift
    if ui_tty; then
        choice="$(printf '%s\n' "$@" | gum filter --header "$header" \
            --placeholder "Type to filter · Enter to select · Esc to cancel" --height 15 \
            --indicator.foreground "$C_WHITE" --indicator.background "$C_ACCENT" \
            --cursor-text.foreground "$C_WHITE" --cursor-text.background "$C_ACCENT" \
            --selected-indicator.foreground "$C_WHITE" --selected-indicator.background "$C_INDIGO" \
            --match.foreground "$C_BLACK" --match.background "$C_FIND_HIGHLIGHT" \
            --header.foreground "$C_CYAN" --header.background "$C_BG_SECONDARY")" || return 1
        [ -n "$choice" ] || return 1
        echo "$choice"
        return 0
    fi
    ui_choose "$header" "$@"
}
# Numbered menu returning the chosen key (the text before ')') in a variable.
# Cancel / Esc yields "0" when a "0" entry exists, otherwise "".
ask_menu() { # variable header "key|label"...
    local var="$1" header="$2" entry key label choice="" cancel=""
    shift 2
    header="${header%% \[*}"
    local labels=()
    for entry in "$@"; do
        key="${entry%%|*}"; label="${entry#*|}"
        labels+=("$key) $label")
        [ "$key" = "0" ] && cancel="0"
    done
    if ui_tty; then
        choice="$(gum choose --header "$header" --height 15 \
            --cursor.foreground "$C_WHITE" --cursor.background "$C_ACCENT" \
            --selected.foreground "$C_WHITE" --selected.background "$C_INDIGO" \
            --header.foreground "$C_CYAN" --header.background "$C_BG_SECONDARY" \
            -- "${labels[@]}")" || choice=""
        choice="${choice%%)*}"
    else
        for entry in "${labels[@]}"; do echo "  $entry"; done
        read -rp "$header: " choice
    fi
    printf -v "$var" '%s' "${choice:-$cancel}"
}
# Rich submenu following Apple HIG Menu anatomy:
# Items are "KEY\tTITLE\tDESCRIPTION". Prints the chosen KEY ("0" on cancel).
gum_action_menu() { # title prompt items...
    local title="$1" prompt="${2:-Action}" line key ttl desc choice
    shift 2
    local lines=()
    for line in "$@"; do
        IFS=$'\t' read -r key ttl desc <<<"$(printf '%b' "$line")"
        lines+=("$key) $ttl — $desc")
    done
    local rc cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}" n
    for n in "${!lines[@]}"; do
        # keep every entry on one row so the list never wraps
        [ "${#lines[n]}" -gt $((cols - 8)) ] && lines[n]="${lines[n]:0:$((cols - 9))}…"
    done
    if ! ui_tty; then
        # Non-interactive fallback: plain numbered list on stderr, answer from stdin
        printf '== %s ==\n' "$title" >&2
        printf '  %s\n' "${lines[@]}" >&2
        read -rp "$prompt: " choice || choice=0
        echo "${choice:-0}"
        return 0
    fi
    if [ "${#lines[@]}" -gt 8 ]; then
        choice="$(printf '%s\n' "${lines[@]}" | gum filter \
            --header " $title " \
            --placeholder "$prompt · Type to filter · Enter to select · Esc to go back" \
            --height 20 \
            --indicator.foreground "$C_WHITE" --indicator.background "$C_ACCENT" \
            --cursor-text.foreground "$C_WHITE" --cursor-text.background "$C_ACCENT" \
            --selected-indicator.foreground "$C_WHITE" --selected-indicator.background "$C_INDIGO" \
            --match.foreground "$C_BLACK" --match.background "$C_FIND_HIGHLIGHT" \
            --header.foreground "$C_CYAN" --header.background "$C_BG_SECONDARY")"
        rc=$?
    else
        choice="$(gum choose \
            --header " $title " \
            --height 14 \
            --cursor.foreground "$C_WHITE" --cursor.background "$C_ACCENT" \
            --selected.foreground "$C_WHITE" --selected.background "$C_INDIGO" \
            --header.foreground "$C_CYAN" --header.background "$C_BG_SECONDARY" \
            -- "${lines[@]}")"
        rc=$?
    fi
    if [ $rc -ne 0 ] || [ -z "$choice" ]; then
        echo "0"   # Esc / Ctrl+C / empty selection means "Back"
        return 0
    fi
    echo "${choice%%)*}"
}

# Shared interactive checkbox menu built on `gum choose --no-limit` with Apple HIG
# selection background highlighting and top context table.
# Reads CB_ITEMS=() and CB_SELECTED=() (0/1 per item) and updates CB_SELECTED.
# Returns: 0 = Run selected, 1 = Cancel/Back, 2 = Extra action
checkbox_menu_select() {
    local title="$1"
    local subtitle="$2"
    local run_label="${3:-Run Selected Tasks}"
    local cancel_label="${4:-Back to Main Menu}"
    local color="${5:-$C_BLUE}"
    local extra_label="${6:-}"
    local i token idx all_set new_state any_selected valid choice mark

    if ui_tty; then
        local labels=() preselected=() out line extra_picked=0 any=0
        for i in "${!CB_ITEMS[@]}"; do
            labels+=("$(printf '%02d  %s' "$((i + 1))" "${CB_ITEMS[i]//,/;}")")
            [ "${CB_SELECTED[i]:-0}" -eq 1 ] && preselected+=("${labels[i]}")
        done
        local extra_item=""
        if [ -n "$extra_label" ]; then
            extra_item="⚙  ${extra_label//,/;}"
            labels+=("$extra_item")
        fi

        ui_banner "$title" "$color"
        if [ -n "$subtitle" ]; then
            local sub_rows=() sub_line k v
            while IFS= read -r sub_line; do
                sub_line="${sub_line#"${sub_line%%[![:space:]]*}"}"
                [ -z "$sub_line" ] && continue
                if [[ "$sub_line" == *:* ]]; then
                    k="${sub_line%%:*}"
                    v="${sub_line#*: }"
                    sub_rows+=("${k//,/;},${v//,/;}")
                else
                    sub_rows+=("Context,${sub_line//,/;}")
                fi
            done <<< "$(printf '%b' "$subtitle")"
            sub_rows+=("Selection,${#preselected[@]} of ${#CB_ITEMS[@]} preselected")
            ui_info_table "Attribute,Details" "${sub_rows[@]}"
        else
            ui_info_table "Attribute,Details" \
                "Menu,${title//,/;}" \
                "Items,${#CB_ITEMS[@]} available (${#preselected[@]} preselected)" \
                "Action,${run_label//,/;}"
        fi

        local selected_csv="" p
        for p in "${preselected[@]}"; do selected_csv+="${selected_csv:+,}$p"; done
        local args=(--no-limit --height 20 --ordered
            --cursor.foreground "$C_WHITE" --cursor.background "$C_ACCENT"
            --selected.foreground "$C_WHITE" --selected.background "$C_INDIGO"
            --header.foreground "$C_CYAN" --header.background "$C_BG_SECONDARY"
            --header " [Space/x] Toggle · [Ctrl+A] Toggle All · [Enter] ${run_label} · [Esc] ${cancel_label} ")
        [ -n "$selected_csv" ] && args+=(--selected "$selected_csv")

        out="$(gum choose "${args[@]}" -- "${labels[@]}")" || return 1

        for i in "${!CB_ITEMS[@]}"; do CB_SELECTED[i]=0; done
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            if [ -n "$extra_item" ] && [ "$line" = "$extra_item" ]; then
                extra_picked=1
            elif [[ "$line" =~ ^([0-9]+)\  ]]; then
                idx=$((10#${BASH_REMATCH[1]} - 1))
                if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#CB_ITEMS[@]}" ]; then
                    CB_SELECTED[idx]=1
                    any=1
                fi
            fi
        done <<<"$out"

        # The extra action only wins when no regular item is ticked (Ctrl+A ticks it too)
        if [ "$extra_picked" -eq 1 ] && [ "$any" -eq 0 ]; then return 2; fi
        if [ "$any" -eq 0 ]; then
            ui_warn "No items selected."
            sleep 1
            return 1
        fi
        return 0
    fi

    # Non-interactive fallback: numbered text menu
    while true; do
        echo "== ${title} =="
        [ -n "$subtitle" ] && printf '%b\n' "$subtitle"
        echo " Toggle items with numbers [1-${#CB_ITEMS[@]}] (e.g. 1 or 1,3)."
        for i in "${!CB_ITEMS[@]}"; do
            mark=" "
            [ "${CB_SELECTED[i]}" -eq 1 ] && mark="X"
            printf "  %2d) [%s] %s\n" "$((i + 1))" "$mark" "${CB_ITEMS[i]}"
        done
        echo "   A) Toggle Select ALL / NONE"
        echo "   R) ${run_label}"
        [ -n "$extra_label" ] && echo "   C) ${extra_label}"
        echo "   0) ${cancel_label}"

        read -rp "Enter choice: " choice || return 1
        case "$choice" in
            0|[Qq]|back) return 1 ;;
            [Cc])
                [ -n "$extra_label" ] && return 2
                echo "Invalid selection."
                ;;
            [Aa])
                all_set=1
                for i in "${!CB_ITEMS[@]}"; do
                    if [ "${CB_SELECTED[i]}" -eq 0 ]; then all_set=0; break; fi
                done
                new_state=$((1 - all_set))
                for i in "${!CB_ITEMS[@]}"; do CB_SELECTED[i]=$new_state; done
                ;;
            [Rr])
                any_selected=0
                for i in "${!CB_ITEMS[@]}"; do
                    [ "${CB_SELECTED[i]}" -eq 1 ] && { any_selected=1; break; }
                done
                if [ "$any_selected" -eq 0 ]; then
                    echo "No items selected. Mark at least one with its number."
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
                [ "$valid" -eq 0 ] && echo "Invalid selection."
                ;;
        esac
    done
}

# Main-menu dashboard: gum join (logo + side-by-side gum tables) rendered at top.
ui_dashboard() {
    ui_tty || return 0
    local logo sys_table env_table os_name kernel_v ansible_v brew_v pixi_v dbox_v waydroid_v gum_v
    os_name="$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Fedora Linux}")"
    os_name="${os_name//,/;}"
    kernel_v="$(uname -r 2>/dev/null || echo 'unknown')"
    gum_v="$(gum --version 2>/dev/null | awk '{print $NF}')"
    ansible_v="$(command -v ansible >/dev/null 2>&1 && ansible --version 2>/dev/null | head -n1 | awk '{print $NF}' | tr -d ']' || echo 'Missing')"
    brew_v="$([ -x /home/linuxbrew/.linuxbrew/bin/brew ] || command -v brew >/dev/null 2>&1 && echo 'Ready' || echo 'Not Set')"
    pixi_v="$([ -x "$HOME/.pixi/bin/pixi" ] || command -v pixi >/dev/null 2>&1 && echo 'Ready' || echo 'Not Set')"
    dbox_v="$(command -v distrobox >/dev/null 2>&1 && echo 'Installed' || echo 'Missing')"
    waydroid_v="$(command -v waydroid >/dev/null 2>&1 && echo 'Installed' || echo 'Missing')"

    logo="$(gum style --border double --border-foreground "$C_BLUE" --background "$C_BG_SECONDARY" --padding "1 2" \
        --foreground "$C_CYAN" --bold --align center \
        "Fedora Workstation" \
        "Control Center" \
        "$(ui_c "mint" "HIG ${HIG_APPEARANCE^} · ${HIG_CONTRAST^}")" \
        "$(ui_c "gray" "gum ${gum_v}")")"

    sys_table="$(printf 'User,%s\nHost,%s\nOS,%s\nKernel,%s\nShell,%s\n' \
        "$(whoami)" "$(hostname)" "$os_name" "$kernel_v" "$(basename "${SHELL:-bash}")" \
        | ui_table "System,Information")"

    env_table="$(printf 'Ansible,%s\nHomebrew,%s\nPixi,%s\nDistrobox,%s\nWaydroid,%s\n' \
        "$ansible_v" "$brew_v" "$pixi_v" "$dbox_v" "$waydroid_v" \
        | ui_table "Subsystem,Status")"

    gum join --horizontal --align center "$logo" "  " "$sys_table" "  " "$env_table"
}

# Ensure this script is run as a regular user, not root
if [ "$(id -u)" -eq 0 ]; then
    ui_err "Warning: Do NOT run this setup script as root!"
    echo -e "Please execute this script as your regular user (e.g. 'sandbox' or 'admin')."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_repo_root() {
    local candidate
    for candidate in \
        "$SCRIPT_DIR" \
        "$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)" \
        "$HOME/Code/Terminal/Ansible-Playbook-Fedora-Workstation" \
        "$HOME/Ansible-Playbook-Fedora-Workstation"; do
        if [ -n "$candidate" ] && [ -d "$candidate/tasks" ] && [ -f "$candidate/local.yml" ]; then
            echo "$candidate"
            return 0
        fi
    done
    echo "$SCRIPT_DIR"
}

REPO_ROOT="$(resolve_repo_root)"
SUDO_CMD=""

ensure_work_folder_and_ansible() {
    local default_repo_url="https://github.com/AIJosue/Ansible-Playbook-Fedora-Workstation.git"
    local default_target_dir="$HOME/Code/Terminal/Ansible-Playbook-Fedora-Workstation"
    local desktop_launcher="$HOME/Desktop/launcher.sh"

    local current_repo
    current_repo="$(resolve_repo_root)"
    local repo_valid=0

    if [ -n "$current_repo" ] && [ -d "$current_repo/tasks" ] && [ -f "$current_repo/local.yml" ]; then
        repo_valid=1
        REPO_ROOT="$current_repo"
    fi

    local ansible_installed=0
    if command -v ansible-playbook >/dev/null 2>&1 && command -v ansible >/dev/null 2>&1; then
        ansible_installed=1
    fi

    # If both playbook folder and ansible are present, ensure Desktop launcher is up to date and return
    if [ "$repo_valid" -eq 1 ] && [ "$ansible_installed" -eq 1 ]; then
        return 0
    fi

    ui_banner "Prerequisites Verification: Playbook & Ansible" "$C_INDIGO"
    ui_info_table "Component,Status" \
        "Playbook Workspace,$([ "$repo_valid" -eq 1 ] && echo "Found ($REPO_ROOT)" || echo "Missing ($default_target_dir)")" \
        "Ansible Engine,$([ "$ansible_installed" -eq 1 ] && echo "Installed" || echo "Not Installed")" \
        "Desktop Launcher,$desktop_launcher"

    # 1. Check & Prompt for Playbook Repository Folder
    if [ "$repo_valid" -eq 0 ]; then
        ui_warn "• Ansible playbook workspace folder was not found."
        ui_info_table "Requirement,Expected Value" \
            "Repository URL,$default_repo_url" \
            "Target Directory,$default_target_dir" \
            "Required Files,local.yml and tasks/"
        ask_yn "Would you like to clone the repository now?" "Y" clone_choice
        clone_choice="${clone_choice:-Y}"
        if [[ "$clone_choice" =~ ^[Yy]$ ]]; then
            ask_input "Repository URL [${default_repo_url}]: " user_repo_url
            user_repo_url="${user_repo_url:-$default_repo_url}"

            mkdir -p "$(dirname "$default_target_dir")"
            if command -v git >/dev/null 2>&1; then
                ui_info "[*] Cloning ${user_repo_url} into ${default_target_dir}..."
                if git clone "$user_repo_url" "$default_target_dir"; then
                    ui_ok "✓ Successfully cloned playbook repository."
                    REPO_ROOT="$default_target_dir"
                    repo_valid=1
                else
                    ui_err "git clone failed."
                    return 1
                fi
            else
                ui_warn "git is not installed. Installing git via sudo dnf..."
                sudo dnf install -y git
                if git clone "$user_repo_url" "$default_target_dir"; then
                    ui_ok "✓ Successfully cloned playbook repository."
                    REPO_ROOT="$default_target_dir"
                    repo_valid=1
                else
                    ui_err "git clone failed."
                    return 1
                fi
            fi
        else
            ui_err "Playbook workspace is required to continue."
            return 1
        fi
    fi

    # 2. Check & Prompt for Ansible Installation
    if [ "$ansible_installed" -eq 0 ]; then
        echo
        ui_warn "• Ansible is not installed or not found in PATH."
        ask_yn "Install Ansible now via sudo dnf?" "Y" install_ansible_choice
        install_ansible_choice="${install_ansible_choice:-Y}"
        if [[ "$install_ansible_choice" =~ ^[Yy]$ ]]; then
            ui_info "[*] Installing ansible via dnf..."
            if sudo dnf install -y ansible; then
                ui_ok "✓ Ansible installed successfully."
                ansible_installed=1
            else
                ui_err "Failed to install ansible via dnf."
                return 1
            fi
        else
            ui_err "Ansible is required to proceed."
            return 1
        fi
    fi

    # 3. Synchronize and execute launcher at desktop if we are not already running it
    if [ -f "$REPO_ROOT/launcher.sh" ]; then
        mkdir -p "$HOME/Desktop"
        cp -f "$REPO_ROOT/launcher.sh" "$desktop_launcher"
        chmod +x "$desktop_launcher"
        ui_ok "✓ Desktop launcher deployed at: ${desktop_launcher}"

        # If current script was run from outside Desktop, execute the Desktop launcher
        local running_script
        running_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
        local canonical_desktop
        canonical_desktop="$(cd "$HOME/Desktop" 2>/dev/null && pwd)/launcher.sh"

        if [ "$running_script" != "$canonical_desktop" ]; then
            echo -e "$(ui_c "cyan" "[*] Executing launcher at Desktop (${desktop_launcher})...")\n"
            exec "$desktop_launcher" "$@"
        fi
    fi
}

ensure_work_folder_and_ansible "$@"

run_full_playbook() {
    local playbook_path="$REPO_ROOT/local.yml"

    ui_banner "Run Full Fedora Workstation Playbook" "$C_INDIGO"

    if [ ! -f "$playbook_path" ]; then
        ui_err "Playbook not found at: $playbook_path"
        return 1
    fi

    if ! command -v ansible-playbook >/dev/null 2>&1; then
        ui_err "'ansible-playbook' is not installed or not in PATH."
        ui_warn "Install it with: sudo dnf install ansible"
        return 1
    fi

    local become_flag="--ask-become-pass"
    if [ "$(id -u)" -eq 0 ]; then
        become_flag=""
    fi

    ui_info_table "Parameter,Value" \
        "Playbook File,$playbook_path" \
        "Privilege Escalation,${become_flag:-root}" \
        "Command,ansible-playbook $playbook_path $become_flag"
    echo ""
    ansible-playbook "$playbook_path" $become_flag
    local status=$?

    if [ $status -eq 0 ]; then
        echo
        ui_ok "✓ Full Ansible playbook completed successfully!"
    else
        echo
        ui_err "Playbook execution finished with exit code ${status}."
    fi
    return $status
}

run_playbook_subtask() {
    local subtask_tag="$1"
    local playbook_path="$REPO_ROOT/local.yml"

    if [ ! -f "$playbook_path" ]; then
        ui_err "Playbook not found at: $playbook_path"
        return 1
    fi

    if ! command -v ansible-playbook >/dev/null 2>&1; then
        ui_err "'ansible-playbook' is not installed or not in PATH."
        ui_warn "Install it with: sudo dnf install ansible"
        return 1
    fi

    local become_flag="--ask-become-pass"
    if [ "$(id -u)" -eq 0 ]; then
        become_flag=""
    fi

    echo
    ui_info_table "Subtask Parameter,Value" \
        "Ansible Tag,--tags ${subtask_tag}" \
        "Playbook,$playbook_path" \
        "Flags,${become_flag:-none}"
    ansible-playbook "$playbook_path" --tags "$subtask_tag" $become_flag
}

prompt_run_playbook_subtask() {
    local feature_name="$1"
    local subtask_tag="$2"
    local desc="$3"

    echo
    ui_warn "[!] Required dependency or provisioned file for '${feature_name}' is missing."
    ui_info_table "Missing Dependency,Details" \
        "Feature,${feature_name}" \
        "Ansible Tag,--tags ${subtask_tag}" \
        "Description,${desc}"
    ask_yn "Would you like to run the Ansible playbook for this subtask now?" "Y" run_choice
    run_choice="${run_choice:-Y}"
    if [[ "$run_choice" =~ ^[Yy]$ ]]; then
        run_playbook_subtask "$subtask_tag"
        return $?
    fi
    return 1
}

require_sudo() {
    local reason="${1:-perform administrative tasks}"
    SUDO_CMD=""
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            ui_err "sudo is required to ${reason}."
            return 1
        fi
        if ! sudo -v; then
            ui_err "sudo authentication failed."
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
        ui_ok "✓ Added $comment hook to ~/.bashrc"
    else
        ui_warn "• $comment already configured in ~/.bashrc"
    fi

    if [ -f "$HOME/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
        touch "$HOME/.zshrc"
        if ! grep -q "$pattern" "$HOME/.zshrc" 2>/dev/null; then
            {
                echo ""
                echo "# $comment"
                echo "$line"
            } >> "$HOME/.zshrc"
            ui_ok "✓ Added $comment hook to ~/.zshrc"
        fi
    fi
}

configure_homebrew() {
    ui_banner "[1/8] Configure Homebrew Environment & PATH" "$C_ORANGE"

    local BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
    if [ ! -x "$BREW_PATH" ] && command -v brew >/dev/null 2>&1; then
        BREW_PATH="$(command -v brew)"
    fi

    local SHELLENV_LINE='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    ui_info_table "Setting,Value" \
        "Target User,$(whoami)" \
        "Binary Path,$BREW_PATH" \
        "Shell Profiles,~/.bashrc & ~/.zshrc" \
        "Status,$([ -x "$BREW_PATH" ] && echo "Installed" || echo "Not Installed")"

    if [ -x "$BREW_PATH" ]; then
        ui_ok "Found Homebrew at: ${BREW_PATH}"
        ensure_shell_rc_line "linuxbrew.*shellenv" "Homebrew environment" "$SHELLENV_LINE"
        eval "$($BREW_PATH shellenv)"
        echo -e "$(ui_c "bold:green" "✓ Homebrew active:") $(brew --version | head -n 1)"
    else
        ui_warn "Homebrew is not detected at /home/linuxbrew/.linuxbrew/bin/brew."
        ask_yn "Would you like to install Homebrew now?" "N" choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            ui_info "Running Homebrew installer..."
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
                ensure_shell_rc_line "linuxbrew.*shellenv" "Homebrew environment" "$SHELLENV_LINE"
                ui_ok "✓ Homebrew installed and configured!"
            fi
        else
            ui_warn "Skipping Homebrew configuration."
        fi
    fi
}

install_pixi() {
    ui_banner "[2/8] Install Pixi Package Manager" "$C_MINT"

    local PIXI_BIN="$HOME/.pixi/bin/pixi"
    local pixi_ver="Not Installed"
    if [ -x "$PIXI_BIN" ] || command -v pixi >/dev/null 2>&1; then
        pixi_ver="$(pixi --version 2>/dev/null || "$PIXI_BIN" --version)"
    fi
    ui_info_table "Setting,Value" \
        "Package Manager,Pixi (https://pixi.sh)" \
        "Install Prefix,$HOME/.pixi/bin" \
        "Detected Version,$pixi_ver"

    if [ -x "$PIXI_BIN" ] || command -v pixi >/dev/null 2>&1; then
        echo -e "$(ui_c "bold:green" "Pixi is already installed:") $pixi_ver"
        ask_yn "Do you want to reinstall/update Pixi?" "N" reinstall_choice
        if [[ ! "$reinstall_choice" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    ui_info "Downloading and running Pixi official installer (https://pixi.sh)..."
    curl -fsSL https://pixi.sh/install.sh | bash

    # Configure PATH in shell files
    local PIXI_DIR="$HOME/.pixi/bin"
    if [ -d "$PIXI_DIR" ]; then
        export PATH="$PIXI_DIR:$PATH"
        ensure_shell_rc_line '\.pixi/bin' "Pixi package manager" 'export PATH="$HOME/.pixi/bin:$PATH"'
        echo -e "$(ui_c "green" "✓ Pixi successfully installed:") $("$PIXI_DIR/pixi" --version)"
    else
        ui_err "Pixi directory $PIXI_DIR was not found after install."
    fi
}

update_terminal_utilities() {
    ui_banner "[3/8] Refresh TLDR & Terminal Utilities Cache" "$C_TEAL"
    ui_info_table "Utility,Operation" \
        "tldr,Update community command examples cache" \
        "bat,Rebuild syntax highlighting & theme binary cache" \
        "git-lfs,Configure user-level Git Large File Storage hooks" \
        "fc-cache,Force refresh user and system font caches" \
        "mandb,Update manual page index database"

    # 1. Update TLDR pages cache
    if command -v tldr >/dev/null 2>&1; then
        if ui_spin "Updating TLDR pages cache..." bash -c 'tldr --update || tldr -u' >/dev/null 2>&1; then
            ui_ok "✓ TLDR documentation cache updated."
        else
            ui_warn "TLDR update completed with notices."
        fi
    else
        ui_warn "• 'tldr' command not found, skipping."
    fi

    # 2. Update Bat syntax & theme cache
    if command -v bat >/dev/null 2>&1; then
        ui_spin "Updating Bat syntax & theme cache..." bash -c 'bat cache --build' >/dev/null 2>&1 || true
        ui_ok "✓ Bat cache built."
    fi

    # 3. Configure Git LFS for user
    if command -v git-lfs >/dev/null 2>&1; then
        ui_spin "Configuring Git LFS hooks for user profile..." bash -c 'git lfs install --skip-repo' >/dev/null 2>&1 || true
        ui_ok "✓ Git LFS configured."
    fi

    # 4. Refresh font caches
    if command -v fc-cache >/dev/null 2>&1; then
        ui_spin "Refreshing font caches (fc-cache)..." fc-cache -f >/dev/null 2>&1 || true
        ui_ok "✓ Font cache refreshed."
    fi

    # 5. Refresh Man database if available
    if command -v mandb >/dev/null 2>&1; then
        ui_spin "Updating man database cache..." mandb -q >/dev/null 2>&1 || true
        ui_ok "✓ Man database refreshed."
    fi

    ui_ok "✓ All terminal utilities updated successfully!"
}

setup_distrobox() {
    ui_banner "[4/8] Set Up Ubuntu Distrobox Container" "$C_ORANGE"

    local CONTAINER_NAME="ubuntu-toolbox"
    local CONTAINER_IMAGE="quay.io/toolbx/ubuntu-toolbox:latest"
    ui_info_table "Container Property,Value" \
        "Container Name,$CONTAINER_NAME" \
        "OCI Image,$CONTAINER_IMAGE" \
        "Default Add-on,UniGetUI (.deb) auto-export"

    # Verify distrobox is available
    if ! command -v distrobox >/dev/null 2>&1; then
        prompt_run_playbook_subtask "Distrobox" "packages_dnf" "Install base DNF packages including distrobox" || return 1
        if ! command -v distrobox >/dev/null 2>&1; then
            ui_err "'distrobox' is still not installed or not in PATH."
            return 1
        fi
    fi

    # Check if a container with this name already exists
    if distrobox list 2>/dev/null | grep -q "^${CONTAINER_NAME}\b\|[[:space:]]${CONTAINER_NAME}[[:space:]]"; then
        ui_warn "• Distrobox container '${CONTAINER_NAME}' already exists."
        ask_yn "Do you want to replace it? This will stop and remove the existing container." "N" replace_choice
        if [[ "$replace_choice" =~ ^[Yy]$ ]]; then
            ui_info "Stopping and removing existing container '${CONTAINER_NAME}'..."
            distrobox stop --yes "${CONTAINER_NAME}" 2>/dev/null || true
            distrobox rm --yes "${CONTAINER_NAME}" 2>/dev/null || true
        else
            ui_warn "Skipping distrobox setup."
            return 0
        fi
    fi

    ui_info "Creating distrobox container '${CONTAINER_NAME}' from ${CONTAINER_IMAGE}..."
    ui_warn "Note: The image will be pulled on first run — this may take a moment."

    if distrobox create \
        --name "${CONTAINER_NAME}" \
        --image "${CONTAINER_IMAGE}" \
        --yes; then
        ui_ok "✓ Distrobox container '${CONTAINER_NAME}' created successfully."
        ui_info "Initializing container (first-run setup)..."
        distrobox enter "${CONTAINER_NAME}" -- true 2>/dev/null \
            && echo -e "$(ui_c "green" "✓ Container initialized and ready.")" \
            || echo -e "$(ui_c "yellow" "• Container created — it will finish initializing on first 'distrobox enter ${CONTAINER_NAME}'.")"

        # Option to default install UniGetUI (deb) inside the container
        local install_unigetui_choice
        ask_yn "Install UniGetUI.linux-x64.deb inside '${CONTAINER_NAME}' by default?" "Y" install_unigetui_choice
        install_unigetui_choice="${install_unigetui_choice:-Y}"
        if [[ "$install_unigetui_choice" =~ ^[Yy]$ ]]; then
            install_unigetui_deb_distrobox "${CONTAINER_NAME}"
        fi
    else
        ui_err "Failed to create distrobox container '${CONTAINER_NAME}'."
        return 1
    fi
}

install_unigetui_deb_distrobox() {
    local container_name="${1:-ubuntu-toolbox}"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/unigetui_downloads"
    mkdir -p "$cache_dir"

    ui_banner "Install UniGetUI (.deb) into Distrobox" "$C_CYAN"
    ui_info_table "Property,Value" \
        "Upstream Repository,Devolutions/UniGetUI" \
        "Target Container,$container_name" \
        "Download Cache,$cache_dir"

    if ! command -v distrobox >/dev/null 2>&1; then
        ui_err "'distrobox' is not installed."
        return 1
    fi

    ui_info "[*] Fetching latest UniGetUI .deb release from GitHub..."
    local deb_info
    deb_info=$(python3 -c "
import urllib.request, json, sys
repo = 'Devolutions/UniGetUI'
try:
    url = f'https://api.github.com/repos/{repo}/releases/latest'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'})
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.loads(r.read().decode())
    for a in d.get('assets', []):
        name = a.get('name', '')
        url = a.get('browser_download_url', '')
        if name.endswith('.deb') and 'x64' in name:
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
        ui_warn "Could not resolve latest .deb from GitHub API. Using fallback URL..."
        deb_url="https://github.com/Devolutions/UniGetUI/releases/download/v2026.3.3/UniGetUI.linux-x64.deb"
        deb_name="UniGetUI.linux-x64.deb"
    fi

    local target_file="$cache_dir/$deb_name"
    ui_info "[*] Downloading ${deb_name}..."
    if ! curl -fLC - --progress-bar -o "$target_file" "$deb_url"; then
        ui_err "Failed to download UniGetUI .deb from $deb_url"
        return 1
    fi

    echo
    ui_info "[*] Installing ${deb_name} into '${container_name}' container via apt..."
    if distrobox enter "${container_name}" -- sudo apt-get update && \
       distrobox enter "${container_name}" -- sudo apt-get install -y "$target_file"; then
        echo
        ui_info "[*] Exporting UniGetUI desktop app and binary to host..."
        distrobox enter "${container_name}" -- distrobox-export --app unigetui 2>/dev/null || true
        distrobox enter "${container_name}" -- distrobox-export --bin /usr/bin/unigetui --export-path "$HOME/.local/bin" 2>/dev/null || true
        ui_ok "✓ UniGetUI (.deb) installed and exported successfully from Distrobox!"
    else
        ui_err "Failed to install UniGetUI .deb inside distrobox container."
        return 1
    fi
}

configure_flathub_user() {
    ui_banner "[5/8] Add Flathub Remote (User)" "$C_TEAL"
    ui_info_table "Remote Property,Value" \
        "Remote Name,flathub (user scope)" \
        "Repository URL,https://dl.flathub.org/repo/flathub.flatpakrepo" \
        "Target User,$(whoami)"

    if ! command -v flatpak >/dev/null 2>&1; then
        prompt_run_playbook_subtask "Flatpak" "flatpak_cli" "Install flatpak package manager only" || return 1
        if ! command -v flatpak >/dev/null 2>&1; then
            ui_err "'flatpak' is still not installed or not in PATH."
            return 1
        fi
    fi

    ui_info "Adding Flathub repository for user: $(whoami)..."
    if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        ui_ok "✓ Flathub remote added successfully for user."
    else
        ui_err "Failed to add Flathub user remote."
        return 1
    fi
}

configure_fedora_flatpak_user() {
    ui_banner "[6/8] Add Fedora Flatpak Remote (User)" "$C_TEAL"
    ui_info_table "Remote Property,Value" \
        "Remote Name,fedora (user scope)" \
        "Registry URI,oci+https://registry.fedoraproject.org" \
        "Target User,$(whoami)"

    if ! command -v flatpak >/dev/null 2>&1; then
        prompt_run_playbook_subtask "Flatpak" "flatpak_cli" "Install flatpak package manager only" || return 1
        if ! command -v flatpak >/dev/null 2>&1; then
            ui_err "'flatpak' is still not installed or not in PATH."
            return 1
        fi
    fi

    ui_info "Adding Fedora Flatpak repository for user: $(whoami)..."
    if flatpak remote-add --user --if-not-exists fedora oci+https://registry.fedoraproject.org; then
        ui_ok "✓ Fedora Flatpak remote added successfully for user."
    else
        ui_err "Failed to add Fedora Flatpak user remote."
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
        "Target User: $(whoami)\nScope: --user (unprivileged)" \
        "Apply Selected Remotes" \
        "Back to Main Menu" \
        "$C_TEAL" || return 0

    echo
    ui_info "=== Configuring Selected User Flatpak Remotes ==="
    [ "${CB_SELECTED[0]}" -eq 1 ] && configure_flathub_user
    [ "${CB_SELECTED[1]}" -eq 1 ] && configure_fedora_flatpak_user

    echo
    ui_ok "✓ Flatpak remotes configuration complete!"
    ui_pause "Press Enter to continue..."
}

disable_pipewire_streaming() {
    ui_banner "Disable PipeWire Audio Redirection" "$C_PINK"
    ui_info_table "Cleanup Target,Path" \
        "Sender Profiles,~/.bashrc and ~/.profile" \
        "Desktop Environment,~/.config/environment.d/pipewire-share.conf" \
        "Receiver TCP Config,~/.config/pipewire/pipewire-pulse.conf.d/tcp-share.conf"

    require_sudo "disable audio redirection" || return 1

    # 1. Ask for Sender (to remove redirection configs)
    echo -e "$(ui_c "bold" "[Step 1: The Sound Source / Sender (Transmitter)]")"
    ask_input "Enter username of the SENDER (whose redirection you want to remove) [default: $(whoami)]: " USER_SENDER
    USER_SENDER=${USER_SENDER:-$(whoami)}
    if ! id "$USER_SENDER" &>/dev/null; then
        ui_err "User '$USER_SENDER' does not exist."
        return 1
    fi
    local SENDER_HOME
    SENDER_HOME=$(getent passwd "$USER_SENDER" | cut -d: -f6)

    ui_info "[*] Removing audio redirection from SENDER ($USER_SENDER)..."

    # Remove from ~/.bashrc
    local BASHRC_FILE="$SENDER_HOME/.bashrc"
    if [[ -f "$BASHRC_FILE" ]]; then
        $SUDO_CMD sed -i '/# Route audio output to/d' "$BASHRC_FILE"
        $SUDO_CMD sed -i '/export PULSE_SERVER=tcp:/d' "$BASHRC_FILE"
        ui_ok "✓ Cleaned $USER_SENDER's ~/.bashrc"
    fi

    # Remove from ~/.profile
    local PROFILE_FILE="$SENDER_HOME/.profile"
    if [[ -f "$PROFILE_FILE" ]]; then
        $SUDO_CMD sed -i '/# Route audio output to/d' "$PROFILE_FILE"
        $SUDO_CMD sed -i '/export PULSE_SERVER=tcp:/d' "$PROFILE_FILE"
        ui_ok "✓ Cleaned $USER_SENDER's ~/.profile"
    fi

    # Remove environment.d config
    local ENV_CONF="$SENDER_HOME/.config/environment.d/pipewire-share.conf"
    if [[ -f "$ENV_CONF" ]]; then
        $SUDO_CMD rm -f "$ENV_CONF"
        ui_ok "✓ Removed $ENV_CONF"
    fi

    # 2. Ask for Receiver (to remove TCP listener config)
    echo ""
    echo -e "$(ui_c "bold" "[Step 2: The Sound Output / Receiver (Speaker Owner)]")"
    ask_input "Enter username of the RECEIVER (optional, press Enter to skip): " USER_RECEIVER
    if [[ -n "$USER_RECEIVER" ]]; then
        if ! id "$USER_RECEIVER" &>/dev/null; then
            ui_warn "Warning: User '$USER_RECEIVER' not found. Skipping receiver cleanup."
        else
            local RECEIVER_HOME
            RECEIVER_HOME=$(getent passwd "$USER_RECEIVER" | cut -d: -f6)
            local TCP_CONF="$RECEIVER_HOME/.config/pipewire/pipewire-pulse.conf.d/tcp-share.conf"
            if [[ -f "$TCP_CONF" ]]; then
                $SUDO_CMD rm -f "$TCP_CONF"
                ui_ok "✓ Removed $TCP_CONF"
            fi

            if $SUDO_CMD systemctl --user -M "${USER_RECEIVER}@" is-active --quiet pipewire-pulse.service 2>/dev/null; then
                $SUDO_CMD systemctl --user -M "${USER_RECEIVER}@" restart pipewire.service pipewire-pulse.service wireplumber.service
                ui_ok "✓ Restarted pipewire, pipewire-pulse and wireplumber for $USER_RECEIVER."
            fi
        fi
    fi

    echo ""
    ui_banner "PipeWire Audio Redirection Disabled!" "$C_GREEN"
    echo "Note: If $USER_SENDER is currently logged in, please log out and"
    echo "      back in for desktop environment changes to fully reset."
    ui_hr
}

enable_pipewire_streaming() {
    ui_banner "Enable PipeWire Audio Redirection" "$C_PINK"

    if [ ! -t 0 ] && [ -z "${USER_RECEIVER:-}" ]; then
        ui_warn "Non-interactive session detected; skipping PipeWire setup (requires user input)."
        return 0
    fi

    ui_info_table "Audio Role,Description" \
        "The Sender (Source),User running apps (Firefox; games; mpv) whose audio is routed out" \
        "The Receiver (Speakers),User with physical access to speakers/headphones playing the audio" \
        "Transport Protocol,PipeWire-Pulse native TCP stream (default port 4713)"
    echo ""

    ui_warn "Note: PipeWire multi-user audio setup requires administrative privileges."
    require_sudo "configure PipeWire audio redirection" || return 1""

    # 1. Receiver (Speaker owner)
    echo -e "$(ui_c "bold" "[Step 1: The Sound Output / Receiver]")"
    ask_input "Enter username of the user with the WORKING SPEAKERS [default: $(whoami)]: " USER_RECEIVER
    USER_RECEIVER=${USER_RECEIVER:-$(whoami)}
    if ! id "$USER_RECEIVER" &>/dev/null; then
        ui_err "User '$USER_RECEIVER' does not exist."
        return 1
    fi
    local RECEIVER_HOME
    RECEIVER_HOME=$(getent passwd "$USER_RECEIVER" | cut -d: -f6)

    # 2. Sender (Music/App owner)
    echo ""
    echo -e "$(ui_c "bold" "[Step 2: The Sound Source / Sender]")"
    ask_input "Enter username of the user who wants to TRANSMIT/SEND audio: " USER_SENDER
    if ! id "$USER_SENDER" &>/dev/null; then
        ui_err "User '$USER_SENDER' does not exist."
        return 1
    fi
    local SENDER_HOME
    SENDER_HOME=$(getent passwd "$USER_SENDER" | cut -d: -f6)

    # 3. Connection details
    echo ""
    echo -e "$(ui_c "bold" "[Step 3: Network Connection]")"
    echo "  - Same PC: use 127.0.0.1"
    echo "  - Over LAN: enter the Receiver's IP address on the local network"
    ask_input "Enter IP address [default: 127.0.0.1]: " BIND_IP
    BIND_IP=${BIND_IP:-127.0.0.1}

    ask_input "Enter port to use [default: 4713]: " BIND_PORT
    BIND_PORT=${BIND_PORT:-4713}

    echo ""
    ui_info "[*] Configuring the RECEIVER ($USER_RECEIVER) to accept incoming audio..."

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
        $SUDO_CMD systemctl --user -M "${USER_RECEIVER}@" restart pipewire.service pipewire-pulse.service wireplumber.service
        ui_ok "✓ pipewire, pipewire-pulse and wireplumber restarted for $USER_RECEIVER."
    else
        ui_warn "• $USER_RECEIVER is not currently active; configuration will load on next login."
    fi

    # Configure Sender environment
    echo ""
    ui_info "[*] Configuring the SENDER ($USER_SENDER) to route audio to $USER_RECEIVER..."

    local ENV_LINE="export PULSE_SERVER=tcp:${BIND_IP}:${BIND_PORT}"

    # Terminal apps (~/.bashrc)
    local BASHRC_FILE="$SENDER_HOME/.bashrc"
    if $SUDO_CMD grep -Fxq "$ENV_LINE" "$BASHRC_FILE" 2>/dev/null; then
        ui_warn "• Route already set in $USER_SENDER's .bashrc."
    else
        echo "" | $SUDO_CMD tee -a "$BASHRC_FILE" >/dev/null
        echo "# Route audio output to $USER_RECEIVER" | $SUDO_CMD tee -a "$BASHRC_FILE" >/dev/null
        echo "$ENV_LINE" | $SUDO_CMD tee -a "$BASHRC_FILE" >/dev/null
        $SUDO_CMD chown "$USER_SENDER":"$USER_SENDER" "$BASHRC_FILE"
        ui_ok "✓ Configured $USER_SENDER's ~/.bashrc (Terminal apps)"
    fi

    # Desktop sessions (~/.profile)
    local PROFILE_FILE="$SENDER_HOME/.profile"
    if $SUDO_CMD grep -Fxq "$ENV_LINE" "$PROFILE_FILE" 2>/dev/null; then
        ui_warn "• Route already set in $USER_SENDER's .profile."
    else
        echo "" | $SUDO_CMD tee -a "$PROFILE_FILE" >/dev/null
        echo "# Route audio output to $USER_RECEIVER" | $SUDO_CMD tee -a "$PROFILE_FILE" >/dev/null
        echo "$ENV_LINE" | $SUDO_CMD tee -a "$PROFILE_FILE" >/dev/null
        $SUDO_CMD chown "$USER_SENDER":"$USER_SENDER" "$PROFILE_FILE"
        ui_ok "✓ Configured $USER_SENDER's ~/.profile (Login sessions)"
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
    ui_ok "✓ Configured $USER_SENDER's environment.d (Desktop GUI icons and launchers)"

    echo ""
    ui_banner "Setup Complete & Fully Persistent!" "$C_GREEN"
    ui_info_table "Configured Role,Status" \
        "Receiver ($USER_RECEIVER),Listening on tcp:${BIND_IP}:${BIND_PORT} and playing to speakers" \
        "Sender ($USER_SENDER),Routing PULSE_SERVER to tcp:${BIND_IP}:${BIND_PORT}" \
        "Session Notice,Log out and back in once for desktop launcher changes to apply"
    ui_hr
}

configure_pipewire_streaming() {
    if [ ! -t 0 ]; then
        enable_pipewire_streaming
        return 0
    fi

    ui_banner "PipeWire Multi-User Audio Redirection" "$C_PINK"
    ui_info_table "Property,Details" \
        "Subsystem,PipeWire / PulseAudio TCP Bridge" \
        "Default Endpoint,127.0.0.1:4713 (Local or LAN IP)" \
        "Persistence,~/.bashrc; ~/.profile; ~/.config/environment.d"

    local pw_items=(
        "1\t🔊 Enable PipeWire Redirection…\tRoute audio output across local users or machines via TCP"
        "2\t🔇 Disable PipeWire Redirection…\tRemove audio routes, clean up environment files, and restore defaults"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    local pw_choice
    pw_choice=$(gum_action_menu "PipeWire Audio Redirection" "Option" "${pw_items[@]}")

    case "$pw_choice" in
        1) enable_pipewire_streaming ;;
        2) disable_pipewire_streaming ;;
        *) return 0 ;;
    esac
}

run_waydroid_init_wizard() {
    ui_banner "Waydroid Initialization Wizard" "$C_GREEN"

    if [ ! -t 0 ]; then
        ui_warn "Non-interactive session detected; skipping Waydroid setup (requires user input)."
        return 0
    fi

    local SYSTEM_OTA="https://ota.waydro.id/system"
    local VENDOR_OTA="https://ota.waydro.id/vendor"
    ui_info_table "OTA Endpoint,Channel URL" \
        "System OTA,$SYSTEM_OTA" \
        "Vendor OTA,$VENDOR_OTA" \
        "Image Directory,/var/lib/waydroid/images"

    ui_warn "Note: Waydroid initialization requires administrative privileges."
    require_sudo "configure Waydroid" || return 1

    # 1. Official Fedora Repository Check & Install
    ui_info "[*] Checking Waydroid package..."
    if ! rpm -q waydroid &>/dev/null; then
        ui_warn "[!] Waydroid is not installed."
        prompt_run_playbook_subtask "Waydroid" "packages_dnf,waydroid" "Install Waydroid package and configure integration"
        if ! rpm -q waydroid &>/dev/null; then
            ask_yn "Install waydroid from Fedora's official repos now via dnf?" "Y" INSTALL_CONFIRM
            INSTALL_CONFIRM="${INSTALL_CONFIRM:-Y}"

            if [[ "$INSTALL_CONFIRM" =~ ^[Yy]$ ]]; then
                ui_info "[*] Installing waydroid and sqlite via dnf..."
                $SUDO_CMD dnf install -y waydroid sqlite
            else
                ui_err "[-] Cannot proceed without installing waydroid."
                return 1
            fi
        fi
    else
        ui_ok "[+] Waydroid is already installed from official repos."
    fi

    echo ""

    # 2. Interactive Selection: Google Play vs Vanilla (using HIG menu with background selection)
    ui_info_table "Image Variant,Included Components" \
        "GAPPS (Default),Includes Google Play Store & Google Mobile Services (GMS)" \
        "VANILLA,Clean open-source LineageOS without Google services"
    local img_choice=""
    ask_menu img_choice "Select Android System Image" \
        "1|GAPPS — Google Play Store & Google Mobile Services" \
        "2|VANILLA — Clean Open-Source LineageOS"
    local SYSTEM_TYPE="GAPPS"
    [ "${img_choice:-1}" = "2" ] && SYSTEM_TYPE="VANILLA"

    echo ""
    ui_ok "[*] Selected build: ${SYSTEM_TYPE}"

    # 3. Interactive Force/Wipe Option
    local FORCE_FLAG=""
    if [[ -d "/var/lib/waydroid/images" && "$($SUDO_CMD ls -A /var/lib/waydroid/images 2>/dev/null)" ]]; then
        echo ""
        ui_warn "[!] Existing Waydroid images detected in /var/lib/waydroid/images."
        ask_yn "Do you want to force wipe and re-download images?" "N" FORCE_CHOICE
        FORCE_CHOICE="${FORCE_CHOICE:-N}"
        if [[ "$FORCE_CHOICE" =~ ^[Yy]$ ]]; then
            FORCE_FLAG="-f"
        fi
    fi

    # 4. Stop service if active
    if systemctl is-active --quiet waydroid-container 2>/dev/null; then
        ui_info "[*] Stopping running container daemon..."
        $SUDO_CMD systemctl stop waydroid-container
    fi

    # 5. Initialize Waydroid
    echo ""
    ui_info "[*] Initializing Waydroid (${SYSTEM_TYPE})..."
    ui_info "[*] Pulling from official OTA endpoints..."

    $SUDO_CMD waydroid init \
        -s "${SYSTEM_TYPE}" \
        -c "${SYSTEM_OTA}" \
        -v "${VENDOR_OTA}" \
        ${FORCE_FLAG}

    # 6. Service Management
    echo ""
    ui_info "[*] Enabling and starting waydroid-container.service..."
    $SUDO_CMD systemctl enable --now waydroid-container

    echo ""
    ui_banner "Waydroid Initialized Successfully!" "$C_GREEN"

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
        ui_err "libndk script not found at: $NDK_SCRIPT"
        return 1
    fi

    ui_banner "Waydroid libndk ARM Translation Setup" "$C_GREEN"
    ui_info_table "Property,Details" \
        "Component,libndk ARM/ARM64 Translation Layer" \
        "Helper Script,$NDK_SCRIPT" \
        "Target CPU,AMD / Intel x86_64 Host"
    ask_menu ndk_choice "Select libndk Action" "1|Install libndk ARM Translation" "2|Remove libndk ARM Translation" "0|Back to Waydroid Menu"
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
            ui_err "Invalid option: '$ndk_choice'."
            ;;
    esac
}

manage_widevine() {
    local WIDEVINE_SCRIPT="$REPO_ROOT/Scripts/install-widevine.sh"

    if [[ ! -f "$WIDEVINE_SCRIPT" ]]; then
        ui_err "Widevine script not found at: $WIDEVINE_SCRIPT"
        return 1
    fi

    ui_banner "Waydroid Widevine DRM Setup" "$C_GREEN"
    ui_info_table "Property,Details" \
        "Component,Google Widevine L3 DRM" \
        "Helper Script,$WIDEVINE_SCRIPT" \
        "Target Subsystem,Waydroid Android Container"
    ask_menu wv_choice "Select Widevine Action" "1|Install Widevine DRM" "2|Remove Widevine DRM" "0|Back to Waydroid Menu"
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
            ui_err "Invalid option: '$wv_choice'."
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

    echo
    ui_info "[*] Resolving & downloading latest ${app_name}..."
    ui_info_table "APK Package,Details" \
        "Application,${app_name}" \
        "Source URL,${download_url}" \
        "Local Cache,${target_apk}"

    if ! curl -fLC - --progress-bar -o "$target_apk" "$download_url"; then
        ui_err "Failed to download ${app_name} from ${download_url}"
        return 1
    fi

    ui_ok "[+] Successfully downloaded ${app_name}."

    # Verify if waydroid container is available to install
    if command -v waydroid &>/dev/null; then
        ui_info "[*] Installing ${dest_filename} into Waydroid container..."
        if waydroid app install "$target_apk"; then
            ui_ok "[+] ${app_name} installed into Waydroid successfully!"
        else
            ui_warn "[!] 'waydroid app install' returned non-zero."
            echo -e "    The APK is saved at: ${target_apk}"
            echo -e "    You can install it manually inside Waydroid session using:"
            echo -e "    waydroid app install \"${target_apk}\""
        fi
    else
        ui_warn "[!] waydroid command not found. APK saved at: ${target_apk}"
    fi
}

install_fdroid_official() {
    download_and_install_apk "F-Droid Official Client" "https://f-droid.org/F-Droid.apk" "F-Droid.apk"
}

install_aurora_store() {
    local url
    url=$(ui_spin_fn "Resolving latest fdroid apk..." fetch_latest_fdroid_apk_url "com.aurora.store" 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        url="https://f-droid.org/repo/com.aurora.store_76.apk"
    fi
    download_and_install_apk "Aurora Store" "$url" "AuroraStore.apk"
}

install_neostore_fdroid() {
    local url
    url=$(ui_spin_fn "Resolving latest fdroid apk..." fetch_latest_fdroid_apk_url "com.machiav3lli.fdroid" 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        url="https://f-droid.org/repo/com.machiav3lli.fdroid_1303.apk"
    fi
    download_and_install_apk "Neo Store (Modern F-Droid Client)" "$url" "NeoStore.apk"
}

install_smartdock() {
    local url
    url=$(ui_spin_fn "Resolving latest fdroid apk..." fetch_latest_fdroid_apk_url "cu.axel.smartdock" 2>/dev/null || true)
    if [[ -z "$url" ]]; then
        url="https://f-droid.org/repo/cu.axel.smartdock_1150.apk"
    fi
    download_and_install_apk "SmartDock Desktop Launcher" "$url" "SmartDock.apk"
}

install_mobilerun() {
    ui_banner "MobileRun Setup (via uv)" "$C_GREEN"
    ui_info_table "Property,Details" \
        "Tool,MobileRun Android Automation Harness" \
        "Installer,uv tool install mobilerun" \
        "Binary Path,$HOME/.local/bin/mobilerun"

    if ! command -v uv >/dev/null 2>&1; then
        ui_err "'uv' is not installed or not in PATH."
        ui_warn "Install uv with: sudo dnf install uv   or   curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi

    ui_info "[*] Installing mobilerun tool using uv..."
    uv tool install mobilerun

    # Ensure ~/.local/bin is in PATH for current subshell
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if command -v mobilerun >/dev/null 2>&1 || [ -x "$HOME/.local/bin/mobilerun" ]; then
        local MR_BIN
        MR_BIN="$(command -v mobilerun 2>/dev/null || echo "$HOME/.local/bin/mobilerun")"
        ui_ok "✓ mobilerun is installed."

        if command -v adb >/dev/null 2>&1; then
            echo
            ui_info "[*] Checking connected ADB devices..."
            adb devices -l
        fi

        echo ""
        ui_warn "Note: 'mobilerun setup' installs its helper components to one of your connected ADB devices."
        ask_yn "Run 'mobilerun setup' now?" "Y" run_mr_setup
        run_mr_setup="${run_mr_setup:-Y}"
        if [[ "$run_mr_setup" =~ ^[Yy]$ ]]; then
            "$MR_BIN" setup
        else
            ui_warn "Skipped running setup. Run '$MR_BIN setup' when your ADB target is connected."
        fi
    else
        ui_err "mobilerun binary not found after installation."
        return 1
    fi
}

install_xtmapper() {
    local url
    url=$(ui_spin_fn "Resolving latest github apk..." fetch_latest_github_apk_url "Xtr126/XtMapper" 2>/dev/null || true)
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
        "Select Waydroid APKs & Add-ons to Install" \
        "Cache Directory: ${XDG_CACHE_HOME:-$HOME/.cache}/waydroid_downloads\nTarget: Active Waydroid Container & ADB" \
        "Install Selected Apps" \
        "Back to Waydroid Menu" \
        "$C_GREEN" || return 0

    echo
    ui_info "=== Installing Selected Waydroid Add-ons ==="
    [ "${CB_SELECTED[0]}" -eq 1 ] && install_fdroid_official
    [ "${CB_SELECTED[1]}" -eq 1 ] && install_aurora_store
    [ "${CB_SELECTED[2]}" -eq 1 ] && install_neostore_fdroid
    [ "${CB_SELECTED[3]}" -eq 1 ] && install_smartdock
    [ "${CB_SELECTED[4]}" -eq 1 ] && install_xtmapper
    [ "${CB_SELECTED[5]}" -eq 1 ] && install_3dmark
    [ "${CB_SELECTED[6]}" -eq 1 ] && install_mobilerun
    echo
    ui_ok "[+] Completed installation of selected apps!"
    ui_pause "Press Enter to continue..."
}

apply_bazzite_waydroid_config() {
    ui_banner "Install Bazzite Custom Waydroid Files" "$C_GREEN"
    local SOURCE_DIR="$REPO_ROOT/files/waydroid"
    ui_info_table "Asset Category,Destination" \
        "Source Directory,$SOURCE_DIR" \
        "Control Scripts,/usr/libexec/waydroid-container-* & /usr/bin/waydroid-*" \
        "Launcher Defaults,/etc/default/waydroid-launcher" \
        "Polkit Policy,/usr/share/polkit-1/actions & rules.d"

    if [ ! -d "$SOURCE_DIR" ]; then
        ui_err "Source directory not found: $SOURCE_DIR"
        return 1
    fi

    ui_info "[*] Copying container control scripts to /usr/libexec and /usr/bin..."
    sudo install -m 0755 "$SOURCE_DIR/waydroid-container-start" /usr/libexec/waydroid-container-start
    sudo install -m 0755 "$SOURCE_DIR/waydroid-container-stop" /usr/libexec/waydroid-container-stop
    sudo install -m 0755 "$SOURCE_DIR/waydroid-container-restart" /usr/libexec/waydroid-container-restart
    sudo install -m 0755 "$SOURCE_DIR/waydroid-fix-controllers" /usr/libexec/waydroid-fix-controllers
    sudo install -m 0755 "$SOURCE_DIR/waydroid-choose-gpu" /usr/bin/waydroid-choose-gpu
    sudo install -m 0755 "$SOURCE_DIR/waydroid-launcher" /usr/bin/waydroid-launcher

    ui_info "[*] Copying launcher defaults to /etc/default/waydroid-launcher..."
    sudo install -m 0644 "$SOURCE_DIR/waydroid-launcher.default" /etc/default/waydroid-launcher

    ui_info "[*] Installing Polkit policy and rules for unprivileged container control..."
    sudo mkdir -p /usr/share/polkit-1/actions /usr/share/polkit-1/rules.d
    sudo install -m 0644 "$SOURCE_DIR/org.bazzite.waydroid.policy" /usr/share/polkit-1/actions/org.bazzite.waydroid.policy
    sudo install -m 0644 "$SOURCE_DIR/30-waydroid.rules" /usr/share/polkit-1/rules.d/30-waydroid.rules

    ui_ok "[+] Successfully applied Bazzite Waydroid custom files and policies!"
}

waydroid_troubleshooting_menu() {
    local ts_items=(
        "1\t🚀 Start Container Service\tsudo waydroid container start"
        "2\t▶️  Start User Session\twaydroid session start"
        "3\t🖥️  Show Full-Screen UI\twaydroid show-full-ui"
        "4\t🪟 Enable Multi-Window Mode\twaydroid prop set persist.waydroid.multi_windows true"
        "5\t🪟 Disable Multi-Window Mode\twaydroid prop set persist.waydroid.multi_windows false"
        "6\t🛑 Stop Session & Container\tCleanly stop waydroid session and LXC container"
        "8\t📖 View Startup & Reset Guide…\tDisplay troubleshooting information and manual commands"
        "7\t🗑️  Wipe & Reset Waydroid Data…\tDestructive: completely reset and remove Waydroid images and state"
        "0\t🚪 Back to Waydroid Menu\tReturn to previous menu"
    )

    while true; do
        if ui_tty; then
            local wd_srv="Inactive"
            systemctl is-active --quiet waydroid-container 2>/dev/null && wd_srv="Active (Running)"
            ui_banner "Waydroid Troubleshooting & Maintenance" "$C_ORANGE"
            ui_info_table "Component,Current State" \
                "Container Daemon (waydroid-container),$wd_srv" \
                "Image Path,/var/lib/waydroid/images" \
                "User Data,$HOME/.local/share/waydroid"
        fi
        local ts_choice
        ts_choice=$(gum_action_menu "Waydroid Troubleshooting & Maintenance" "Troubleshoot" "${ts_items[@]}")

        case "$ts_choice" in
            1)
                echo
                ui_info "[*] Starting Waydroid container (root)..."
                sudo waydroid container start
                ;;
            2)
                echo
                ui_info "[*] Starting Waydroid user session..."
                ui_warn "[i] Note: Keep this running. When 'Android with user 0 is ready' appears, launch apps from menu or show UI."
                waydroid session start
                ;;
            3)
                echo
                ui_info "[*] Launching Waydroid in full-screen mode..."
                waydroid show-full-ui
                ;;
            4)
                echo
                ui_info "[*] Enabling Waydroid multi-window mode..."
                waydroid prop set persist.waydroid.multi_windows true
                ui_ok "[+] persist.waydroid.multi_windows set to true."
                if ui_confirm "Restart session now to apply?" "N"; then
                    ui_info "[*] Stopping session..."
                    waydroid session stop 2>/dev/null || true
                    ui_ok "[+] Session stopped. Launch an app from the applications menu to start in multi-window mode."
                fi
                ;;
            5)
                echo
                ui_info "[*] Disabling multi-window mode..."
                waydroid prop set persist.waydroid.multi_windows false
                ui_ok "[+] persist.waydroid.multi_windows set to false."
                if ui_confirm "Restart session now to apply?" "N"; then
                    ui_info "[*] Stopping session..."
                    waydroid session stop 2>/dev/null || true
                    ui_ok "[+] Session stopped."
                fi
                ;;
            6)
                echo
                ui_info "[*] Stopping Waydroid session and container..."
                waydroid session stop 2>/dev/null || true
                sudo waydroid container stop 2>/dev/null || true
                ui_ok "[+] Waydroid session and container stopped."
                ;;
            7)
                ui_hr
                ui_err "  WARNING: REINSTALL & WIPE WAYDROID DATA            "
                ui_hr
                echo "This will:"
                echo "  1. Stop Waydroid session and container"
                echo "  2. Optionally remove waydroid package via dnf"
                echo "  3. Remove data dirs: /var/lib/waydroid, /home/.waydroid,"
                echo "     ~/waydroid, ~/.share/waydroid, ~/.local/share/applications/*aydroid*,"
                echo "     and ~/.local/share/waydroid"
                ui_hr
                if ! ui_confirm "Are you sure you want to proceed?" "N"; then
                    ui_warn "Aborted."
                    ui_pause "Press Enter to continue..."
                    continue
                fi

                echo
                ui_info "[*] Step 1: Stopping session and container..."
                waydroid session stop 2>/dev/null || true
                sudo waydroid container stop 2>/dev/null || true

                if ui_confirm "Remove waydroid package via dnf?" "N"; then
                    ui_info "[*] Removing waydroid package..."
                    sudo dnf remove -y waydroid
                fi

                ui_info "[*] Step 2: Cleaning up Waydroid state and rootfs directories..."
                sudo rm -rf /var/lib/waydroid /home/.waydroid
                rm -rf "$HOME/waydroid" "$HOME/.share/waydroid" "$HOME/.local/share/waydroid"
                rm -f "$HOME/.local/share/applications/"*aydroid* 2>/dev/null || true

                ui_ok "[+] Cleanup complete! You can reinstall or re-initialize Waydroid now."
                ui_warn "[i] If you removed the package, a system reboot is recommended before reinstalling."
                ;;
            8)
                clear
                ui_banner "Waydroid Troubleshooting & Manual Setup Guide" "$C_BLUE"
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
     ./launcher.sh --waydroid
EOF
                ;;
            *)
                break
                ;;
        esac
        echo ""
        ui_pause "Press Enter to continue..."
    done
}

fedora_waydroid_setup_wizard() {
    local w_items=(
        "2\t🚀 Run Automated Full Waydroid Setup\tInitialize images, install libndk ARM translation, and enable Widevine DRM"
        "1\t📦 Select & Install APKs / Add-ons…\tBatch checkbox selector for F-Droid, Aurora, SmartDock, 3DMark, and MobileRun"
        "3\t📱 Initialize Waydroid Container…\tConfigure GAPPS or Vanilla Android image and initialize LXC container"
        "4\t⚙️  Manage libndk ARM Translation…\tInstall or remove native ARM/ARM64 translation layer for x86_64"
        "5\t🔒 Manage Widevine DRM…\tInstall or remove Google Widevine L3 DRM media support"
        "6\t🛡️  Deploy Bazzite Custom Policies\tInstall container control scripts, launcher defaults, and Polkit rules"
        "7\t🎮 Select Render GPU…\tConfigure primary GPU node for Waydroid (waydroid-choose-gpu)"
        "8\t🕹️  Trigger Controller Input Sync\tRefresh Steam and gamepad uevents inside container"
        "9\t👆 Toggle Fake Touch Simulation\tSwitch persist.waydroid.fake_touch on or off for mouse-as-touch"
        "10\t📲 Install Single APK Package…\tPick and install an individual Android APK or tool"
        "11\t🔧 Troubleshooting & Maintenance…\tManual session controls, multi-window toggles, and full data reset"
        "0\t🚪 Back to Main Menu\tReturn to primary launcher menu"
    )

    while true; do
        if ui_tty; then
            local wd_pkg="Not Installed" wd_srv="Stopped"
            rpm -q waydroid &>/dev/null && wd_pkg="Installed ($(rpm -q --queryformat '%{VERSION}' waydroid 2>/dev/null))"
            systemctl is-active --quiet waydroid-container 2>/dev/null && wd_srv="Running"
            ui_banner "Fedora Waydroid Setup Wizard" "$C_GREEN"
            ui_info_table "Waydroid Subsystem,Status" \
                "Package Status,$wd_pkg" \
                "Container Service,$wd_srv" \
                "Helper Scripts,$REPO_ROOT/Scripts/install-{libndk;widevine}.sh"
        fi
        local w_choice
        w_choice=$(gum_action_menu "Fedora Waydroid Setup Wizard" "Waydroid" "${w_items[@]}")

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
                ui_pause "Press Enter to continue..."
                ;;
            7)
                if [ -x "/usr/bin/waydroid-choose-gpu" ]; then
                    sudo /usr/bin/waydroid-choose-gpu
                else
                    ui_warn "[!] /usr/bin/waydroid-choose-gpu not found. Deploying Bazzite custom files now..."
                    apply_bazzite_waydroid_config
                    sudo /usr/bin/waydroid-choose-gpu
                fi
                ui_pause "Press Enter to continue..."
                ;;
            8)
                if [ -x "/usr/libexec/waydroid-fix-controllers" ]; then
                    sudo /usr/libexec/waydroid-fix-controllers
                    ui_ok "[+] Controller uevents triggered successfully."
                else
                    echo add | sudo tee /sys/devices/virtual/input/input*/event*/uevent >/dev/null 2>&1 || true
                    ui_ok "[+] Fallback controller uevents triggered."
                fi
                ui_pause "Press Enter to continue..."
                ;;
            9)
                local cur_ft
                cur_ft=$(waydroid prop get persist.waydroid.fake_touch 2>/dev/null || echo "not set")
                echo -e "Current fake_touch setting: $(ui_c "bold" "$cur_ft")"
                if [ "$cur_ft" = "1" ] || [ "$cur_ft" = "true" ]; then
                    waydroid prop set persist.waydroid.fake_touch 0
                    ui_warn "[*] Set persist.waydroid.fake_touch = 0 (Disabled)"
                else
                    waydroid prop set persist.waydroid.fake_touch 1
                    ui_ok "[*] Set persist.waydroid.fake_touch = 1 (Enabled)"
                fi
                ui_pause "Press Enter to continue..."
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
                apk_choice=$(gum_action_menu "Install Single Waydroid APK" "APK" "${apk_items[@]}")
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
            ""|0|[Qq]|back)
                break
                ;;
            *)
                echo
                ui_err "Invalid option: '$w_choice'."
                ;;
        esac
    done
}

setup_waydroid() {
    fedora_waydroid_setup_wizard "$@"
}

prune_podman() {
    if ! command -v podman >/dev/null 2>&1; then
        ui_err "'podman' is not installed."
        return 1
    fi
    ui_info "Running podman system prune..."
    podman system prune
}

prune_podman_all() {
    if ! command -v podman >/dev/null 2>&1; then
        ui_err "'podman' is not installed."
        return 1
    fi
    ui_warn "This removes ALL unused images and volumes."
    ask_yn "Continue?" "N" confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || return 0
    podman system prune -a --volumes
}

forget_snap_snapshots() {
    if ! command -v snap >/dev/null 2>&1; then
        ui_warn "• 'snap' not found, skipping."
        return 0
    fi
    ui_info "Removing saved snap snapshots..."
    sudo snap saved | awk 'NR>1 {print $1}' | xargs -r -n 1 sudo snap forget
    ui_ok "✓ Snap snapshots removed."
}

benchmark_folder() {
    local dir testfile
    ask_input "Folder to benchmark [default: $HOME]: " dir
    dir="${dir:-$HOME}"
    if [ ! -d "$dir" ] || [ ! -w "$dir" ]; then
        ui_err "'$dir' is not a writable directory."
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

headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64)'}
endpoints = [
    'https://benchmark.unigine.com/superposition',
    'https://unigine.com/products/benchmarks/superposition/'
]

candidates = set()
for u in endpoints:
    try:
        req = urllib.request.Request(u, headers=headers)
        with urllib.request.urlopen(req, timeout=12) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            matches = re.findall(r'https?://[^\s\"\'<>]+(?:Unigine_Superposition|superposition)[^\s\"\'<>]*\.run', html, re.I)
            candidates.update(matches)
    except Exception:
        pass

if candidates:
    def extract_ver(link):
        m = re.search(r'Unigine_Superposition-([0-9.]+)\.run', link, re.I)
        if m:
            try:
                return [int(x) for x in m.group(1).split('.')]
            except Exception:
                pass
        return [0]
    print(sorted(list(candidates), key=extract_ver, reverse=True)[0])
    sys.exit(0)

print('https://assets.unigine.com/d/Unigine_Superposition-1.1.run')
"
}

install_unigine_superposition() {
    local target_dir="$HOME/Benchmarks/Unigine"
    mkdir -p "$target_dir"

    echo
    ui_info "[*] Resolving latest Unigine Superposition Linux release..."
    local download_url
    download_url="$(ui_spin_fn "Resolving latest unigine superposition..." fetch_latest_unigine_superposition_url)"
    local filename
    filename="$(basename "$download_url")"
    local dest_file="$target_dir/$filename"

    ui_info_table "Benchmark Asset,Value" \
        "Release File,${filename}" \
        "Source URL,${download_url}" \
        "Destination,${dest_file}"

    if [ -f "$dest_file" ]; then
        ask_yn "File $dest_file already exists. Re-download?" "N" redownload
        if [[ ! "$redownload" =~ ^[Yy]$ ]]; then
            chmod +x "$dest_file"
            ui_ok "[+] Installer is executable at: ${dest_file}"
            echo -e "    Run with: ${dest_file}"
            return 0
        fi
    fi

    echo
    ui_info "[*] Downloading ${filename} (~1.5GB)..."
    if curl -fLC - --progress-bar -o "$dest_file" "$download_url"; then
        chmod +x "$dest_file"
        ui_ok "[+] Successfully downloaded and set executable: ${dest_file}"
        echo -e "    To install/run Superposition Benchmark:"
        echo -e "    ${dest_file}"
    else
        ui_err "Failed to download Unigine Superposition from ${download_url}"
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
        "System Cleanup & Benchmarks" \
        "Scope: Podman containers/volumes; Snap snapshots; Direct I/O & GPU benchmarks" \
        "Run Selected Tasks" \
        "Back to Main Menu" \
        "$C_YELLOW" || return 0

    echo
    ui_info "=== Executing Selected Cleanup & Benchmark Tasks ==="
    [ "${CB_SELECTED[0]}" -eq 1 ] && prune_podman
    [ "${CB_SELECTED[1]}" -eq 1 ] && prune_podman_all
    [ "${CB_SELECTED[2]}" -eq 1 ] && forget_snap_snapshots
    [ "${CB_SELECTED[3]}" -eq 1 ] && benchmark_folder
    [ "${CB_SELECTED[4]}" -eq 1 ] && install_unigine_superposition

    echo
    ui_ok "✓ Cleanup and benchmark tasks completed!"
    ui_pause "Press Enter to continue..."
}

autostart_libvirt_vm() {
    if ! command -v virsh >/dev/null 2>&1; then
        ui_err "'virsh' is not installed."
        return 1
    fi
    local vms vm
    mapfile -t vms < <(sudo virsh list --all --name | sed '/^$/d')
    if [ "${#vms[@]}" -eq 0 ]; then
        ui_warn "• No libvirt VMs found."
        return 0
    fi
    vm="$(ui_choose "Select VM to autostart" "Libvirt VMs" "${vms[@]}" "Cancel")"
    [ -z "$vm" ] || [ "$vm" = "Cancel" ] && return 0
    sudo virsh autostart "$vm" && echo -e "$(ui_c "green" "✓ '$vm' will start at boot.")"
}

forward_libvirt_ports() {
    if ! command -v firewall-cmd >/dev/null 2>&1; then
        ui_err "'firewall-cmd' (firewalld) is not installed."
        return 1
    fi
    ui_banner "Forward Ports to Libvirt VMs" "$C_PURPLE"
    ui_info_table "Firewall Property,Details" \
        "Firewalld Zone,libvirt (bridge virbr0)" \
        "Default Range,49152-65535 (TCP + UDP)" \
        "Persistence,--permanent + firewall-cmd --reload"
    ask_menu p_choice "Select Port Forwarding Rule" \
        "1|Open Default Dynamic Range (49152-65535 TCP & UDP)" \
        "2|Open Custom Port or Range…" \
        "0|Cancel"
    local ports=()
    case "$p_choice" in
        1) ports=("49152-65535/tcp" "49152-65535/udp") ;;
        2)
            ask_input "Port or range (e.g. 8080 or 5000-5100): " port
            if ! [[ "$port" =~ ^[0-9]+(-[0-9]+)?$ ]]; then
                ui_err "Invalid port: '$port'."
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
    sudo firewall-cmd --reload && echo -e "$(ui_c "green" "✓ Opened ${ports[*]} in libvirt zone.")"
}

define_libvirt_vms() {
    if ! command -v virsh >/dev/null 2>&1; then
        ui_err "'virsh' is not installed."
        return 1
    fi
    local dir="$HOME/Platforms/Virtualization/kvm-qemu"
    [ -n "$(ls "$dir"/*.xml 2>/dev/null)" ] || dir="$REPO_ROOT/VMs"
    local xmls=("$dir"/*.xml)
    if [ ! -f "${xmls[0]}" ]; then
        ui_warn "• No VM XML files found in $dir."
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
        "Source Directory: $dir\nHypervisor: QEMU/KVM (virsh define)" \
        "Define Selected VMs" \
        "Back to Menu" \
        "$C_PURPLE" || return 0

    local to_define=()
    for i in "${!xmls[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_define+=("${xmls[i]}")
    done

    echo
    ui_info "Defining ${#to_define[@]} VM(s)..."
    local f
    for f in "${to_define[@]}"; do
        sudo virsh define "$f" && echo -e "$(ui_c "green" "✓ Defined $(basename \"$f\").")"
    done
    ui_pause "Press Enter to return..."
}

start_default_libvirt_network() {
    if ! command -v virsh >/dev/null 2>&1; then
        ui_err "'virsh' is not installed."
        return 1
    fi
    ui_info "[*] Starting and autostarting libvirt 'default' network..."
    sudo virsh net-start default 2>/dev/null || true
    sudo virsh net-autostart default 2>/dev/null || true

    if sudo virsh net-info default 2>/dev/null; then
        ui_ok "✓ Libvirt 'default' network configured and verified."
    else
        ui_warn "• Unable to query 'default' network info."
    fi
}

list_virt_builder_templates() {
    if ! command -v virt-builder >/dev/null 2>&1; then
        ui_err "'virt-builder' is not installed."
        ui_warn "Install it with: sudo dnf install libguestfs-tools-c"
        return 1
    fi
    ui_banner "Available virt-builder OS Templates" "$C_BLUE"
    virt-builder --list
}

build_virt_builder_vm() {
    if ! command -v virt-builder >/dev/null 2>&1; then
        ui_err "'virt-builder' is not installed."
        ui_warn "Install it with: sudo dnf install libguestfs-tools-c"
        return 1
    fi

    ui_banner "Build VM Image with virt-builder" "$C_BLUE"

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

    local os_template="" t_pick="" entry
    local t_menu=()
    for entry in "${popular_templates[@]}"; do
        t_menu+=("$(printf '%-22s %s' "${entry%%:*}" "(${entry#*:})")")
    done
    t_menu+=("Browse & filter ALL available templates ($my_arch)" "Custom template name (enter manually)" "Cancel")

    while [ -z "$os_template" ]; do
        t_pick="$(ui_choose "Select an OS template" "${t_menu[@]}")" || return 0
        case "$t_pick" in
            Cancel) return 0 ;;
            Custom*)
                ask_input "Enter exact template name: " os_template
                ;;
            Browse*)
                local all_templates=()
                mapfile -t all_templates < <(ui_spin_fn "Fetching full template list for $my_arch..." virt-builder --list 2>/dev/null \
                    | awk -v arch="$my_arch" '$2 == arch {print $0}')
                if [ "${#all_templates[@]}" -eq 0 ]; then
                    ui_warn "No templates found for $my_arch. Please enter manually."
                    ask_input "Template name: " os_template
                else
                    t_pick="$(ui_filter "All virt-builder templates ($my_arch)" "${all_templates[@]}")" || continue
                    os_template="${t_pick%% *}"
                fi
                ;;
            *) os_template="${t_pick%% *}" ;;
        esac
    done

    ui_ok "✓ Selected template: $os_template"

    # Destination and sizing
    local default_img_name="${os_template}-vm.qcow2"
    ask_input "Output image name (under /var/lib/libvirt/images) [default: $default_img_name]: " img_name
    img_name="${img_name:-$default_img_name}"

    local output_path="/var/lib/libvirt/images/$img_name"

    ask_input "Disk size [default: 20G]: " disk_size
    disk_size="${disk_size:-20G}"

    # Root Password options
    echo -e "\n$(ui_c "bold" "Root Password Configuration:")"
    ask_menu pwd_choice "Select password option [1-3] (default: 1)" "1|Auto-generate a secure random password (printed on completion)" "2|Enter custom root password" "3|Disable root password (SSH key only)"
    pwd_choice="${pwd_choice:-1}"

    local root_pwd_arg=""
    case "$pwd_choice" in
        2)
            ask_password "Enter root password: " custom_pwd
            echo ""
            ask_password "Confirm root password: " custom_pwd_confirm
            echo ""
            if [ "$custom_pwd" != "$custom_pwd_confirm" ]; then
                ui_err "Passwords do not match."
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
    local ssh_mode ssh_key="" ssh_key_tmp=""
    ssh_mode="$(ui_choose "SSH public key to inject into root" \
        "Use default ($default_ssh_key)" \
        "Browse for a public key file" \
        "Paste a public key" \
        "None (skip SSH injection)")" || ssh_mode="None"
    case "$ssh_mode" in
        Browse*) ask_file "Select the SSH public key (.pub) to inject" ssh_key "$HOME/.ssh" ;;
        Paste*)
            local pasted_key=""
            ask_write "Paste the SSH public key" pasted_key
            if [ -n "$pasted_key" ]; then
                ssh_key_tmp="$(mktemp --suffix=.pub)"
                ssh_key="$ssh_key_tmp"
                printf '%s\n' "$pasted_key" > "$ssh_key"
            fi
            ;;
        None*) ssh_key="none" ;;
        *) ssh_key="$default_ssh_key" ;;
    esac
    [ -z "$ssh_key" ] && ssh_key="none"

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

    echo
    ui_info "[*] Building VM with virt-builder..."
    ui_info_table "Build Parameter,Configuration" \
        "OS Template,$os_template" \
        "Target Image,$output_path" \
        "Disk Size,$disk_size (qcow2)" \
        "Root Auth,$root_pwd_arg" \
        "SSH Public Key,$ssh_key"
    echo ""

    sudo virt-builder "${builder_args[@]}"
    [ -n "$ssh_key_tmp" ] && rm -f "$ssh_key_tmp"

    if [ -f "$output_path" ]; then
        ui_banner "VM Image Built Successfully!" "$C_GREEN"
        ui_info_table "Result,Value" \
            "Output Image,$output_path" \
            "Quick Import,sudo virt-install --name ${img_name%.*} --ram 2048 --vcpus 2 --disk path=$output_path --import --network network=default"
        echo
        ui_info "To import and run this VM immediately via virt-install:"
        echo -e "  sudo virt-install --name ${img_name%.*} --ram 2048 --vcpus 2 --disk path=$output_path --import --network network=default\n"
    else
        echo
        ui_err "Failed to create $output_path"
        return 1
    fi
}

configure_libvirt() {
    if ! command -v virsh >/dev/null 2>&1; then
        prompt_run_playbook_subtask "Libvirt/KVM" "services" "Enable virtualization stack and services" || return 1
        if ! command -v virsh >/dev/null 2>&1; then
            ui_err "'virsh' is still not installed."
            return 1
        fi
    fi
    local l_items=(
        "1\t🌐 Start & Enable Default Network\tEnsure virbr0 default network is active and autostarts on boot"
        "3\t🏗️  Build VM Image with virt-builder…\tCreate bootable Fedora, Debian, Ubuntu, or CentOS QCOW2 disk"
        "6\t📄 Define VMs from XML…\tImport Android, Linux, and Windows libvirt domains from XML templates"
        "4\t🚀 Configure VM Boot Autostart…\tSelect a guest domain to start automatically at host boot"
        "5\t🛡️  Forward Firewall Ports to VMs…\tOpen guest/host ports in the firewalld libvirt zone"
        "2\t📋 List Available OS Templates\tDisplay repository of virt-builder pre-built cloud OS images"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    while true; do
        if ui_tty; then
            ui_banner "Libvirt / KVM Hypervisor Helpers" "$C_PURPLE"
            ui_info_table "Hypervisor Property,Details" \
                "Management Tool,virsh / virt-builder / firewall-cmd" \
                "Default Network,default (virbr0 NAT bridge)" \
                "Storage Pool,/var/lib/libvirt/images"
        fi
        local l_choice
        l_choice=$(gum_action_menu "Libvirt VM Helpers" "Libvirt" "${l_items[@]}")

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
        prompt_run_playbook_subtask "Vagrant" "packages_dnf" "Install virtualization packages" || return 1
        if ! command -v vagrant >/dev/null 2>&1; then
            ui_err "'vagrant' is still not installed."
            return 1
        fi
    fi
    if [ ! -f "$dir/Vagrantfile" ]; then
        prompt_run_playbook_subtask "Vagrant VM (${name})" "vagrant" "Provision Vagrant environments and files" || return 1
        if [ ! -f "$dir/Vagrantfile" ]; then
            ui_err "$dir/Vagrantfile not found. Run the playbook first."
            return 1
        fi
    fi

    local vg_actions=(
        "1\t▶️  Start Virtual Machine\tvagrant up --provider libvirt"
        "4\t🔑 Connect via SSH\tvagrant ssh"
        "3\tℹ️  Check VM Status\tvagrant status"
        "2\t⏹️  Stop Virtual Machine\tvagrant halt"
        "5\t🗑️  Destroy Virtual Machine…\tDestructive: vagrant destroy -f (removes VM disk)"
        "0\t🚪 Back to Vagrant Menu\tReturn to Vagrant menu"
    )

    while true; do
        if ui_tty; then
            ui_banner "Vagrant Environment: $name" "$C_PURPLE"
            ui_info_table "Environment Property,Value" \
                "Box Name,$name" \
                "Working Directory,$dir" \
                "Provider,libvirt (KVM)"
        fi
        local v_choice
        v_choice=$(gum_action_menu "Vagrant VM: $name" "Action" "${vg_actions[@]}")

        case "$v_choice" in
            1) (cd "$dir" && vagrant up --provider libvirt) ;;
            2) (cd "$dir" && vagrant halt) ;;
            3) (cd "$dir" && vagrant status) ;;
            4) (cd "$dir" && vagrant ssh) ;;
            5)
                if ui_confirm "Destroy '$name' VM and its disk?" "N"; then
                    (cd "$dir" && vagrant destroy -f)
                fi
                ;;
            *) return 0 ;;
        esac
    done
}

configure_vagrant() {
    local vg_items=(
        "1\t🐧 Manage Ubuntu 24.04 Desktop VM…\tNoble Numbat developer workstation box"
        "2\t🌐 Manage YunoHost Server VM…\tDebian self-hosting application server box"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    while true; do
        if ui_tty; then
            ui_banner "Vagrant Virtual Machines" "$C_PURPLE"
            ui_info_table "Vagrant Property,Details" \
                "Base Path,$HOME/Platforms/Virtualization/vagrant" \
                "Provider,libvirt (QEMU/KVM)" \
                "Available Boxes,ubuntu (24.04) & yunohost"
        fi
        local vg_choice
        vg_choice=$(gum_action_menu "Vagrant VMs" "Vagrant" "${vg_items[@]}")

        case "$vg_choice" in
            1) manage_vagrant_vm ubuntu ;;
            2) manage_vagrant_vm yunohost ;;
            *) return 0 ;;
        esac
    done
}

manage_virtualization() {
    local vm_items=(
        "1\t🌐 Start & Enable Default Network\tsudo virsh net-start & net-autostart default (virbr0)"
        "3\t🏗️  Build VM Image with virt-builder…\tCreate bootable OS qcow2 with root password & SSH injection"
        "4\t📄 Define Libvirt VMs from XML…\tImport VMs/*.xml for Android, Linux, and Windows"
        "5\t🚀 Configure VM Boot Autostart…\tSelect a libvirt domain to start automatically at boot"
        "6\t🛡️  Forward Firewall Ports to VMs…\tOpen guest/host ports in firewalld libvirt zone"
        "2\t📋 List Available OS Templates\tvirt-builder --list"
        "7\t🐧 Manage Vagrant Ubuntu 24.04…\tStart, stop, SSH, or destroy Ubuntu desktop VM"
        "8\t🌐 Manage Vagrant YunoHost Server…\tStart, stop, SSH, or destroy YunoHost server VM"
        "0\t🚪 Back to Main Menu\tReturn to primary launcher menu"
    )

    while true; do
        if ui_tty; then
            local virsh_st="Missing" vg_st="Missing"
            command -v virsh >/dev/null 2>&1 && virsh_st="Installed"
            command -v vagrant >/dev/null 2>&1 && vg_st="Installed"
            ui_banner "Virtualization & VM Management" "$C_PURPLE"
            ui_info_table "Stack Component,Status & Path" \
                "Libvirt / Virsh,$virsh_st (/var/lib/libvirt/images)" \
                "Vagrant CLI,$vg_st ($HOME/Platforms/Virtualization/vagrant)" \
                "VM XML Templates,$REPO_ROOT/VMs"
        fi
        local vm_choice
        vm_choice=$(gum_action_menu "Virtualization & VM Management" "Virtualization" "${vm_items[@]}")

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
    ui_banner "Install DeepSeek Harness Web (dsh)" "$C_MINT"

    local appimages_dir="$HOME/AppImages"
    mkdir -p "$appimages_dir"
    ui_info_table "Property,Details" \
        "Package,@deepseek-ai/dsh (npx)" \
        "Environment,Pixi workspace in $appimages_dir" \
        "Launch Mode,web --no-open"

    # Ensure pixi is available
    local pixi_bin
    pixi_bin="$(command -v pixi 2>/dev/null || echo "$HOME/.pixi/bin/pixi")"
    if [ ! -x "$pixi_bin" ]; then
        ui_warn "Pixi not found. Running Pixi setup first..."
        install_pixi
        pixi_bin="$(command -v pixi 2>/dev/null || echo "$HOME/.pixi/bin/pixi")"
    fi

    # Initialize pixi environment in $HOME/AppImages if not already present
    if [ -x "$pixi_bin" ]; then
        if [ ! -f "$appimages_dir/pixi.toml" ]; then
            ui_info "Initializing Pixi environment in $appimages_dir..."
            (cd "$appimages_dir" && "$pixi_bin" init --format toml . 2>/dev/null || "$pixi_bin" init .)
            ui_ok "✓ Pixi environment initialized in $appimages_dir."
        else
            ui_ok "✓ Pixi environment already exists in $appimages_dir."
        fi
    else
        ui_warn "Warning: Pixi is not executable; proceeding with npx installation directly."
    fi

    # Ensure npx / nodejs is available
    if ! command -v npx >/dev/null 2>&1; then
        ui_err "'npx' is not found. Please ensure Node.js is installed."
        return 1
    fi

    ui_info "Installing DeepSeek Harness via npx in $appimages_dir..."
    (cd "$appimages_dir" && npx -y @deepseek-ai/dsh web --no-open)

    ui_ok "✓ DeepSeek Harness installation finished in $appimages_dir."
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
    local dest_dir="$HOME/AppImages/llama-prism"
    mkdir -p "$dest_dir"

    local target_archive="$dest_dir/$name"
    local extract_folder="${name%.tar.gz}"
    extract_folder="${extract_folder%.zip}"
    local sub_dir="$dest_dir/$extract_folder"

    echo
    ui_info "[*] Downloading $name..."
    curl -fL --progress-bar -o "$target_archive" "$url"

    mkdir -p "$sub_dir"
    ui_info "[*] Extracting to $sub_dir..."
    if [[ "$name" == *.tar.gz ]]; then
        tar -xzf "$target_archive" -C "$sub_dir"
    elif [[ "$name" == *.zip ]]; then
        unzip -q -o "$target_archive" -d "$sub_dir"
    fi

    find "$sub_dir" -type f -exec chmod +x {} + 2>/dev/null || true
    rm -f "$target_archive"
    ui_ok "✓ Successfully installed: $sub_dir"
}

download_and_extract_prism_assets() {
    local target_type="$1"
    local dest_dir="$HOME/AppImages/llama-prism"
    mkdir -p "$dest_dir"

    ui_info "Fetching latest release assets for PrismML-Eng/llama.cpp..."
    local asset_lines
    asset_lines="$(ui_spin_fn "Resolving latest prism llamacpp release assets..." fetch_prism_llamacpp_release_assets "$target_type")"
    if [ -z "$asset_lines" ]; then
        ui_err "Failed to fetch assets or none matched target '${target_type}'."
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
        ui_warn "• No assets found."
        return 0
    fi

    checkbox_menu_select \
        "Select Prism llama.cpp Binaries to Install" \
        "Source: https://github.com/PrismML-Eng/llama.cpp\nDestination: $dest_dir" \
        "Download & Extract Selected Binaries" \
        "Back to Filter Menu" \
        "$C_MINT" || return 0

    local to_download=()
    local i
    for i in "${!CB_ITEMS[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_download+=("$i")
    done

    echo
    ui_info "Downloading and extracting ${#to_download[@]} binary asset(s)..."
    for i in "${to_download[@]}"; do
        download_and_extract_prism_single_asset "${CB_ITEMS[i]}" "${urls[i]}"
    done

    echo
    ui_ok "✓ Selected binaries installed in: $dest_dir"
    ui_pause "Press Enter to continue..."
}

install_prism_llamacpp() {
    while true; do
        ui_banner "Install Prism llama.cpp Binaries" "$C_MINT"
        ui_info_table "Property,Details" \
            "Upstream Repository,https://github.com/PrismML-Eng/llama.cpp" \
            "Target Directory,$HOME/AppImages/llama-prism" \
            "Supported Backends,CUDA; Vulkan; ROCm; SYCL; CPU; Android ARM64"
        ask_menu prism_choice "Select Platform Filter" \
            "1|Browse All Linux & Android Binaries…" \
            "2|Browse Linux Binaries Only (CUDA, Vulkan, ROCm, SYCL, CPU)…" \
            "3|Browse Android Binaries Only (ARM64)…" \
            "0|Back to Main Menu"
        case "$prism_choice" in
            1) download_and_extract_prism_assets "all" ;;
            2) download_and_extract_prism_assets "linux" ;;
            3) download_and_extract_prism_assets "android" ;;
            0|[Qq]|back) return 0 ;;
            *) echo -e "$(ui_c "red" "Invalid option: '$prism_choice'.")" ;;
        esac
    done
}

install_llama_dory() {
    local target_dir="$HOME/AppImages/llama-dory"
    local repo_url="https://github.com/brianchmielNV/llama.cpp.git"
    local branch="dory-support"

    ui_banner "Install & Build llama-dory (Nemotron Dory)" "$C_MINT"
    ui_info_table "Build Property,Value" \
        "Repository,$repo_url" \
        "Git Branch,$branch" \
        "Target Directory,$target_dir" \
        "Build Type,CMake Release (Shared Libraries)"
    ui_hr

    if [ -d "$target_dir/.git" ]; then
        ui_info "[*] Existing llama-dory git repo detected. Updating..."
        git -C "$target_dir" fetch origin "$branch"
        git -C "$target_dir" checkout "$branch"
        git -C "$target_dir" pull origin "$branch"
    else
        ui_info "[*] Cloning llama-dory ($branch)..."
        mkdir -p "$HOME/AppImages"
        git clone -b "$branch" "$repo_url" "$target_dir"
    fi

    ui_info "[*] Building llama-dory binaries (Release)..."
    mkdir -p "$target_dir/build"
    (
        cd "$target_dir/build" || exit 1
        cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
        cmake --build . --config Release -j"$(nproc 2>/dev/null || echo 4)"
    )

    if [ -f "$target_dir/build/bin/llama-server" ]; then
        ui_ok "✓ Successfully built llama-dory server & binaries in $target_dir/build/bin"
        if [ ! -f "$target_dir/start-server.sh" ]; then
            cat << 'EOF' > "$target_dir/start-server.sh"
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/build/bin:${SCRIPT_DIR}/../.pixi/envs/default/lib:${LD_LIBRARY_PATH}"

MODEL="${1:-/home/admin/Platforms/AI/NVIDIA-Nemotron-Labs-Dory1.0-4B-Q5_K_M.gguf}"
HOST="${HOST:-192.168.12.116}"
PORT="${PORT:-5001}"
LOOPS="${DORY_LOOPS:-2}"

exec "${SCRIPT_DIR}/build/bin/llama-server" \
  -m "${MODEL}" \
  --device none \
  --override-kv "dory.num_loops=int:${LOOPS},dory.recurrent_kv_cache_mode=str:per_loop" \
  --host "${HOST}" \
  --port "${PORT}" \
  "$@"
EOF
            chmod +x "$target_dir/start-server.sh"
        fi
    else
        ui_err "✗ Build failed or llama-server not found."
        ui_pause "Press Enter to continue..."
        return 1
    fi

    ui_pause "Press Enter to continue..."
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
    echo
    ui_info "[*] Downloading $name directly to $dest_dir..."
    curl -fL --progress-bar -o "$target_file" "$url"
    chmod +x "$target_file"
    ui_ok "✓ Successfully installed executable to: $target_file"
}

install_koboldcpp() {
    local dest_dir="$HOME/AppImages"
    mkdir -p "$dest_dir"

    ui_info "Fetching latest release assets for LostRuins/koboldcpp..."
    local asset_lines
    asset_lines="$(ui_spin_fn "Resolving latest koboldcpp release assets..." fetch_koboldcpp_release_assets)"
    if [ -z "$asset_lines" ]; then
        ui_err "Failed to fetch assets from LostRuins/koboldcpp."
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
        ui_warn "• No Linux binary assets found."
        return 0
    fi

    checkbox_menu_select \
        "Select KoboldCpp Binaries to Download" \
        "Source: https://github.com/LostRuins/koboldcpp\nDestination: $dest_dir" \
        "Download Selected Binaries" \
        "Back to Main Menu" \
        "$C_MINT" || return 0

    local to_download=()
    local i
    for i in "${!CB_ITEMS[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_download+=("$i")
    done

    echo
    ui_info "Downloading ${#to_download[@]} binary asset(s) to $dest_dir..."
    for i in "${to_download[@]}"; do
        download_koboldcpp_single_binary "${CB_ITEMS[i]}" "${urls[i]}"
    done

    echo
    ui_ok "✓ Selected binaries installed directly to: $dest_dir"
    ui_pause "Press Enter to continue..."
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
    local dest_dir="$HOME/AppImages/localai"
    mkdir -p "$dest_dir"

    local target_file="$dest_dir/$name"
    echo
    ui_info "[*] Downloading $name directly to $dest_dir..."
    curl -fL --progress-bar -o "$target_file" "$url"

    if [[ "$name" == *.tar.xz ]] || [[ "$name" == *.tar.gz ]]; then
        ui_info "[*] Extracting $name into $dest_dir..."
        tar -xf "$target_file" -C "$dest_dir"
        ui_ok "✓ Successfully unpacked: $target_file"
    else
        chmod +x "$target_file"
        ui_ok "✓ Successfully installed executable to: $target_file"
    fi

    # Also symlink LocalAI-Launcher or binary to $HOME/AppImages if AppImage
    if [[ "$name" == *.AppImage ]]; then
        ln -sf "$target_file" "$HOME/AppImages/$name" 2>/dev/null || true
    fi
}

install_localai() {
    local dest_dir="$HOME/AppImages/localai"
    mkdir -p "$dest_dir"

    ui_info "Fetching latest release assets for mudler/LocalAI..."
    local asset_lines
    asset_lines="$(ui_spin_fn "Resolving latest localai release assets..." fetch_localai_release_assets)"
    if [ -z "$asset_lines" ]; then
        ui_err "Failed to fetch release assets from GitHub API."
        ui_warn "Please verify internet connection or check GitHub rate limits."
        ui_pause "Press Enter to return to menu..."
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
        "Select LocalAI Binaries & Launchers" \
        "Source: https://github.com/mudler/LocalAI\nDestination: $dest_dir" \
        "Download Selected Assets" \
        "Back to Main Menu" \
        "$C_MINT" || return 0

    local to_download=()
    local i
    for i in "${!CB_ITEMS[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_download+=("$i")
    done

    echo
    ui_info "Downloading ${#to_download[@]} asset(s) to $dest_dir..."
    for i in "${to_download[@]}"; do
        download_localai_single_asset "${CB_ITEMS[i]}" "${urls[i]}"
    done

    echo
    ui_ok "✓ Selected LocalAI assets installed directly to: $dest_dir"
    ui_pause "Press Enter to continue..."
}

install_openclaw_deb_distrobox() {
    local container_name="ubuntu-toolbox"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/openclaw_downloads"
    mkdir -p "$cache_dir"

    ui_banner "[Step 0] Install Latest OpenClaw (.deb) in Ubuntu Distrobox" "$C_INDIGO"
    ui_info_table "Property,Value" \
        "Upstream Repository,openclaw/openclaw" \
        "Target Distrobox,$container_name" \
        "Download Cache,$cache_dir"

    if ! command -v distrobox >/dev/null 2>&1; then
        ui_err "'distrobox' is not installed."
        return 1
    fi

    # Ensure container exists or prompt to create
    if ! distrobox list 2>/dev/null | grep -q "^${container_name}\b\|[[:space:]]${container_name}[[:space:]]"; then
        ui_warn "• Distrobox container '${container_name}' does not exist."
        ask_yn "Create '${container_name}' container now?" "Y" cr_choice
        cr_choice="${cr_choice:-Y}"
        if [[ "$cr_choice" =~ ^[Yy]$ ]]; then
            setup_distrobox || return 1
        else
            ui_err "[-] Cannot install .deb without target distrobox container."
            return 1
        fi
    fi

    local target_deb=""
    # Check if latest deb already exists in ~/Downloads
    if [ -f "$HOME/Downloads/OpenClaw-2026.11.2-amd64.deb" ]; then
        target_deb="$HOME/Downloads/OpenClaw-2026.11.2-amd64.deb"
        echo -e "$(ui_c "green" "✓ Using existing deb package:") $target_deb"
    else
        ui_info "[*] Fetching latest OpenClaw .deb release from GitHub..."
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
            IFS=$'	' read -r deb_name deb_url <<< "$deb_info"
        else
            ui_warn "Could not resolve latest .deb from GitHub API. Using fallback URL..."
            deb_url="https://github.com/openclaw/openclaw/releases/download/v2026.11.2/OpenClaw-2026.11.2-amd64.deb"
            deb_name="OpenClaw-2026.11.2-amd64.deb"
        fi

        target_deb="$cache_dir/$deb_name"
        ui_info "[*] Downloading ${deb_name}..."
        if ! curl -fLC - --progress-bar -o "$target_deb" "$deb_url"; then
            ui_err "Failed to download OpenClaw .deb from $deb_url"
            return 1
        fi
    fi

    echo -e "\n$(ui_c "blue" "[*] Installing $(basename \"$target_deb\") into '${container_name}' container via apt...")"
    if distrobox enter "${container_name}" -- sudo apt-get update &&        distrobox enter "${container_name}" -- sudo apt-get install -y "$target_deb"; then
        echo
        ui_info "[*] Exporting OpenClaw desktop app and binary to host..."
        distrobox enter "${container_name}" -- distrobox-export --app openclaw 2>/dev/null || true
        distrobox enter "${container_name}" -- distrobox-export --bin /usr/bin/openclaw --export-path "$HOME/.local/bin" 2>/dev/null || true
        ui_ok "✓ Step 0 complete: OpenClaw (.deb) installed and exported successfully from Distrobox!"
    else
        ui_err "Failed to install OpenClaw .deb inside distrobox container."
        return 1
    fi
}

install_deepseek_harness_desktop_deb_distrobox() {
    local container_name="ubuntu-toolbox"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/deepseek_harness_downloads"
    mkdir -p "$cache_dir"

    ui_banner "Install DeepSeek Harness Desktop (.deb) into Distrobox" "$C_MINT"
    ui_info_table "Property,Value" \
        "Upstream Repository,dsh-tauri/deepseek-harness-desktop" \
        "Target Distrobox,$container_name" \
        "Download Cache,$cache_dir"

    if ! command -v distrobox >/dev/null 2>&1; then
        ui_err "'distrobox' is not installed."
        return 1
    fi

    # Ensure container exists or prompt to create
    if ! distrobox list 2>/dev/null | grep -q "^${container_name}\b\|[[:space:]]${container_name}[[:space:]]"; then
        ui_warn "• Distrobox container '${container_name}' does not exist."
        ask_yn "Create '${container_name}' container now?" "Y" cr_choice
        cr_choice="${cr_choice:-Y}"
        if [[ "$cr_choice" =~ ^[Yy]$ ]]; then
            setup_distrobox || return 1
        else
            ui_err "[-] Cannot install .deb without target distrobox container."
            return 1
        fi
    fi

    ui_info "[*] Fetching latest DeepSeek Harness Desktop .deb release from GitHub..."
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
        ui_warn "Could not resolve latest .deb from GitHub API. Using fallback URL..."
        deb_url="https://github.com/dsh-tauri/deepseek-harness-desktop/releases/download/v0.25.2/Deepseek.Harness.Desktop_0.25.2_amd64.deb"
        deb_name="Deepseek.Harness.Desktop_0.25.2_amd64.deb"
    fi

    local target_file="$cache_dir/$deb_name"
    ui_info "[*] Downloading ${deb_name}..."
    if ! curl -fLC - --progress-bar -o "$target_file" "$deb_url"; then
        ui_err "Failed to download DeepSeek Harness Desktop .deb from $deb_url"
        return 1
    fi

    echo
    ui_info "[*] Installing ${deb_name} into '${container_name}' container via apt..."
    if distrobox enter "${container_name}" -- sudo apt-get update && \
       distrobox enter "${container_name}" -- sudo apt-get install -y "$target_file"; then
        echo
        ui_info "[*] Exporting DeepSeek Harness Desktop app and binary to host..."
        distrobox enter "${container_name}" -- distrobox-export --app deepseek-harness-desktop 2>/dev/null || true
        distrobox enter "${container_name}" -- distrobox-export --bin /usr/bin/deepseek-harness-desktop --export-path "$HOME/.local/bin" 2>/dev/null || true
        ui_ok "✓ DeepSeek Harness Desktop (.deb) installed and exported successfully from Distrobox!"
    else
        ui_err "Failed to install DeepSeek Harness Desktop .deb inside distrobox container."
        return 1
    fi
}

install_openclaw_path_config() {
    ui_banner "[Step 1] Configure PATH for OpenClaw Binary" "$C_INDIGO"
    ui_info_table "PATH Property,Details" \
        "Binary Directory,$HOME/.openclaw/bin" \
        "Shell Profiles,~/.bashrc & ~/.zshrc"
    ui_info "[*] Adding $HOME/.openclaw/bin to PATH (created by CLI installer)..."

    export PATH="$HOME/.openclaw/bin:$PATH"
    ensure_shell_rc_line '\.openclaw/bin' "OpenClaw CLI binary directory" 'export PATH="$HOME/.openclaw/bin:$PATH"'
    ui_ok "✓ Step 1 complete: PATH configured with $HOME/.openclaw/bin"
}

install_openclaw_cli_host() {
    ui_banner "[Step 2] Run OpenClaw CLI Installer on Host" "$C_INDIGO"
    ui_info_table "Execution Context,Value" \
        "Target Environment,Regular Host (Outside Distrobox)" \
        "Installer Command,curl -fsSL https://openclaw.ai/install-cli.sh | bash"

    ui_info "[*] Executing OpenClaw CLI installer on host..."
    if curl -fsSL https://openclaw.ai/install-cli.sh | bash; then
        ui_ok "✓ Step 2 complete: OpenClaw CLI installer executed successfully."
    else
        ui_err "OpenClaw CLI installation script returned an error."
        return 1
    fi
}

install_openclaw_onboard_daemon() {
    ui_banner "[Step 3] Run OpenClaw Onboard & Install Daemon (on Host)" "$C_INDIGO"
    ui_info_table "Daemon Property,Value" \
        "Target Environment,Regular Host (Outside Distrobox)" \
        "Onboard Command,openclaw onboard --install-daemon"

    export PATH="$HOME/.openclaw/bin:$PATH"

    if command -v openclaw >/dev/null 2>&1; then
        ui_info "[*] Found 'openclaw' in PATH at: $(command -v openclaw)"
        ask_yn "Run 'openclaw onboard --install-daemon' now?" "Y" run_daemon
        run_daemon="${run_daemon:-Y}"
        if [[ "$run_daemon" =~ ^[Yy]$ ]]; then
            ui_info "[*] Running: openclaw onboard --install-daemon ..."
            openclaw onboard --install-daemon || true
            ui_ok "✓ Step 3 executed: OpenClaw onboard finished."
        else
            ui_warn "Skipped automatic execution. Run it directly anytime:"
            echo -e "  $(ui_c "cyan" "openclaw onboard --install-daemon")"
        fi
    else
        ui_warn "Notice: 'openclaw' not found yet in PATH."
        echo -e "Once installed or in a refreshed shell, run:"
        echo -e "  $(ui_c "cyan" "openclaw onboard --install-daemon")"
    fi
}

install_openclaw() {
    CB_ITEMS=(
        "[Step 0] Install OpenClaw .deb (/home/admin/Downloads/OpenClaw-2026.11.2-amd64.deb) into ubuntu-toolbox distrobox"
        "[Step 1] Add /home/admin/.openclaw/bin/openclaw to PATH"
        "[Step 2] Run curl -fsSL https://openclaw.ai/install-cli.sh | bash on Host"
        "[Step 3] Run openclaw onboard --install-daemon on Host"
    )
    CB_SELECTED=(1 1 1 1)

    checkbox_menu_select \
        "Install OpenClaw Sequence (Steps 0 - 3)" \
        "Source: https://github.com/openclaw/openclaw & https://openclaw.ai\nTarget: Host CLI + ubuntu-toolbox Distrobox" \
        "Run Selected Installation Steps" \
        "Back to Main Menu" \
        "$C_INDIGO" || return 0

    echo
    ui_info "=== Executing OpenClaw Installation Sequence ==="
    [ "${CB_SELECTED[0]}" -eq 1 ] && install_openclaw_deb_distrobox
    [ "${CB_SELECTED[1]}" -eq 1 ] && install_openclaw_path_config
    [ "${CB_SELECTED[2]}" -eq 1 ] && install_openclaw_cli_host
    [ "${CB_SELECTED[3]}" -eq 1 ] && install_openclaw_onboard_daemon

    echo
    ui_ok "✓ OpenClaw sequence finished."
    ui_pause "Press Enter to continue..."
}

download_devpod_cli() {
    local target_arch
    case "$(uname -m)" in
        x86_64)  target_arch="amd64" ;;
        aarch64|arm64) target_arch="arm64" ;;
        *)
            ui_err "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac

    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    local dest_file="$install_dir/devpod"

    echo
    ui_info "[*] Fetching latest DevPod release..."
    local download_url=""
    local tag=""
    if command -v curl &>/dev/null; then
        local release_json
        release_json="$(curl -fsSL https://api.github.com/repos/loft-sh/devpod/releases/latest 2>/dev/null || true)"
        tag="$(echo "$release_json" | grep -m1 '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
        download_url="$(echo "$release_json" | grep "browser_download_url" | grep "devpod-linux-${target_arch}\"" | head -n 1 | cut -d '"' -f 4)"
    fi

    if [ -z "$download_url" ]; then
        download_url="https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-${target_arch}"
    fi

    local ver_label="${tag:-latest}"
    local tmp_download
    tmp_download="$(mktemp -t devpod-download-XXXXXX)"

    ui_banner "Install DevPod CLI" "$C_MINT"
    ui_info_table "DevPod Property,Value" \
        "Version,$ver_label (${target_arch})" \
        "Download URL,$download_url" \
        "Destination,$dest_file"

    ui_info "[*] Downloading DevPod binary ($ver_label, ${target_arch})..."
    if curl -fsSL -L "$download_url" -o "$tmp_download"; then
        # If downloaded file is an archive, extract the binary, else install directly
        if file "$tmp_download" | grep -qi "gzip compressed data"; then
            ui_info "[*] Extracting archive..."
            tar -xzf "$tmp_download" -C "$install_dir" devpod 2>/dev/null || tar -xzf "$tmp_download" -C "$install_dir"
        elif file "$tmp_download" | grep -qi "tar archive"; then
            ui_info "[*] Extracting archive..."
            tar -xf "$tmp_download" -C "$install_dir" devpod 2>/dev/null || tar -xf "$tmp_download" -C "$install_dir"
        else
            cp -f "$tmp_download" "$dest_file"
        fi
        rm -f "$tmp_download"
        chmod +x "$dest_file"
        ui_ok "✓ Successfully installed DevPod binary to $dest_file"

        # Ensure ~/.local/bin is in PATH for current session and shell config
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            ui_warn "• Note: Added ~/.local/bin to current PATH."
        fi
        "$dest_file" version 2>/dev/null || true
    else
        rm -f "$tmp_download"
        ui_err "✗ Failed to download DevPod from $download_url"
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
        ui_err "[!] Could not resolve latest download URL for $name."
        return 1
    fi

    local target_path="$appimages_dir/$filename"
    echo
    ui_info "[*] Downloading latest ${name}..."
    ui_info_table "AppImage Asset,Value" \
        "Application,${name}" \
        "Source URL,${download_url}" \
        "Destination,${target_path}"

    if curl -fLC - --progress-bar -o "$target_path" "$download_url"; then
        chmod +x "$target_path"
        ui_ok "[+] Successfully downloaded and set executable: ${target_path}"
        return 0
    else
        ui_err "Failed to download ${name} from ${download_url}"
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

fetch_latest_appimageupdatetool_url() {
    python3 -c "
import urllib.request, json, re, sys
headers = {'User-Agent': 'Mozilla/5.0'}
try:
    req = urllib.request.Request('https://api.github.com/repos/AppImageCommunity/AppImageUpdate/releases/tags/continuous', headers=headers)
    with urllib.request.urlopen(req, timeout=12) as r:
        data = json.loads(r.read().decode())
        pattern = re.compile(r'appimageupdatetool.*x86_64\.AppImage$', re.IGNORECASE)
        for a in data.get('assets', []):
            if pattern.search(a.get('name', '')):
                print(a.get('browser_download_url'))
                sys.exit(0)
except Exception:
    pass
sys.exit(1)
" 2>/dev/null || echo "https://github.com/AppImageCommunity/AppImageUpdate/releases/download/continuous/appimageupdatetool-x86_64.AppImage"
}

# --- AppImage Installers ---

install_bionic_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest bionic..." fetch_latest_bionic_url)"
    local fn="bionic.appimage"
    download_and_install_single_appimage "Bionic (LM Studio Agent)" "$url" "$fn"
}

install_darktable_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest darktable appimage..." fetch_latest_darktable_appimage_url)"
    local fn="darktable.appimage"
    download_and_install_single_appimage "Darktable" "$url" "$fn"
}

install_eden_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest eden appimage..." fetch_latest_eden_appimage_url)"
    local fn="eden.appimage"
    download_and_install_single_appimage "Eden Nintendo Switch Emulator" "$url" "$fn"
}

install_jan_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest jan appimage..." fetch_latest_jan_appimage_url)"
    local fn="jan.appimage"
    download_and_install_single_appimage "Jan AI Desktop" "$url" "$fn"
}

install_lmms_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest lmms appimage..." fetch_latest_lmms_appimage_url)"
    local fn="lmms.appimage"
    download_and_install_single_appimage "LMMS Digital Audio Workstation" "$url" "$fn"
}

install_musescore_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest musescore appimage..." fetch_latest_musescore_appimage_url)"
    local fn="musescore_studio.appimage"
    download_and_install_single_appimage "MuseScore Studio" "$url" "$fn"
}

install_qtscrcpy_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest qtscrcpy appimage..." fetch_latest_qtscrcpy_appimage_url)"
    local fn="qtscrcpy.appimage"
    download_and_install_single_appimage "QtScrcpy (Android Display & Control)" "$url" "$fn"
}

install_unsloth_appimage() {
    local url
    url="$(ui_spin_fn "Resolving latest unsloth appimage..." fetch_latest_unsloth_appimage_url)"
    local fn="unsloth.appimage"
    download_and_install_single_appimage "Unsloth AI Studio" "$url" "$fn"
}

install_appimageupdatetool() {
    local url
    url="$(ui_spin_fn "Resolving latest appimageupdatetool..." fetch_latest_appimageupdatetool_url)"
    local fn="appimageupdatetool.AppImage"
    download_and_install_single_appimage "AppImageUpdate Tool" "$url" "$fn"
}

install_deepseek_harness_desktop() {
    install_deepseek_harness_desktop_deb_distrobox
}

# Unified AppImage Hub
appimage_hub_menu() {
    local hub_items=(
        "AppImageUpdate Tool (Official Updater CLI)"
        "Bionic (LM Studio Agent)"
        "Darktable (Photography & RAW Developer)"
        "DeepSeek Harness Desktop (Distrobox .deb)"
        "DeepSeek Harness Web (Pixi env & dsh web in ~/AppImages)"
        "DevPod CLI (loft-sh/devpod binary into ~/.local/bin)"
        "Eden (Nintendo Switch Emulator)"
        "Jan (Open-source ChatGPT Alternative)"
        "KoboldCpp (Standalone llama.cpp & UI)"
        "LMMS (Music Production Suite)"
        "LocalAI (Multi-model local AI runtime & AppImage in ~/AppImages/localai)"
        "MuseScore Studio (Music Notation & Scoring)"
        "OpenClaw (CLI, Gateway & Distrobox .deb)"
        "llama-dory (Nemotron-Dory llama.cpp build in ~/AppImages/llama-dory)"
        "llama-prism (Prism llama.cpp inference binaries in ~/AppImages/llama-prism)"
        "QtScrcpy (Android Screen Mirror & Control)"
        "Unsloth (Fast LLM Finetuning & Studio)"
    )
    local hub_sel=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
    local rc

    while true; do
        CB_ITEMS=("${hub_items[@]}")
        CB_SELECTED=("${hub_sel[@]}")
        checkbox_menu_select \
            "AppImage Hub & Local AI Engines" \
            "Target Directory: $HOME/AppImages\nCatalog: 17 Local AI Runtimes; Creative Suites & Portable Apps" \
            "Download Selected AppImages & AI Tools" \
            "Back to Main Menu" \
            "$C_MINT" \
            "Compact & Configure Portable AppImages…"
        rc=$?
        hub_sel=("${CB_SELECTED[@]}")

        if [ "$rc" -eq 1 ]; then
            return 0
        elif [ "$rc" -eq 2 ]; then
            run_appimage_compact
            continue
        fi

        echo
        ui_info "=== Downloading Selected AppImages & AI Tools ==="
        [ "${hub_sel[0]}" -eq 1 ] && install_appimageupdatetool
        [ "${hub_sel[1]}" -eq 1 ] && install_bionic_appimage
        [ "${hub_sel[2]}" -eq 1 ] && install_darktable_appimage
        [ "${hub_sel[3]}" -eq 1 ] && install_deepseek_harness_desktop
        [ "${hub_sel[4]}" -eq 1 ] && setup_deepseek_harness
        [ "${hub_sel[5]}" -eq 1 ] && install_devpod
        [ "${hub_sel[6]}" -eq 1 ] && install_eden_appimage
        [ "${hub_sel[7]}" -eq 1 ] && install_jan_appimage
        [ "${hub_sel[8]}" -eq 1 ] && install_koboldcpp
        [ "${hub_sel[9]}" -eq 1 ] && install_lmms_appimage
        [ "${hub_sel[10]}" -eq 1 ] && install_localai
        [ "${hub_sel[11]}" -eq 1 ] && install_musescore_appimage
        [ "${hub_sel[12]}" -eq 1 ] && install_openclaw
        [ "${hub_sel[13]}" -eq 1 ] && install_llama_dory
        [ "${hub_sel[14]}" -eq 1 ] && install_prism_llamacpp
        [ "${hub_sel[15]}" -eq 1 ] && install_qtscrcpy_appimage
        [ "${hub_sel[16]}" -eq 1 ] && install_unsloth_appimage

        echo
        ui_ok "[+] Selected AppImage & AI installations complete!"
        ui_pause "Press Enter to continue..."
    done
}

run_appimage_compact() {
    local appimages_dir="$HOME/AppImages"
    if [ ! -d "$appimages_dir" ]; then
        ui_warn "• Directory $appimages_dir does not exist."
        return 0
    fi

    shopt -s nullglob nocaseglob
    local appimages=("$appimages_dir"/*.appimage)
    shopt -u nullglob nocaseglob

    if [ "${#appimages[@]}" -eq 0 ]; then
        ui_warn "• No .AppImage files found in $appimages_dir."
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
        "Directory: $appimages_dir\nOperations: Auto-update + .config & .home portable folders" \
        "Configure Selected AppImages" \
        "Back to Menu" \
        "$C_MINT" || return 0

    local to_process=()
    for i in "${!appimages[@]}"; do
        [ "${CB_SELECTED[i]}" -eq 1 ] && to_process+=("${appimages[i]}")
    done

    echo
    ui_info "Processing ${#to_process[@]} selected AppImage(s)..."
    local count=0
    local appimage fname
    for appimage in "${to_process[@]}"; do
        [ -f "$appimage" ] || continue
        fname="$(basename "$appimage")"
        echo
        ui_info "[*] Processing $fname..."
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

    echo
    ui_ok "✓ Finished processing $count AppImage(s)."
    ui_pause "Press Enter to return..."
}

run_ujust() {
    if ! command -v just >/dev/null 2>&1 || { ! command -v ujust >/dev/null 2>&1 && [ ! -x "/usr/bin/ujust" ]; }; then
        ui_warn "Notice: 'just' or 'ujust' is missing."
        prompt_run_playbook_subtask "ujust" "ujust" "Configure just/ujust task runner and Bluefin recipes" || return 1
        if ! command -v just >/dev/null 2>&1; then
            ui_err "'just' binary is still not installed in PATH."
            return 1
        fi
        if ! command -v ujust >/dev/null 2>&1 && [ ! -x "/usr/bin/ujust" ]; then
            ui_err "'ujust' is still not found."
            return 1
        fi
    fi

    local ujust_bin
    ujust_bin="$(command -v ujust 2>/dev/null || echo "/usr/bin/ujust")"

    local uj_items=(
        "1\t🎯 Choose Recipe Interactively…\tLaunch ujust with fuzzy recipe selector (ujust --choose)"
        "2\t📋 List All Available Recipes\tDisplay system and user-defined ujust tasks"
        "3\t✨ Configure Terminal Bling…\tRun ublue-bling shell configuration assistant"
        "4\t⌨️  Run Custom ujust Recipe…\tEnter a specific recipe name and arguments"
        "0\t🚪 Back to Main Menu\tReturn to previous menu"
    )

    while true; do
        if ui_tty; then
            ui_banner "ujust / Universal Blue Task Runner" "$C_INDIGO"
            ui_info_table "Runner Property,Value" \
                "ujust Binary,$ujust_bin" \
                "just Version,$(just --version 2>/dev/null || echo 'Installed')" \
                "Bling Assistant,$([ -x /usr/bin/ublue-bling ] && echo '/usr/bin/ublue-bling' || echo 'Optional')"
        fi
        local uj_choice
        uj_choice=$(gum_action_menu "ujust / Universal Blue Task Runner" "ujust" "${uj_items[@]}")

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
                    ui_warn "ublue-bling script not found in /usr/bin."
                fi
                ;;
            4)
                ask_input "Enter ujust recipe name and arguments (e.g. 'install-brew'): " recipe_args
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
        ui_pause "Press Enter to continue..."
    done
}

configure_udev_rules() {
    ui_banner "Configure Gamepad, Joystick & VR udev Rules" "$C_BLUE"

    local UDEV_DIR="$REPO_ROOT/files/udev"

    if [ ! -d "$UDEV_DIR" ]; then
        prompt_run_playbook_subtask "udev rules" "udev" "Deploy gamepad, joystick & VR udev rules" || return 1
        if [ ! -d "$UDEV_DIR" ]; then
            ui_err "udev source directory still not found: $UDEV_DIR"
            return 1
        fi
    fi

    local rules=("$UDEV_DIR"/*.rules)
    if [ ${#rules[@]} -eq 0 ] || [ ! -e "${rules[0]}" ]; then
        ui_err "No udev rule files found in $UDEV_DIR"
        return 1
    fi

    ui_info_table "udev Configuration,Value" \
        "Source Directory,$UDEV_DIR" \
        "Rule Files Found,${#rules[@]} file(s) (*.rules)" \
        "Target Directory,/etc/udev/rules.d" \
        "Reload Action,udevadm control --reload-rules && udevadm trigger"
    ui_warn "Note: Installing udev rules requires administrator privileges."
    require_sudo "install udev rules to /etc/udev/rules.d/" || return 1

    ui_info "[*] Ensuring /etc/udev/rules.d exists..."
    sudo mkdir -p /etc/udev/rules.d

    ui_info "[*] Installing udev rules..."
    for rule in "${rules[@]}"; do
        local rname
        rname="$(basename "$rule")"
        sudo install -m 0644 "$rule" "/etc/udev/rules.d/$rname"
        echo -e "  $(ui_c "green" "✓") $rname"
    done

    ui_info "[*] Reloading and triggering udev rules..."
    if command -v udevadm >/dev/null 2>&1; then
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        ui_ok "✓ udev rules reloaded and triggered successfully!"
    else
        ui_warn "Warning: 'udevadm' command not found. Rules copied but not reloaded."
    fi

    ui_ok "✓ Successfully deployed gamepad, joystick, and VR udev rules."
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
        echo
        ui_info "=== Running Default Non-Interactive Onboarding Sequence ==="
        configure_homebrew
        install_pixi
        update_terminal_utilities
        setup_distrobox
        configure_flathub_user
        configure_fedora_flatpak_user
        configure_udev_rules
        apply_bazzite_waydroid_config 2>/dev/null || true
        waydroid prop set persist.waydroid.multi_windows true 2>/dev/null || true
        echo -e "\n$(ui_c "bold:green" "All non-interactive onboarding steps completed!")\n"
        return 0
    fi

    checkbox_menu_select \
        "Core User Onboarding Sequence" \
        "Target User: $(whoami)\nWorkflow: Sequential execution of selected onboarding stages" \
        "Run Selected Onboarding Steps" \
        "Back to Main Menu" \
        "$C_CYAN" || return 0

    echo
    ui_info "=== Executing Selected Onboarding Sequence ==="
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
        echo
        ui_info "[*] Configuring Waydroid Multi-Window Mode..."
        if command -v waydroid >/dev/null 2>&1; then
            waydroid prop set persist.waydroid.multi_windows true
            ui_ok "[+] persist.waydroid.multi_windows enabled."
        else
            ui_warn "[!] 'waydroid' command not yet installed; skipped setting property."
        fi
    fi
    [ "${CB_SELECTED[8]}" -eq 1 ] && setup_waydroid
    [ "${CB_SELECTED[9]}" -eq 1 ] && configure_pipewire_streaming

    echo -e "\n$(ui_c "bold:green" "Selected onboarding steps have been successfully executed!")\n"
    ui_pause "Press Enter to continue..."
}

show_help() {
    local text
    text="$(cat <<'EOF'
Usage: launcher.sh [FLAG]

Flags:
  --playbook                      Execute the entire Ansible playbook (--ask-become-pass)
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
  --updatetool                    Install AppImageUpdate Tool
  --bionic | --darktable | --eden | --jan | --lmms | --musescore | --qtscrcpy | --unsloth
  --dsh-desktop, --dsh-deb        Install DeepSeek Harness Desktop (.deb) into Distrobox
  --deepseek, --dsh               Install DeepSeek Harness Web
  --devpod                        Install DevPod CLI
  --koboldcpp, --kobold           Install KoboldCpp Standalone Binary
  --localai, --local-ai           Install LocalAI Binary / AppImage
  --openclaw                      Install OpenClaw (CLI, Service & Distrobox .deb)
  --dory, --llama-dory            Install & Build llama-dory (Nemotron-Dory)
  --prism, --llamacpp             Install Prism llama.cpp Binaries (llama-prism)
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
)"
    if ui_tty; then
        {
            ui_markdown "# Fedora Workstation Launcher" "Run without flags for the interactive gum menu, or pass one flag:"
            echo
            printf '%s\n' "$text"
        } | ui_pager
    else
        printf '%s\n' "$text"
    fi
}

# Non-interactive CLI flag handling
if [ $# -gt 0 ]; then
    case "$1" in
        --playbook)                     run_full_playbook ;;
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
        --updatetool)                   install_appimageupdatetool ;;
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
        --dory|--llama-dory)            install_llama_dory ;;
        --prism|--llamacpp)             install_prism_llamacpp ;;
        --koboldcpp|--kobold)           install_koboldcpp ;;
        --localai|--local-ai)           install_localai ;;
        --openclaw)                     install_openclaw ;;
        --devpod)                       install_devpod ;;
        --udev|--udev-rules)            configure_udev_rules ;;
        -h|--help)                      show_help ;;
        *)
            ui_err "Unknown flag: $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
    exit $?
fi

# Interactive Menu Loop (Apple HIG Menu Organization, Action Verbs, Title-Style Capitalization, and Ellipses)
main_menu_entries=(
    "1\t🚀 Run Core User Onboarding…\tEssential onboarding: Homebrew, Pixi, Distrobox, Flatpaks, udev rules, and Waydroid"
    "2\t📖 Run Full Fedora Playbook\tExecute complete system provisioning playbook (ansible-playbook local.yml --ask-become-pass)"
    "3\t⚡ Open ujust Task Runner…\tBrowse ujust recipes, list tasks, configure terminal bling, or run custom tasks"
    "4\t🍺 Configure Homebrew & PATH\tSet up Linuxbrew environment and shell profiles (~/.bashrc, ~/.zshrc)"
    "5\t📦 Install Pixi Package Manager\tInstall or update fast Conda-compatible package manager (pixi.sh)"
    "6\t🔄 Refresh Terminal Caches\tUpdate tldr pages, rebuild bat syntax themes, refresh fonts, and update man-db"
    "7\t🐧 Set Up Ubuntu Distrobox…\tCreate or replace Ubuntu toolbox container and export UniGetUI"
    "8\t🧩 Configure User Flatpak Remotes…\tEnable user-level Flathub and Fedora OCI remotes without root access"
    "9\t🤖 Open AppImage & Local AI Hub…\tDownload and manage 17 local AI engines, LLM runtimes, and creative apps"
    "10\t🗜️  Compact Portable AppImages…\tOptimize AppImages with portable config/home folders and auto-updaters"
    "11\t📱 Open Waydroid Setup Wizard…\tAndroid container with ARM translation (libndk), Widevine, GAPPS, and multi-window"
    "12\t🖥️  Manage Virtualization & VMs…\tControl Libvirt networks, virt-builder OS templates, XML domains, and Vagrant"
    "13\t🎮 Install Gamepad & VR udev Rules\tDeploy hardware input rules to /etc/udev/rules.d for Steam, VR, and controllers"
    "14\t🔊 Configure PipeWire Audio Routing…\tMulti-user low-latency TCP network audio streaming between sender and receiver"
    "15\t🧹 Run System Cleanup & Benchmarks…\tPrune container caches, remove Snap snapshots, and run disk/GPU benchmarks"
    "0\t🚪 Quit Launcher\tExit Fedora Workstation Control Center"
)

while true; do
    choice=""
    if ui_tty; then
        clear
        ui_dashboard
    fi
    choice="$(gum_action_menu "Select an action (type to filter, Enter to launch, Esc to exit)" "Search Action" "${main_menu_entries[@]}")"
    [ -z "$choice" ] && choice=0

    case "$choice" in
        1) run_all ;;
        2) run_full_playbook ;;
        3) run_ujust ;;
        4) configure_homebrew ;;
        5) install_pixi ;;
        6) update_terminal_utilities ;;
        7) setup_distrobox ;;
        8) configure_flatpak_remotes_user ;;
        9) appimage_hub_menu ;;
        10) run_appimage_compact ;;
        11) fedora_waydroid_setup_wizard ;;
        12) manage_virtualization ;;
        13) configure_udev_rules ;;
        14) configure_pipewire_streaming ;;
        15) cleanup_system ;;
        0|[Qq]|exit)
            echo
            ui_ok "Exiting setup. You can run this script again anytime!"
            exit 0
            ;;
        *)
            echo
            ui_err "Invalid option: '$choice'. Please enter 0-15."
            ;;
    esac
    echo ""
    ui_pause "Press Enter to return to the menu..."
done

