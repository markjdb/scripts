#!/bin/sh

warn()
{
    echo "$(basename ${0}): $1" 1>&2
}

err()
{
    warn "$1"
    exit 1
}

which pciconf >/dev/null 2>&1 || err "This script only works on FreeBSD."

[ $(id -u) -eq 0 ] || err "This script must be run as root."

isadev=$(pciconf -l | awk '/^isab0/ {print $1}')

if [ -z "$isadev" ]; then
    warn "isab isn't attached... this might not work (but probably will)."
    for pcidev in $(pciconf -l | awk '{print $1}'); do
        pciconf -r $pcidev 0x104 >/dev/null 2>&1
    done
else
    pciconf -r $isadev 0x104 >/dev/null 2>&1
fi
