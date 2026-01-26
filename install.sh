#!/bin/bash
set -e

miktexsetup finish --shared=yes
miktex --admin packages update-package-database
miktex --admin packages update
miktex packages update-package-database
miktex packages update
mpm --admin --verbose --package-level=basic --upgrade

# Install required packages for luatex/lualatex format creation
echo "Installing required packages for luatex formats..."
mpm --admin --install etex
mpm --admin --install lua-uni-algos
mpm --admin --install latexmk

# Build formats for luatex, lualatex, and xelatex
echo "Building luatex format..."
miktex --admin formats build luatex

echo "Building lualatex format..."
miktex --admin formats build lualatex

echo "Building xelatex format..."
miktex --admin formats build xelatex