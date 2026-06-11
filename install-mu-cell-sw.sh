#!/usr/bin/env bash
# install_mucell.sh
# Installs or updates the mu-cell SDR driver suite, then installs bluestation-bs.
# Safe to re-run after a reboot or on an existing install.

set -euo pipefail

REPO_URL="https://github.com/Jankyneering/mu-cell-bb-drivers"
INSTALL_DIR="$HOME/mu-cell-bb-drivers"

BS_API_BLUESTATION="https://api.github.com/repos/MidnightBlueLabs/tetra-bluestation/releases/latest"
BS_API_FLOWSTATION="https://api.github.com/repos/razvanzeces/flowstation/releases/latest"
BS_DEST="$HOME/bluestation-bs"
BS_VERSION_FILE="$HOME/.bluestation_version"

# ─── Color helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ─── 1. System dependencies ───────────────────────────────────────────────────
install_deps() {
    info "Checking system dependencies..."

    PACKAGES=(
        git make g++ cmake
        libsoapysdr-dev soapysdr-tools libasound2-dev python3-soapysdr
        libssl-dev clang llvm-dev libclang-dev
    )

    MISSING=()
    for pkg in "${PACKAGES[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            MISSING+=("$pkg")
        fi
    done

    if [ ${#MISSING[@]} -eq 0 ]; then
        info "All system packages are already installed."
    else
        info "Installing missing packages: ${MISSING[*]}"
        sudo apt update
        sudo apt install -y --no-install-recommends "${MISSING[@]}"
    fi
}

# ─── 2. Clone or update the repo ──────────────────────────────────────────────
# Returns 0 if a build is needed, 1 if already up to date.
clone_or_update_repo() {
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        info "Cloning mu-cell-bb-drivers to $INSTALL_DIR..."
        git clone "$REPO_URL" "$INSTALL_DIR"
        return 0
    fi

    info "Repository already exists. Checking for updates..."
    cd "$INSTALL_DIR"    
	git fetch origin

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/main")

    if [ "$LOCAL" = "$REMOTE" ]; then
        info "Repository is up to date ($(git rev-parse --short HEAD))."
        return 1
    else
        warn "Updates found. Pulling latest changes..."
        git pull --ff-only
        return 0
    fi
}

# ─── 3. Build and install the DTS overlay ─────────────────────────────────────
build_dts() {
    DTS_DIR="$INSTALL_DIR/raspberry-pi-drivers/mu-cell-bb-dts"

    if [ ! -d "$DTS_DIR" ]; then
        error "DTS directory not found: $DTS_DIR"
        error "Check that submodules were initialised correctly."
        exit 1
    fi

    info "Building DTS overlay..."
    cd "$DTS_DIR"
    make overlay
    sudo make install
}

# ─── 4. Build and install SoapyMuCell ─────────────────────────────────────────
build_soapy() {
    SOAPY_DIR="$INSTALL_DIR/SoapyMuCell"

    if [ ! -d "$SOAPY_DIR" ]; then
        error "SoapyMuCell directory not found: $SOAPY_DIR"
        error "Check that submodules were initialised correctly."
        exit 1
    fi

    info "Building SoapyMuCell..."
    cd "$SOAPY_DIR"
    mkdir -p build
    cd build
    cmake ..
    make
    sudo make install
    sudo ldconfig
}

# ─── 5. Probe the driver ──────────────────────────────────────────────────────
probe_driver() {
    info "Probing mu-cell driver..."

    if SoapySDRUtil --probe=driver=mucell 2>&1; then
        info "Driver probe succeeded."
    else
        warn "Driver probe returned a non-zero exit code."
        warn "If this is right after install, a reboot may be required."
        warn "Re-run this script after rebooting to verify."
    fi
}

# ─── 6. Detect Pi model ───────────────────────────────────────────────────────
detect_pi_model() {
    # /proc/device-tree/model is the most reliable source on Pi OS
    if [ -f /proc/device-tree/model ]; then
        PI_MODEL=$(tr -d '\0' < /proc/device-tree/model)
    else
        PI_MODEL=""
    fi

    if echo "$PI_MODEL" | grep -qi "raspberry pi 5"; then
        echo "rpi5"
    else
        # Pi 3, 4, Zero 2, etc. all use the rpi4 binary
        echo "rpi4"
    fi
}

# ─── 7. Install or update bluestation-bs ──────────────────────────────────────
# $1 = "bluestation" or "flowstation"
install_binary() {
    local variant="$1"

    if [ "$variant" = "flowstation" ]; then
        local api_url="$BS_API_FLOWSTATION"
        local keyword="bluestation-bs"   # flowstation uses same binary name
    else
        local api_url="$BS_API_BLUESTATION"
        local pi_model
        pi_model=$(detect_pi_model)
        local keyword="bluestation-bs-$pi_model"
        info "Detected platform: $pi_model"
    fi

    info "Fetching latest release info from GitHub..."
    local release_json
    release_json=$(curl -fsSL "$api_url")

    local remote_tag
    remote_tag=$(echo "$release_json" | grep '"tag_name"' | head -1 | cut -d'"' -f4)

    if [ -z "$remote_tag" ]; then
        error "Could not fetch release info from $api_url"
        error "Check your network connection or GitHub API rate limits (60 req/hr unauthenticated)."
        exit 1
    fi

    # Check stored version
    local stored_tag=""
    local stored_variant=""
    if [ -f "$BS_VERSION_FILE" ]; then
        stored_tag=$(grep "^tag=" "$BS_VERSION_FILE" | cut -d'=' -f2)
        stored_variant=$(grep "^variant=" "$BS_VERSION_FILE" | cut -d'=' -f2)
    fi

    if [ "$remote_tag" = "$stored_tag" ] && [ "$variant" = "$stored_variant" ] && [ -f "$BS_DEST" ]; then
        info "bluestation-bs is already up to date ($stored_tag, $stored_variant)."
        return
    fi

    # Find the right asset URL
    local asset_url
    asset_url=$(echo "$release_json" \
        | grep '"browser_download_url"' \
        | grep "$keyword" \
        | head -1 \
        | cut -d'"' -f4)

    if [ -z "$asset_url" ]; then
        error "Could not find an asset matching '$keyword' in release $remote_tag."
        error "Available assets:"
        echo "$release_json" | grep '"browser_download_url"' | cut -d'"' -f4 >&2
        exit 1
    fi

    info "Downloading $remote_tag ($variant) from:"
    info "  $asset_url"
    curl -fsSL -o "$BS_DEST" "$asset_url"
    chmod +x "$BS_DEST"

    # Save installed version
    cat > "$BS_VERSION_FILE" <<EOF
tag=$remote_tag
variant=$variant
EOF

    info "bluestation-bs installed to $BS_DEST ($remote_tag)"
	echo "Don't forget to generate your config.toml with the settings of your cell!" >&2
	echo "You can create it on https://bluestation.russel053.com/ , then import the config file" >&2
}

# ─── 8. Ask which variant to install ──────────────────────────────────────────
choose_variant() {
    # Print menu to stderr so it isn't swallowed by $() command substitution
    echo "" >&2
    echo "Which software would you like to install?" >&2
    echo "  1) bluestation (stable, fewer features) [default]" >&2
    echo "  2) flowstation (less stable, more features)" >&2
    echo "" >&2
    read -r -p "Choice [1]: " CHOICE </dev/tty
    CHOICE="${CHOICE:-1}"

    case "$CHOICE" in
        2) echo "flowstation" ;;
        *) echo "bluestation" ;;
    esac
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    install_deps

    NEEDS_BUILD=false
    if clone_or_update_repo; then
        NEEDS_BUILD=true
    fi

    if $NEEDS_BUILD; then
        build_dts
        build_soapy
        info "Build complete."
        warn "A reboot is recommended to load the new DTS overlay."
        read -r -p "Reboot now? [y/N] " REPLY
        if [[ "${REPLY,,}" == "y" ]]; then
            sudo reboot
			exit 0
        else
            info "Skipping reboot. Re-run this script after rebooting to verify the driver."
            exit 0
        fi
    else
        probe_driver
    fi

    VARIANT=$(choose_variant)
    install_binary "$VARIANT"
}

main "$@"