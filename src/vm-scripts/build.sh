#!/usr/bin/env sh

set -ue

src_mount_path="/mnt/hostshare"
build_scripts_dir="$src_mount_path/aports-scripts"

keyname="pkgkey"

_log() {
    echo -e "\n=== $1 ==="
}

get_tools() {
    _log "Getting Tools"
    dev_tools="git"
    build_tools="abuild alpine-conf syslinux xorriso squashfs-tools grub mtools"
    apk_repo_url="https://dl-cdn.alpinelinux.org/alpine/v3.24/main\nhttps://dl-cdn.alpinelinux.org/alpine/v3.24/community\n"

    printf "$apk_repo_url" > /etc/apk/repositories
    apk update

    apk add $build_tools $dev_tools
}

setup_build_environment() {
    _log "Setting Up Build Environment"
    mkdir -p /root
    cd /root
    
    if [ ! -d "aports" ]; then
        git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git
    fi

    cd aports
    # Installs mkimg.gitprofile.sh and genapkovl-gitprofile.sh. The overlay
    # generator is self-contained, so the stock genapkovl-dhcp.sh is left alone
    # and re-running the build does not append duplicate customisations.
    cp "$build_scripts_dir"/* scripts/

    # Patch mkimage.sh to remove the deprecated --no-chown flag causing the usermode error
    sed -i 's/--no-chown//g' scripts/mkimage.sh
    
    # Setup keys
    mkdir -p ~/.abuild
    cp "$src_mount_path/$keyname" ~/.abuild/$keyname
    cp "$src_mount_path/static/$keyname.pub" ~/.abuild/$keyname.pub
    
    # abuild requires strict private key permissions (read/write by owner only)
    chmod 600 ~/.abuild/$keyname
    chmod 644 ~/.abuild/$keyname.pub
    export PACKAGER_PRIVKEY="$HOME/.abuild/$keyname"

    mkdir -p tmp
    export TMPDIR=$PWD/tmp
}

make_image() {
    _log "Making Image"
    cd /root/aports
    export PACKAGER_PRIVKEY="/root/.abuild/$keyname"
    
    # Force abuild/mkimage to permit execution under the root user
    export FORCE_ROOT=1
    
    sh scripts/mkimage.sh \
        --tag edge \
        --outdir "$1" \
        --arch x86_64 \
        --repository https://dl-cdn.alpinelinux.org/alpine/edge/main \
        --repository https://dl-cdn.alpinelinux.org/alpine/edge/community \
        --profile gitprofile
}

get_tools
setup_build_environment
make_image "/mnt/hostshare/iso/"

_log "Build Finished"
