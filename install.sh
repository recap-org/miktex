#!/bin/bash
# Install MiKTeX (RECAP build) on Linux.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/recap-org/miktex/dev/install.sh | bash
#   curl -fsSL <url> | bash -s -- --version 26.2
#   ./install.sh --from ./miktex          # local mode (CI)
#
# Run as a regular user with sudo privileges.
set -euo pipefail

REPO="recap-org/miktex"
INSTALL_DIR="/usr/local/miktex"
USER_DIR=""
VERSION=""
FROM_DIR=""

usage() {
	cat <<-EOF
	Usage: $0 [OPTIONS]
	Options:
	  --version VER   MiKTeX version to install (default: latest release)
	  --from DIR      Install from a local directory instead of downloading
	  --to DIR        Installation directory (default: /usr/local/miktex)
	  --user-dir DIR  MiKTeX user data directory (default: ~/.miktex)
	  -h, --help      Show this help message
	EOF
	exit 0
}

while [[ $# -gt 0 ]]; do
	case $1 in
		--version)  VERSION="$2";     shift 2 ;;
		--from)     FROM_DIR="$2";    shift 2 ;;
		--to)       INSTALL_DIR="$2"; shift 2 ;;
		--user-dir) USER_DIR="$2";    shift 2 ;;
		-h|--help)  usage ;;
		*) echo "Unknown option: $1"; exit 1 ;;
	esac
done

USER_DIR="${USER_DIR:-$HOME/.miktex}"
ARCH=$(uname -m)

# Use sudo if available; skip if already root
if command -v sudo &>/dev/null; then
	SUDO=sudo
elif [[ $(id -u) -eq 0 ]]; then
	SUDO=""
else
	echo "Error: sudo is required when not running as root" >&2
	exit 1
fi

# ── Obtain MiKTeX files ─────────────────────────────────────────────

if [[ -n "$FROM_DIR" ]]; then
	# Local mode: install from an existing directory
	if [[ ! -d "$FROM_DIR" ]]; then
		echo "Error: source directory $FROM_DIR does not exist" >&2
		exit 1
	fi
	SOURCE_DIR="$FROM_DIR"
	CLEANUP=""
else
	# Download mode: fetch tarball from GitHub releases
	if [[ -z "$VERSION" ]]; then
		VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
			| grep '"tag_name"' | head -1 | cut -d'"' -f4)
		if [[ -z "$VERSION" ]]; then
			echo "Error: could not determine latest release" >&2
			exit 1
		fi
	fi

	TARBALL="miktex-${VERSION}-linux-${ARCH}.tar.xz"
	URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"

	TMPDIR=$(mktemp -d)
	CLEANUP="$TMPDIR"
	trap 'rm -rf "$CLEANUP"' EXIT

	echo "Downloading MiKTeX ${VERSION} for ${ARCH}..."
	curl -fSL "$URL" -o "${TMPDIR}/${TARBALL}"
	tar -xJf "${TMPDIR}/${TARBALL}" -C "$TMPDIR"
	SOURCE_DIR=$(find "$TMPDIR" -maxdepth 2 -type d -name miktex | head -1)
	if [[ -z "$SOURCE_DIR" ]]; then
		echo "Error: could not find miktex directory in tarball" >&2
		exit 1
	fi
fi

# ── Install binaries ────────────────────────────────────────────────

echo "Installing MiKTeX to ${INSTALL_DIR}..."
$SUDO mkdir -p "$INSTALL_DIR"
$SUDO cp -r "$SOURCE_DIR/"* "$INSTALL_DIR/"

export PATH="${INSTALL_DIR}/bin:$PATH"
INITEXMF="${INSTALL_DIR}/bin/initexmf"
MIKTEX="${INSTALL_DIR}/bin/miktex"
MPM="${INSTALL_DIR}/bin/mpm"

# ── Configure ────────────────────────────────────────────────────────

echo "Configuring MiKTeX..."
mkdir -p "$USER_DIR"/{config,data,install}
"$INITEXMF" \
	--user-config="$USER_DIR/config" \
	--user-data="$USER_DIR/data" \
	--user-install="$USER_DIR/install"

# Admin + user settings
$SUDO "$INITEXMF" --admin --set-config-value '[MPM]AutoInstall=1'
"$INITEXMF" --set-config-value '[MPM]AutoInstall=1'
$SUDO "$INITEXMF" --admin --set-config-value '[Core]InstallDocFiles=0'
"$INITEXMF" --set-config-value '[Core]InstallDocFiles=0'
$SUDO "$INITEXMF" --admin --set-config-value '[Core]InstallSourceFiles=0'
"$INITEXMF" --set-config-value '[Core]InstallSourceFiles=0'

# Update package database
$SUDO "$MIKTEX" --admin packages update-package-database
$SUDO "$MIKTEX" --admin packages update
"$MIKTEX" packages update-package-database
"$MIKTEX" packages update

# Install base packages
"$INITEXMF" --update-fndb
"$MPM" --verbose --package-level=basic --upgrade
for pkg in etex lua-uni-algos xkeyval latexmk; do
	"$MPM" --install "$pkg" 2>/dev/null || true
done
"$INITEXMF" --update-fndb

# Symlink utf8.def workaround
UTF8_DEF=$(find "$USER_DIR" -path "*/tex/latex/base/utf8.def" 2>/dev/null | head -1)
if [[ -n "$UTF8_DEF" ]]; then
	ln -sf utf8.def "$(dirname "$UTF8_DEF")/utf-8.def"
fi

# Create engine symlinks in PATH
$SUDO "$INITEXMF" --admin --mklinks

# ── Cleanup caches ───────────────────────────────────────────────────

rm -rf "$USER_DIR"/data/miktex/cache
$SUDO rm -rf "$INSTALL_DIR"/texmfs/*/miktex/cache

echo "MiKTeX installation complete!"
