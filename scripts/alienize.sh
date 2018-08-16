#!/bin/bash -x

#
# this script generates rpm and tgz pkgs from deb ones
#

# global to host since only host should run this script
# WARN: dont run this script inside containers

LOCKFILE=/tmp/alienize.lock

getout() {
    echo ERROR: $@
    exit 1
}

ctrlc() {
    # cleanup

    if [ -d /tmp/$$ ]; then
        rm -rf /tmp/$$/*
        rmdir /tmp/$$
    fi
}


i=0
lockdown() {
    # totally racy locking function

    while true; do
        if [ ! -f $LOCKFILE ]; then
            echo $$ > $LOCKFILE
            sync
            break
        fi

        echo "trying to acquire the lock"

        # wait a bit for the lock
        # WARN: cron should not be less than 120 sec

        sleep 5
        i=$((i+5))
        if [ $i -eq 60 ]; then
            echo "could not obtain the lock, exiting"
            exit 1
        fi

    done
}

lockup() {
    rm -f $LOCKFILE
    sync
}

trap "ctrlc" 2
lockdown

OLDDIR=$PWD
MAINDIR="$HOME/work/pkgs"

TEMPDIR="/tmp/$$"
mkdir $TEMPDIR
cd $TEMPDIR

# check existing .deb files and see if associated .tgz and .rpm exist
# if not, convert .deb files using alien tool

for arch in $(ls -1 $MAINDIR); do

    # redhat architecture logic

    if [ "$arch" == "amd64" ]; then
        altarch="x86_64"
    elif [ "$arch" == "arm64" ]; then
        altarch="aarch64"
    elif [ "$arch" == "armhf" ]; then
        altarch="armhfp"
    elif [ "$arch" == "i386" ]; then
        altarch="i386"
    fi

    for pkg in $(ls -1 $MAINDIR/$arch); do
        for deb in $(ls -1 $MAINDIR/$arch/$pkg/*.deb 2> /dev/null); do

            echo $filename
            filename=${deb/\.deb}
            rpm=$filename.rpm
            tgz=$filename.tgz

            # rpm

            if [ ! -f $rpm ]; then
                echo generating $rpm
                sudo alien --target=$altarch --to-rpm $deb 2>&1 > /dev/null 2>&1
                tempfile=$(ls -1 *.rpm 2>/dev/null)
                if [ -f $tempfile ]; then
                    mv $tempfile $filename.rpm
                else
                    getout "does $tempfile exist ?"
                fi
            else
                echo $rpm already exists
            fi

            # tgz

            if [ ! -f $tgz ]; then
                echo generating $tgz
                sudo alien --to-tgz $deb 2>&1 > /dev/null 2>&1
                tempfile=$(ls -1 *.tgz 2>/dev/null)
                if [ -f $tempfile ]; then
                    mv $tempfile $filename.tgz
                else
                    getout "does $tempfile exist ?"
                fi
            else
                echo $tgz already exists
            fi

        done
    done
done

cd $OLDDIR
if [ "$TEMPDIR" != "/tmp" ] && [ "$TEMPDIR" != "/tmp/" ]; then
    sudo rm -f $TEMPDIR
fi

lockup
