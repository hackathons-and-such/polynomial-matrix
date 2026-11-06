#!/bin/sh -e

# Custom overlay (apkovl) generator for the gitprofile image.
#
# This is based on aports/scripts/genapkovl-dhcp.sh. mkimage runs it from the
# destination directory and passes the image hostname as $1. It is a complete
# replacement for the stock DHCP overlay, so customisations must happen before
# the final tar command below.

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

# Packages that should be installed at boot in addition to alpine-base.
# Add new packages here (they also need to be in the profile's $apks list so
# that they are bundled in the ISO's /apks repository).
extra_packages="git dialog iwd fzf"

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
    ln -s /etc/init.d/iwd "$tmp"/etc/runlevels/default/iwd
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

mkdir -p "$tmp"/etc/apk
{
	echo alpine-base
	for pkg in $extra_packages; do
		echo "$pkg"
	done
} | makefile root:root 0644 "$tmp"/etc/apk/world

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

# Add any other custom files/scripts above this line, before the overlay is
# packed. Anything placed after the tar command will not be included.
tar -c -C "$tmp" etc | gzip -9n > "$HOSTNAME.apkovl.tar.gz"
