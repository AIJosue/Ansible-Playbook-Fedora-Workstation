#!/bin/bash
set -e

DEST_DIR="$HOME/AppImages"
mkdir -p "$DEST_DIR"

echo "Downloading AppImages to $DEST_DIR..."

get_latest_gh_release_url() {
    curl -s "https://api.github.com/repos/$1/releases/latest" | grep "browser_download_url" | grep -iE "$2" | grep -v "\.sig" | grep -v "\.zsync" | head -n 1 | cut -d '"' -f 4
}

download_if_not_exists() {
    local url="$1"
    local name="$2"
    if [ -z "$url" ]; then
        echo "Failed to get URL for $name"
        return
    fi
    local dest="$DEST_DIR/$name"
    # If a file already exists with that exact name, skip. 
    # For versioned names, if we want to keep latest, we might just wget it.
    echo "Downloading $name..."
    curl -L "$url" -o "$dest"
    chmod +x "$dest"
}

# 1. Cursor
download_if_not_exists "https://downloader.cursor.sh/linux/appImage/x64" "cursor.appimage"

# 2. Darktable
DARK_URL=$(get_latest_gh_release_url "darktable-org/darktable" "x86_64.*\.AppImage")
download_if_not_exists "$DARK_URL" "darktable.appimage"

# 3. Jan
JAN_URL=$(get_latest_gh_release_url "janhq/jan" "amd64\.AppImage")
download_if_not_exists "$JAN_URL" "jan.appimage"

# 4. KoboldCPP
KOBOLD_URL=$(get_latest_gh_release_url "LostRuins/koboldcpp" "linux-x64")
download_if_not_exists "$KOBOLD_URL" "koboldcpp-linux-x64"

# 5. LMMS
LMMS_URL=$(get_latest_gh_release_url "LMMS/lmms" "linux-x86_64\.AppImage")
download_if_not_exists "$LMMS_URL" "lmms.appimage"

# 6. MuseScore
MUSE_URL=$(get_latest_gh_release_url "musescore/MuseScore" "x86_64\.AppImage")
download_if_not_exists "$MUSE_URL" "musescore.appimage"

# 7. QtScrcpy
# Note: they usually release for ubuntu-x64
QT_URL=$(get_latest_gh_release_url "barry-ran/QtScrcpy" "x64.*\.AppImage")
download_if_not_exists "$QT_URL" "qtscrcpy.appimage"

# 8. DevPod
DEVPOD_URL=$(get_latest_gh_release_url "loft-sh/devpod" "amd64\.AppImage")
download_if_not_exists "$DEVPOD_URL" "devpod.appimage"

# 9. LM Studio (Static URL for latest)
LM_URL="https://releases.lmstudio.ai/linux/x86/latest/LM_Studio-linux-x86.AppImage"
download_if_not_exists "$LM_URL" "lmstudio.appimage"

echo "AppImages downloaded."
