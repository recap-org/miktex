#!/bin/bash
set -e

# Create build directory outside source
rm -rf build
mkdir build
cd build

# Run CMake with installation prefix
# Using $HOME/miktex so no sudo is required for installation
cmake \
  -DCMAKE_INSTALL_PREFIX="$HOME/miktex" \
  -DWITH_UI_QT=OFF \
  ../

# Build MiKTeX
echo "Building MiKTeX..."
make -j$(nproc) 2>&1 | tee build.log

# Install
echo "Installing MiKTeX..."
make install 2>&1 | tee -a build.log

echo "Build complete! MiKTeX installed to $HOME/miktex"
echo "Add to PATH with: export PATH=\"\$HOME/miktex/bin:\$PATH\""
echo "Full build log saved to: $(pwd)/build.log"