#!/bin/bash
set -e

echo "Building s6 for ${TARGETARCH:-amd64}..."
docker build -t s6-builder .

echo "Extracting tarballs..."
CONTAINER=$(docker create s6-builder)
rm -rf *.tar.gz
docker cp "$CONTAINER":/s6-${TARGETARCH:-amd64}.tar.gz .
docker cp "$CONTAINER":/s6-portable-utils-${TARGETARCH:-amd64}.tar.gz .
docker rm "$CONTAINER"

echo "✓ Tarballs extracted:"
ls -lh *.tar.gz
