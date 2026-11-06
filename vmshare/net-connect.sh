#!/usr/bin/env sh

ip link set eth0 up
udhcp -i eth0
