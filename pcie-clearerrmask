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

pcieroot_regread()
{
    pciconf -r pci0:0:0:0 $1 2>/dev/null
}

pcieroot_regclear()
{
    pciconf -w pci0:0:0:0 $1 0
}

doit()
{
    echo "clearing $1 - original value was $(pcieroot_regread ${2})"
    pcieroot_regclear $2
}

which pciconf >/dev/null 2>&1 || err "This script only works on FreeBSD."

[ $(id -u) -eq 0 ] || err "This script must be run as root."

if ! dmesg | grep -q -e '^rasum:.*Jasper Forest' -e '^rasum:.*Sandy Bridge'; then
    warn "This script probably won't work on this platform, but we'll try anyway."
fi

warn "Attempting to clear error masks."

doit XPCORERRMSK 0x204
doit XPUNCERRMSK 0x20C
doit UNCEDMASK   0x218
doit COREDMASK   0x21C
doit RPEDMASK    0x220
doit XPUNCEDMASK 0x224
doit XPCOREDMASK 0x228
