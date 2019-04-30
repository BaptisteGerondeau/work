#!/bin/bash
NBD_MAXDEV=16

if [ -z "$NBDDEV" ]; then
    for i in $(seq 0 $(($NBD_MAXDEV-1))); do
    if ! $(findmnt -rno SOURCE "/dev/nbd$i"); then
        NBDDEV="/dev/nbd$i"
        echo "$NBDDEV"
    break
    fi
    if $(findmnt -rno SOURCE "/dev/nbd$i") && [ "$i" -eq "$NBD_MAXDEV" ]; then
        echo "No NBD device available, lease free a NBD device manually"
        exit 1
    fi
    done
fi
