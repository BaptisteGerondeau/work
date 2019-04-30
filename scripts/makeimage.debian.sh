#!/bin/bash

debootstrap --include=$PACKAGES \
            buster \
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

echo """## /etc/network/interfaces

auto lo
iface lo inet loopback
    dns-nameserver 10.40.0.1
    dns-nameserver 8.8.8.8
    dns-nameserver 8.8.4.4

iface eth0 inet manual

auto vlan40
iface vlan40 inet dhcp
    bridge_ports eth0
    bridge_stp off
    bridge_maxwait 0

source /etc/network/interfaces.d/*

## end of file""" | tee $TARGET/etc/network/interfaces

echo "" | tee $TARGET/etc/motd
echo "" | tee $TARGET/etc/issue
echo "" | tee $TARGET/etc/issue.net

echo """## /etc/ssh/sshd_config

Port 22
AddressFamily inet
ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

#RekeyLimit default none

SyslogFacility AUTH
LogLevel INFO

LoginGraceTime 1m
PermitRootLogin prohibit-password
StrictModes yes
MaxAuthTries 5
MaxSessions 20

PubkeyAuthentication yes

#AuthorizedKeysFile .ssh/authorized_keys
AuthorizedPrincipalsFile none
AuthorizedKeysCommand none
AuthorizedKeysCommandUser nobody

HostbasedAuthentication no
IgnoreUserKnownHosts no
IgnoreRhosts yes

PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
GSSAPIAuthentication no
UsePAM yes

AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts yes
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
PermitTTY yes
PrintMotd no
PrintLastLog no
TCPKeepAlive yes
UseLogin no
PermitUserEnvironment no
Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
PermitTunnel yes
#ChrootDirectory none
#VersionAddendum none
Banner none

AcceptEnv LANG LC_* EDITOR PAGER SYSTEMD_EDITOR

Subsystem	sftp	/usr/lib/openssh/sftp-server

## end of file""" | tee $TARGET/etc/ssh/sshd_config

echo """## /etc/ssh/ssh_config

Host *
#   ForwardAgent no
#   ForwardX11 no
#   ForwardX11Trusted yes
#   PasswordAuthentication yes
#   HostbasedAuthentication no
#   GSSAPIAuthentication no
#   GSSAPIDelegateCredentials no
#   GSSAPIKeyExchange no
#   GSSAPITrustDNS no
#   BatchMode no
#   CheckHostIP yes
#   AddressFamily any
#   ConnectTimeout 0
#   IdentityFile ~/.ssh/id_rsa
#   IdentityFile ~/.ssh/id_dsa
#   IdentityFile ~/.ssh/id_ecdsa
#   IdentityFile ~/.ssh/id_ed25519
#   Port 22
#   Protocol 2
#   Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc
#   MACs hmac-md5,hmac-sha1,umac-64@openssh.com
#   EscapeChar ~
#   Tunnel no
#   TunnelDevice any:any
#   PermitLocalCommand no
#   VisualHostKey no
#   ProxyCommand ssh -q -W %h:%p gateway.example.com
#   RekeyLimit 1G 1h
#   GSSAPIAuthentication no
    SendEnv LANG LC_* EDITOR PAGER
    StrictHostKeyChecking no
    HashKnownHosts yes

## end of file""" | tee $TARGET/etc/ssh/ssh_config

echo """## /etc/hosts

127.0.0.1 localhost
127.0.1.1 $HOSTNAME

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

## end of file""" | tee $TARGET/etc/hosts

echo """## /etc/pam.d/sshd

@include common-auth

account    required     pam_nologin.so

@include common-account

session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so close
session    required     pam_loginuid.so
session    optional     pam_keyinit.so force revoke

@include common-session

session    required     pam_limits.so
session    required     pam_env.so # [1]
session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so open

@include common-password

## end of file""" | tee $TARGET/etc/pam.d/sshd

echo """## /etc/pam.d/login

auth       optional   pam_faildelay.so  delay=3000000

auth [success=ok new_authtok_reqd=ok ignore=ignore user_unknown=bad default=die] pam_securetty.so

auth       requisite  pam_nologin.so

session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session    required     pam_loginuid.so
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
session       required   pam_env.so readenv=1
session       required   pam_env.so readenv=1 envfile=/etc/default/locale

@include common-auth

auth       optional   pam_group.so

session    required   pam_limits.so
session    optional   pam_keyinit.so force revoke

@include common-account
@include common-session
@include common-password

## end of file """ | tee $TARGET/etc/pam.d/login

ARCH=$(uname -r | cut -d'-' -f3)

chroot $TARGET /bin/bash -c "apt-get update"
chroot $TARGET /bin/bash -c "apt-get install -y linux-image-$ARCH linux-headers-$ARCH"
#chroot $TARGET /bin/bash -c "apt-get build-dep -y hello"
#chroot $TARGET /bin/bash -c "apt-get build-dep -y linux-image-$ARCH"
