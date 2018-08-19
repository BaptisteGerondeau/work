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

# http://xxx/latest/arch/pkg/yyy.{deb,rpm,txz}
# http://xxx/latest/all/pkg/yyy.{deb,rpm,txz}

for arch in $(ls -1 | grep -v latest | grep -v all); do

    mkdir latest/$arch

    for pkg in $(ls $arch); do

        mkdir latest/$arch/$pkg

        [ ! -d latest/all/$pkg ] && mkdir latest/all/$pkg

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

# http://xxx/arch/pkg/yyy.{deb,rpm,txz}
# http://xxx/all/pkg/yyy.{deb,rpm,txz}

[ ! -d all ] && mkdir all
rm -rf all/*

for arch in $(ls -1 | grep -v latest | grep -v all); do

    for pkg in $(ls $arch); do

        [ ! -d all/$pkg ] && mkdir all/$pkg

        deb=$(ls -1 $arch/$pkg/*.deb 2> /dev/null)
        rpm=$(ls -1 $arch/$pkg/*.rpm 2> /dev/null)
        txz=$(ls -1 $arch/$pkg/*.txz 2> /dev/null)

        for d in $deb; do ln -s ../../$d ./all/$pkg/$(basename $d); done
        for r in $rpm; do ln -s ../../$r ./all/$pkg/$(basename $r); done
        for t in $txz; do ln -s ../../$t ./all/$pkg/$(basename $t); done

    done

done

cd $OLDDIR
