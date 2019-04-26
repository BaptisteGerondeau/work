#!/bin/bash

if [ $UID -ne 0 ]
then
    sudo NBDDEV=$NBDDEV $0 $1
    exit 0
fi

set -x
set +e

## variables
MAINDIR=$(dirname $0)
[ "$MAINDIR" == "." ] && MAINDIR=$(pwd)
DISTRIBUTION=$1
[ -z ${DISTRIBUTION} ] && echo "tell me the distribution!" && exit 1
source "$MAINDIR/../config/$DISTRIBUTION.default"
[ -f "$MAINDIR/../config/$DISTRIBUTION.local" ] && source "$MAINDIR/../config/$DISTRIBUTION.local"

IMGDIR="/var/lib/libvirt/images"
TARGET="/target/$HOSTNAME"

## end of variables

if [ ! -d $IMGDIR ]
then
    echo "$IMGDIR doesn't exist!" && exit 1
fi

if [ -d $IMGDIR/$HOSTNAME ]
then
    echo "$IMGDIR/$HOSTNAME isn't empty! Delete it" && exit 1
fi

set -e

TMPDIR="$IMGDIR/$HOSTNAME"
TMPFILE="$IMGDIR/$HOSTNAME/disk01.ext4.qcow2"

mkdir $TMPDIR

#sudo apt-get install libguestfs-tools 
modprobe nbd max_part=16
source "$MAINDIR/nbdfinder.sh"

qemu-nbd -d $NBDDEV 2>&1 > /dev/null
qemu-nbd -d $NBDDEV 2>&1 > /dev/null
qemu-nbd -d $NBDDEV 2>&1 > /dev/null
udevadm settle

[ -f $TMPFILE ] && rm $TMPFILE
qemu-img create -f qcow2 $TMPFILE 30G
qemu-nbd -c $NBDDEV $TMPFILE
udevadm settle
mkfs.ext4 -LROOT $NBDDEV

set +e

if [ ! -d $TARGET ]; then
	mkdir $TARGET
fi

umount $TARGET 2>&1 /dev/null
umount $TARGET 2>&1 /dev/null

set -e

# guestmount -a $TMPFILE -m /dev/sda1 --rw $TARGET
# Cannot unmount after script failure
mount $NBDDEV $TARGET

### Make the image
source "$MAINDIR/makeimage.$DISTRIBUTION.sh" || { echo "makeimage.$DISTRIBUTION.sh not found"; exit 1; }

# bring kernel image + ramdisk to host
if [ ! $VMLINUZ ] || [ ! $INITRD ]; then
	VMLINUZ=$($SUDO ls -1tr $TARGET/boot/vmlinuz* | tail -1)
	INITRD=$($SUDO ls -1tr $TARGET/boot/initr* | tail -1)
fi

if [ -d $MACHINEDIR ]; then
	echo "linux=$VMLINUZ initrd=$INITRD"
	$SUDO cp $VMLINUZ $TMPDIR/vmlinuz
	$SUDO cp $INITRD $TMPDIR/initrd.img
fi

umount $TARGET/dev/pts
umount $TARGET/dev
umount $TARGET/sys
umount $TARGET/proc
umount $TARGET

NEWUUID=$(uuidgen)
NEWMAC=$(printf '52:54:00:%02X:%02X:%02X\n' $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])

XML="""<domain type='kvm'>
  <name>$HOSTNAME</name>
  <uuid>$NEWUUID</uuid>
  <memory unit='GiB'>$RAMGB</memory>
  <currentMemory unit='GiB'>$RAMGB</currentMemory>
  <vcpu placement='static'>$VCPUS</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='aarch64' machine='virt-2.12'>hvm</type>
    <kernel>$IMGDIR/$HOSTNAME/vmlinuz</kernel>
    <initrd>$IMGDIR/$HOSTNAME/initrd.img</initrd>
    <cmdline>root=/dev/vda noresume console=tty0 console=ttyAMA0,38400n8 net.ifnames=0 apparmor=0</cmdline>
    <boot dev='hd'/>
  </os>
  <features>
    <gic version='3'/>
  </features>
  <cpu mode='host-passthrough' check='none'/>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup' track='guest'>
      <catchup threshold='123' slew='120' limit='10000'/>
    </timer>
    <timer name='pit' tickpolicy='delay'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-system-aarch64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='$IMGDIR/$HOSTNAME/disk01.ext4.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <controller type='pci' index='0' model='pcie-root'/>
    <controller type='pci' index='1' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='1' port='0x8'/>
    </controller>
    <controller type='pci' index='2' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='2' port='0x9'/>
    </controller>
    <controller type='pci' index='3' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='3' port='0xa'/>
    </controller>
    <controller type='pci' index='4' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='4' port='0xb'/>
    </controller>
    <controller type='virtio-serial' index='0'/>
    <interface type='bridge'>
      <mac address='$NEWMAC'/>
      <source bridge='$INTERFACE'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target type='system-serial' port='0'>
        <model name='pl011'/>
      </target>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <console type='pty'>
      <target type='virtio' port='1'/>
    </console>
    <memballoon model='virtio'/>
  </devices>
</domain>"""

echo $XML > $TMPDIR/$HOSTNAME.xml

if ! $(virsh define $TMPDIR/$HOSTNAME.xml &> /dev/null); then
virsh undefine $HOSTNAME
fi

virsh define $TMPDIR/$HOSTNAME.xml
