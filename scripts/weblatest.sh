#!/bin/bash

MAINDIR="/var/www/html"


getout() {
    echo ERROR: $@
    exit 1
}

[ ! -d $MAINDIR ] && getout "no maindir found"

OLDDIR=$PWD
cd $MAINDIR

[ ! -d latest ] && mkdir latest
rm -rf latest/* && mkdir latest/all
ln -s ../README.txt latest/README.txt
ln -s ../HEADER.txt latest/HEADER.txt

# http://xxx/latest/arch/pkg/yyy.{deb,rpm,txz}
# http://xxx/latest/all/pkg/yyy.{deb,rpm,txz}

for arch in $(ls -1 | grep -v latest | grep -v all | grep -v shared | grep -v \.txt); do

    mkdir latest/$arch

    [ ! -f latest/$arch/README.txt ] && ln -s ../README.txt latest/$arch/README.txt
    [ ! -f latest/$arch/HEADER.txt ] && ln -s ../HEADER.txt latest/$arch/HEADER.txt

    for pkg in $(ls $arch | grep -v kselftest | grep -v \.txt); do

        mkdir latest/$arch/$pkg

        [ ! -f latest/$arch/$pkg/README.txt ] && ln -s ../../../README.txt latest/$arch/$pkg/README.txt
        [ ! -f latest/$arch/$pkg/HEADER.txt ] && ln -s ../../../HEADER.txt latest/$arch/$pkg/HEADER.txt

        [ ! -d latest/all/$pkg ] && mkdir latest/all/$pkg

        [ ! -f latest/all/README.txt ] && ln -s ../../README.txt latest/all/README.txt
        [ ! -f latest/all/HEADER.txt ] && ln -s ../../HEADER.txt latest/all/HEADER.txt

        [ ! -f latest/all/$pkg/README.txt ] && ln -s ../../README.txt latest/all/$pkg/README.txt
        [ ! -f latest/all/$pkg/HEADER.txt ] && ln -s ../../HEADER.txt latest/all/$pkg/HEADER.txt

        deb=$(ls -t1 $arch/$pkg/*.deb 2> /dev/null | head -1)
        rpm=$(ls -t1 $arch/$pkg/*.rpm 2> /dev/null | head -1)
        txz=$(ls -t1 $arch/$pkg/*.txz 2> /dev/null | head -1)

        [ $deb ] && ln -s ../../../$deb ./latest/$arch/$pkg/$(basename $deb)
        [ $rpm ] && ln -s ../../../$rpm ./latest/$arch/$pkg/$(basename $rpm)
        [ $txz ] && ln -s ../../../$txz ./latest/$arch/$pkg/$(basename $txz)

        [ $deb ] && ln -s ../../../$deb ./latest/all/$pkg/$(basename $deb)
        [ $rpm ] && ln -s ../../../$rpm ./latest/all/$pkg/$(basename $rpm)
        [ $txz ] && ln -s ../../../$txz ./latest/all/$pkg/$(basename $txz)

    done
done

mkdir -p latest/all/kselftest

ln -s ../../../README.txt latest/all/kselftest/README.txt
ln -s ../../../HEADER.txt latest/all/kselftest/HEADER.txt

for arch in $(ls -1 | grep -v latest | grep -v all | grep -v shared | grep -v \.txt); do

    PKGS=""
    PKGS+=" $(ls -1t $arch/kselftest/*v4.17*.txz | head -1)"
    PKGS+=" $(ls -1t $arch/kselftest/*v4.18.*.txz | head -1)"
    PKGS+=" $(ls -1t $arch/kselftest/*v4.18-*.txz | head -1)"
    PKGS+=" $(ls -1t $arch/kselftest/*v4.14.*.txz | head -1)"
    PKGS+=" $(ls -1t $arch/kselftest/*next-*.txz | head -1)"

    mkdir latest/$arch/kselftest

    [ ! -f latest/$arch/kselftest/README.txt ] && ln -s ../../../README.txt latest/$arch/kselftest/README.txt
    [ ! -f latest/$arch/kselftest/HEADER.txt ] && ln -s ../../../HEADER.txt latest/$arch/kselftest/HEADER.txt

    for pkg in $PKGS; do

        txz=$(ls $pkg 2> /dev/null | head -1)
        deb=$(ls ${pkg/\.txz}.deb 2> /dev/null | head -1)
        rpm=$(ls ${pkg/\.txz}.rpm 2> /dev/null | head -1)

        [ ! -f latest/$arch/kselftest/README.txt ] && ln -s ../../../README.txt latest/$arch/kselftest/README.txt
        [ ! -f latest/$arch/kselftest/HEADER.txt ] && ln -s ../../../HEADER.txt latest/$arch/kselftest/HEADER.txt

        [ $deb ] && ln -s ../../../$deb ./latest/$arch/kselftest/$(basename $deb)
        [ $rpm ] && ln -s ../../../$rpm ./latest/$arch/kselftest/$(basename $rpm)
        [ $txz ] && ln -s ../../../$txz ./latest/$arch/kselftest/$(basename $txz)

        [ $deb ] && ln -s ../../../$deb ./latest/all/kselftest/$(basename $deb)
        [ $rpm ] && ln -s ../../../$rpm ./latest/all/kselftest/$(basename $rpm)
        [ $txz ] && ln -s ../../../$txz ./latest/all/kselftest/$(basename $txz)

    done
done

# http://xxx/arch/pkg/yyy.{deb,rpm,txz}
# http://xxx/all/pkg/yyy.{deb,rpm,txz}

[ ! -d all ] && mkdir all
rm -rf all/*

ln -s ../README.txt all/README.txt
ln -s ../HEADER.txt all/HEADER.txt

for arch in $(ls -1 | grep -v latest | grep -v all | grep -v shared | grep -v \.txt); do

    for pkg in $(ls -1 $arch | grep -v txt | xargs); do

        [ ! -d all/$pkg ] && mkdir all/$pkg

        [ ! -f all/$pkg/README.txt ] && ln -s ../../README.txt all/$pkg/README.txt
        [ ! -f all/$pkg/HEADER.txt ] && ln -s ../../HEADER.txt all/$pkg/HEADER.txt

        deb=$(ls -1 $arch/$pkg/*.deb 2> /dev/null)
        rpm=$(ls -1 $arch/$pkg/*.rpm 2> /dev/null)
        txz=$(ls -1 $arch/$pkg/*.txz 2> /dev/null)

        for d in $deb; do ln -s ../../$d ./all/$pkg/$(basename $d); done
        for r in $rpm; do ln -s ../../$r ./all/$pkg/$(basename $r); done
        for t in $txz; do ln -s ../../$t ./all/$pkg/$(basename $t); done

    done

done

cd $OLDDIR
