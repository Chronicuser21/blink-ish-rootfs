#!/bin/bash
# debootstrap.sh - Create Debian 10 i386 minimal rootfs
#
# This script runs debootstrap to create a minimal Debian rootfs
# for iSH. It's designed to be called from the Dockerfile.
#
# Usage: ./debootstrap.sh [output_dir]
#   output_dir - Directory to create rootfs in (default: /rootfs)

set -e

OUTPUT_DIR="${1:-/rootfs}"
DEBIAN_VERSION="buster"
ARCH="i386"
MIRROR="http://archive.debian.org/debian"

echo "=== Starting debootstrap for Debian ${DEBIAN_VERSION} ${ARCH} ==="
echo "Output directory: ${OUTPUT_DIR}"
echo "Mirror: ${MIRROR}"
echo ""

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Run debootstrap
# Note: i386 on x86_64 host works without QEMU for debootstrap
# using --variant=minbase for minimal installation
# excluding man-db to avoid long delays on iSH
debootstrap \
	--arch="${ARCH}" \
	--variant=minbase \
	--include=apt,dpkg,bash,coreutils,grep,sed,awk \
	"${DEBIAN_VERSION}" \
	"${OUTPUT_DIR}" \
	"${MIRROR}"

echo ""
echo "=== Debootstrap completed successfully ==="
echo "Rootfs created at: ${OUTPUT_DIR}"
