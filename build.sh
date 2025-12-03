#!/bin/sh
set -eu

SKALIBS_VERSION="2.14.4.0"
EXECLINE_VERSION="2.9.7.0"
S6_VERSION="2.13.2.0"
S6_PORTABLE_UTILS_VERSION="2.3.1.0"

PREFIX="${PREFIX:-/tmp/s6-install}"
BUILD_DIR="/tmp/s6-build"

export CFLAGS="-Os -ffunction-sections -fdata-sections"
export LDFLAGS="-Wl,--gc-sections -s"

echo "Building s6 ecosystem..."
mkdir -p "$BUILD_DIR" "$PREFIX"
cd "$BUILD_DIR"

# Build skalibs
echo "Building skalibs ${SKALIBS_VERSION}..."
curl -fsSL "https://skarnet.org/software/skalibs/skalibs-${SKALIBS_VERSION}.tar.gz" | tar xz
cd "skalibs-${SKALIBS_VERSION}"
./configure --prefix="$PREFIX" --enable-static-libc
make -j$(nproc)
make install
cd ..

# Build execline
echo "Building execline ${EXECLINE_VERSION}..."
curl -fsSL "https://skarnet.org/software/execline/execline-${EXECLINE_VERSION}.tar.gz" | tar xz
cd "execline-${EXECLINE_VERSION}"
./configure --prefix="$PREFIX" --with-include="$PREFIX/include" --with-lib="$PREFIX/lib" --with-sysdeps="$PREFIX/lib/skalibs/sysdeps" --enable-static-libc
make -j$(nproc)
make install
cd ..

# Build s6
echo "Building s6 ${S6_VERSION}..."
curl -fsSL "https://skarnet.org/software/s6/s6-${S6_VERSION}.tar.gz" | tar xz
cd "s6-${S6_VERSION}"
./configure --prefix="$PREFIX" --with-include="$PREFIX/include" --with-lib="$PREFIX/lib" --with-sysdeps="$PREFIX/lib/skalibs/sysdeps" --enable-static-libc
make -j$(nproc)
make install
cd ..

echo "✓ s6 built successfully"

# Strip and compress s6 binaries
echo "Stripping s6 binaries..."
strip "$PREFIX"/bin/* 2>/dev/null || true
echo "Compressing s6 binaries..."
find "$PREFIX/bin" -type f -exec upx --best --lzma {} \;

# Create s6 tarball
echo "Creating s6 tarball..."
cd "$PREFIX"
tar czf /s6-${TARGETARCH:-amd64}.tar.gz bin lib
echo "✓ s6 tarball created"

# Clean for portable-utils build
echo "Cleaning for portable-utils build..."
rm -rf "$PREFIX/bin"/*

# Build s6-portable-utils with multicall
echo "Building s6-portable-utils ${S6_PORTABLE_UTILS_VERSION} with multicall..."
cd "$BUILD_DIR"
curl -fsSL "https://skarnet.org/software/s6-portable-utils/s6-portable-utils-${S6_PORTABLE_UTILS_VERSION}.tar.gz" | tar xz
cd "s6-portable-utils-${S6_PORTABLE_UTILS_VERSION}"
./configure --prefix="$PREFIX" --with-include="$PREFIX/include" --with-lib="$PREFIX/lib" --with-sysdeps="$PREFIX/lib/skalibs/sysdeps" --enable-static-libc --enable-multicall
make -j$(nproc)
make install

echo "✓ s6-portable-utils built successfully"

# Strip and compress portable-utils
echo "Stripping portable-utils..."
strip "$PREFIX"/bin/* 2>/dev/null || true
echo "Compressing portable-utils..."
find "$PREFIX/bin" -type f -exec upx --best --lzma {} \; 2>/dev/null || true

# Create portable-utils tarball
echo "Creating portable-utils tarball..."
cd "$PREFIX"
tar czf /s6-portable-utils-${TARGETARCH:-amd64}.tar.gz bin lib
echo "✓ s6-portable-utils tarball created"
