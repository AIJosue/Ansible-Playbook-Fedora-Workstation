#!/bin/bash
# Setup User Environment (gum edition) - Fedora Workstation Control Center
[ "$(id -u)" -eq 0 ] && { echo "Warning: Do NOT run this setup script as root! Execute as a regular user." >&2; exit 1; }

# ==============================================================================
# User Configuration (customize paths, URLs, and defaults here or via env vars)
# ==============================================================================

# Repository & Launcher Paths
BOOTSTRAP_REPO_URL="${BOOTSTRAP_REPO_URL:-https://github.com/AIJosue/Ansible-Playbook-Fedora-Workstation.git}"
BOOTSTRAP_TARGET_DIR="${BOOTSTRAP_TARGET_DIR:-$HOME/Code/Terminal/Ansible-Playbook-Fedora-Workstation}"
LEGACY_REPO_DIR="${LEGACY_REPO_DIR:-$HOME/Ansible-Playbook-Fedora-Workstation}"
DESKTOP_LAUNCHER="${DESKTOP_LAUNCHER:-$HOME/Desktop/launcher.sh}"
PLAYBOOK_FILE="${PLAYBOOK_FILE:-local.yml}"

# UI & Theme ("dark" | "light", "standard" | "high")
HIG_APPEARANCE="${HIG_APPEARANCE:-dark}"
HIG_CONTRAST="${HIG_CONTRAST:-standard}"

# User Directories & Binaries
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-$HOME/.local/bin}"
CACHE_BASE_DIR="${CACHE_BASE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$HOME/Downloads}"
APPIMAGES_DIR="${APPIMAGES_DIR:-$HOME/AppImages}"
CUSTOM_SCRIPTS_DIR="${CUSTOM_SCRIPTS_DIR:-$HOME/Code/Terminal/scripts}"
BENCHMARKS_DIR="${BENCHMARKS_DIR:-$HOME/Benchmarks/Unigine}"
SSH_DIR="${SSH_DIR:-$HOME/.ssh}"

# Package Managers & CLI Tools
HOMEBREW_BIN="${HOMEBREW_BIN:-/home/linuxbrew/.linuxbrew/bin/brew}"
HOMEBREW_INSTALL_URL="${HOMEBREW_INSTALL_URL:-https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh}"
PIXI_DIR="${PIXI_DIR:-$HOME/.pixi/bin}"
PIXI_BIN="${PIXI_BIN:-$PIXI_DIR/pixi}"
PIXI_INSTALL_URL="${PIXI_INSTALL_URL:-https://pixi.sh/install.sh}"
STARSHIP_INSTALL_URL="${STARSHIP_INSTALL_URL:-https://starship.rs/install.sh}"
UJUST_BIN="${UJUST_BIN:-/usr/bin/ujust}"
UBLUE_BLING_BIN="${UBLUE_BLING_BIN:-/usr/bin/ublue-bling}"

# AI / LLM Runtimes & OpenClaw
KOBOLDCPP_BIN="${KOBOLDCPP_BIN:-$APPIMAGES_DIR/koboldcpp-linux-x64-nocuda}"
KOBOLDCPP_PROMPTS_DIR="${KOBOLDCPP_PROMPTS_DIR:-$HOME/Platforms/AI/Prompts}"
LLAMA_PRISM_DIR="${LLAMA_PRISM_DIR:-$APPIMAGES_DIR/llama-prism}"
LLAMA_DORY_DIR="${LLAMA_DORY_DIR:-$APPIMAGES_DIR/llama-dory}"
LLAMA_DORY_REPO_URL="${LLAMA_DORY_REPO_URL:-https://github.com/brianchmielNV/llama.cpp.git}"
LLAMA_DORY_BRANCH="${LLAMA_DORY_BRANCH:-dory-support}"
LLAMA_DORY_DEFAULT_MODEL="${LLAMA_DORY_DEFAULT_MODEL:-$HOME/Platforms/AI/NVIDIA-Nemotron-Labs-Dory1.0-4B-Q5_K_M.gguf}"
LLAMA_DORY_HOST="${LLAMA_DORY_HOST:-192.168.12.116}"
LLAMA_DORY_PORT="${LLAMA_DORY_PORT:-5001}"
LOCALAI_DIR="${LOCALAI_DIR:-$APPIMAGES_DIR/localai}"
OPENCLAW_BIN_DIR="${OPENCLAW_BIN_DIR:-$HOME/.openclaw/bin}"
OPENCLAW_INSTALL_URL="${OPENCLAW_INSTALL_URL:-https://openclaw.ai/install-cli.sh}"
OPENCLAW_DEB_FALLBACK="${OPENCLAW_DEB_FALLBACK:-$DOWNLOADS_DIR/OpenClaw-2026.11.2-amd64.deb}"

# Distrobox & Flatpak
DISTROBOX_CONTAINER="${DISTROBOX_CONTAINER:-ubuntu-toolbox}"
DISTROBOX_IMAGE="${DISTROBOX_IMAGE:-quay.io/toolbx/ubuntu-toolbox:latest}"
FLATHUB_REMOTE_URL="${FLATHUB_REMOTE_URL:-https://dl.flathub.org/repo/flathub.flatpakrepo}"
FEDORA_FLATPAK_URI="${FEDORA_FLATPAK_URI:-oci+https://registry.fedoraproject.org}"

# PipeWire Audio Redirection
PIPEWIRE_DEFAULT_IP="${PIPEWIRE_DEFAULT_IP:-127.0.0.1}"
PIPEWIRE_DEFAULT_PORT="${PIPEWIRE_DEFAULT_PORT:-4713}"

# Waydroid
WAYDROID_SYSTEM_OTA="${WAYDROID_SYSTEM_OTA:-https://ota.waydro.id/system}"
WAYDROID_VENDOR_OTA="${WAYDROID_VENDOR_OTA:-https://ota.waydro.id/vendor}"
WAYDROID_IMAGES_DIR="${WAYDROID_IMAGES_DIR:-/var/lib/waydroid/images}"
WAYDROID_DATA_DIR="${WAYDROID_DATA_DIR:-$HOME/.local/share/waydroid}"
WAYDROID_CACHE_DIR="${WAYDROID_CACHE_DIR:-$CACHE_BASE_DIR/waydroid_downloads}"

# Virtualization & System
KVM_XML_DIR="${KVM_XML_DIR:-$HOME/Platforms/Virtualization/kvm-qemu}"
VAGRANT_BASE_DIR="${VAGRANT_BASE_DIR:-$HOME/Platforms/Virtualization/vagrant}"
LIBVIRT_IMAGES_DIR="${LIBVIRT_IMAGES_DIR:-/var/lib/libvirt/images}"
LIBVIRT_DEFAULT_DISK_SIZE="${LIBVIRT_DEFAULT_DISK_SIZE:-20G}"
LIBVIRT_DEFAULT_PORT_RANGE="${LIBVIRT_DEFAULT_PORT_RANGE:-49152-65535}"
UDEV_RULES_DEST="${UDEV_RULES_DEST:-/etc/udev/rules.d}"

# ==============================================================================
# Runtime State & Core Helpers
# ==============================================================================
SUDO_CMD=""
U="${USER:-$(whoami)}"

_has() { command -v "$1" >/dev/null 2>&1; }
_yes() { [[ "${1:-}" =~ ^[Yy]$ ]]; }
_read_tty() { if [ -r /dev/tty ] && [ -w /dev/tty ]; then read "$@" < /dev/tty; else read "$@"; fi; }
_is_repo_root() { [ -n "$1" ] && [ -f "$1/$PLAYBOOK_FILE" ] && { [ -d "$1/roles" ] || [ -d "$1/tasks" ] || [ -d "$1/.git" ]; }; }
_uhome() { getent passwd "$1" | cut -d: -f6; }
_need() { _has "$1" && return 0; ui_err "'$1' is not installed.${2:+ $2}"; return 1; }
_chk_user() { id "$1" &>/dev/null || { ui_err "User '$1' does not exist."; return 1; }; }

_running_file=""
[ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ] && \
  _running_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/$(basename "${BASH_SOURCE[0]}")"

_find_repo_root() {
  local c
  for c in "${_running_file:+$(dirname "$_running_file")}" "${_running_file:+$(cd "$(dirname "$_running_file")/.." 2>/dev/null && pwd)}" "$PWD" "$BOOTSTRAP_TARGET_DIR" "$LEGACY_REPO_DIR"; do
    _is_repo_root "$c" && { echo "$c"; return 0; }
  done
  return 1
}

_dnf_install() { _has sudo && _has dnf && sudo dnf install -y "$1"; }

_sync_repo() {
  local url="${1:-$BOOTSTRAP_REPO_URL}" dest="${2:-$BOOTSTRAP_TARGET_DIR}"
  if ! _has git; then
    echo "[*] Installing git via sudo dnf..."
    _dnf_install git || { echo "Error: Failed to install git." >&2; return 1; }
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -d "$dest/.git" ]; then
    echo "[*] Updating existing git repository at $dest..."; git -C "$dest" pull --rebase || true
  else
    echo "[*] Cloning repository from $url..."; git clone "$url" "$dest" || { echo "Error: Failed to clone repository." >&2; return 1; }
  fi
}

_sync_desktop_launcher() {
  [ -f "$1/launcher.sh" ] || return 0
  mkdir -p "$(dirname "$DESKTOP_LAUNCHER")"
  cp -f "$1/launcher.sh" "$DESKTOP_LAUNCHER" 2>/dev/null || true
  chmod +x "$DESKTOP_LAUNCHER" 2>/dev/null || true
}

_found_repo="$(_find_repo_root || true)"
if [ -z "$_found_repo" ]; then
  echo "==> Ansible-Playbook-Fedora-Workstation: Setup & Launch <=="
  echo "[*] Playbook workspace not found locally. Initializing repository at $BOOTSTRAP_TARGET_DIR..."
  _sync_repo "$BOOTSTRAP_REPO_URL" "$BOOTSTRAP_TARGET_DIR" || exit 1
  _found_repo="$BOOTSTRAP_TARGET_DIR"
  ! _has gum && _has sudo && { echo "[*] Installing gum via sudo dnf..."; sudo dnf install -y gum 2>/dev/null || true; }
  _sync_desktop_launcher "$_found_repo"
fi

_target_launcher="$_found_repo/launcher.sh"
if [ "$_running_file" != "$_target_launcher" ] && [ "$_running_file" != "$DESKTOP_LAUNCHER" ] && [ -f "$_target_launcher" ]; then
  chmod +x "$_target_launcher"
  [ ! -t 0 ] && [ -r /dev/tty ] && [ -w /dev/tty ] && exec /bin/bash "$_target_launcher" "$@" < /dev/tty
  exec /bin/bash "$_target_launcher" "$@"
fi

# Apple HIG Color System & gum Theming
_hig_set() {
  C_RED=$1 C_ORANGE=$2 C_YELLOW=$3 C_GREEN=$4 C_MINT=$5 C_TEAL=$6 C_CYAN=$7 C_BLUE=$8 C_INDIGO=$9
  C_PURPLE=${10} C_PINK=${11} C_BROWN=${12} C_GRAY=${13} C_GRAY2=${14} C_GRAY4=${15} C_GRAY5=${16}
}
case "${HIG_APPEARANCE}:${HIG_CONTRAST}" in
  light:high) _hig_set "#E9152D" "#C55300" "#A16A00" "#008932" "#008575" "#008198" "#007EAE" "#1E6EF4" "#564ADE" "#B02FC2" "#E7124D" "#956D51" "#6C6C70" "#8E8E93" "#BCBCC0" "#D8D8DC" ;;
  light:*)    _hig_set "#FF383C" "#FF8D28" "#FFCC00" "#34C759" "#00C8B3" "#00C3D0" "#00C0E8" "#0088FF" "#6155F5" "#CB30E0" "#FF2D55" "#AC7F5E" "#8E8E93" "#AEAEB2" "#D1D1D6" "#E5E5EA" ;;
  *:high)     _hig_set "#FF6165" "#FFA056" "#FEDF43" "#4AD968" "#54DFCB" "#3BDDEC" "#6DD9FF" "#5CB8FF" "#A7AAFF" "#EA8DFF" "#FF8AC4" "#DBA679" "#AEAEB2" "#7C7C80" "#444446" "#363638" ;;
  *)          _hig_set "#FF4245" "#FF9230" "#FFD600" "#30D158" "#00DAC3" "#00D2E0" "#3CD3FE" "#0091FF" "#6D7CFF" "#DB34F2" "#FF375F" "#B78A66" "#8E8E93" "#636366" "#3A3A3C" "#2C2C2E" ;;
esac
C_WHITE="#FFFFFF" C_BLACK="#000000" C_LABEL="$C_WHITE" C_SECONDARY_LABEL="$C_GRAY" C_TERTIARY_LABEL="$C_GRAY2"
C_SEPARATOR="$C_GRAY4" C_BG_SECONDARY="$C_GRAY5" C_BG_TERTIARY="$C_GRAY4" C_ACCENT="$C_BLUE" C_FIND_HIGHLIGHT="$C_YELLOW"

for _p in CHOOSE FILTER INPUT WRITE TABLE; do export "GUM_${_p}_HEADER_FOREGROUND=$C_CYAN"; done
for _p in CHOOSE FILTER TABLE; do export "GUM_${_p}_HEADER_BACKGROUND=$C_BG_SECONDARY"; done
for _p in CHOOSE INPUT WRITE FILE; do export "GUM_${_p}_CURSOR_FOREGROUND=$C_WHITE" "GUM_${_p}_CURSOR_BACKGROUND=$C_ACCENT"; done
for _p in FILTER INPUT WRITE; do export "GUM_${_p}_PLACEHOLDER_FOREGROUND=$C_TERTIARY_LABEL"; done
for _p in CHOOSE CONFIRM FILE TABLE; do export "GUM_${_p}_SELECTED_FOREGROUND=$C_WHITE"; done
for _p in CHOOSE FILTER CONFIRM; do export "GUM_${_p}_PADDING=0 1"; done
_gx() { local p="$1"; shift; while [ $# -gt 1 ]; do export "GUM_${p}_${1}=$2"; shift 2; done; }
_gx CHOOSE ITEM_FOREGROUND "$C_LABEL" SELECTED_BACKGROUND "$C_INDIGO" SELECTED_PREFIX " ✓ " UNSELECTED_PREFIX " ○ " CURSOR_PREFIX " ❯ "
_gx FILTER INDICATOR " ❯ " INDICATOR_FOREGROUND "$C_WHITE" INDICATOR_BACKGROUND "$C_ACCENT" SELECTED_PREFIX " ✓ " SELECTED_PREFIX_FOREGROUND "$C_WHITE" SELECTED_PREFIX_BACKGROUND "$C_INDIGO" UNSELECTED_PREFIX " ○ " UNSELECTED_PREFIX_FOREGROUND "$C_SECONDARY_LABEL" TEXT_FOREGROUND "$C_LABEL" CURSOR_TEXT_FOREGROUND "$C_WHITE" CURSOR_TEXT_BACKGROUND "$C_ACCENT" MATCH_FOREGROUND "$C_BLACK" MATCH_BACKGROUND "$C_FIND_HIGHLIGHT" PROMPT "🔍 " PROMPT_FOREGROUND "$C_CYAN"
_gx INPUT PROMPT_FOREGROUND "$C_BLUE"
_gx WRITE CURSOR_LINE_BACKGROUND "$C_BG_SECONDARY"
_gx CONFIRM PROMPT_FOREGROUND "$C_CYAN" PROMPT_BACKGROUND "$C_BG_SECONDARY" SELECTED_BACKGROUND "$C_ACCENT" UNSELECTED_BACKGROUND "$C_BG_TERTIARY" UNSELECTED_FOREGROUND "$C_LABEL"
_gx SPIN SPINNER_FOREGROUND "$C_MINT" TITLE_FOREGROUND "$C_CYAN"
_gx FILE DIRECTORY_FOREGROUND "$C_BLUE" SELECTED_BACKGROUND "$C_INDIGO" SYMLINK_FOREGROUND "$C_TEAL" PERMISSIONS_FOREGROUND "$C_SECONDARY_LABEL" FILE_SIZE_FOREGROUND "$C_BROWN"
_gx TABLE CELL_FOREGROUND "$C_LABEL" BORDER_FOREGROUND "$C_SEPARATOR" SELECTED_BACKGROUND "$C_ACCENT"
_gx PAGER HELP_FOREGROUND "$C_SECONDARY_LABEL" LINE_NUMBER_FOREGROUND "$C_TERTIARY_LABEL" MATCH_FOREGROUND "$C_CYAN" MATCH_HIGH_FOREGROUND "$C_BLACK" MATCH_HIGH_BACKGROUND "$C_FIND_HIGHLIGHT"
unset _p

ensure_gum() {
  _has gum && return 0
  echo "The 'gum' CLI (charmbracelet/gum) is required by this launcher." >&2
  if _has sudo && _has dnf; then
    local ans="Y"
    if [ -t 0 ] || { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then _read_tty -rp "Install gum now via 'sudo dnf install gum'? [Y/n]: " ans
    else echo "[*] Non-interactive environment detected. Installing gum via sudo dnf..."; fi
    _yes "${ans:-Y}" && _dnf_install gum && _has gum && return 0
  fi
  echo "Install it with: sudo dnf install gum" >&2; exit 1
}
ensure_gum

# gum UI Layer
ui_tty() { [ -t 0 ] && [ -t 2 ]; }

ui_c() {
  local s="$1" fl=() c=""
  case "$s" in bold) fl+=(--bold); s="" ;; bold:*) fl+=(--bold); s="${s#bold:}" ;; esac
  case "$s" in green) c="$C_GREEN" ;; yellow) c="$C_YELLOW" ;; cyan) c="$C_CYAN" ;; mint) c="$C_MINT" ;; gray) c="$C_GRAY" ;; esac
  [ -n "$c" ] && fl+=(--foreground "$c")
  [ "${#fl[@]}" -eq 0 ] && printf '%s' "$2" || gum style "${fl[@]}" -- "$2"
}

ui_banner() { ui_tty && gum style --border rounded --border-foreground "${2:-$C_BLUE}" --background "$C_BG_SECONDARY" --padding "0 2" --margin "1 0 0 0" --bold --foreground "$C_WHITE" -- "$1" || printf '\n== %s ==\n' "$1"; }
ui_hr()       { gum style --foreground "$C_SEPARATOR" -- "$(printf '─%.0s' {1..60})"; }
ui_ok()       { gum style --foreground "$C_GREEN" --bold -- "$*"; }
_ui_log()     { GUM_LOG_LEVEL_FOREGROUND="$1" GUM_LOG_MESSAGE_FOREGROUND="$2" gum log --level "$3" -- "${@:4}"; }
ui_info()     { _ui_log "$C_CYAN" "$C_LABEL" info "$*"; }
ui_warn()     { _ui_log "$C_ORANGE" "$C_YELLOW" warn "$*"; }
ui_err()      { _ui_log "$C_RED" "$C_PINK" error "$*" >&2; }
ui_table()    { local c="${1:-Property,Value}"; ui_tty && gum table --print --separator "," --columns "$c" --border rounded 2>/dev/null || { printf '%s\n' "$c"; cat; }; }

ui_info_table() {
  local cols="Property,Details" r
  [[ "${1:-}" == *,* ]] && [ $# -gt 1 ] && [[ "$1" =~ ^[A-Za-z0-9_[:space:]]+,[A-Za-z0-9_[:space:]]+$ ]] && { cols="$1"; shift; }
  ui_tty && { printf '%s\n' "$@" | ui_table "$cols"; } || for r in "$@"; do printf '  %-20s %s\n' "${r%%,*}:" "${r#*,}"; done
}

ui_spin() { local t="$1"; shift; ui_tty && gum spin --spinner dot --title "$t" --show-error -- "$@" || "$@"; }

ui_spin_fn() {
  local t="$1" fn="$2" f tmp rc; shift 2
  ui_tty || { "$fn" "$@"; return $?; }
  export -f "$fn" 2>/dev/null || true
  for f in $(declare -F | awk '{print $3}' | grep -E '^(fetch_|ui_|_|_has)'); do export -f "$f"; done
  tmp="$(mktemp)"; gum spin --spinner dot --title "$t" -- bash -c '"$@" > "$0"' "$tmp" "$fn" "$@"
  rc=$?; cat "$tmp"; rm -f "$tmp"; return $rc
}

ui_confirm() {
  local q="$1" d="${2:-Y}" aff="${3:-Confirm}" neg="${4:-Cancel}" bg="${5:-$C_ACCENT}" ans df="--default=true"
  [[ "$q" =~ ([Dd]estroy|[Ww]ipe|[Rr]emove|[Dd]elete|[Rr]eplace|[Ff]orce|[Pp]rune) ]] && [ -z "${5:-}" ] && bg="$C_RED"
  if ui_tty; then
    [[ "$d" =~ ^[Nn] ]] && df="--default=false"
    gum confirm "$df" --affirmative " $aff " --negative " $neg " --selected.background "$bg" -- "$q"; return $?
  fi
  _read_tty -rp "$q [$d]: " ans || ans="$d"; _yes "${ans:-$d}"
}

ask_yn() { local v=N; ui_confirm "$1" "$2" && v=Y; printf -v "$3" '%s' "$v"; }

ask_input() {
  local p="${1%: }" var="$2" ph="${3:-}" v=""
  [ -z "$ph" ] && [[ "$p" =~ \[(default:\ )?([^]]+)\]$ ]] && { ph="${BASH_REMATCH[2]}"; p="${p% \[*}"; }
  ui_tty && { v="$(gum input --header "$p" --prompt "❯ " --placeholder "${ph:-Type a value and press Enter}" --width 0)" || v=""; } || { _read_tty -rp "$p: " v || v=""; }
  printf -v "$var" '%s' "$v"
}

ask_password() {
  local v=""
  ui_tty && { v="$(gum input --password --header "${1%: }" --prompt "🔒 " --prompt.foreground "$C_ORANGE" --placeholder "Hidden input")" || v=""; } || { _read_tty -s -rp "$1" v || v=""; echo ""; }
  printf -v "$2" '%s' "$v"
}

ui_pause() { local m="${1:-Press Enter to continue...}"; ui_tty && { gum input --prompt "" --placeholder "$m" --no-show-help >/dev/null || true; } || read -rp "$m" _; }

ui_choose() {
  local h="$1" c sel; shift
  if ui_tty; then c="$(gum choose --header "$h" --height 15 -- "$@")" || return 1; [ -n "$c" ] && { echo "$c"; return 0; }; return 1; fi
  select sel in "$@"; do [ -n "$sel" ] && { echo "$sel"; return 0; }; done; return 1
}

ask_menu() {
  local var="$1" h="${2%% \[*}" e k c="" cancel="" labels=(); shift 2
  for e in "$@"; do k="${e%%|*}"; labels+=("$k) ${e#*|}"); [ "$k" = "0" ] && cancel="0"; done
  if ui_tty; then c="$(gum choose --header "$h" --height 15 -- "${labels[@]}")" || c=""; c="${c%%)*}"
  else for e in "${labels[@]}"; do echo "  $e"; done; read -rp "$h: " c; fi
  printf -v "$var" '%s' "${c:-$cancel}"
}

gum_action_menu() {
  local t="$1" p="${2:-Action}" l k ttl d c lines=() rc cols="${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}" n; shift 2
  for l in "$@"; do IFS=$'\t' read -r k ttl d <<<"$(printf '%b' "$l")"; lines+=("$k) $ttl — $d"); done
  for n in "${!lines[@]}"; do [ "${#lines[n]}" -gt $((cols - 8)) ] && lines[n]="${lines[n]:0:$((cols - 9))}…"; done
  if ! ui_tty; then printf '== %s ==\n' "$t" >&2; printf '  %s\n' "${lines[@]}" >&2; read -rp "$p: " c || c=0; echo "${c:-0}"; return 0; fi
  if [ "${#lines[@]}" -gt 8 ]; then c="$(printf '%s\n' "${lines[@]}" | gum filter --header " $t " --placeholder "$p · Type to filter · Enter to select · Esc to go back" --height 20)"; rc=$?
  else c="$(gum choose --header " $t " --height 14 -- "${lines[@]}")"; rc=$?; fi
  [ $rc -ne 0 ] || [ -z "$c" ] && echo "0" || echo "${c%%)*}"
}

checkbox_menu_select() {
  local t="$1" sub="$2" rlbl="${3:-Run Selected Tasks}" clbl="${4:-Back to Main Menu}" col="${5:-$C_BLUE}" xlbl="${6:-}"
  local i tok idx all ns any val ch mk
  if ui_tty; then
    local lbls=() pre=() out ln xpick=0 a=0 xitem="" csv="" p
    for i in "${!CB_ITEMS[@]}"; do
      lbls+=("$(printf '%02d  %s' "$((i + 1))" "${CB_ITEMS[i]//,/;}")")
      [ "${CB_SELECTED[i]:-0}" -eq 1 ] && pre+=("${lbls[i]}")
    done
    [ -n "$xlbl" ] && { xitem="⚙  ${xlbl//,/;}" ; lbls+=("$xitem"); }
    ui_banner "$t" "$col"
    if [ -n "$sub" ]; then
      local sr=() sl
      while IFS= read -r sl; do
        sl="${sl#"${sl%%[![:space:]]*}"}"; [ -z "$sl" ] && continue
        [[ "$sl" == *:* ]] && sr+=("${sl%%:*},${sl#*: }") || sr+=("Context,${sl//,/;}")
      done <<< "$(printf '%b' "$sub")"
      sr+=("Selection,${#pre[@]} of ${#CB_ITEMS[@]} preselected")
      ui_info_table "Attribute,Details" "${sr[@]}"
    else
      ui_info_table "Attribute,Details" "Menu,${t//,/;}" "Items,${#CB_ITEMS[@]} available (${#pre[@]} preselected)" "Action,${rlbl//,/;}"
    fi
    for p in "${pre[@]}"; do csv+="${csv:+,}$p"; done
    local args=(--no-limit --height 20 --ordered --header " [Space/x] Toggle · [Ctrl+A] Toggle All · [Enter] ${rlbl} · [Esc] ${clbl} ")
    [ -n "$csv" ] && args+=(--selected "$csv")
    out="$(gum choose "${args[@]}" -- "${lbls[@]}")" || return 1
    for i in "${!CB_ITEMS[@]}"; do CB_SELECTED[i]=0; done
    while IFS= read -r ln; do
      [ -z "$ln" ] && continue
      if [ -n "$xitem" ] && [ "$ln" = "$xitem" ]; then xpick=1
      elif [[ "$ln" =~ ^([0-9]+)\  ]]; then idx=$((10#${BASH_REMATCH[1]} - 1)); [ "$idx" -ge 0 ] && [ "$idx" -lt "${#CB_ITEMS[@]}" ] && { CB_SELECTED[idx]=1; a=1; }; fi
    done <<<"$out"
    [ "$xpick" -eq 1 ] && [ "$a" -eq 0 ] && return 2
    [ "$a" -eq 0 ] && { ui_warn "No items selected."; sleep 1; return 1; }
    return 0
  fi
  while true; do
    echo "== ${t} =="; [ -n "$sub" ] && printf '%b\n' "$sub"
    echo " Toggle items with numbers [1-${#CB_ITEMS[@]}] (e.g. 1 or 1,3)."
    for i in "${!CB_ITEMS[@]}"; do mk=" "; [ "${CB_SELECTED[i]}" -eq 1 ] && mk="X"; printf "  %2d) [%s] %s\n" "$((i + 1))" "$mk" "${CB_ITEMS[i]}"; done
    echo "   A) Toggle Select ALL / NONE"; echo "   R) ${rlbl}"; [ -n "$xlbl" ] && echo "   C) ${xlbl}"; echo "   0) ${clbl}"
    read -rp "Enter choice: " ch || return 1
    case "$ch" in
      0|[Qq]|back) return 1 ;;
      [Cc]) [ -n "$xlbl" ] && return 2 || echo "Invalid selection." ;;
      [Aa]) all=1; for i in "${!CB_ITEMS[@]}"; do [ "${CB_SELECTED[i]}" -eq 0 ] && { all=0; break; }; done
            ns=$((1 - all)); for i in "${!CB_ITEMS[@]}"; do CB_SELECTED[i]=$ns; done ;;
      [Rr]) any=0; for i in "${!CB_ITEMS[@]}"; do [ "${CB_SELECTED[i]}" -eq 1 ] && { any=1; break; }; done
            [ "$any" -eq 0 ] && { echo "No items selected."; continue; }; return 0 ;;
      *) val=0; for tok in ${ch//,/ }; do
           [[ "$tok" =~ ^[0-9]+$ ]] && [ "$tok" -ge 1 ] && [ "$tok" -le "${#CB_ITEMS[@]}" ] && { idx=$((tok - 1)); CB_SELECTED[idx]=$((1 - CB_SELECTED[idx])); val=1; }
         done; [ "$val" -eq 0 ] && echo "Invalid selection." ;;
    esac
  done
}

_run_checkbox_fns() {
  local t="$1" sub="$2" r="$3" b="$4" c="$5" h="$6" d="$7"; shift 7
  local fns=("$@") i
  checkbox_menu_select "$t" "$sub" "$r" "$b" "$c" || return 0
  echo; ui_info "=== $h ==="
  for i in "${!fns[@]}"; do [ "${CB_SELECTED[i]}" -eq 1 ] && "${fns[i]}"; done
  echo; ui_ok "$d"; ui_pause "Press Enter to continue..."
}

ui_dashboard() {
  ui_tty || return 0
  local os kv gv av bv pv dv wv logo st et
  os="$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Fedora Linux}")"; os="${os//,/;}"
  kv="$(uname -r 2>/dev/null || echo 'unknown')"
  gv="$(gum --version 2>/dev/null | awk '{print $NF}')"
  av="$(_has ansible && ansible --version 2>/dev/null | head -n1 | awk '{print $NF}' | tr -d ']' || echo 'Missing')"
  bv="$([ -x "$HOMEBREW_BIN" ] || _has brew && echo 'Ready' || echo 'Not Set')"
  pv="$([ -x "$PIXI_BIN" ] || _has pixi && echo 'Ready' || echo 'Not Set')"
  dv="$(_has distrobox && echo 'Installed' || echo 'Missing')"
  wv="$(_has waydroid && echo 'Installed' || echo 'Missing')"
  logo="$(gum style --border double --border-foreground "$C_BLUE" --background "$C_BG_SECONDARY" --padding "1 2" --foreground "$C_CYAN" --bold --align center "Fedora Workstation" "Control Center" "$(ui_c "mint" "HIG ${HIG_APPEARANCE^} · ${HIG_CONTRAST^}")" "$(ui_c "gray" "gum ${gv}")")"
  st="$(printf 'User,%s\nHost,%s\nOS,%s\nKernel,%s\nShell,%s\n' "$U" "${HOSTNAME:-$(hostname)}" "$os" "$kv" "$(basename "${SHELL:-bash}")" | ui_table "System,Information")"
  et="$(printf 'Ansible,%s\nHomebrew,%s\nPixi,%s\nDistrobox,%s\nWaydroid,%s\n' "$av" "$bv" "$pv" "$dv" "$wv" | ui_table "Subsystem,Status")"
  gum join --horizontal --align center "$logo" "  " "$st" "  " "$et"
}

# Core Helpers & Playbook Verification
SCRIPT_DIR="${_running_file:+$(dirname "$_running_file")}"
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
REPO_ROOT="$(_find_repo_root || echo "$SCRIPT_DIR")"

ensure_work_folder_and_ansible() {
  local cur repo_ok=0 ans_ok=0
  cur="$(_find_repo_root || echo "$SCRIPT_DIR")"
  _is_repo_root "$cur" && { repo_ok=1; REPO_ROOT="$cur"; }
  _has ansible-playbook && _has ansible && ans_ok=1
  [ "$repo_ok" -eq 1 ] && [ "$ans_ok" -eq 1 ] && { [ ! -f "$DESKTOP_LAUNCHER" ] && _sync_desktop_launcher "$REPO_ROOT"; return 0; }
  ui_banner "Prerequisites Verification: Playbook & Ansible" "$C_INDIGO"
  ui_info_table "Component,Status" "Playbook Workspace,$([ "$repo_ok" -eq 1 ] && echo "Found ($REPO_ROOT)" || echo "Missing ($BOOTSTRAP_TARGET_DIR)")" "Ansible Engine,$([ "$ans_ok" -eq 1 ] && echo "Installed" || echo "Not Installed")" "Desktop Launcher,$DESKTOP_LAUNCHER"
  if [ "$repo_ok" -eq 0 ]; then
    ui_warn "• Ansible playbook workspace folder was not found."
    ask_yn "Would you like to clone the repository now?" "Y" cc; _yes "${cc:-Y}" || { ui_err "Playbook workspace is required."; return 1; }
    ask_input "Repository URL [${BOOTSTRAP_REPO_URL}]: " uu
    _sync_repo "${uu:-$BOOTSTRAP_REPO_URL}" "$BOOTSTRAP_TARGET_DIR" || return 1
    ui_ok "✓ Playbook repository ready at $BOOTSTRAP_TARGET_DIR."; REPO_ROOT="$BOOTSTRAP_TARGET_DIR"
  fi
  if [ "$ans_ok" -eq 0 ]; then
    echo; ui_warn "• Ansible is not installed or not found in PATH."
    ask_yn "Install Ansible now via sudo dnf?" "Y" ic; _yes "${ic:-Y}" || { ui_err "Ansible is required to proceed."; return 1; }
    ui_info "[*] Installing ansible via dnf..."
    _dnf_install ansible && ui_ok "✓ Ansible installed." || { ui_err "Failed to install ansible."; return 1; }
  fi
  if [ -f "$REPO_ROOT/launcher.sh" ]; then
    _sync_desktop_launcher "$REPO_ROOT"; ui_ok "✓ Desktop launcher deployed at: ${DESKTOP_LAUNCHER}"
    local cd_desk; cd_desk="$(cd "$(dirname "$DESKTOP_LAUNCHER")" 2>/dev/null && pwd)/$(basename "$DESKTOP_LAUNCHER")"
    [ "$_running_file" != "$cd_desk" ] && { echo -e "$(ui_c "cyan" "[*] Executing launcher at Desktop (${DESKTOP_LAUNCHER})...")\n"; exec "$DESKTOP_LAUNCHER" "$@"; }
  fi
}
ensure_work_folder_and_ansible "$@" || exit 1

_need_pb() {
  [ -f "$REPO_ROOT/$PLAYBOOK_FILE" ] || { ui_err "Playbook not found at: $REPO_ROOT/$PLAYBOOK_FILE"; return 1; }
  _need ansible-playbook "Install it with: sudo dnf install ansible"
}

_exec_ansible() {
  _need_pb || return 1
  local pb="$REPO_ROOT/$PLAYBOOK_FILE" bf="--ask-become-pass" st
  [ "$(id -u)" -eq 0 ] && bf=""
  echo; ui_info_table "Parameter,Value" "Playbook File,$pb" "Privilege Escalation,${bf:-root}" "Command,ansible-playbook $pb $* $bf"
  echo ""; ansible-playbook "$pb" "$@" $bf; st=$?; echo
  [ $st -eq 0 ] && ui_ok "✓ Ansible execution completed!" || ui_err "Playbook finished with exit code ${st}."
  return $st
}

_run_ansible() {
  if [ -n "${1:-}" ]; then _exec_ansible --tags "$1"
  else ui_banner "Run Full Fedora Workstation Playbook" "$C_INDIGO"; _exec_ansible; fi
}

_ansible_list_tasks() {
  _need_pb || return 1
  local line
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]{6}([^[:space:]:]+)[[:space:]]+:[[:space:]]+(.+)[[:space:]]+TAGS:[[:space:]]*\[(.*)\]$ ]] && \
      printf '%s\t%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]%"${BASH_REMATCH[2]##*[![:space:]]}"}" "${BASH_REMATCH[3]}"
  done < <(ansible-playbook "$REPO_ROOT/$PLAYBOOK_FILE" ${1:+--tags "$1"} --list-tasks 2>/dev/null)
}

_ansible_task_action_menu() {
  local role="$1" task="$2" tags="$3" st="${4:-$1}" ft="$1 : $2"
  local items=(
    "1\t▶ Run From This Task (--start-at-task)\tStart at '${task}' within --tags ${st}"
    "2\t🪜 Step From This Task (--start-at-task --step)\tConfirm each task interactively starting at '${task}'"
    "3\t🏷️  Run by Task Tags (--tags)\tRun tasks tagged [${tags:-$st}]"
    "4\t🧪 Dry Run / Check (--check --diff)\tPreview changes for '${task}' without modifying system"
    "0\t⬅ Back\tReturn to task list"
  )
  while true; do
    ui_tty && ui_banner "Task: ${ft}" "$C_INDIGO"
    ui_info_table "Attribute,Value" "Role,${role}" "Task,${task}" "Tags,${tags:-none}"
    case "$(gum_action_menu "Select Execution Mode" "Mode" "${items[@]}")" in
      1) _exec_ansible --tags "$st" --start-at-task "$ft" ;;
      2) _exec_ansible --tags "$st" --start-at-task "$ft" --step ;;
      3) local tc="${tags// /}"; _exec_ansible --tags "${tc:-$st}" ;;
      4) _exec_ansible --tags "$st" --start-at-task "$ft" --step --check --diff ;;
      *) return 0 ;;
    esac
    echo ""; ui_pause "Press Enter to continue..."
  done
}

_ansible_role_tasks_menu() {
  local tr="$1" title="$2" r t tg idx rt="" ch off=1
  local -a t_roles=() t_names=() t_tags=() items=()
  while IFS=$'\t' read -r r t tg; do
    [ -n "$tr" ] && [ "$r" != "$tr" ] && continue
    t_roles+=("$r"); t_names+=("$t"); t_tags+=("$tg"); [ -z "$rt" ] && rt="${tg%%,*}"
  done <<< "$PLAYBOOK_TASKS_CACHE"
  [ "${#t_names[@]}" -eq 0 ] && { ui_warn "No tasks found for '${tr:-playbook}'."; return 0; }
  rt="${rt// /}"
  while true; do
    items=()
    if [ -n "$tr" ]; then
      off=3
      items+=("1\t▶ Run Entire Role (--tags ${rt:-$tr})\tRun all ${#t_names[@]} tasks in ${tr}" "2\t🪜 Step Through Role (--step)\tConfirm each of the ${#t_names[@]} tasks in ${tr}")
      for idx in "${!t_names[@]}"; do items+=("$((idx + 3))\t🔹 ${t_names[idx]}\tTAGS: [${t_tags[idx]}]"); done
    else
      for idx in "${!t_names[@]}"; do items+=("$((idx + 1))\t🔹 ${t_roles[idx]} : ${t_names[idx]}\tTAGS: [${t_tags[idx]}]"); done
    fi
    items+=("0\t⬅ Back\tReturn to roles")
    ui_tty && ui_banner "$title" "$C_CYAN"
    ch="$(gum_action_menu "Select a task to run or debug" "Task" "${items[@]}")"
    case "$ch" in
      0|"") return 0 ;;
      1|2)
        if [ -n "$tr" ]; then _exec_ansible --tags "${rt:-$tr}" $([ "$ch" = 2 ] && echo --step); echo ""; ui_pause "Press Enter to continue..."
        else idx=$((ch - 1)); [ "$idx" -lt "${#t_names[@]}" ] && _ansible_task_action_menu "${t_roles[idx]}" "${t_names[idx]}" "${t_tags[idx]}" "${t_tags[idx]%%,*}"; fi ;;
      *)
        [[ "$ch" =~ ^[0-9]+$ ]] && idx=$((ch - off)) && [ "$idx" -ge 0 ] && [ "$idx" -lt "${#t_names[@]}" ] && \
          _ansible_task_action_menu "${t_roles[idx]}" "${t_names[idx]}" "${t_tags[idx]}" "${rt:-${t_roles[idx]}}" ;;
    esac
  done
}

run_playbook_menu() {
  _need_pb || return 1
  [ ! -t 0 ] && { _run_ansible; return $?; }
  ui_info "Parsing Ansible playbook tasks from ${PLAYBOOK_FILE}..."
  PLAYBOOK_TASKS_CACHE="$(_ansible_list_tasks)"
  [ -n "$PLAYBOOK_TASKS_CACHE" ] || { ui_err "Failed to parse tasks from $REPO_ROOT/$PLAYBOOK_FILE"; return 1; }

  local -a roles=() rcnt=() rtags=()
  local r t tg i f ch
  while IFS=$'\t' read -r r t tg; do
    f=-1; for i in "${!roles[@]}"; do [ "${roles[i]}" = "$r" ] && { f="$i"; break; }; done
    [ "$f" -eq -1 ] && { roles+=("$r"); rcnt+=(1); rtags+=("${tg// /,}"); } || rcnt[f]=$((rcnt[f] + 1))
  done <<< "$PLAYBOOK_TASKS_CACHE"

  while true; do
    local items=("1\t🚀 Run Full Playbook (local.yml)\tExecute all roles and tasks" "2\t🔍 Browse All Playbook Tasks…\tInspect and run/step any individual task")
    for i in "${!roles[@]}"; do items+=("$((i + 3))\t📦 ${roles[i]}\t${rcnt[i]} tasks · tags: [${rtags[i]}]"); done
    items+=("0\t🚪 Back to Main Menu\tReturn")
    ui_tty && ui_banner "Dynamic Ansible Playbook & Task Runner" "$C_INDIGO"
    ch="$(gum_action_menu "Select a role or task view (parsed from local.yml)" "Role" "${items[@]}")"
    case "$ch" in
      0|"") return 0 ;;
      1) _run_ansible; echo ""; ui_pause "Press Enter to continue..." ;;
      2) _ansible_role_tasks_menu "" "All Tasks in local.yml" ;;
      *) [[ "$ch" =~ ^[0-9]+$ ]] && i=$((ch - 3)) && [ "$i" -ge 0 ] && [ "$i" -lt "${#roles[@]}" ] && _ansible_role_tasks_menu "${roles[i]}" "Role Tasks: ${roles[i]}" ;;
    esac
  done
}

prompt_run_playbook_subtask() {
  echo; ui_warn "[!] Required dependency or file for '${1}' is missing."
  ui_info_table "Missing Dependency,Details" "Feature,${1}" "Ansible Tag,--tags ${2}" "Description,${3}"
  ask_yn "Run the Ansible playbook for this subtask now?" "Y" rc; _yes "${rc:-Y}" && _run_ansible "$2"
}

_need_pb_cmd() {
  _has "$1" && return 0
  prompt_run_playbook_subtask "$2" "$3" "$4" || return 1
  _need "$1"
}

require_sudo() {
  SUDO_CMD=""
  [ "$EUID" -ne 0 ] && { _has sudo || { ui_err "sudo is required to ${1:-perform administrative tasks}."; return 1; }; sudo -v || { ui_err "sudo authentication failed."; return 1; }; SUDO_CMD="sudo"; }
}

ensure_shell_rc_line() {
  local pat="$1" cmt="$2" line="$3" rc sh
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    sh="${rc##*.}"; sh="${sh%rc}"
    [ "$rc" = "$HOME/.zshrc" ] && { { [ -f "$rc" ] || _has zsh; } || continue; touch "$rc"; }
    if ! grep -q "$pat" "$rc" 2>/dev/null; then
      printf '\n# %s\n%s\n' "$cmt" "${line//\{SH\}/$sh}" >> "$rc"; ui_ok "✓ Added $cmt hook to ${rc/#$HOME/\~}"
    elif [ "$rc" = "$HOME/.bashrc" ]; then ui_warn "• $cmt already configured in ~/.bashrc"; fi
  done
}

_dl_file() { curl -fL --progress-bar -o "$2" "$1" || { ui_err "Failed to download ${3:-$1}"; return 1; }; }

_fetch_release_assets() {
  curl -fsSL -A "Mozilla/5.0" -m 15 "$1" 2>/dev/null | python3 -c "
import json, re, sys
pat, excl, first = re.compile(sys.argv[1], re.I), sys.argv[2], sys.argv[3] == '1'
excl_re = re.compile(excl, re.I) if excl else None
for a in json.load(sys.stdin).get('assets', []):
  n, u = a.get('name', ''), a.get('browser_download_url', '')
  if pat.search(n) and not (excl_re and excl_re.search(n)):
    print(f'{n}\t{u}')
    if first: break
" "${2:-.*}" "${3:-}" "${4:-0}" 2>/dev/null
}

_ensure_distrobox_container() {
  local c="${1:-$DISTROBOX_CONTAINER}"
  _need distrobox || return 1
  if ! distrobox list 2>/dev/null | grep -q "^${c}\b\|[[:space:]]${c}[[:space:]]"; then
    ui_warn "• Distrobox container '${c}' does not exist."
    ask_yn "Create '${c}' container now?" "Y" crc
    _yes "${crc:-Y}" && setup_distrobox || { ui_err "[-] Cannot install .deb without target distrobox container."; return 1; }
  fi
}

_install_deb_distrobox() {
  local t="$1" repo="$2" pat="$3" excl="$4" fb_u="$5" fb_n="$6" app="$7" bin="$8" ldeb="${9:-}"
  local cn="$DISTROBOX_CONTAINER" cache="${CACHE_BASE_DIR}/${app}_downloads" tgt="" info dn du
  mkdir -p "$cache"; ui_banner "$t" "$C_INDIGO"
  ui_info_table "Property,Value" "Upstream Repository,$repo" "Target Distrobox,$cn" "Download Cache,$cache"
  _ensure_distrobox_container "$cn" || return 1
  if [ -n "$ldeb" ] && [ -f "$ldeb" ]; then
    tgt="$ldeb"; echo -e "$(ui_c "green" "✓ Using existing deb package:") $tgt"
  else
    ui_info "[*] Fetching latest .deb release from GitHub ($repo)..."
    info="$(_fetch_release_assets "https://api.github.com/repos/$repo/releases/latest" "$pat" "$excl" 1 || true)"
    if [ -n "$info" ]; then IFS=$'\t' read -r dn du <<< "$info"
    else ui_warn "Could not resolve latest .deb. Using fallback URL..."; dn="$fb_n"; du="$fb_u"; fi
    tgt="$cache/$dn"; ui_info "[*] Downloading ${dn}..."
    _dl_file "$du" "$tgt" ".deb from $du" || return 1
  fi
  echo; ui_info "[*] Installing $(basename "$tgt") into '${cn}'..."
  if distrobox enter "$cn" -- sudo apt-get update && distrobox enter "$cn" -- sudo apt-get install -y "$tgt"; then
    echo; ui_info "[*] Exporting $app to host..."
    distrobox enter "$cn" -- distrobox-export --app "$app" 2>/dev/null || true
    distrobox enter "$cn" -- distrobox-export --bin "$bin" --export-path "$LOCAL_BIN_DIR" 2>/dev/null || true
    ui_ok "✓ $app (.deb) installed and exported!"
  else ui_err "Failed to install $app .deb inside distrobox."; return 1; fi
}

# Developer Environments, Distrobox & Flatpaks
configure_homebrew() {
  ui_banner "[1/8] Configure Homebrew Environment & PATH" "$C_ORANGE"
  local bp="$HOMEBREW_BIN" se="eval \"\$($HOMEBREW_BIN shellenv)\""
  [ ! -x "$bp" ] && _has brew && bp="$(command -v brew)"
  ui_info_table "Setting,Value" "Target User,$U" "Binary Path,$bp" "Shell Profiles,~/.bashrc & ~/.zshrc" "Status,$([ -x "$bp" ] && echo "Installed" || echo "Not Installed")"
  if [ -x "$bp" ]; then
    ui_ok "Found Homebrew at: ${bp}"
    ensure_shell_rc_line "linuxbrew.*shellenv" "Homebrew environment" "$se"; eval "$($bp shellenv)"
    echo -e "$(ui_c "bold:green" "✓ Homebrew active:") $(brew --version | head -n 1)"
  else
    ui_warn "Homebrew not detected at ${HOMEBREW_BIN}."
    ask_yn "Install Homebrew now?" "N" ch
    if _yes "$ch"; then
      ui_info "Running Homebrew installer..."
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")"
      [ -x "$HOMEBREW_BIN" ] && { eval "$("$HOMEBREW_BIN" shellenv)"; ensure_shell_rc_line "linuxbrew.*shellenv" "Homebrew environment" "$se"; ui_ok "✓ Homebrew installed!"; }
    else ui_warn "Skipping Homebrew configuration."; fi
  fi
}

install_pixi() {
  ui_banner "[2/8] Install Pixi Package Manager" "$C_MINT"
  local pbin="$PIXI_BIN" pdir="$PIXI_DIR" pver="Not Installed"
  { [ -x "$pbin" ] || _has pixi; } && pver="$(pixi --version 2>/dev/null || "$pbin" --version)"
  ui_info_table "Setting,Value" "Package Manager,Pixi (https://pixi.sh)" "Install Prefix,$pdir" "Detected Version,$pver"
  if [ -x "$pbin" ] || _has pixi; then
    echo -e "$(ui_c "bold:green" "Pixi is already installed:") $pver"
    ask_yn "Reinstall/update Pixi?" "N" rc; _yes "$rc" || return 0
  fi
  ui_info "Running Pixi official installer..."
  curl -fsSL "$PIXI_INSTALL_URL" | bash
  if [ -d "$pdir" ]; then
    export PATH="$pdir:$PATH"; ensure_shell_rc_line '\.pixi/bin' "Pixi package manager" "export PATH=\"${pdir}:\$PATH\""
    echo -e "$(ui_c "green" "✓ Pixi installed:") $("$pdir/pixi" --version)"
  else ui_err "Pixi directory $pdir not found after install."; fi
}

install_starship() {
  ui_banner "Install Starship Prompt" "$C_CYAN"
  local sh_hook='command -v starship >/dev/null 2>&1 && eval "$(starship init {SH})"'
  if _has starship; then
    ui_ok "✓ Starship prompt is already installed: $(starship --version 2>/dev/null | head -n 1)"
    ensure_shell_rc_line 'starship init' "Starship prompt" "$sh_hook"; return 0
  fi
  _need curl "Install curl first to download Starship." || return 1
  ui_info "Installing Starship prompt binary from starship.rs..."
  if ( set -o pipefail; curl -fsSL --connect-timeout 10 "$STARSHIP_INSTALL_URL" | sh -s -- -y ); then
    ui_ok "✓ Starship prompt installed: $(starship --version 2>/dev/null | head -n 1)"
    ensure_shell_rc_line 'starship init' "Starship prompt" "$sh_hook"
  else ui_warn "Starship prompt installation failed or was skipped."; return 1; fi
}

update_terminal_utilities() {
  ui_banner "[3/8] Refresh TLDR & Terminal Utilities Cache" "$C_TEAL"
  ui_info_table "Utility,Operation" "tldr,Update command examples cache" "bat,Rebuild syntax theme cache" "git-lfs,Configure user Git LFS hooks" "fc-cache,Refresh font caches" "mandb,Update man page database"
  if _has tldr; then ui_spin "Updating TLDR pages cache..." bash -c 'tldr --update || tldr -u' >/dev/null 2>&1 && ui_ok "✓ TLDR cache updated." || ui_warn "TLDR update had notices."
  else ui_warn "• 'tldr' not found, skipping."; fi
  local item cmd title ecmd msg
  for item in \
    "bat|Updating Bat syntax cache...|bat cache --build|✓ Bat cache built." \
    "git-lfs|Configuring Git LFS hooks...|git lfs install --skip-repo|✓ Git LFS configured." \
    "fc-cache|Refreshing font caches...|fc-cache -f|✓ Font cache refreshed." \
    "mandb|Updating man database...|mandb -q|✓ Man database refreshed."; do
    IFS='|' read -r cmd title ecmd msg <<< "$item"
    _has "$cmd" && { ui_spin "$title" bash -c "$ecmd" >/dev/null 2>&1 || true; ui_ok "$msg"; }
  done
  ui_ok "✓ All terminal utilities updated!"
}

setup_distrobox() {
  ui_banner "[4/8] Set Up Ubuntu Distrobox Container" "$C_ORANGE"
  local cn="$DISTROBOX_CONTAINER" img="$DISTROBOX_IMAGE"
  ui_info_table "Container Property,Value" "Container Name,$cn" "OCI Image,$img" "Default Add-on,UniGetUI (.deb) auto-export"
  _need_pb_cmd distrobox "Distrobox" "packages_dnf" "Install base DNF packages including distrobox" || return 1
  if distrobox list 2>/dev/null | grep -q "^${cn}\b\|[[:space:]]${cn}[[:space:]]"; then
    ui_warn "• Distrobox container '${cn}' already exists."
    ask_yn "Replace it? (Stops and removes existing container)" "N" rep
    if _yes "$rep"; then ui_info "Removing '${cn}'..."; distrobox stop --yes "$cn" 2>/dev/null || true; distrobox rm --yes "$cn" 2>/dev/null || true
    else ui_warn "Skipping distrobox setup."; return 0; fi
  fi
  ui_info "Creating '${cn}' from ${img}..."; ui_warn "Note: Image pull may take a moment on first run."
  if distrobox create --name "$cn" --image "$img" --yes; then
    ui_ok "✓ Distrobox '${cn}' created."
    distrobox enter "$cn" -- true 2>/dev/null && echo -e "$(ui_c "green" "✓ Container initialized.")" || echo -e "$(ui_c "yellow" "• Will finish initializing on first 'distrobox enter ${cn}'.")"
    ask_yn "Install UniGetUI.linux-x64.deb inside '${cn}'?" "Y" ug
    _yes "${ug:-Y}" && _install_deb_distrobox "Install UniGetUI (.deb) into Distrobox" "Devolutions/UniGetUI" 'x64.*\.deb$' "" "https://github.com/Devolutions/UniGetUI/releases/download/v2026.3.3/UniGetUI.linux-x64.deb" "UniGetUI.linux-x64.deb" "unigetui" "/usr/bin/unigetui"
  else ui_err "Failed to create distrobox '${cn}'."; return 1; fi
}

_add_flatpak_remote() {
  ui_banner "$1" "$C_TEAL"
  ui_info_table "Remote Property,Value" "Remote Name,$2 (user scope)" "$3,$4" "Target User,$U"
  _need_pb_cmd flatpak "Flatpak" "flatpak_cli" "Install flatpak package manager only" || return 1
  ui_info "Adding $2 repository for $U..."
  flatpak remote-add --user --if-not-exists "$2" "$4" && ui_ok "✓ $2 remote added." || { ui_err "Failed to add $2 remote."; return 1; }
}
configure_flathub_user()        { _add_flatpak_remote "[5/8] Add Flathub Remote (User)" "flathub" "Repository URL" "$FLATHUB_REMOTE_URL"; }
configure_fedora_flatpak_user() { _add_flatpak_remote "[6/8] Add Fedora Flatpak Remote (User)" "fedora" "Registry URI" "$FEDORA_FLATPAK_URI"; }

configure_flatpak_remotes_user() {
  CB_ITEMS=("Flathub Remote (${FLATHUB_REMOTE_URL#https://})" "Fedora Flatpak Remote (${FEDORA_FLATPAK_URI})")
  CB_SELECTED=(1 1)
  _run_checkbox_fns "Configure User Flatpak Remotes" "Target User: $U\nScope: --user (unprivileged)" \
    "Apply Selected Remotes" "Back to Main Menu" "$C_TEAL" "Configuring Selected User Flatpak Remotes" "✓ Flatpak remotes configuration complete!" \
    configure_flathub_user configure_fedora_flatpak_user
}

# PipeWire Multi-User Audio Redirection
_restart_pipewire_user() {
  $SUDO_CMD systemctl --user -M "${1}@" is-active --quiet pipewire-pulse.service 2>/dev/null || return 1
  $SUDO_CMD systemctl --user -M "${1}@" restart pipewire.service pipewire-pulse.service wireplumber.service
  ui_ok "✓ Restarted pipewire services for $1."
}

disable_pipewire_streaming() {
  ui_banner "Disable PipeWire Audio Redirection" "$C_PINK"
  ui_info_table "Cleanup Target,Path" "Sender Profiles,~/.bashrc and ~/.profile" "Desktop Environment,~/.config/environment.d/pipewire-share.conf" "Receiver TCP Config,~/.config/pipewire/pipewire-pulse.conf.d/tcp-share.conf"
  require_sudo "disable audio redirection" || return 1
  echo -e "$(ui_c "bold" "[Step 1: The Sound Source / Sender]")"
  ask_input "Username of SENDER [default: $U]: " USER_SENDER; USER_SENDER=${USER_SENDER:-$U}
  _chk_user "$USER_SENDER" || return 1
  local shome rc econf rhome tconf; shome=$(_uhome "$USER_SENDER")
  for rc in "$shome/.bashrc" "$shome/.profile"; do
    [ -f "$rc" ] && { $SUDO_CMD sed -i -e '/# Route audio output to/d' -e '/export PULSE_SERVER=tcp:/d' "$rc"; ui_ok "✓ Cleaned $USER_SENDER's ~/${rc##*/}"; }
  done
  econf="$shome/.config/environment.d/pipewire-share.conf"; [ -f "$econf" ] && { $SUDO_CMD rm -f "$econf"; ui_ok "✓ Removed $econf"; }
  echo ""; echo -e "$(ui_c "bold" "[Step 2: The Sound Output / Receiver]")"
  ask_input "Username of RECEIVER (optional, Enter to skip): " USER_RECEIVER
  if [ -n "$USER_RECEIVER" ]; then
    if id "$USER_RECEIVER" &>/dev/null; then
      rhome=$(_uhome "$USER_RECEIVER"); tconf="$rhome/.config/pipewire/pipewire-pulse.conf.d/tcp-share.conf"
      [ -f "$tconf" ] && { $SUDO_CMD rm -f "$tconf"; ui_ok "✓ Removed $tconf"; }
      _restart_pipewire_user "$USER_RECEIVER" || true
    else ui_warn "User '$USER_RECEIVER' not found. Skipping receiver cleanup."; fi
  fi
  echo ""; ui_banner "PipeWire Audio Redirection Disabled!" "$C_GREEN"
  echo "Note: Log out and back in as $USER_SENDER for desktop changes to reset."; ui_hr
}

enable_pipewire_streaming() {
  ui_banner "Enable PipeWire Audio Redirection" "$C_PINK"
  [ ! -t 0 ] && [ -z "${USER_RECEIVER:-}" ] && { ui_warn "Non-interactive session; skipping PipeWire setup."; return 0; }
  ui_info_table "Audio Role,Description" "Sender (Source),User running apps whose audio is routed out" "Receiver (Speakers),User with physical access to speakers" "Protocol,PipeWire-Pulse TCP (default port ${PIPEWIRE_DEFAULT_PORT})"
  require_sudo "configure PipeWire audio redirection" || return 1
  echo -e "$(ui_c "bold" "[Step 1: Receiver]")"
  ask_input "Username with WORKING SPEAKERS [default: $U]: " USER_RECEIVER; USER_RECEIVER=${USER_RECEIVER:-$U}
  _chk_user "$USER_RECEIVER" || return 1
  local rhome shome; rhome=$(_uhome "$USER_RECEIVER")
  echo ""; echo -e "$(ui_c "bold" "[Step 2: Sender]")"
  ask_input "Username to TRANSMIT/SEND audio: " USER_SENDER
  _chk_user "$USER_SENDER" || return 1
  shome=$(_uhome "$USER_SENDER")
  echo ""; echo -e "$(ui_c "bold" "[Step 3: Network]")"
  ask_input "IP address (${PIPEWIRE_DEFAULT_IP} for same PC) [default: ${PIPEWIRE_DEFAULT_IP}]: " BIND_IP; BIND_IP=${BIND_IP:-$PIPEWIRE_DEFAULT_IP}
  ask_input "Port [default: ${PIPEWIRE_DEFAULT_PORT}]: " BIND_PORT; BIND_PORT=${BIND_PORT:-$PIPEWIRE_DEFAULT_PORT}

  local cdir="$rhome/.config/pipewire/pipewire-pulse.conf.d" el="export PULSE_SERVER=tcp:${BIND_IP}:${BIND_PORT}" rc edir="$shome/.config/environment.d"
  $SUDO_CMD mkdir -p "$cdir"
  printf 'pulse.properties = {\n    server.address = [\n        "unix:native"\n        "tcp:%s:%s"\n    ]\n}\n' "$BIND_IP" "$BIND_PORT" | $SUDO_CMD tee "$cdir/tcp-share.conf" >/dev/null
  $SUDO_CMD chown -R "$USER_RECEIVER":"$USER_RECEIVER" "$rhome/.config/pipewire"
  $SUDO_CMD loginctl enable-linger "$USER_RECEIVER" 2>/dev/null || true
  _restart_pipewire_user "$USER_RECEIVER" || ui_warn "• $USER_RECEIVER inactive; will load on next login."

  for rc in "$shome/.bashrc" "$shome/.profile"; do
    if $SUDO_CMD grep -Fxq "$el" "$rc" 2>/dev/null; then ui_warn "• Route already set in $USER_SENDER's ${rc##*/}"
    else printf '\n# Route audio output to %s\n%s\n' "$USER_RECEIVER" "$el" | $SUDO_CMD tee -a "$rc" >/dev/null; $SUDO_CMD chown "$USER_SENDER":"$USER_SENDER" "$rc"; ui_ok "✓ Configured $USER_SENDER's ~/${rc##*/}"; fi
  done
  $SUDO_CMD mkdir -p "$edir"
  printf '# Route audio output to %s\nPULSE_SERVER=tcp:%s:%s\n' "$USER_RECEIVER" "$BIND_IP" "$BIND_PORT" | $SUDO_CMD tee "$edir/pipewire-share.conf" >/dev/null
  $SUDO_CMD chown -R "$USER_SENDER":"$USER_SENDER" "$edir"
  echo ""; ui_banner "Setup Complete & Fully Persistent!" "$C_GREEN"
  ui_info_table "Role,Status" "Receiver ($USER_RECEIVER),Listening on tcp:${BIND_IP}:${BIND_PORT}" "Sender ($USER_SENDER),Routing PULSE_SERVER to tcp:${BIND_IP}:${BIND_PORT}" "Notice,Log out and back in for desktop launchers"
  ui_hr
}

configure_pipewire_streaming() {
  [ ! -t 0 ] && { enable_pipewire_streaming; return 0; }
  ui_banner "PipeWire Multi-User Audio Redirection" "$C_PINK"
  ui_info_table "Property,Details" "Subsystem,PipeWire / PulseAudio TCP Bridge" "Default Endpoint,${PIPEWIRE_DEFAULT_IP}:${PIPEWIRE_DEFAULT_PORT}" "Persistence,~/.bashrc; ~/.profile; ~/.config/environment.d"
  case "$(gum_action_menu "PipeWire Audio Redirection" "Option" \
    "1\t🔊 Enable PipeWire Redirection…\tRoute audio output across local users or machines via TCP" \
    "2\t🔇 Disable PipeWire Redirection…\tRemove audio routes and clean up environment files" \
    "0\t🚪 Back to Main Menu\tReturn to previous menu")" in
    1) enable_pipewire_streaming ;; 2) disable_pipewire_streaming ;;
  esac
}

# Waydroid Setup & Maintenance
run_waydroid_init_wizard() {
  ui_banner "Waydroid Initialization Wizard" "$C_GREEN"
  [ ! -t 0 ] && { ui_warn "Non-interactive session; skipping Waydroid setup."; return 0; }
  local SOTA="$WAYDROID_SYSTEM_OTA" VOTA="$WAYDROID_VENDOR_OTA" ic="" stype="GAPPS" ff=""
  ui_info_table "OTA Endpoint,Channel URL" "System OTA,$SOTA" "Vendor OTA,$VOTA" "Image Directory,$WAYDROID_IMAGES_DIR"
  require_sudo "configure Waydroid" || return 1
  if ! rpm -q waydroid &>/dev/null; then
    ui_warn "[!] Waydroid is not installed."
    prompt_run_playbook_subtask "Waydroid" "packages_dnf,waydroid" "Install Waydroid package and configure integration"
    if ! rpm -q waydroid &>/dev/null; then
      ask_yn "Install waydroid via dnf?" "Y" ic; _yes "${ic:-Y}" && $SUDO_CMD dnf install -y waydroid sqlite || { ui_err "[-] Cannot proceed without waydroid."; return 1; }
    fi
  else ui_ok "[+] Waydroid is already installed."; fi
  ask_menu ic "Select Android System Image" "1|GAPPS — Google Play Store & GMS" "2|VANILLA — Clean Open-Source LineageOS"
  [ "${ic:-1}" = "2" ] && stype="VANILLA"
  [ -d "$WAYDROID_IMAGES_DIR" ] && [ -n "$($SUDO_CMD ls -A "$WAYDROID_IMAGES_DIR" 2>/dev/null)" ] && { ask_yn "Existing images found. Force wipe and re-download?" "N" fc; _yes "$fc" && ff="-f"; }
  systemctl is-active --quiet waydroid-container 2>/dev/null && $SUDO_CMD systemctl stop waydroid-container
  ui_info "[*] Initializing Waydroid (${stype})..."
  $SUDO_CMD waydroid init -s "$stype" -c "$SOTA" -v "$VOTA" $ff
  $SUDO_CMD systemctl enable --now waydroid-container
  ui_banner "Waydroid Initialized Successfully!" "$C_GREEN"
  if [ "$stype" = "GAPPS" ]; then
    cat <<EOF
[!] GOOGLE PLAY CERTIFICATION REQUIRED (user: ${SUDO_USER:-$USER}):
1. Start session: waydroid session start
2. Get ID: sudo waydroid shell 'sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select value from main where name=\"android_id\";"'
3. Register at: https://www.google.com/android/uncertified (wait 5-10 min, restart session)
EOF
  else echo -e "Launch anytime with:\n    waydroid session start\n    waydroid show-full-ui"; fi
}

_manage_waydroid_addon() {
  local sp="$REPO_ROOT/Scripts/$3" c=""
  [ -f "$sp" ] || { ui_err "Script not found: $sp"; return 1; }
  ui_banner "$1" "$C_GREEN"
  ui_info_table "Property,Details" "Component,$2" "Helper Script,$sp" "Target,${4:-Waydroid Android Container}"
  ask_menu c "Select Action" "1|Install $2" "2|Remove $2" "0|Back to Waydroid Menu"
  case "$c" in 1) sudo "$sp" install ;; 2) sudo "$sp" uninstall ;; 0|[Qq]|back) return 0 ;; *) ui_err "Invalid option: '$c'." ;; esac
}

fetch_latest_fdroid_apk_url() {
  curl -fsSL -A "Mozilla/5.0" -m 12 "https://f-droid.org/api/v1/packages/$1" 2>/dev/null | python3 -c "
import json, sys
pkg = sys.argv[1]; d = json.load(sys.stdin); sug = d.get('suggestedVersionCode')
for p in d.get('packages', []):
  if p.get('versionCode') == sug and p.get('apkName'): print(f'https://f-droid.org/repo/{p[\"apkName\"]}'); sys.exit(0)
print(f'https://f-droid.org/repo/{pkg}_{sug}.apk')
" "$1" 2>/dev/null
}

fetch_latest_github_apk_url() {
  local out; out="$(_fetch_release_assets "https://api.github.com/repos/$1/releases/latest" '\.apk$' "" 1 || true)"
  [ -n "$out" ] && echo "${out#*$'\t'}" || echo "https://github.com/$1/releases/latest/download/app-release.apk"
}

download_and_install_apk() {
  local cache="$WAYDROID_CACHE_DIR" tgt
  mkdir -p "$cache"; tgt="$cache/$3"
  echo; ui_info "[*] Downloading ${1}..."
  ui_info_table "APK Package,Details" "Application,${1}" "Source URL,${2}" "Local Cache,${tgt}"
  _dl_file "$2" "$tgt" "${1}" || return 1
  ui_ok "[+] Downloaded ${1}."
  if _has waydroid; then
    ui_info "[*] Installing ${3} into Waydroid..."
    waydroid app install "$tgt" && ui_ok "[+] ${1} installed!" || ui_warn "[!] 'waydroid app install' failed. Saved at: ${tgt}"
  else ui_warn "[!] waydroid not found. APK saved at: ${tgt}"; fi
}

install_mobilerun() {
  ui_banner "MobileRun Setup (via uv)" "$C_GREEN"
  _need uv "Install via: sudo dnf install uv  or  curl -LsSf https://astral.sh/uv/install.sh | sh" || return 1
  uv tool install mobilerun
  [[ ":$PATH:" != *":$LOCAL_BIN_DIR:"* ]] && export PATH="$LOCAL_BIN_DIR:$PATH"
  local mr; mr="$(command -v mobilerun 2>/dev/null || echo "$LOCAL_BIN_DIR/mobilerun")"
  [ -x "$mr" ] || { ui_err "mobilerun binary not found after install."; return 1; }
  ui_ok "✓ mobilerun installed."
  _has adb && { ui_info "[*] Checking ADB devices..."; adb devices -l; }
  ask_yn "Run 'mobilerun setup' now?" "Y" run_mr
  _yes "${run_mr:-Y}" && "$mr" setup || ui_warn "Run '$mr setup' when ADB target is connected."
}

_WD_APPS=(
  "F-Droid Official Client|direct|https://f-droid.org/F-Droid.apk||F-Droid.apk"
  "Aurora Store (Google Play Client)|fdroid|com.aurora.store|https://f-droid.org/repo/com.aurora.store_76.apk|AuroraStore.apk"
  "Neo Store (Modern F-Droid Client)|fdroid|com.machiav3lli.fdroid|https://f-droid.org/repo/com.machiav3lli.fdroid_1303.apk|NeoStore.apk"
  "SmartDock Desktop Launcher|fdroid|cu.axel.smartdock|https://f-droid.org/repo/cu.axel.smartdock_1150.apk|SmartDock.apk"
  "XtMapper Keymapper|github|Xtr126/XtMapper|https://github.com/Xtr126/XtMapper/releases/download/v2.5.0/app-release.apk|XtMapper.apk"
  "3DMark Android Benchmark (UL Solutions)|direct|https://benchmarks.ul.com/downloads/3DMark.apk||3DMark.apk"
  "Morphe Manager|github|MorpheApp/morphe-manager|https://github.com/MorpheApp/morphe-manager/releases/download/v2.5.0/morphe-manager-2.5.0.apk|MorpheManager.apk"
  "MobileRun Portal|github|droidrun/mobilerun-portal|https://github.com/droidrun/mobilerun-portal/releases/download/v0.8.2/com.mobilerun.portal-0.8.2.apk|MobileRunPortal.apk"
  "MobileRun (via uv, installs to ADB device)|mobilerun|||"
)

_install_wd_app() {
  local lbl kind arg fb fn u
  IFS='|' read -r lbl kind arg fb fn <<< "${_WD_APPS[$1]}"
  case "$kind" in
    direct) download_and_install_apk "$lbl" "$arg" "$fn" ;;
    fdroid) u=$(ui_spin_fn "Resolving latest fdroid apk..." fetch_latest_fdroid_apk_url "$arg" 2>/dev/null || true); download_and_install_apk "$lbl" "${u:-$fb}" "$fn" ;;
    github) u=$(ui_spin_fn "Resolving latest github apk..." fetch_latest_github_apk_url "$arg" 2>/dev/null || true); download_and_install_apk "$lbl" "${u:-$fb}" "$fn" ;;
    mobilerun) install_mobilerun ;;
  esac
}

install_all_waydroid_apps() {
  local i; CB_ITEMS=(); for i in "${!_WD_APPS[@]}"; do CB_ITEMS+=("${_WD_APPS[i]%%|*}"); done
  CB_SELECTED=(1 1 1 1 1 1 1 1 0)
  checkbox_menu_select "Select Waydroid APKs & Add-ons to Install" "Cache: $WAYDROID_CACHE_DIR\nTarget: Active Waydroid Container & ADB" \
    "Install Selected Apps" "Back to Waydroid Menu" "$C_GREEN" || return 0
  echo; ui_info "=== Installing Selected Waydroid Add-ons ==="
  for i in "${!_WD_APPS[@]}"; do [ "${CB_SELECTED[i]}" -eq 1 ] && _install_wd_app "$i"; done
  echo; ui_ok "[+] Completed installation of selected apps!"; ui_pause "Press Enter to continue..."
}

apply_bazzite_waydroid_config() {
  ui_banner "Install Bazzite Custom Waydroid Files" "$C_GREEN"
  local sdir="$REPO_ROOT/files/waydroid" f
  [ -d "$sdir" ] || { ui_err "Source directory not found: $sdir"; return 1; }
  for f in waydroid-container-start waydroid-container-stop waydroid-container-restart waydroid-fix-controllers; do sudo install -m 0755 "$sdir/$f" "/usr/libexec/$f"; done
  for f in waydroid-choose-gpu waydroid-launcher; do sudo install -m 0755 "$sdir/$f" "/usr/bin/$f"; done
  sudo install -m 0644 "$sdir/waydroid-launcher.default" /etc/default/waydroid-launcher
  sudo mkdir -p /usr/share/polkit-1/actions /usr/share/polkit-1/rules.d
  sudo install -m 0644 "$sdir/org.bazzite.waydroid.policy" /usr/share/polkit-1/actions/org.bazzite.waydroid.policy
  sudo install -m 0644 "$sdir/30-waydroid.rules" /usr/share/polkit-1/rules.d/30-waydroid.rules
  ui_ok "[+] Applied Bazzite Waydroid custom files and policies!"
}

_wd_stop() { waydroid session stop 2>/dev/null || true; sudo waydroid container stop 2>/dev/null || true; }

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
  ) tc val
  while true; do
    if ui_tty; then
      local srv="Inactive"; systemctl is-active --quiet waydroid-container 2>/dev/null && srv="Active (Running)"
      ui_banner "Waydroid Troubleshooting & Maintenance" "$C_ORANGE"
      ui_info_table "Component,Current State" "Container Daemon,$srv" "Image Path,$WAYDROID_IMAGES_DIR" "User Data,$WAYDROID_DATA_DIR"
    fi
    tc=$(gum_action_menu "Waydroid Troubleshooting & Maintenance" "Troubleshoot" "${ts_items[@]}")
    case "$tc" in
      1) sudo waydroid container start ;;
      2) ui_warn "[i] Keep running until 'Android with user 0 is ready'."; waydroid session start ;;
      3) waydroid show-full-ui ;;
      4|5) val="true"; [ "$tc" = "5" ] && val="false"
           waydroid prop set persist.waydroid.multi_windows "$val"; ui_ok "[+] persist.waydroid.multi_windows = $val"
           ui_confirm "Restart session now?" "N" && { waydroid session stop 2>/dev/null || true; ui_ok "[+] Session stopped."; } ;;
      6) _wd_stop; ui_ok "[+] Stopped." ;;
      7) ui_hr; ui_err "  WARNING: REINSTALL & WIPE WAYDROID DATA"; ui_hr
         ui_confirm "Wipe all Waydroid images, user data, and optionally remove package?" "N" || { ui_warn "Aborted."; ui_pause; continue; }
         _wd_stop; ui_confirm "Remove waydroid package via dnf?" "N" && sudo dnf remove -y waydroid
         sudo rm -rf /var/lib/waydroid /home/.waydroid
         rm -rf "$HOME/waydroid" "$HOME/.share/waydroid" "$HOME/.local/share/waydroid" "$HOME/.local/share/applications/"*aydroid* 2>/dev/null || true
         ui_ok "[+] Cleanup complete!" ;;
      8) clear; ui_banner "Waydroid Manual Setup & Reset Guide" "$C_BLUE"
         printf 'Start: sudo waydroid container start && waydroid session start && waydroid show-full-ui\nMulti-Window: waydroid prop set persist.waydroid.multi_windows true && waydroid session stop\nReset: ./launcher.sh --waydroid (after removing /var/lib/waydroid and ~/.local/share/waydroid)\n' ;;
      *) break ;;
    esac
    echo ""; ui_pause "Press Enter to continue..."
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
  ) wc cur_ft ac m i
  while true; do
    if ui_tty; then
      local pkg="Not Installed" srv="Stopped"
      rpm -q waydroid &>/dev/null && pkg="Installed ($(rpm -q --queryformat '%{VERSION}' waydroid 2>/dev/null))"
      systemctl is-active --quiet waydroid-container 2>/dev/null && srv="Running"
      ui_banner "Fedora Waydroid Setup Wizard" "$C_GREEN"
      ui_info_table "Waydroid Subsystem,Status" "Package Status,$pkg" "Container Service,$srv" "Helper Scripts,$REPO_ROOT/Scripts/install-{libndk;widevine}.sh"
    fi
    wc=$(gum_action_menu "Fedora Waydroid Setup Wizard" "Waydroid" "${w_items[@]}")
    case "$wc" in
      1) install_all_waydroid_apps ;;
      2) run_waydroid_init_wizard
         [ -f "$REPO_ROOT/Scripts/install-libndk.sh" ] && sudo "$REPO_ROOT/Scripts/install-libndk.sh" install
         [ -f "$REPO_ROOT/Scripts/install-widevine.sh" ] && sudo "$REPO_ROOT/Scripts/install-widevine.sh" install ;;
      3) run_waydroid_init_wizard ;;
      4) _manage_waydroid_addon "Waydroid libndk ARM Translation Setup" "libndk ARM/ARM64 Translation Layer" "install-libndk.sh" "AMD / Intel x86_64 Host" ;;
      5) _manage_waydroid_addon "Waydroid Widevine DRM Setup" "Google Widevine L3 DRM" "install-widevine.sh" ;;
      6) apply_bazzite_waydroid_config; ui_pause ;;
      7) [ -x /usr/bin/waydroid-choose-gpu ] || apply_bazzite_waydroid_config; sudo /usr/bin/waydroid-choose-gpu; ui_pause ;;
      8) [ -x /usr/libexec/waydroid-fix-controllers ] && sudo /usr/libexec/waydroid-fix-controllers || { echo add | sudo tee /sys/devices/virtual/input/input*/event*/uevent >/dev/null 2>&1 || true; }; ui_ok "[+] Controller uevents triggered."; ui_pause ;;
      9) cur_ft=$(waydroid prop get persist.waydroid.fake_touch 2>/dev/null || echo "not set")
         [ "$cur_ft" = "1" ] || [ "$cur_ft" = "true" ] && { waydroid prop set persist.waydroid.fake_touch 0; ui_warn "[*] fake_touch = 0"; } || { waydroid prop set persist.waydroid.fake_touch 1; ui_ok "[*] fake_touch = 1"; }
         ui_pause ;;
      10) m=(); for i in "${!_WD_APPS[@]}"; do m+=("$((i+1))\t${_WD_APPS[i]%%|*}\tInstall into Waydroid / ADB"); done; m+=("0\tBack\tReturn")
          ac=$(gum_action_menu "Install Single Waydroid APK" "APK" "${m[@]}"); [[ "$ac" =~ ^[0-9]+$ ]] && (( ac >= 1 && ac <= ${#_WD_APPS[@]} )) && _install_wd_app "$((ac - 1))" ;;
      11) waydroid_troubleshooting_menu ;;
      ""|0|[Qq]|back) break ;;
      *) ui_err "Invalid option: '$wc'." ;;
    esac
  done
}

# System Cleanup & Benchmarks
prune_podman()     { _need podman || return 1; ui_info "Running podman system prune..."; podman system prune; }
prune_podman_all() { _need podman || return 1; ui_warn "This removes ALL unused images and volumes."; ask_yn "Continue?" "N" c; _yes "$c" && podman system prune -a --volumes; }
forget_snap_snapshots() { _has snap || { ui_warn "• 'snap' not found, skipping."; return 0; }; ui_info "Removing saved snap snapshots..."; sudo snap saved | awk 'NR>1 {print $1}' | xargs -r -n 1 sudo snap forget; ui_ok "✓ Snap snapshots removed."; }

benchmark_folder() {
  local dir tf; ask_input "Folder to benchmark [default: $HOME]: " dir; dir="${dir:-$HOME}"
  [ -d "$dir" ] && [ -w "$dir" ] || { ui_err "'$dir' is not a writable directory."; return 1; }
  tf="$(mktemp -p "$dir" .benchmark.XXXXXX)" || return 1
  echo "Write: $(dd if=/dev/zero of="$tf" bs=1G count=1 oflag=direct 2>&1 | tail -n1 | awk -F', ' '{print $NF}')"
  echo "Read:  $(dd if="$tf" of=/dev/null bs=1G count=1 iflag=direct 2>&1 | tail -n1 | awk -F', ' '{print $NF}')"
  rm -f "$tf"
}

fetch_latest_unigine_superposition_url() {
  python3 -c "
import urllib.request, re
hdr, cands = {'User-Agent': 'Mozilla/5.0'}, set()
for u in ['https://benchmark.unigine.com/superposition', 'https://unigine.com/products/benchmarks/superposition/']:
  try:
    with urllib.request.urlopen(urllib.request.Request(u, headers=hdr), timeout=12) as r:
      cands.update(re.findall(r'https?://[^\s\"\'<>]+(?:Unigine_Superposition|superposition)[^\s\"\'<>]*\.run', r.read().decode('utf-8', 'ignore'), re.I))
  except Exception: pass
print(sorted(cands, key=lambda l: [int(x) for x in m.group(1).split('.')] if (m := re.search(r'Unigine_Superposition-([0-9.]+)\.run', l, re.I)) else [0], reverse=True)[0] if cands else 'https://assets.unigine.com/d/Unigine_Superposition-1.1.run')
"
}

install_unigine_superposition() {
  local tdir="$BENCHMARKS_DIR" url fn df; mkdir -p "$tdir"
  url="$(ui_spin_fn "Resolving latest unigine superposition..." fetch_latest_unigine_superposition_url)"
  fn="$(basename "$url")"; df="$tdir/$fn"
  ui_info_table "Benchmark Asset,Value" "Release File,$fn" "Source URL,$url" "Destination,$df"
  if [ -f "$df" ]; then
    ask_yn "File $df exists. Re-download?" "N" rd
    _yes "$rd" || { chmod +x "$df"; ui_ok "[+] Executable at: $df"; return 0; }
  fi
  ui_info "[*] Downloading ${fn} (~1.5GB)..."
  _dl_file "$url" "$df" "from $url" && { chmod +x "$df"; ui_ok "[+] Downloaded: $df"; }
}

cleanup_system() {
  CB_ITEMS=("Podman system prune (containers, networks, dangling images)" "Podman system prune ALL (-a --volumes)" "Remove saved Snap snapshots" "Folder read/write benchmark (direct I/O dd test)" "Download & Setup Unigine Superposition Benchmark (.run)")
  CB_SELECTED=(1 0 1 0 0)
  _run_checkbox_fns "System Cleanup & Benchmarks" "Scope: Podman; Snap snapshots; Direct I/O & GPU benchmarks" \
    "Run Selected Tasks" "Back to Main Menu" "$C_YELLOW" "Executing Cleanup & Benchmark Tasks" "✓ Cleanup and benchmark tasks completed!" \
    prune_podman prune_podman_all forget_snap_snapshots benchmark_folder install_unigine_superposition
}

# Virtualization & VM Management (Libvirt & Vagrant)
autostart_libvirt_vm() {
  _need virsh || return 1
  local vms vm; mapfile -t vms < <(sudo virsh list --all --name | sed '/^$/d')
  [ "${#vms[@]}" -eq 0 ] && { ui_warn "• No libvirt VMs found."; return 0; }
  vm="$(ui_choose "Select VM to autostart" "${vms[@]}" "Cancel")"; [ -z "$vm" ] || [ "$vm" = "Cancel" ] && return 0
  sudo virsh autostart "$vm" && ui_ok "✓ '$vm' will start at boot."
}

forward_libvirt_ports() {
  _need firewall-cmd || return 1
  ui_banner "Forward Ports to Libvirt VMs" "$C_PURPLE"
  ask_menu pc "Select Port Forwarding Rule" "1|Open Default Dynamic Range (${LIBVIRT_DEFAULT_PORT_RANGE} TCP & UDP)" "2|Open Custom Port or Range…" "0|Cancel"
  local ports=() p
  case "$pc" in
    1) ports=("${LIBVIRT_DEFAULT_PORT_RANGE}/tcp" "${LIBVIRT_DEFAULT_PORT_RANGE}/udp") ;;
    2) ask_input "Port or range (e.g. 8080 or 5000-5100): " port
       [[ "$port" =~ ^[0-9]+(-[0-9]+)?$ ]] || { ui_err "Invalid port: '$port'."; return 1; }
       ports=("$port/tcp" "$port/udp") ;;
    *) return 0 ;;
  esac
  for p in "${ports[@]}"; do sudo firewall-cmd --permanent --zone=libvirt --add-port="$p" || return 1; done
  sudo firewall-cmd --reload && ui_ok "✓ Opened ${ports[*]} in libvirt zone."
}

define_libvirt_vms() {
  _need virsh || return 1
  local dir="$KVM_XML_DIR"; [ -n "$(ls "$dir"/*.xml 2>/dev/null)" ] || dir="$REPO_ROOT/files/vms"
  local xmls=("$dir"/*.xml) i
  [ -f "${xmls[0]}" ] || { ui_warn "• No VM XML files found in $dir."; return 0; }
  CB_ITEMS=(); CB_SELECTED=(); for i in "${!xmls[@]}"; do CB_ITEMS[i]="$(basename "${xmls[i]}")"; CB_SELECTED[i]=1; done
  checkbox_menu_select "Define Libvirt VMs from XML" "Source: $dir\nHypervisor: QEMU/KVM (virsh define)" "Define Selected VMs" "Back to Menu" "$C_PURPLE" || return 0
  for i in "${!xmls[@]}"; do [ "${CB_SELECTED[i]}" -eq 1 ] && sudo virsh define "${xmls[i]}" && ui_ok "✓ Defined ${CB_ITEMS[i]}."; done
  ui_pause "Press Enter to return..."
}

start_default_libvirt_network() {
  _need virsh || return 1
  ui_info "[*] Starting and autostarting libvirt 'default' network..."
  sudo virsh net-start default 2>/dev/null || true; sudo virsh net-autostart default 2>/dev/null || true
  sudo virsh net-info default 2>/dev/null && ui_ok "✓ Libvirt 'default' network ready." || ui_warn "• Unable to query 'default' network."
}

list_virt_builder_templates() {
  _need virt-builder "Install: sudo dnf install libguestfs-tools-c" || return 1
  ui_banner "Available virt-builder OS Templates" "$C_BLUE"; virt-builder --list
}

build_virt_builder_vm() {
  _need virt-builder "Install: sudo dnf install libguestfs-tools-c" || return 1
  ui_banner "Build VM Image with virt-builder" "$C_BLUE"
  local arch="$(uname -m)" tpl="" pick="" e menu=()
  for e in "debian-12:Debian 12" "debian-13:Debian 13" "fedora-41:Fedora 41 Server" "fedora-42:Fedora 42 Server" "ubuntu-20.04:Ubuntu 20.04" "centosstream-9:CentOS Stream 9" "alma-8.5:AlmaLinux 8.5" "opensuse-tumbleweed:openSUSE Tumbleweed"; do
    menu+=("$(printf '%-22s %s' "${e%%:*}" "(${e#*:})")")
  done
  menu+=("Browse & filter ALL templates ($arch)" "Custom template name" "Cancel")
  while [ -z "$tpl" ]; do
    pick="$(ui_choose "Select an OS template" "${menu[@]}")" || return 0
    case "$pick" in
      Cancel) return 0 ;; Custom*) ask_input "Template name: " tpl ;;
      Browse*) local all=(); mapfile -t all < <(ui_spin_fn "Fetching templates for $arch..." virt-builder --list 2>/dev/null | awk -v a="$arch" '$2==a{print}')
               [ "${#all[@]}" -eq 0 ] && { ui_warn "None found for $arch."; ask_input "Template name: " tpl; } || {
                 ui_tty && pick="$(printf '%s\n' "${all[@]}" | gum filter --header "All templates ($arch)" --placeholder "Type to filter · Enter to select · Esc to cancel" --height 15)" || pick="$(ui_choose "All templates ($arch)" "${all[@]}")" || continue
                 tpl="${pick%% *}"
               } ;;
      *) tpl="${pick%% *}" ;;
    esac
  done
  local def_img="${tpl}-vm.qcow2" out_p root_pwd="generate"
  ask_input "Output image name [default: $def_img]: " img_name; img_name="${img_name:-$def_img}"; out_p="$LIBVIRT_IMAGES_DIR/$img_name"
  ask_input "Disk size [default: $LIBVIRT_DEFAULT_DISK_SIZE]: " disk_sz; disk_sz="${disk_sz:-$LIBVIRT_DEFAULT_DISK_SIZE}"
  ask_menu pwd_c "Root Password Option" "1|Auto-generate random password" "2|Custom root password" "3|Disable root password (SSH only)"
  case "${pwd_c:-1}" in
    2) ask_password "Root password: " p1; ask_password "Confirm password: " p2; [ "$p1" != "$p2" ] && { ui_err "Passwords do not match."; return 1; }; [ -n "$p1" ] && root_pwd="password:$p1" ;;
    3) root_pwd="disabled" ;;
  esac
  local def_key="$SSH_DIR/id_rsa.pub" ssh_m ssh_k="" ssh_tmp=""
  [ ! -f "$def_key" ] && [ -f "$SSH_DIR/id_ed25519.pub" ] && def_key="$SSH_DIR/id_ed25519.pub"
  ssh_m="$(ui_choose "SSH public key to inject" "Use default ($def_key)" "Browse for .pub file" "Paste public key" "None")" || ssh_m="None"
  case "$ssh_m" in
    Browse*)
      if ui_tty; then gum style --foreground "$C_SECONDARY_LABEL" -- "Select SSH public key (arrows to browse, Enter to pick, Esc to cancel)"; ssh_k="$(gum file --all --height 12 "$SSH_DIR")" || ssh_k=""
      else read -rp "Select SSH public key: " ssh_k; fi ;;
    Paste*)
      local pk=""; if ui_tty; then pk="$(gum write --header "Paste SSH public key  (Ctrl+D to submit, Esc to cancel)" --placeholder "Paste text here..." --height 6 --width 0)" || pk=""; else read -rp "Paste SSH public key: " pk; fi
      pk="${pk//$'\n'/}"; [ -n "$pk" ] && { ssh_tmp="$(mktemp --suffix=.pub)"; ssh_k="$ssh_tmp"; printf '%s\n' "$pk" > "$ssh_k"; } ;;
    None*) ssh_k="none" ;; *) ssh_k="$def_key" ;;
  esac
  require_sudo "write VM image to $LIBVIRT_IMAGES_DIR" || return 1
  sudo mkdir -p "$LIBVIRT_IMAGES_DIR"
  local bargs=("$tpl" "--output" "$out_p" "--format" "qcow2" "--size" "$disk_sz" "--root-password" "$root_pwd")
  [ -n "$ssh_k" ] && [ "$ssh_k" != "none" ] && [ -f "$ssh_k" ] && bargs+=("--ssh-inject" "root:file:$ssh_k")
  ui_info_table "Build Parameter,Configuration" "OS Template,$tpl" "Target Image,$out_p" "Disk Size,$disk_sz (qcow2)" "Root Auth,$root_pwd"
  sudo virt-builder "${bargs[@]}"; [ -n "$ssh_tmp" ] && rm -f "$ssh_tmp"
  if [ -f "$out_p" ]; then
    ui_banner "VM Image Built!" "$C_GREEN"
    echo "Import: sudo virt-install --name ${img_name%.*} --ram 2048 --vcpus 2 --disk path=$out_p --import --network network=default"
  else ui_err "Failed to create $out_p"; return 1; fi
}

manage_vagrant_vm() {
  local name="$1" dir="$VAGRANT_BASE_DIR/$1"
  _need_pb_cmd vagrant "Vagrant" "packages_dnf" "Install virtualization packages" || return 1
  if [ ! -f "$dir/Vagrantfile" ]; then prompt_run_playbook_subtask "Vagrant VM (${name})" "vagrant" "Provision Vagrant files" || return 1; [ -f "$dir/Vagrantfile" ] || { ui_err "$dir/Vagrantfile not found."; return 1; }; fi
  local items=("1\t▶️  Start VM\tvagrant up --provider libvirt" "4\t🔑 Connect via SSH\tvagrant ssh" "3\tℹ️  Check Status\tvagrant status" "2\t⏹️  Stop VM\tvagrant halt" "5\t🗑️  Destroy VM…\tvagrant destroy -f" "0\t🚪 Back\tReturn")
  while true; do
    ui_tty && { ui_banner "Vagrant Environment: $name" "$C_PURPLE"; ui_info_table "Property,Value" "Box,$name" "Directory,$dir" "Provider,libvirt"; }
    case "$(gum_action_menu "Vagrant VM: $name" "Action" "${items[@]}")" in
      1) (cd "$dir" && vagrant up --provider libvirt) ;; 2) (cd "$dir" && vagrant halt) ;; 3) (cd "$dir" && vagrant status) ;; 4) (cd "$dir" && vagrant ssh) ;;
      5) ui_confirm "Destroy '$name' VM?" "N" && (cd "$dir" && vagrant destroy -f) ;; *) return 0 ;;
    esac
  done
}

_LV_ITEMS=("1\t🌐 Start Default Network\tsudo virsh net-start/autostart default" "3\t🏗️  Build VM Image with virt-builder…\tCreate bootable qcow2" "4\t📄 Define Libvirt VMs from XML…\tImport files/vms/*.xml" "5\t🚀 Configure VM Boot Autostart…\tAutostart domain at boot" "6\t🛡️  Forward Firewall Ports…\tOpen ports in libvirt zone" "2\t📋 List OS Templates\tvirt-builder --list")
_VG_ITEMS=("7\t🐧 Manage Vagrant Ubuntu 24.04…\tUbuntu desktop VM" "8\t🌐 Manage Vagrant YunoHost Server…\tYunoHost server VM")
_virt_dispatch() {
  case "$1" in
    1) start_default_libvirt_network ;; 2) list_virt_builder_templates ;; 3) build_virt_builder_vm ;; 4) define_libvirt_vms ;;
    5) autostart_libvirt_vm ;; 6) forward_libvirt_ports ;; 7) manage_vagrant_vm ubuntu ;; 8) manage_vagrant_vm yunohost ;; *) return 1 ;;
  esac
}
_virt_menu() {
  local banner="$1" title="$2" prompt="$3"; shift 3
  while true; do ui_tty && ui_banner "$banner" "$C_PURPLE"; _virt_dispatch "$(gum_action_menu "$title" "$prompt" "$@" "0\t🚪 Back to Main Menu\tReturn")" || return 0; done
}
configure_libvirt() { _need_pb_cmd virsh "Libvirt/KVM" "services" "Enable virtualization stack" || return 1; _virt_menu "Libvirt / KVM Hypervisor Helpers" "Libvirt VM Helpers" "Libvirt" "${_LV_ITEMS[@]}"; }
configure_vagrant() { while true; do ui_tty && ui_banner "Vagrant Virtual Machines" "$C_PURPLE"; _virt_dispatch "$(gum_action_menu "Vagrant VMs" "Vagrant" "${_VG_ITEMS[0]/#7/1}" "${_VG_ITEMS[1]/#8/2}" "0\t🚪 Back\tReturn" | sed 's/^1$/7/;s/^2$/8/')" || return 0; done; }
manage_virtualization() {
  while true; do
    ui_tty && { ui_banner "Virtualization & VM Management" "$C_PURPLE"; ui_info_table "Component,Status" "Libvirt/Virsh,$(_has virsh && echo Installed || echo Missing)" "Vagrant,$(_has vagrant && echo Installed || echo Missing)" "XML Templates,$REPO_ROOT/files/vms"; }
    _virt_dispatch "$(gum_action_menu "Virtualization & VM Management" "Virtualization" "${_LV_ITEMS[@]}" "${_VG_ITEMS[@]}" "0\t🚪 Back to Main Menu\tReturn")" || return 0
  done
}

# Local AI Engines & AppImage Hub
setup_deepseek_harness() {
  ui_banner "Install DeepSeek Harness Web (dsh)" "$C_MINT"
  local adir="$APPIMAGES_DIR" pbin; mkdir -p "$adir"
  pbin="$(command -v pixi 2>/dev/null || echo "$PIXI_BIN")"
  [ ! -x "$pbin" ] && { ui_warn "Pixi not found. Running Pixi setup..."; install_pixi; pbin="$(command -v pixi 2>/dev/null || echo "$PIXI_BIN")"; }
  [ -x "$pbin" ] && [ ! -f "$adir/pixi.toml" ] && (cd "$adir" && "$pbin" init --format toml . 2>/dev/null || "$pbin" init .)
  _need npx "Please install Node.js." || return 1
  ui_info "Installing DeepSeek Harness via npx in $adir..."
  (cd "$adir" && npx -y @deepseek-ai/dsh web --no-open)
  ui_ok "✓ DeepSeek Harness finished in $adir."
}

_dl_extract_asset() {
  local n="$1" u="$2" dest="$3" sm="${4:-0}" tgt sub
  mkdir -p "$dest"; tgt="$dest/$n"; ui_info "[*] Downloading $n..."
  curl -fL --progress-bar -o "$tgt" "$u" || { ui_err "Failed to download $n"; return 1; }
  if [ "$sm" -eq 1 ]; then
    sub="$dest/${n%.tar.gz}"; sub="${sub%.zip}"; mkdir -p "$sub"
    [[ "$n" == *.tar.gz ]] && tar -xzf "$tgt" -C "$sub"; [[ "$n" == *.zip ]] && unzip -q -o "$tgt" -d "$sub"
    find "$sub" -type f -exec chmod +x {} + 2>/dev/null || true; rm -f "$tgt"; ui_ok "✓ Installed: $sub"
  elif [[ "$n" == *.tar.xz || "$n" == *.tar.gz ]]; then tar -xf "$tgt" -C "$dest"; ui_ok "✓ Unpacked: $tgt"
  else chmod +x "$tgt"; [[ "$n" == *.AppImage ]] && ln -sf "$tgt" "$APPIMAGES_DIR/$n" 2>/dev/null || true; ui_ok "✓ Installed executable: $tgt"; fi
}

_select_and_install_release_assets() {
  local t="$1" repo="$2" dest="$3" spin="$4" pat="$5" excl="$6" sm="${7:-0}" back="${8:-Back to Main Menu}" lines n u i urls=()
  mkdir -p "$dest"; ui_info "Fetching latest release assets for ${repo}..."
  lines="$(ui_spin_fn "$spin" _fetch_release_assets "https://api.github.com/repos/$repo/releases/latest" "$pat" "$excl" 0)"
  [ -n "$lines" ] || { ui_err "Failed to fetch assets from ${repo}."; return 1; }
  CB_ITEMS=(); CB_SELECTED=()
  while IFS=$'\t' read -r n u; do [ -z "$n" ] && continue; CB_ITEMS+=("$n"); urls+=("$u"); CB_SELECTED+=(0); done <<< "$lines"
  [ "${#CB_ITEMS[@]}" -eq 0 ] && { ui_warn "• No matching assets found."; return 0; }
  checkbox_menu_select "$t" "Source: https://github.com/${repo}\nDestination: $dest" "Download Selected Assets" "$back" "$C_MINT" || return 0
  for i in "${!CB_ITEMS[@]}"; do [ "${CB_SELECTED[i]}" -eq 1 ] && _dl_extract_asset "${CB_ITEMS[i]}" "${urls[i]}" "$dest" "$sm"; done
  ui_ok "✓ Selected assets installed in: $dest"; ui_pause "Press Enter to continue..."
}

install_prism_llamacpp() {
  local c pat excl
  while true; do
    ui_banner "Install Prism llama.cpp Binaries" "$C_MINT"
    ask_menu c "Select Platform Filter" "1|Browse All Linux & Android Binaries…" "2|Browse Linux Binaries Only…" "3|Browse Android Binaries Only…" "0|Back to Main Menu"
    case "$c" in
      1) pat='(linux|ubuntu|android)'; excl='(win|macos|xcframework)' ;;
      2) pat='(linux|ubuntu)'; excl='(win|macos|xcframework)' ;;
      3) pat='android'; excl='' ;;
      0|[Qq]|back) return 0 ;; *) ui_err "Invalid option: '$c'."; continue ;;
    esac
    _select_and_install_release_assets "Select Prism llama.cpp Binaries" "PrismML-Eng/llama.cpp" "$LLAMA_PRISM_DIR" "Resolving prism llamacpp assets..." "$pat" "$excl" 1 "Back to Filter Menu"
  done
}

install_llama_dory() {
  local td="$LLAMA_DORY_DIR" ru="$LLAMA_DORY_REPO_URL" br="$LLAMA_DORY_BRANCH"
  ui_banner "Install & Build llama-dory (Nemotron Dory)" "$C_MINT"
  if [ -d "$td/.git" ]; then git -C "$td" fetch origin "$br" && git -C "$td" checkout "$br" && git -C "$td" pull origin "$br"
  else mkdir -p "$(dirname "$td")"; git clone -b "$br" "$ru" "$td"; fi
  mkdir -p "$td/build"
  (cd "$td/build" && cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release && cmake --build . --config Release -j"$(nproc 2>/dev/null || echo 4)")
  if [ -f "$td/build/bin/llama-server" ]; then
    ui_ok "✓ Built llama-dory in $td/build/bin"
    [ ! -f "$td/start-server.sh" ] && cat << EOF > "$td/start-server.sh" && chmod +x "$td/start-server.sh"
#!/usr/bin/env bash
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="\${SCRIPT_DIR}/build/bin:\${SCRIPT_DIR}/../.pixi/envs/default/lib:\${LD_LIBRARY_PATH}"
exec "\${SCRIPT_DIR}/build/bin/llama-server" -m "\${1:-${LLAMA_DORY_DEFAULT_MODEL}}" --device none --override-kv "dory.num_loops=int:\${DORY_LOOPS:-2},dory.recurrent_kv_cache_mode=str:per_loop" --host "\${HOST:-${LLAMA_DORY_HOST}}" --port "\${PORT:-${LLAMA_DORY_PORT}}" "\$@"
EOF
  else ui_err "✗ Build failed."; fi
  ui_pause "Press Enter to continue..."
}

install_koboldcpp() { _select_and_install_release_assets "Select KoboldCpp Binaries" "LostRuins/koboldcpp" "$APPIMAGES_DIR" "Resolving koboldcpp assets..." 'linux' '\.exe$' 0; }
launch_koboldcpp() {
  local bin="$KOBOLDCPP_BIN" pdir="$KOBOLDCPP_PROMPTS_DIR" cfgs=() m=() i ch cfg
  [ -f "$bin" ] || { ui_err "KoboldCpp binary not found: $bin"; return 1; }
  [ -x "$bin" ] || chmod +x "$bin" 2>/dev/null || true
  [ -d "$pdir" ] || { ui_err "Prompts directory not found: $pdir"; return 1; }
  shopt -s nullglob; cfgs=("$pdir"/*.kcpps); shopt -u nullglob
  [ "${#cfgs[@]}" -eq 0 ] && { ui_warn "• No .kcpps configs found in $pdir."; return 0; }
  for i in "${!cfgs[@]}"; do m+=("$((i+1))\t$(basename "${cfgs[i]}" .kcpps)\t${cfgs[i]}"); done
  m+=("0\tBack\tReturn")
  ch="$(gum_action_menu "Launch KoboldCpp with Prompt Config" "Config" "${m[@]}")"
  [[ "$ch" =~ ^[0-9]+$ ]] && (( ch >= 1 && ch <= ${#cfgs[@]} )) || return 0
  cfg="${cfgs[$((ch - 1))]}"
  ui_info "[*] Launching KoboldCpp with $(basename "$cfg")..."
  "$bin" --config "$cfg"
}
run_custom_scripts() {
  local sdir="$CUSTOM_SCRIPTS_DIR" scripts=() m=() i ch sc f
  [ -d "$sdir" ] || { ui_err "Scripts directory not found: $sdir"; return 1; }
  shopt -s nullglob; for f in "$sdir"/*; do [ -f "$f" ] && scripts+=("$f"); done; shopt -u nullglob
  [ "${#scripts[@]}" -eq 0 ] && { ui_warn "• No scripts found in $sdir."; return 0; }
  for i in "${!scripts[@]}"; do m+=("$((i+1))\t$(basename "${scripts[i]}")\t${scripts[i]}"); done
  m+=("0\tBack\tReturn")
  ch="$(gum_action_menu "Run Custom Script ($sdir)" "Script" "${m[@]}")"
  [[ "$ch" =~ ^[0-9]+$ ]] && (( ch >= 1 && ch <= ${#scripts[@]} )) || return 0
  sc="${scripts[$((ch - 1))]}"
  ui_info "[*] Running $(basename "$sc")..."
  if [[ "$sc" == *.sh ]]; then bash "$sc"; else [ -x "$sc" ] || chmod +x "$sc" 2>/dev/null || true; "$sc"; fi
}
install_localai()   { _select_and_install_release_assets "Select LocalAI Binaries & Launchers" "mudler/LocalAI" "$LOCALAI_DIR" "Resolving localai assets..." '(linux|appimage)' '(\.exe|\.sha256|\.sig|\.txt|\.md|\.source\.tar\.gz)$' 0; }

install_openclaw_deb_distrobox() {
  _install_deb_distrobox "[Step 0] Install OpenClaw (.deb) in Ubuntu Distrobox" "openclaw/openclaw" 'amd64.*\.deb$' "" \
    "https://github.com/openclaw/openclaw/releases/download/v2026.11.2/OpenClaw-2026.11.2-amd64.deb" "OpenClaw-2026.11.2-amd64.deb" "openclaw" "/usr/bin/openclaw" "$OPENCLAW_DEB_FALLBACK"
}
install_deepseek_harness_desktop() {
  _install_deb_distrobox "Install DeepSeek Harness Desktop (.deb) into Distrobox" "dsh-tauri/deepseek-harness-desktop" 'amd64.*\.deb$' 'bundle' \
    "https://github.com/dsh-tauri/deepseek-harness-desktop/releases/download/v0.25.2/Deepseek.Harness.Desktop_0.25.2_amd64.deb" "Deepseek.Harness.Desktop_0.25.2_amd64.deb" "deepseek-harness-desktop" "/usr/bin/deepseek-harness-desktop"
}

install_openclaw_path_config() { export PATH="$OPENCLAW_BIN_DIR:$PATH"; ensure_shell_rc_line '\.openclaw/bin' "OpenClaw CLI binary directory" "export PATH=\"${OPENCLAW_BIN_DIR}:\$PATH\""; ui_ok "✓ Step 1: PATH configured."; }
install_openclaw_cli_host() { ui_banner "[Step 2] OpenClaw CLI Installer" "$C_INDIGO"; curl -fsSL "$OPENCLAW_INSTALL_URL" | bash && ui_ok "✓ Step 2 complete." || { ui_err "OpenClaw CLI installer failed."; return 1; }; }
install_openclaw_onboard_daemon() {
  export PATH="$OPENCLAW_BIN_DIR:$PATH"
  if _has openclaw; then
    ask_yn "Run 'openclaw onboard --install-daemon' now?" "Y" rd
    _yes "${rd:-Y}" && { openclaw onboard --install-daemon || true; ui_ok "✓ Step 3 complete."; }
  else ui_warn "'openclaw' not in PATH yet. Run 'openclaw onboard --install-daemon' later."; fi
}
install_openclaw() {
  CB_ITEMS=("[Step 0] Install OpenClaw .deb into ${DISTROBOX_CONTAINER} distrobox" "[Step 1] Add ${OPENCLAW_BIN_DIR/#$HOME/\~} to PATH" "[Step 2] Run ${OPENCLAW_INSTALL_URL#https://} on Host" "[Step 3] Run openclaw onboard --install-daemon")
  CB_SELECTED=(1 1 1 1)
  _run_checkbox_fns "Install OpenClaw Sequence (Steps 0 - 3)" "Target: Host CLI + ${DISTROBOX_CONTAINER} Distrobox" \
    "Run Selected Steps" "Back to Main Menu" "$C_INDIGO" "Executing OpenClaw Installation" "✓ OpenClaw sequence finished." \
    install_openclaw_deb_distrobox install_openclaw_path_config install_openclaw_cli_host install_openclaw_onboard_daemon
}

download_devpod_cli() {
  local arch idir="$LOCAL_BIN_DIR" df url="" tmp
  case "$(uname -m)" in x86_64) arch="amd64" ;; aarch64|arm64) arch="arm64" ;; *) ui_err "Unsupported arch: $(uname -m)"; return 1 ;; esac
  mkdir -p "$idir"; df="$idir/devpod"
  url="$(_fetch_release_assets "https://api.github.com/repos/loft-sh/devpod/releases/latest" "devpod-linux-${arch}$" "" 1 | cut -f2 || true)"
  url="${url:-https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-${arch}}"
  tmp="$(mktemp -t devpod-dl-XXXXXX)"; ui_banner "Install DevPod CLI" "$C_MINT"
  if curl -fsSL -L "$url" -o "$tmp"; then
    if file "$tmp" | grep -qi "gzip compressed"; then tar -xzf "$tmp" -C "$idir" devpod 2>/dev/null || tar -xzf "$tmp" -C "$idir"
    elif file "$tmp" | grep -qi "tar archive"; then tar -xf "$tmp" -C "$idir" devpod 2>/dev/null || tar -xf "$tmp" -C "$idir"
    else cp -f "$tmp" "$df"; fi
    rm -f "$tmp"; chmod +x "$df"; ui_ok "✓ DevPod installed to $df"
    [[ ":$PATH:" != *":$LOCAL_BIN_DIR:"* ]] && export PATH="$LOCAL_BIN_DIR:$PATH"
    "$df" version 2>/dev/null || true
  else rm -f "$tmp"; ui_err "✗ Failed to download DevPod"; return 1; fi
}

fetch_appimage_url() {
  local out
  case "$1" in
    github) out="$(_fetch_release_assets "https://api.github.com/repos/$2/releases/latest" "$3" "" 1 || true)"; [ -n "$out" ] && echo "${out#*$'\t'}" ;;
    gh_tag) out="$(_fetch_release_assets "https://api.github.com/repos/$2/releases/tags/$3" 'appimageupdatetool.*x86_64\.AppImage$' "" 1 || true)"; [ -n "$out" ] && echo "${out#*$'\t'}" || echo "https://github.com/AppImageCommunity/AppImageUpdate/releases/download/continuous/appimageupdatetool-x86_64.AppImage" ;;
    eden) out="$(_fetch_release_assets "https://git.eden-emu.dev/api/v1/repos/eden-emu/eden/releases/latest" 'Eden-Linux-.*amd64-clang-pgo\.AppImage$' "" 1 || true)"; [ -n "$out" ] && echo "${out#*$'\t'}" ;;
    redirect) curl -sI "$2" | awk 'tolower($1)=="location:"{print $2}' | tr -d '\r' ;;
    unsloth) curl -fsSL -A "Mozilla/5.0" -m 12 "https://github.com/unslothai/unsloth/releases/latest/download/latest.json" 2>/dev/null | python3 -c "import json,sys;print(json.load(sys.stdin)['platforms']['linux-x86_64']['url'])" 2>/dev/null || echo "https://github.com/unslothai/unsloth/releases/latest/download/Unsloth-Desktop-Linux.AppImage" ;;
  esac
}

declare -A _AI_SPECS=(
  [updatetool]="AppImageUpdate Tool|appimageupdatetool.AppImage|gh_tag|AppImageCommunity/AppImageUpdate|continuous"
  [bionic]="Bionic (LM Studio Agent)|bionic.appimage|redirect|https://lmstudio.ai/download/bionic/latest/linux/x64|"
  [darktable]="Darktable|darktable.appimage|github|darktable-org/darktable|Darktable-.*x86_64\.AppImage$"
  [eden]="Eden Nintendo Switch Emulator|eden.appimage|eden||"
  [jan]="Jan AI Desktop|jan.appimage|github|janhq/jan|Jan_.*amd64\.AppImage$"
  [lmms]="LMMS Digital Audio Workstation|lmms.appimage|github|LMMS/lmms|lmms-.*linux-x86_64\.AppImage$"
  [musescore]="MuseScore Studio|musescore_studio.appimage|github|musescore/MuseScore|MuseScore-Studio-.*x86_64\.AppImage$"
  [qtscrcpy]="QtScrcpy (Android Display & Control)|qtscrcpy.appimage|github|barry-ran/QtScrcpy|QtScrcpy-ubuntu-x64-.*\.AppImage$"
  [unsloth]="Unsloth AI Studio|unsloth.appimage|unsloth||"
)

_install_appimage_key() {
  local nm fn md a1 a2 u adir="$APPIMAGES_DIR" tp
  IFS='|' read -r nm fn md a1 a2 <<< "${_AI_SPECS[$1]}"
  u="$(ui_spin_fn "Resolving latest ${fn}..." fetch_appimage_url "$md" "$a1" "$a2")"
  mkdir -p "$adir"; [ -z "$u" ] || [ "$u" = "None" ] && { ui_err "[!] Could not resolve URL for $nm."; return 1; }
  tp="$adir/$fn"; ui_info "[*] Downloading ${nm}..."
  ui_info_table "AppImage Asset,Value" "Application,$nm" "Source URL,$u" "Destination,$tp"
  _dl_file "$u" "$tp" "$nm" && chmod +x "$tp" && ui_ok "[+] Installed: $tp"
}

appimage_hub_menu() {
  local hub=(
    "AppImageUpdate Tool (Official Updater CLI)|_install_appimage_key updatetool"
    "Bionic (LM Studio Agent)|_install_appimage_key bionic"
    "Darktable (Photography & RAW Developer)|_install_appimage_key darktable"
    "DeepSeek Harness Desktop (Distrobox .deb)|install_deepseek_harness_desktop"
    "DeepSeek Harness Web (Pixi env & dsh web)|setup_deepseek_harness"
    "DevPod CLI (loft-sh/devpod -> ${LOCAL_BIN_DIR/#$HOME/\~})|download_devpod_cli"
    "Eden (Nintendo Switch Emulator)|_install_appimage_key eden"
    "Jan (Open-source ChatGPT Alternative)|_install_appimage_key jan"
    "KoboldCpp (Standalone llama.cpp & UI)|install_koboldcpp"
    "LMMS (Music Production Suite)|_install_appimage_key lmms"
    "LocalAI (Multi-model AI runtime)|install_localai"
    "MuseScore Studio (Music Notation)|_install_appimage_key musescore"
    "OpenClaw (CLI, Gateway & Distrobox .deb)|install_openclaw"
    "llama-dory (Nemotron-Dory llama.cpp build)|install_llama_dory"
    "llama-prism (Prism llama.cpp binaries)|install_prism_llamacpp"
    "QtScrcpy (Android Screen Mirror & Control)|_install_appimage_key qtscrcpy"
    "Unsloth (Fast LLM Finetuning & Studio)|_install_appimage_key unsloth"
  )
  local sel=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0) rc i
  while true; do
    CB_ITEMS=(); for i in "${!hub[@]}"; do CB_ITEMS+=("${hub[i]%%|*}"); done; CB_SELECTED=("${sel[@]}")
    checkbox_menu_select "AppImage Hub & Local AI Engines" "Target: $APPIMAGES_DIR\nCatalog: 17 Local AI Runtimes; Creative Suites & Portable Apps" \
      "Download Selected AppImages & AI Tools" "Back to Main Menu" "$C_MINT" "Compact & Configure Portable AppImages…"
    rc=$?; sel=("${CB_SELECTED[@]}"); [ "$rc" -eq 1 ] && return 0; [ "$rc" -eq 2 ] && { run_appimage_compact; continue; }
    for i in "${!hub[@]}"; do [ "${sel[i]}" -eq 1 ] && ${hub[i]#*|}; done
    ui_ok "[+] Selected installations complete!"; ui_pause "Press Enter to continue..."
  done
}

run_appimage_compact() {
  local adir="$APPIMAGES_DIR" i count=0 app fname
  [ -d "$adir" ] || { ui_warn "• $adir does not exist."; return 0; }
  shopt -s nullglob nocaseglob; local imgs=("$adir"/*.appimage); shopt -u nullglob nocaseglob
  [ "${#imgs[@]}" -eq 0 ] && { ui_warn "• No .AppImage files in $adir."; return 0; }
  CB_ITEMS=(); CB_SELECTED=(); for i in "${!imgs[@]}"; do CB_ITEMS[i]="$(basename "${imgs[i]}")"; CB_SELECTED[i]=0; done
  checkbox_menu_select "Compact & Configure Portable AppImages" "Directory: $adir\nOperations: Auto-update + .config & .home folders" "Configure Selected AppImages" "Back to Menu" "$C_MINT" || return 0
  for i in "${!imgs[@]}"; do
    [ "${CB_SELECTED[i]}" -eq 1 ] || continue
    app="${imgs[i]}"; fname="$(basename "$app")"; ui_info "[*] Processing $fname..."
    chmod +x "$app" 2>/dev/null || true
    [ -x "$adir/appimageupdatetool.AppImage" ] && [ "$fname" != "appimageupdatetool.AppImage" ] && (cd "$adir" && ./appimageupdatetool.AppImage "$fname" 2>/dev/null || true)
    (cd "$adir" && ./"$fname" --appimage-portable-config 2>/dev/null || true; ./"$fname" --appimage-portable-home 2>/dev/null || true)
    count=$((count + 1))
  done
  ui_ok "✓ Processed $count AppImage(s)."; ui_pause "Press Enter to return..."
}

# ujust, udev & Core Onboarding
run_ujust() {
  if ! _has just || { ! _has ujust && [ ! -x "$UJUST_BIN" ]; }; then
    prompt_run_playbook_subtask "ujust" "ujust" "Configure just/ujust task runner" || return 1
    _has just && { _has ujust || [ -x "$UJUST_BIN" ]; } || { ui_err "'just' or 'ujust' still missing."; return 1; }
  fi
  local uj; uj="$(command -v ujust 2>/dev/null || echo "$UJUST_BIN")"
  local items=("1\t🎯 Choose Recipe Interactively…\tujust --choose" "2\t📋 List All Recipes\tDisplay system and user ujust tasks" "3\t✨ Configure Terminal Bling…\tRun ublue-bling" "4\t⌨️  Run Custom Recipe…\tEnter recipe name and args" "0\t🚪 Back to Main Menu\tReturn")
  while true; do
    ui_tty && ui_banner "ujust / Universal Blue Task Runner" "$C_INDIGO"
    case "$(gum_action_menu "ujust Task Runner" "ujust" "${items[@]}")" in
      1) "$uj" --choose ;; 2) "$uj" ;;
      3) _has ublue-bling || [ -x "$UBLUE_BLING_BIN" ] && "$(command -v ublue-bling 2>/dev/null || echo "$UBLUE_BLING_BIN")" || ui_warn "ublue-bling not found." ;;
      4) ask_input "Enter ujust recipe and args: " rargs; [ -n "$rargs" ] && "$uj" $rargs ;;
      *) return 0 ;;
    esac
    echo ""; ui_pause "Press Enter to continue..."
  done
}

configure_udev_rules() {
  ui_banner "Configure Gamepad, Joystick & VR udev Rules" "$C_BLUE"
  local udir="$REPO_ROOT/files/udev"
  [ -d "$udir" ] || { prompt_run_playbook_subtask "udev rules" "udev" "Deploy gamepad, joystick & VR udev rules" || return 1; [ -d "$udir" ] || { ui_err "udev directory not found: $udir"; return 1; }; }
  local rules=("$udir"/*.rules) r
  [ -e "${rules[0]}" ] || { ui_err "No udev rules found in $udir"; return 1; }
  require_sudo "install udev rules" || return 1
  sudo mkdir -p "$UDEV_RULES_DEST"
  for r in "${rules[@]}"; do sudo install -m 0644 "$r" "$UDEV_RULES_DEST/$(basename "$r")"; echo -e "  $(ui_c "green" "✓") $(basename "$r")"; done
  _has udevadm && { sudo udevadm control --reload-rules && sudo udevadm trigger; ui_ok "✓ udev rules reloaded!"; } || ui_warn "'udevadm' not found."
}

_run_all_wd_mw() { _has waydroid && { waydroid prop set persist.waydroid.multi_windows true; ui_ok "[+] multi_windows enabled."; } || ui_warn "[!] waydroid not installed."; }

run_all() {
  CB_ITEMS=("Homebrew Environment & PATH" "Pixi Package Manager" "Starship Prompt" "TLDR Cache & Terminal Utilities" "Ubuntu Distrobox Container" "User Flatpak Remotes (Flathub & Fedora OCI)" "Gamepad, Joystick & VR udev Rules" "Bazzite Waydroid Files & Polkit" "Waydroid Multi-Window Mode" "Waydroid Subsystem Setup" "PipeWire Multi-User Audio Redirection")
  CB_SELECTED=(1 1 1 1 1 1 1 1 1 0 0)
  local steps=(
    "configure_homebrew" "install_pixi" "install_starship || true" "update_terminal_utilities" "setup_distrobox"
    "configure_flathub_user; configure_fedora_flatpak_user" "configure_udev_rules"
    "apply_bazzite_waydroid_config 2>/dev/null || true" "_run_all_wd_mw"
    "fedora_waydroid_setup_wizard" "configure_pipewire_streaming"
  ) i
  if [ ! -t 0 ]; then
    ui_info "=== Running Non-Interactive Onboarding ==="
    for i in {0..8}; do eval "${steps[i]}" || true; done
    ui_ok "All non-interactive onboarding steps completed!"; return 0
  fi
  checkbox_menu_select "Core User Onboarding Sequence" "Target User: $U\nWorkflow: Sequential execution of selected stages" "Run Selected Onboarding Steps" "Back to Main Menu" "$C_CYAN" || return 0
  for i in "${!steps[@]}"; do [ "${CB_SELECTED[i]}" -eq 1 ] && eval "${steps[i]}"; done
  ui_ok "Selected onboarding steps completed!"; ui_pause "Press Enter to continue..."
}

sync_packages_and_yamls() {
  local sync_script="$REPO_ROOT/Scripts/sync_packages.py"
  [ -f "$sync_script" ] || { ui_err "Sync script not found at: $sync_script"; return 1; }
  _need python3 "Install python3 to sync package lists." || return 1
  ui_banner "Sync packages.sh & Ansible YAMLs" "$C_CYAN"
  if [ $# -gt 0 ]; then
    python3 "$sync_script" "$@"
    return $?
  fi
  local report rc=0
  report="$(python3 "$sync_script" --dry-run)" || rc=$?
  [ "$rc" -ne 0 ] && { ui_err "Failed to inspect installed packages."; return "$rc"; }
  printf '%s\n' "$report"
  if printf '%s\n' "$report" | grep -q "No additions or removals detected\."; then
    ui_ok "✓ All package files are already up to date."
    return 0
  fi
  ui_confirm "Apply these additions and removals to packages.sh and YAML files?" "N" || { ui_warn "Aborted. No files were modified."; return 0; }
  python3 "$sync_script" --yes && ui_ok "✓ Updated packages.sh and YAML files."
}

# Help, CLI Flag Dispatch & Main Menu
show_help() {
  local text; text="$(cat <<EOF
Usage: launcher.sh [FLAG]
  --playbook                      Dynamic Ansible Playbook, Role & Task Runner
  --playbook-all                  Run entire Ansible playbook (--ask-become-pass)
  --all                           Core User Onboarding Sequence
  --ujust                         ujust / Universal Blue Task Runner
  --brew | --pixi | --starship    Homebrew / Pixi / Starship Prompt
  --terminal                      Refresh Terminal Caches (tldr, bat, git-lfs, fonts, man)
  --distrobox                     Create Ubuntu Distrobox Container
  --flatpaks, --flatpak-remotes   Configure User Flatpak Remotes
  --flathub | --fedora-flatpak    Add Flathub / Fedora OCI User Remote
  --appimages, --appimage-hub     AppImage Hub & Local AI Engines
  --compact | --updatetool        Compact AppImages / AppImageUpdate Tool
  --bionic | --darktable | --eden | --jan | --lmms | --musescore | --qtscrcpy | --unsloth
  --dsh-desktop, --dsh-deb        DeepSeek Harness Desktop (.deb) in Distrobox
  --deepseek, --dsh | --devpod    DeepSeek Harness Web / DevPod CLI
  --koboldcpp | --localai         KoboldCpp / LocalAI
  --kobold-launch                 Launch KoboldCpp with a .kcpps prompt config
  --scripts                       Pick and run a script from ${CUSTOM_SCRIPTS_DIR/#$HOME/\~}
  --sync-packages, --update-packages  Sync packages.sh & Snap/Flatpak YAMLs (shows additions/removals)
  --openclaw | --dory | --prism   OpenClaw / llama-dory / Prism llama.cpp
  --waydroid | --waydroid-fix     Waydroid Wizard / Troubleshooting
  --vm, --vms, --virtualization   Virtualization & VM Management
  --libvirt | --libvirt-net       Libvirt Helpers / Start Default Network
  --virt-builder-list | --virt-builder   List / Build virt-builder VMs
  --vagrant | --udev | --pipewire Vagrant / udev Rules / PipeWire Audio
  --cleanup | --superposition     System Cleanup / Unigine Superposition
  -h, --help                      Show this help message
EOF
)"
  ui_tty && { { gum format --type markdown -- "# Fedora Workstation Launcher" "Pass one flag, or run without flags for the interactive menu:"; echo; printf '%s\n' "$text"; } | gum pager --soft-wrap; } || printf '%s\n' "$text"
}

if [ $# -gt 0 ]; then
  case "$1" in
    --playbook) run_playbook_menu ;; --playbook-all) _run_ansible ;; --all) run_all ;; --ujust) run_ujust ;; --brew) configure_homebrew ;;
    --pixi) install_pixi ;; --starship) install_starship ;; --terminal) update_terminal_utilities ;; --distrobox) setup_distrobox ;;
    --flathub) configure_flathub_user ;; --fedora-flatpak) configure_fedora_flatpak_user ;;
    --flatpaks|--flatpak-remotes) configure_flatpak_remotes_user ;; --pipewire) configure_pipewire_streaming ;;
    --waydroid) fedora_waydroid_setup_wizard ;; --waydroid-troubleshoot|--waydroid-fix) waydroid_troubleshooting_menu ;;
    --cleanup) cleanup_system ;; --superposition|--unigine) install_unigine_superposition ;;
    --vm|--vms|--virtualization) manage_virtualization ;; --libvirt) configure_libvirt ;;
    --libvirt-net|--net-default) start_default_libvirt_network ;; --virt-builder-list|--templates) list_virt_builder_templates ;;
    --virt-builder|--build-vm) build_virt_builder_vm ;; --vagrant) configure_vagrant ;;
    --appimages|--appimage-hub) appimage_hub_menu ;; --compact) run_appimage_compact ;;
    --updatetool|--bionic|--darktable|--eden|--jan|--lmms|--musescore|--qtscrcpy|--unsloth) _install_appimage_key "${1#--}" ;;
    --dsh-desktop|--dsh-deb) install_deepseek_harness_desktop ;; --deepseek|--dsh) setup_deepseek_harness ;;
    --dory|--llama-dory) install_llama_dory ;; --prism|--llamacpp) install_prism_llamacpp ;;
    --koboldcpp|--kobold) install_koboldcpp ;; --kobold-launch) launch_koboldcpp ;; --scripts) run_custom_scripts ;; --localai|--local-ai) install_localai ;;
    --openclaw) install_openclaw ;; --devpod) download_devpod_cli ;; --udev|--udev-rules) configure_udev_rules ;;
    --sync-packages|--update-packages) shift; sync_packages_and_yamls "$@" ;;
    -h|--help) show_help ;; *) ui_err "Unknown flag: $1" >&2; show_help >&2; exit 1 ;;
  esac
  exit $?
fi

main_menu_entries=(
  "1\t🚀 Run Core User Onboarding…\tHomebrew, Pixi, Distrobox, Flatpaks, udev rules, and Waydroid"
  "2\t📖 Ansible Playbook, Roles & Tasks…\tBrowse roles & individual tasks, run, step, or dry-run"
  "3\t⚡ Open ujust Task Runner…\tBrowse ujust recipes and terminal bling"
  "4\t🍺 Configure Homebrew & PATH\tSet up Linuxbrew environment and shell profiles"
  "5\t📦 Install Pixi Package Manager\tInstall or update Pixi (pixi.sh)"
  "6\t🔄 Refresh Terminal Caches\tUpdate tldr, bat cache, git-lfs, fc-cache, and mandb"
  "7\t🐧 Set Up Ubuntu Distrobox…\tCreate Ubuntu toolbox container and export UniGetUI"
  "8\t🧩 Configure User Flatpak Remotes…\tEnable Flathub and Fedora OCI user remotes"
  "9\t🤖 Open AppImage & Local AI Hub…\tDownload and manage 17 local AI engines and apps"
  "10\t🗜️  Compact Portable AppImages…\tConfigure portable config/home folders and auto-updaters"
  "11\t📱 Open Waydroid Setup Wizard…\tAndroid container with libndk, Widevine, GAPPS, and multi-window"
  "12\t🖥️  Manage Virtualization & VMs…\tLibvirt networks, virt-builder, XML domains, and Vagrant"
  "13\t🎮 Install Gamepad & VR udev Rules\tDeploy hardware input rules to ${UDEV_RULES_DEST}"
  "14\t🔊 Configure PipeWire Audio Routing…\tMulti-user TCP network audio streaming"
  "15\t🧹 Run System Cleanup & Benchmarks…\tPrune containers/snaps and run disk/GPU benchmarks"
  "16\t✨ Install Starship Prompt\tInstall Starship cross-shell prompt binary if missing"
  "17\t🧠 Launch KoboldCpp (Prompts)…\tRun ${KOBOLDCPP_BIN##*/} with a .kcpps config"
  "18\t📜 Run Custom Scripts…\tPick and run scripts from ${CUSTOM_SCRIPTS_DIR/#$HOME/\~}"
  "19\t🔄 Sync packages.sh & YAMLs…\tUpdate DNF, Snap (confined/classic), and Flatpak (system/user) lists"
  "0\t🚪 Quit Launcher\tExit Fedora Workstation Control Center"
)
main_fns=(run_all run_playbook_menu run_ujust configure_homebrew install_pixi update_terminal_utilities setup_distrobox configure_flatpak_remotes_user appimage_hub_menu run_appimage_compact fedora_waydroid_setup_wizard manage_virtualization configure_udev_rules configure_pipewire_streaming cleanup_system install_starship launch_koboldcpp run_custom_scripts sync_packages_and_yamls)

while true; do
  choice=""; ui_tty && { clear; ui_dashboard; }
  choice="$(gum_action_menu "Select an action (type to filter, Enter to launch, Esc to exit)" "Search Action" "${main_menu_entries[@]}")"
  choice="${choice:-0}"
  case "$choice" in
    0|[Qq]|exit) echo; ui_ok "Exiting setup. You can run this script again anytime!"; exit 0 ;;
    [1-9]|1[0-9]) "${main_fns[$((choice - 1))]}" ;;
    *) echo; ui_err "Invalid option: '$choice'. Please enter 0-19." ;;
  esac
  echo ""; ui_pause "Press Enter to return to the menu..."
done
