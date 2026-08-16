#!/bin/bash
set -e
# Without pipefail, `make ... | tee` reports tee's exit status, so a failed
# build would sail past `set -e` and produce an empty tarball.
set -o pipefail

# Create build directory outside source
rm -rf build out
mkdir -p build out/miktex
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
echo "Running make..."
make -j$(nproc) 2>&1 | tee build.log

# Install
echo "Running make install..."
make install 2>&1 | tee -a build.log

cd ..

# Extract version and architecture
echo "Extracting version and architecture..."
VERSION=$(grep "^MIKTEX_VERSION_STR:STRING=" build/CMakeCache.txt 2>/dev/null | cut -d= -f2 || echo "unknown")

# Detect architecture from host system
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
MACHINE=$(uname -m)
ARCH="${OS}-${MACHINE}"

echo "Version: $VERSION"
echo "Architecture: $ARCH"

# Create staging directory for tarball
STAGING_DIR="out/miktex-${VERSION}-${ARCH}"
echo "Creating staging directory: $STAGING_DIR"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy files to staging directory
echo "Copying files to staging directory..."
cp install.sh "$STAGING_DIR/"
mv out/miktex "$STAGING_DIR/miktex"
cp test.sh "$STAGING_DIR/"
cp -r test "$STAGING_DIR/"

# Create tarball
TARBALL="out/miktex-${VERSION}-${ARCH}.tar.xz"
echo "Creating tarball: $TARBALL"
tar -cJf "$TARBALL" -C out "miktex-${VERSION}-${ARCH}"

echo ""
echo "========================================="
echo "Build complete!"
echo "========================================="
echo "Tarball created: $TARBALL"
echo "========================================="