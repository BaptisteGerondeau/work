#!/bin/bash

## variables

HOSTNAME="debian"
VCPUS=4
RAMGB=4
PACKAGES="locales,less,vim,sudo,openssh-server,bash-completion,wget,rsync,git"
INTERFACE="vlan40"

## unlikely to be changed

IMGDIR="/var/lib/libvirt/images"
TARGET="/target"
NBDDEV="/dev/nbd0"

## end of variables

if [ $UID -ne 0 ]
then
    sudo $0
    exit 0
fi

set -x
set +e

if [ ! -d $IMGDIR ]
then
    exit 1
fi

if [ -d $IMGDIR/$HOSTNAME ]
then
    exit 1
fi

set -e

TMPDIR="$IMGDIR/$HOSTNAME"
TMPFILE="$IMGDIR/$HOSTNAME/disk01.ext4.qcow2"

mkdir $TMPDIR

modprobe nbd max_part=16

qemu-nbd -d $NBDDEV 2>&1 > /dev/null
qemu-nbd -d $NBDDEV 2>&1 > /dev/null
qemu-nbd -d $NBDDEV 2>&1 > /dev/null

[ -f $TMPFILE ] && rm $TMPFILE
qemu-img create -f qcow2 $TMPFILE 30G
qemu-nbd -c $NBDDEV $TMPFILE
mkfs.ext4 -LROOT $NBDDEV

set +e

if [ ! -d $TARGET ]; then
	mkdir $TARGET
fi

umount $TARGET 2>&1 /dev/null
umount $TARGET 2>&1 /dev/null

set -e

mount $NBDDEV $TARGET

debootstrap --include=$PACKAGES \
            sid \
            $TARGET \
            http://deb.debian.org/debian/

mount -o bind /dev $TARGET/dev
mount -o bind /dev/pts $TARGET/dev/pts
mount -o bind /sys $TARGET/sys
mount -o bind /proc $TARGET/proc

chroot $TARGET /bin/bash -c "locale-gen en_US.UTF-8"
echo $HOSTNAME | tee $TARGET/etc/hostname

chroot $TARGET /bin/bash -c "passwd -d root"
chroot $TARGET /bin/bash -c "useradd -d /home/inaddy -m -s /bin/bash inaddy"
chroot $TARGET /bin/bash -c "passwd -d inaddy"

chroot $TARGET /bin/bash -c "echo root:root | chpasswd"
chroot $TARGET /bin/bash -c "echo inaddy:inaddy | chpasswd"

echo """## /etc/sudoers

Defaults env_keep += \"LANG LANGUAGE LINGUAS LC_* _XKB_CHARSET\"
Defaults env_keep += \"HOME EDITOR SYSTEMD_EDITOR PAGER\"
Defaults env_keep += \"XMODIFIERS GTK_IM_MODULE QT_IM_MODULE QT_IM_SWITCHER\"

Defaults secure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"

Defaults logfile=/var/log/sudo.log,loglinelen=0
Defaults !syslog, !pam_session

root ALL=(ALL) NOPASSWD: ALL
%wheel ALL=(ALL) NOPASSWD: ALL
%sudo ALL=(ALL) NOPASSWD: ALL
inaddy ALL=(ALL) NOPASSWD: ALL

## end of file""" | tee $TARGET/etc/sudoers

echo """## /etc/fstab

LABEL=ROOT / ext4 errors=remount-ro 0 1

## end of file""" | tee $TARGET/etc/fstab

echo """## /etc/apt/sources.list

deb http://deb.debian.org/debian/ sid main non-free contrib
deb-src http://deb.debian.org/debian/ sid main non-free contrib
deb http://debug.mirrors.debian.org/debian-debug/ sid-debug main

## end of file""" | tee $TARGET/etc/apt/sources.list

echo """## /etc/apt/apt.conf

#Acquire::http::Proxy \"http://0.0.0.0:3128/\";
APT::Install-Recommends \"true\";
APT::Install-Suggests \"false\";
# APT::Get::Assume-Yes \"true\";
# APT::Get::Show-Upgraded \"true\";
APT::Quiet \"true\";
DPkg::Options { \"--force-confdef\";\"--force-confmiss\";\"--force-confold\"};
Debug::pkgProblemResolver \"true\";
Acquire::Languages \"none\";

## end of file""" | tee $TARGET/etc/apt/apt.conf

ARCH=$(uname -r | cut -d'-' -f3)

chroot $TARGET /bin/bash -c "apt-get update"
chroot $TARGET /bin/bash -c "apt-get install -y linux-image-$ARCH linux-headers-$ARCH"
#chroot $TARGET /bin/bash -c "apt-get build-dep -y hello"
#chroot $TARGET /bin/bash -c "apt-get build-dep -y linux-image-$ARCH"

umount $TARGET/dev/pts
umount $TARGET/dev
umount $TARGET/sys
umount $TARGET/proc
umount $TARGET

qemu-nbd -d $NBDDEV
qemu-nbd -d $NBDDEV 2>&1 > /dev/null
qemu-nbd -d $NBDDEV 2>&1 > /dev/null

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

virsh define $TMPDIR/$HOSTNAME.xml

virsh list --all

$(which qcowvmlinuz.sh) $HOSTNAME

