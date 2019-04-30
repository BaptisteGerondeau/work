#!/bin/bash

### DO NOT CALL FIRST : Call "scripts/makeguest.sh centos"
rpm --root $TARGET --initdb
wget $CENTOS_RELEASE_RPM_URL
rpm -ivh --force-debian --nodeps --root $TARGET $(basename $CENTOS_RELEASE_RPM_URL) 
rm -rf /etc/pki
ln -s $TARGET/etc/pki /etc/pki
yum --installroot $TARGET -y install bash yum passwd shadow shadow-utils iputils iproute

mkdir -p $TARGET/dev/pts
mkdir -p $TARGET/sys
mkdir -p $TARGET/proc

mount -o bind /dev $TARGET/dev
mount -o bind /dev/pts $TARGET/dev/pts
mount -o bind /sys $TARGET/sys
mount -o bind /proc $TARGET/proc

echo $HOSTNAME | tee $TARGET/etc/hostname

chroot $TARGET /bin/sh -c "passwd -d root"
chroot $TARGET /bin/sh -c "echo root:root | chpasswd"

chroot $TARGET /bin/sh -c "useradd -d /home/inaddy -m -s /bin/bash inaddy"
chroot $TARGET /bin/sh -c "passwd -d inaddy"
chroot $TARGET /bin/sh -c "echo inaddy:inaddy | chpasswd"

chroot $TARGET /bin/sh -c "useradd -d /home/bgerdeb -m -s /bin/bash bgerdeb"
chroot $TARGET /bin/sh -c "passwd -d bgerdeb"
chroot $TARGET /bin/sh -c "echo bgerdeb:bgerdeb | chpasswd"

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
bgerdeb ALL=(ALL) NOPASSWD: ALL

## end of file""" | tee $TARGET/etc/sudoers

echo """## /etc/fstab

LABEL=ROOT / ext4 defaults 0 1

## end of file""" | tee $TARGET/etc/fstab

echo """## /etc/sysconfig/network

NETWORKING=yes

## end of file""" | tee $TARGET/etc/sysconfig/network

echo """## /etc/resolv.conf

nameserver 10.40.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4

## end of file""" | tee $TARGET/etc/resolv.conf


echo """## /etc/sysconfig/network-scripts/ifcfg-eth0

DEVICE=eth0
ONBOOT=yes
DHCP=yes

## end of file""" | tee $TARGET/etc/sysconfig/network-scripts/ifcfg-eth0

echo """## /etc/selinux/config

SELINUX=disabled
SELINUXTYPE=targeted 

## end of file""" | tee $TARGET/etc/selinux/config

cat /root/.ssh/authorized_keys | tee $TARGET/root/.ssh/authorized_keys

chroot $TARGET /bin/sh -c "rpm --initdb"
chroot $TARGET /bin/sh -c "yum clean all"
chroot $TARGET /bin/sh -c "yum --releasever=7 install -y yum bash centos-release"
chroot $TARGET /bin/bash -c "yum --releasever=7 install -y @core @base kernel kernel-headers redhat-lsb-core dracut-tools dracut-config-generic dracut-config-rescue ${PACKAGES//,/ }"
chroot $TARGET /bin/bash -c "$LOCALE"
