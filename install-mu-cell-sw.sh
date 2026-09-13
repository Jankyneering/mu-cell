#!/usr/bin/env bash
# install-mu-cell-sw.sh
#
# Installs or updates the µCell driver suite: the device tree overlay and the
# SoapyMuCell SoapySDR driver, then probes the board.
#
# Radio software (Tetra-Bluestation, Flowstation, MMDVM-IQ, ...) is not
# installed here. Each is its own project, see docs/quickStartGuide.md.
#
# Safe to re-run after a reboot or on an existing install.
#
# Usage: install-mu-cell-sw.sh [--force] [--no-reboot] [--help]

set -euo pipefail

REPO_URL="${MUCELL_REPO_URL:-https://github.com/Jankyneering/mu-cell-bb-drivers}"
INSTALL_DIR="${MUCELL_INSTALL_DIR:-$HOME/mu-cell-bb-drivers}"
OVERLAY_NAME="mu-cell-bb_raspberrypi"
DOCS_URL="https://github.com/Jankyneering/mu-cell/blob/main/docs/quickStartGuide.md"

FORCE_BUILD=false
ALLOW_REBOOT=true

# ─── Color helpers ────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    NC=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

info()  { printf '%s[INFO]%s  %s\n' "$GREEN" "$NC" "$*"; }
warn()  { printf '%s[WARN]%s  %s\n' "$YELLOW" "$NC" "$*"; }
error() { printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$*" >&2; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Installs or updates the µCell device tree overlay and the SoapyMuCell driver.

Options:
  --force       Rebuild and reinstall even if the repository is up to date
  --no-reboot   Never offer to reboot, just print the reminder
  --help        Show this message

Environment:
  MUCELL_REPO_URL      Driver repository URL
  MUCELL_INSTALL_DIR   Clone location (default: \$HOME/mu-cell-bb-drivers)
EOF
}

# ─── 0. Argument parsing and environment checks ───────────────────────────────
parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --force)     FORCE_BUILD=true ;;
            --no-reboot) ALLOW_REBOOT=false ;;
            --help|-h)   usage; exit 0 ;;
            *)           error "Unknown option: $1"; usage >&2; exit 1 ;;
        esac
        shift
    done
}

check_environment() {
    if [ -z "${BASH_VERSION:-}" ]; then
        error "This script must be run with bash."
        exit 1
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
        error "apt-get not found. This script targets Raspberry Pi OS or another Debian derivative."
        error "See $DOCS_URL for the manual build procedure."
        exit 1
    fi

    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
    elif command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        error "sudo not found and not running as root."
        exit 1
    fi
}

# Ask a yes/no question on the controlling terminal. Returns 1 when there is no
# terminal, so the script stays usable when piped into bash.
prompt_yes_no() {
    local prompt="$1" reply=""

    # /dev/tty can exist and still fail to open when there is no controlling
    # terminal, so probe it in a subshell rather than testing with [ -r ].
    ( exec 3</dev/tty ) 2>/dev/null || return 1
    read -r -p "$prompt" reply </dev/tty || return 1

    case "$reply" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *)                 return 1 ;;
    esac
}

# ─── 1. System dependencies ───────────────────────────────────────────────────
install_deps() {
    info "Checking system dependencies..."

    PACKAGES=(
        git make g++ cmake
        libsoapysdr-dev soapysdr-tools libasound2-dev python3-soapysdr
        libssl-dev clang llvm-dev libclang-dev
        device-tree-compiler
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
        $SUDO apt-get update
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends "${MISSING[@]}"
    fi
}

# ─── 2. Clone or update the repo ──────────────────────────────────────────────
# Returns 0 if a build is needed, 1 if already up to date.
clone_or_update_repo() {
    if [ ! -d "$INSTALL_DIR/.git" ]; then
        info "Cloning mu-cell-bb-drivers to $INSTALL_DIR..."
        git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
        return 0
    fi

    info "Repository already exists. Checking for updates..."
    cd "$INSTALL_DIR"

    if ! git fetch origin; then
        error "Could not reach $REPO_URL. Check your network connection."
        exit 1
    fi

    # Work out the remote default branch instead of assuming "main".
    local default_branch
    git remote set-head origin --auto >/dev/null 2>&1 || true
    default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
    default_branch="${default_branch#origin/}"
    [ -n "$default_branch" ] || default_branch="main"

    local local_rev remote_rev current_branch
    local_rev=$(git rev-parse HEAD)
    remote_rev=$(git rev-parse "origin/$default_branch")
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [ "$local_rev" = "$remote_rev" ]; then
        info "Repository is up to date ($(git rev-parse --short HEAD))."
        # Submodules can still be missing or stale after a partial clone.
        git submodule update --init --recursive
        return 1
    fi

    if [ "$current_branch" != "$default_branch" ]; then
        warn "Local checkout is on '$current_branch', not '$default_branch'. Leaving it alone."
        warn "Update it yourself, or delete $INSTALL_DIR and re-run this script."
        return 1
    fi

    warn "Updates found. Pulling latest changes..."
    if ! git pull --ff-only; then
        error "Fast-forward pull failed. You probably have local commits or changes."
        error "Resolve them in $INSTALL_DIR, or delete the directory and re-run this script."
        exit 1
    fi
    git submodule update --init --recursive
    return 0
}

# ─── 3. Build and install the DTS overlay ─────────────────────────────────────
build_dts() {
    local dts_dir="$INSTALL_DIR/raspberry-pi-drivers/mu-cell-bb-dts"

    if [ ! -d "$dts_dir" ]; then
        error "DTS directory not found: $dts_dir"
        error "Check that submodules were initialised correctly."
        exit 1
    fi

    info "Building DTS overlay..."
    ( cd "$dts_dir" && make overlay && $SUDO make install )
}

# ─── 4. Build and install SoapyMuCell ─────────────────────────────────────────
build_soapy() {
    local soapy_dir="$INSTALL_DIR/SoapyMuCell"

    if [ ! -d "$soapy_dir" ]; then
        error "SoapyMuCell directory not found: $soapy_dir"
        error "Check that submodules were initialised correctly."
        exit 1
    fi

    info "Building SoapyMuCell..."
    (
        cd "$soapy_dir"
        mkdir -p build
        cd build
        cmake ..
        make
        $SUDO make install
        $SUDO ldconfig
    )
}

# ─── 5. Installation state checks ─────────────────────────────────────────────
overlay_installed() {
    [ -f "/boot/firmware/overlays/${OVERLAY_NAME}.dtbo" ] \
        || [ -f "/boot/overlays/${OVERLAY_NAME}.dtbo" ]
}

driver_registered() {
    command -v SoapySDRUtil >/dev/null 2>&1 || return 1
    SoapySDRUtil --info 2>/dev/null | grep -qi "mucell"
}

hat_detected() {
    [ -d /proc/device-tree/hat ]
}

# ─── 6. Probe the driver ──────────────────────────────────────────────────────
probe_driver() {
    info "Probing mu-cell driver..."

    if ! command -v SoapySDRUtil >/dev/null 2>&1; then
        error "SoapySDRUtil not found. The soapysdr-tools package is missing."
        return 1
    fi

    if SoapySDRUtil --probe=driver=mucell; then
        info "Driver probe succeeded."
        return 0
    fi

    warn "Driver probe returned a non-zero exit code."
    if ! hat_detected; then
        warn "The Pi does not see a HAT EEPROM (/proc/device-tree/hat is missing)."
        warn "Check that the board is seated on the GPIO header, and that you have"
        warn "rebooted at least once since the overlay was installed."
    else
        warn "If this is right after install, a reboot may be required."
        warn "Re-run this script after rebooting to verify."
    fi
    return 1
}

# ─── 7. Closing notes ─────────────────────────────────────────────────────────
print_next_steps() {
    echo ""
    info "The board is now a standard SoapySDR device. Use the device string:"
    info "  driver=mucell"
    info "Radio software is installed separately from its own project."
    info "See $DOCS_URL for Bluestation, Flowstation, MMDVM-IQ and general SDR software."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    check_environment
    install_deps

    NEEDS_BUILD=false
    if clone_or_update_repo; then
        NEEDS_BUILD=true
    fi

    if [ "$FORCE_BUILD" = true ]; then
        info "Rebuild forced."
        NEEDS_BUILD=true
    elif [ "$NEEDS_BUILD" = false ] && ! overlay_installed; then
        warn "The device tree overlay is not installed. Building anyway."
        NEEDS_BUILD=true
    elif [ "$NEEDS_BUILD" = false ] && ! driver_registered; then
        warn "SoapySDR does not list a mucell factory. Building anyway."
        NEEDS_BUILD=true
    fi

    if [ "$NEEDS_BUILD" = true ]; then
        build_dts
        build_soapy
        info "Build complete."
        warn "A reboot is required to load the device tree overlay."

        if [ "$ALLOW_REBOOT" = true ] && prompt_yes_no "Reboot now? [y/N] "; then
            info "Rebooting. Re-run this script afterwards to verify the driver."
            $SUDO reboot
            exit 0
        fi

        info "Skipping reboot. Re-run this script after rebooting to verify the driver."
        print_next_steps
        exit 0
    fi

    info "Driver and overlay are already installed and up to date."
    probe_driver || true
    print_next_steps
}

main "$@"