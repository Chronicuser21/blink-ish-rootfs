# Multi-stage Dockerfile for building Debian 10 i386 rootfs converted to iSH fakefs format
#
# Stage 1 (builder): Build fakefsify and create rootfs with debootstrap
# Stage 2 (converter): Convert rootfs to fakefs format

# =============================================================================
# Stage 1: Builder - Build fakefsify and create Debian rootfs
# =============================================================================
FROM debian:bookworm AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    lld \
    debootstrap \
    libarchive-dev \
    sqlite3 \
    libsqlite3-dev \
    meson \
    ninja-build \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone iSH repository for fakefsify source
WORKDIR /build
RUN git clone --depth 1 https://github.com/ish-app/ish.git

# Build fakefsify from iSH source
# Note: fakefsify needs libfakefs which is built from fs/fake-*.c
WORKDIR /build/ish
RUN meson setup build \
    -Dkernel=linux \
    -Dengine=asbestos \
    -Ddefault_library=static \
    && ninja -C build tools/fakefsify

# Create the rootfs directory
RUN mkdir -p /rootfs

# Run debootstrap to create minimal Debian 10 i386 rootfs
# Note: i386 on x86_64 works without QEMU for debootstrap
RUN debootstrap \
    --arch=i386 \
    --variant=minbase \
    --include=apt,dpkg,bash,coreutils,grep,sed,awk \
    buster \
    /rootfs \
    http://archive.debian.org/debian

# Configure apt sources for archive.debian.org (Debian 10 is EOL)
RUN echo "deb http://archive.debian.org/debian buster main" > /rootfs/etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /rootfs/etc/apt/sources.list

# Disable man-db to avoid long delays on iSH
RUN echo 'path-exclude=/usr/share/man/*' > /rootfs/etc/dpkg/dpkg.cfg.d/no-man-db

# Configure apt to minimize size
RUN echo 'Acquire::Languages "none";' > /rootfs/etc/apt/apt.conf.d/99no-languages && \
    echo 'APT::Install-Recommends "false";' > /rootfs/etc/apt/apt.conf.d/99no-install-recommends && \
    echo 'APT::Install-Suggests "false";' >> /rootfs/etc/apt/apt.conf.d/99no-install-recommends

# Clean apt cache
RUN chroot /rootfs apt-get clean && \
    rm -rf /rootfs/var/lib/apt/lists/* \
           /rootfs/var/cache/apt/archives/*.deb \
           /rootfs/usr/share/doc/* \
           /rootfs/usr/share/man/* \
           /rootfs/usr/share/locale/*

# =============================================================================
# Stage 2: Converter - Convert rootfs to iSH fakefs format
# =============================================================================
FROM debian:bookworm AS converter

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libarchive13 \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy rootfs from builder
COPY --from=builder /rootfs /rootfs

# Copy fakefsify binary from builder
COPY --from=builder /build/ish/build/tools/fakefsify /usr/local/bin/fakefsify

# Create output directory
RUN mkdir -p /output

# Create tarball from rootfs
RUN tar -czf /tmp/rootfs.tar.gz -C /rootfs .

# Convert to fakefs format
RUN fakefsify /tmp/rootfs.tar.gz /output/debian10-ish

# Verify output structure
RUN test -d /output/debian10-ish/data && \
    test -f /output/debian10-ish/meta.db && \
    echo "Rootfs conversion successful" || \
    (echo "Rootfs conversion failed"; exit 1)

# Clean up intermediate files
RUN rm -f /tmp/rootfs.tar.gz

# Set the output directory as the working directory
WORKDIR /output
