#!/bin/bash

if [ $UID -ne 0 ]
then
    sudo $0
    exit 0
fi

NUMVFS=32
IBFACE="mlx5_2"

quiet()
{
    $@ 2>&1 > /dev/null 2>&1
}

FILE=/tmp/ibdev2netdev.$$

ibdev2netdev -v | sort -k 2n > $FILE

echo
echo VIFs summary to make your life easier
echo

for ibface in $IBFACE
do
    for vifpciaddr in /sys/class/infiniband/$ibface/device/virtfn*
    do
        pciaddr=$(ls -lah $vifpciaddr | awk '{print $11}' | sed 's:\.\.\/::g')
        mlxdev=$(cat $FILE | grep $pciaddr | awk '{print $2}')
        mlxibdev=$(cat $FILE | grep $pciaddr | cut -d'>' -f2 | awk '{print $1}')
        echo "$mlxdev $pciaddr ($mlxibdev)"
    done
done

rm $FILE

