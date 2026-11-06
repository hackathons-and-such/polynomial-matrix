#!/usr/bin/env sh

build_tools="abuild alpine-conf syslinux xorriso squashfs-tools grub mtools"
repo_url="https://dl-cdn.alpinelinux.org/alpine/v3.24/main\nhttps://dl-cdn.alpinelinux.org/alpine/v3.24/community\n"

setup_apk_repo() {
    printf $repo_url > /etc/apk/repositories
    apk update
}

setup_apk_repo
apk add $build_tools
