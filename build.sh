#!/bin/bash
set -e

# Create build directory outside source
rm -rf build out
mkdir build out
cd build

# Run CMake with installation prefix
# Using $HOME/miktex so no sudo is required for installation
  # -DCMAKE_INSTALL_PREFIX="../out" \
cmake \
  -DUSE_SYSTEM_MPFI=FALSE \
  -DUSE_SYSTEM_HARFBUZZ=FALSE \
  -DUSE_SYSTEM_HARFBUZZ_ICU=FALSE \
  -DWITH_UI_QT=OFF \
  ../

# Build MiKTeX
echo "Building MiKTeX..."
make -j$(nproc) 2>&1 | tee build.log

# Install
echo "Installing MiKTeX..."
make install 2>&1 | tee -a build.log

echo "Build complete! MiKTeX installed"
# echo "Add to PATH with: export PATH=\"\$HOME/miktex/bin:\$PATH\""
# echo "Full build log saved to: $(pwd)/build.log"