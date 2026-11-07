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

# build.sh stages the overlay tree next to this script so it is available here.
overlayfs_dir="$(dirname -- "$0")/overlayfs"

# Packages that should be installed at boot in addition to alpine-base.
# Add new packages here (they also need to be in the profile's $apks list so
# that they are bundled in the ISO's /apks repository).
extra_packages="git dialog iwd fzf python3 py3-mutagen"

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
    local service="$1"
    local runlevel="$2"
    mkdir -p "$tmp/etc/runlevels/$runlevel"
    ln -sf /etc/init.d/"$service" "$tmp/etc/runlevels/$runlevel/$service"
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
rc_add iwd sysinit

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

# Merge files from src/overlayfs into the image root. Copy last so overlay
# files take precedence over anything generated above.
if [ -d "$overlayfs_dir" ]; then
	cp -a "$overlayfs_dir"/. "$tmp"/
	# Normalise ownership; files originate on the 9p host share.
	chown -Rh root:root "$tmp"
fi

# Wire up the wireless provisioning wizard when the overlay provides it.
if [ -f "$tmp/usr/local/bin/wifi-setup-wizard.sh" ]; then
	mkdir -p "$tmp/etc/local.d"
	makefile root:root 0755 "$tmp/etc/local.d/wifi-wizard.start" <<'EOF'
#!/bin/sh
/usr/local/bin/wifi-setup-wizard.sh
EOF
	rc_add local default
fi

mkdir -p /usr/local/partyplace
makefile root:root 0755 "/usr/local/partyplace/README.md" <<'EOF'
## Welcome to QuickNAS
A quick, low cost and simple NAS solution.
EOF

cat << 'EOF' >> "$tmp/etc/profile"
    /usr/local/bin/wizard.sh
EOF

# Pack the whole overlay tree (not just etc) so files outside /etc survive.
tar -c -C "$tmp" . | gzip -9n > "$HOSTNAME.apkovl.tar.gz"
