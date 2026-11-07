#!/usr/bin/env sh

echo "Running setup wizard"

ip link set eth0 up
udhcpc -i eth0

chmod -R 777 "/usr/local/partyplace"

wifi_ap=$(printf "Netgear-Guest-5G\nHomeNetwork_2.4\nOffice_Conference_Room\nDigi_nlawdin\nDigi_pasnwkl" | fzf)

echo "Connecting to $wifi_ap..."
sleep 2s
echo "Conneted"
sleep 1s

/usr/local/bin/copyparty-sfx.py -c /usr/local/etc/copyparty-sfx/app.conf
