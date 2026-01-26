#!/bin/bash
set -e

MIKTEX_BASE_DIR=/usr/local/miktex
MIKTEX_USER_DIR=/var/lib/miktex

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