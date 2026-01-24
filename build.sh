#!/bin/bash
set -e

# Create build directory outside source
mkdir -p build
cd build

# Run CMake with installation prefix
# Using $HOME/miktex so no sudo is required for installation
cmake \
  -DCMAKE_INSTALL_PREFIX="$HOME/miktex" \
  -DWITH_UI_QT=OFF \
  ../

# Build MiKTeX
echo "Building MiKTeX..."
make -j$(nproc)

# Install
echo "Installing MiKTeX..."
make install

echo "Build complete! MiKTeX installed to $HOME/miktex"
echo "Add to PATH with: export PATH=\"\$HOME/miktex/bin:\$PATH\""