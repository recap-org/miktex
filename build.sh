#!/bin/bash
set -e

# Create build directory outside source
rm -rf build out/miktex
mkdir build out/miktex
cd build

# Run CMake with installation prefix
cmake \
  -DCMAKE_INSTALL_PREFIX="../out/miktex" \
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

echo "Build complete!"