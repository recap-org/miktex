#!/bin/bash
set -e

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
miktexsetup finish \
	--shared=yes \
	--user-config=$MIKTEX_USER_DIR/config \
	--user-data=$MIKTEX_USER_DIR/data \
	--user-install=$MIKTEX_USER_DIR/install
initexmf --admin --set-config-value [MPM]AutoInstall=1
miktex --admin packages update-package-database
miktex --admin packages update
miktex packages update-package-database
miktex packages update
initexmf --admin --update-fndb
mpm --admin --verbose --package-level=basic --upgrade

# Install required packages for luatex/lualatex format creation
echo "Installing required packages for luatex and xetex formats..."
mpm --admin --install etex
mpm --admin --install lua-uni-algos
mpm --admin --install latexmk
initexmf --admin --update-fndb

# Ensure utf-8.def is resolvable (pdfLaTeX expects utf-8.def while base ships utf8.def)
UTF_BASE_DIR=$MIKTEX_BASE_DIR/texmfs/install/tex/latex/base
if [ -d "$UTF_BASE_DIR" ]; then
	if [ ! -e "$UTF_BASE_DIR/utf-8.def" ] && [ -e "$UTF_BASE_DIR/utf8.def" ]; then
		ln -sf utf8.def "$UTF_BASE_DIR/utf-8.def"
		initexmf --admin --update-fndb
	fi
fi

echo "MiKTeX installation and configuration complete!"