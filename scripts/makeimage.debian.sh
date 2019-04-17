#!/bin/bash

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

