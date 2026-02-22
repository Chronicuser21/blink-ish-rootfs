#!/bin/bash
# configure.sh - Configure Debian rootfs for iSH
#
# This script configures the rootfs after debootstrap:
# - Sets up apt sources for archive.debian.org (Debian 10 is EOL)
# - Configures apt to minimize size
# - Cleans cache files
#
# Usage: ./configure.sh [rootfs_dir]
#   rootfs_dir - Path to rootfs directory (default: /rootfs)

set -e

ROOTFS="${1:-/rootfs}"

echo "=== Configuring rootfs at ${ROOTFS} ==="

# Configure apt sources for archive.debian.org
# Debian 10 (buster) reached EOL on 2022-09-10
echo "Configuring apt sources for archive.debian.org..."
cat >"${ROOTFS}/etc/apt/sources.list" <<'EOF'
deb http://archive.debian.org/debian buster main
deb http://archive.debian.org/debian-security buster/updates main
EOF

echo "Sources configured:"
cat "${ROOTFS}/etc/apt/sources.list"

# Disable man-db to avoid long delays on iSH during package operations
echo "Disabling man-db..."
mkdir -p "${ROOTFS}/etc/dpkg/dpkg.cfg.d"
echo 'path-exclude=/usr/share/man/*' >"${ROOTFS}/etc/dpkg/dpkg.cfg.d/no-man-db"

# Configure apt to minimize size
echo "Configuring apt for minimal size..."
mkdir -p "${ROOTFS}/etc/apt/apt.conf.d"

# Disable language files
cat >"${ROOTFS}/etc/apt/apt.conf.d/99no-languages" <<'EOF'
Acquire::Languages "none";
EOF

# Disable recommends and suggests
cat >"${ROOTFS}/etc/apt/apt.conf.d/99no-install-recommends" <<'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

# Disable caching (optional, saves space)
cat >"${ROOTFS}/etc/apt/apt.conf.d/99no-cache" <<'EOF'
Dir::Cache "";
Dir::Cache::archives "";
EOF

# Clean apt cache inside rootfs
echo "Cleaning apt cache..."
if chroot "${ROOTFS}" apt-get clean 2>/dev/null; then
	echo "apt-get clean completed"
else
	echo "Note: apt-get clean had issues (may be expected in some setups)"
fi

# Remove cached files
rm -rf "${ROOTFS}/var/lib/apt/lists/*" 2>/dev/null || true
rm -rf "${ROOTFS}/var/cache/apt/archives/*.deb" 2>/dev/null || true

# Remove documentation and locale files to save space
echo "Removing documentation and locale files..."
rm -rf "${ROOTFS}/usr/share/doc/"* 2>/dev/null || true
rm -rf "${ROOTFS}/usr/share/man/"* 2>/dev/null || true
rm -rf "${ROOTFS}/usr/share/locale/"* 2>/dev/null || true

echo ""
echo "=== Configuration completed ==="
echo "Rootfs ready at: ${ROOTFS}"
