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
initexmf \
  --user-config=$MIKTEX_USER_DIR/config \
  --user-data=$MIKTEX_USER_DIR/data \
  --user-install=$MIKTEX_USER_DIR/install
initexmf --admin --set-config-value [MPM]AutoInstall=1
initexmf --set-config-value [MPM]AutoInstall=1
initexmf --admin --set-config-value [Core]InstallDocFiles=0
initexmf --set-config-value [Core]InstallDocFiles=0
initexmf --admin --set-config-value [Core]InstallSourceFiles=0
initexmf --set-config-value [Core]InstallSourceFiles=0
miktex --admin packages update-package-database
miktex --admin packages update
miktex packages update-package-database
miktex packages update
initexmf --update-fndb
initexmf --admin --mklinks

# Clear MiKTeX caches
rm -rf \
  "$MIKTEX_USER_DIR"/data/miktex/cache \
  "$MIKTEX_BASE_DIR"/texmfs/*/miktex/cache


echo "MiKTeX installation and configuration complete!"