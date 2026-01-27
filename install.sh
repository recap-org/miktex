#!/bin/bash
set -e


# Symlink creation flag
CREATE_SYMLINKS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		--from)
			FROM_DIR="$2"
			shift 2
			;;
		--to)
			TO_DIR="$2"
			shift 2
			;;
		--user-dir)
			USER_DIR="$2"
			shift 2
			;;
		--symlink)
			CREATE_SYMLINKS=true
			shift 1
			;;
		-h|--help)
			echo "Usage: $0 [OPTIONS]"
			echo "Options:"
			echo "  --from DIR          MiKTeX source directory to install from (default: ./miktex)"
			echo "  --to DIR            Installation target directory (default: /usr/local/miktex)"
			echo "  --user-dir DIR      MiKTeX user data directory (default: /var/lib/miktex)"
			echo "  -h, --help          Show this help message"
			exit 0
			;;
		*)
			echo "Unknown option: $1"
			echo "Use --help for usage information"
			exit 1
			;;
	esac
done

# Set defaults if not provided via parameters
MIKTEX_SOURCE_DIR=${FROM_DIR:-./miktex}
MIKTEX_BASE_DIR=${TO_DIR:-/usr/local/miktex}
MIKTEX_USER_DIR=${USER_DIR:-/var/lib/miktex}

# Copy MiKTeX installation from source directory
echo "Installing MiKTeX from $MIKTEX_SOURCE_DIR to $MIKTEX_BASE_DIR..."
if [ ! -d "$MIKTEX_SOURCE_DIR" ]; then
	echo "Error: Source directory $MIKTEX_SOURCE_DIR does not exist"
	exit 1
fi
mkdir -p "$MIKTEX_BASE_DIR"
cp -r "$MIKTEX_SOURCE_DIR/"* "$MIKTEX_BASE_DIR/"

mkdir -p $MIKTEX_USER_DIR/{config,data,install}
initexmf \
  --user-config=$MIKTEX_USER_DIR/config \
  --user-data=$MIKTEX_USER_DIR/data \
  --user-install=$MIKTEX_USER_DIR/install
initexmf --admin --set-config-value [MPM]AutoInstall=1
initexmf --set-config-value [MPM]AutoInstall=1
miktex --admin packages update-package-database
miktex --admin packages update
miktex packages update-package-database
miktex packages update
initexmf --update-fndb
mpm --verbose --package-level=basic --upgrade

# Install required packages for luatex/lualatex format creation
echo "Installing required packages for luatex and xetex formats..."
mpm --install etex
mpm --install lua-uni-algos
mpm --install latexmk
initexmf --update-fndb

# Ensure utf-8.def is resolvable (pdfLaTeX expects utf-8.def while base ships utf8.def)
UTF_BASE_DIR=$MIKTEX_USER_DIR/install/tex/latex/base
if [ -d "$UTF_BASE_DIR" ]; then
	if [ ! -e "$UTF_BASE_DIR/utf-8.def" ] && [ -e "$UTF_BASE_DIR/utf8.def" ]; then
		ln -sf utf8.def "$UTF_BASE_DIR/utf-8.def"
		initexmf --update-fndb
	fi
fi

initexmf --admin --mklinks

# Optionally create convenience symlinks in /usr/local/bin for miktex-* binaries
if [ "$CREATE_SYMLINKS" = true ]; then
	echo "Creating symlinks in /usr/local/bin for miktex-* binaries..."
	MIKTEX_BIN_DIR="$MIKTEX_BASE_DIR/bin"
	if [ -d "$MIKTEX_BIN_DIR" ]; then
		for binpath in "$MIKTEX_BIN_DIR"/miktex-*; do
			if [ ! -e "$binpath" ]; then
				continue
			fi
			base=$(basename "$binpath")
			name=${base#miktex-}
			target="/usr/local/bin/$name"
			if [ -e "$target" ]; then
				echo "Skipping $target (already exists)"
				continue
			fi
			ln -s "$binpath" "$target"
			echo "Created symlink: $target -> $binpath"
		done
	else
		echo "Warning: $MIKTEX_BIN_DIR does not exist; no symlinks created"
	fi
fi

echo "MiKTeX installation and configuration complete!"