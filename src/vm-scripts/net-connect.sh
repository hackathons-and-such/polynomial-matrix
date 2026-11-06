#!/usr/bin/env sh

ip link set eth0 up
udhcpc -i eth0
