#!/bin/sh
#
# First-boot wireless provisioning wizard.
#
# This file is installed verbatim from src/overlayfs. The apkovl generator
# also drops /etc/local.d/wifi-wizard.start and enables the `local` service,
# so this runs once at first boot.

clear
echo "=================================================="
echo "      Alpine Linux Wireless Provisioning Wizard   "
echo "=================================================="
echo ""

rc-service iwd --quiet start
sleep 2

device=$(iwctl device list | awk '/wlan/ {print $2}')
if [ -z "$device" ]; then
    echo "Error: No wireless interface detected."
    exit 1
fi

echo "Detected wireless interface: $device"
echo ""

printf 'Enter Target SSID: '
read -r ssid

printf 'Enter Network Passphrase (PSK): '
stty -echo 2>/dev/null
read -r psk
stty echo 2>/dev/null
echo ""

if [ -z "$ssid" ] || [ -z "$psk" ]; then
    echo "Error: SSID and Passphrase parameters cannot be null."
    exit 1
fi

# iwd names profiles after the SSID. SSIDs containing anything other than
# alphanumerics, '-' or '_' are stored as '=' followed by the hex encoding.
case "$ssid" in
    *[!A-Za-z0-9_-]*)
        profile="=$(printf '%s' "$ssid" | od -An -v -tx1 | tr -d ' \n')"
        ;;
    *)
        profile="$ssid"
        ;;
esac

mkdir -p /var/lib/iwd
cat > "/var/lib/iwd/$profile.psk" <<EOT
[Security]
Passphrase=$psk
EOT

chmod 600 "/var/lib/iwd/$profile.psk"

echo "Establishing network association..."
iwctl station "$device" connect "$ssid"

# The wizard is a one-shot first-boot task.
rm -f /etc/local.d/wifi-wizard.start
rc-update del local default 2>/dev/null || true
echo "Configuration successfully finalized."
