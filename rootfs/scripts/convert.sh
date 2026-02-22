#!/bin/bash
# convert.sh - Convert rootfs to iSH fakefs format
#
# This script converts a Debian rootfs directory to iSH's fakefs format:
# - Creates a tarball from the rootfs directory
# - Runs fakefsify to convert to SQLite-based fakefs
# - Verifies the output structure
#
# Usage: ./convert.sh [rootfs_dir] [output_dir]
#   rootfs_dir  - Path to rootfs directory (default: /rootfs)
#   output_dir  - Output directory for fakefs (default: /output)
#
# Output structure:
#   output_dir/debian10-ish/
#   ├── data/        # Actual file content
#   └── meta.db      # SQLite metadata

set -e

ROOTFS="${1:-/rootfs}"
OUTPUT_DIR="${2:-/output}"
ROOTFS_TARBALL="/tmp/rootfs.tar.gz"
FAKEFS_OUTPUT="${OUTPUT_DIR}/debian10-ish"

echo "=== Converting rootfs to fakefs format ==="
echo "Input: ${ROOTFS}"
echo "Output: ${FAKEFS_OUTPUT}"
echo ""

# Verify input exists
if [ ! -d "${ROOTFS}" ]; then
	echo "ERROR: Rootfs directory not found: ${ROOTFS}"
	exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Create tarball from rootfs
echo "Creating tarball from rootfs..."
tar -czf "${ROOTFS_TARBALL}" -C "${ROOTFS}" .
TARBALL_SIZE=$(du -h "${ROOTFS_TARBALL}" | cut -f1)
echo "Tarball created: ${ROOTFS_TARBALL} (${TARBALL_SIZE})"

# Check if fakefsify is available
if ! command -v fakefsify &>/dev/null; then
	echo "ERROR: fakefsify not found in PATH"
	echo "Make sure fakefsify is built and installed"
	exit 1
fi

# Convert to fakefs format
echo "Running fakefsify..."
fakefsify "${ROOTFS_TARBALL}" "${FAKEFS_OUTPUT}"

# Verify output structure
echo ""
echo "Verifying output structure..."

if [ -d "${FAKEFS_OUTPUT}/data" ]; then
	echo "✓ data/ directory found"
else
	echo "✗ data/ directory missing"
	exit 1
fi

if [ -f "${FAKEFS_OUTPUT}/meta.db" ]; then
	echo "✓ meta.db file found"
else
	echo "✗ meta.db file missing"
	exit 1
fi

# Show output size
echo ""
echo "=== Conversion completed ==="
OUTPUT_SIZE=$(du -sh "${FAKEFS_OUTPUT}" | cut -f1)
echo "Output size: ${OUTPUT_SIZE}"
echo "Output location: ${FAKEFS_OUTPUT}"

# Clean up intermediate tarball
rm -f "${ROOTFS_TARBALL}"
echo "Cleaned up intermediate tarball"

# List output contents
echo ""
echo "Output contents:"
ls -la "${FAKEFS_OUTPUT}/"
