#!/bin/bash

which hugeadm 2>&1 > /dev/null || { echo "no hugeadm found"; exit 1; }

# disable transparent hugepages
hugeadm --thp-never

# INVESTIGATE:
#
# LD_PRELOAD=libheapshrink.so heapshrink (2M: 64):	PASS
# LD_PRELOAD=libheapshrink.so heapshrink (1024M: 64):	PASS
# LD_PRELOAD=libhugetlbfs.so HUGETLB_MORECORE=yes heapshrink (2M: 64):	PASS
# LD_PRELOAD=libhugetlbfs.so HUGETLB_MORECORE=yes heapshrink (1024M: 64):	PASS
# LD_PRELOAD=libhugetlbfs.so libheapshrink.so HUGETLB_MORECORE=yes heapshrink (2M: 64):	PASS
# LD_PRELOAD=libhugetlbfs.so libheapshrink.so HUGETLB_MORECORE=yes heapshrink (1024M: 64):	PASS
# LD_PRELOAD=libheapshrink.so HUGETLB_MORECORE_SHRINK=yes HUGETLB_MORECORE=yes heapshrink (2M: 64):	PASS (inconclusive)
# LD_PRELOAD=libheapshrink.so HUGETLB_MORECORE_SHRINK=yes HUGETLB_MORECORE=yes heapshrink (1024M: 64):	PASS (inconclusive)
# LD_PRELOAD=libhugetlbfs.so libheapshrink.so HUGETLB_MORECORE_SHRINK=yes HUGETLB_MORECORE=yes heapshrink (2M: 64):	FAIL	Heap did not shrink
# LD_PRELOAD=libhugetlbfs.so libheapshrink.so HUGETLB_MORECORE_SHRINK=yes HUGETLB_MORECORE=yes heapshrink (1024M: 64):FAIL	Heap did not shrink
#
# FROM:
#
# do_test("heapshrink")
# do_test("heapshrink", LD_PRELOAD="libheapshrink.so")
# do_test("heapshrink", LD_PRELOAD="libhugetlbfs.so", HUGETLB_MORECORE="yes")
# do_test("heapshrink", LD_PRELOAD="libhugetlbfs.so libheapshrink.so", HUGETLB_MORECORE="yes")
# do_test("heapshrink", LD_PRELOAD="libheapshrink.so", HUGETLB_MORECORE="yes", HUGETLB_MORECORE_SHRINK="yes")
# do_test("heapshrink", LD_PRELOAD="libhugetlbfs.so libheapshrink.so", HUGETLB_MORECORE="yes", HUGETLB_MORECORE_SHRINK="yes")
#

#export HUGETLB_VERBOSE=99

export NEWLINKER=/opt/libc6-preload/lib/ld-linux-x86-64.so.2

export LD_LIBRARY_PATH=/opt/libhugetlbfs/tests/obj64

sudo chmod +x $NEWLINKER

PROGRAM="/opt/libhugetlbfs/tests/obj64/heapshrink"
#PROGRAM="/opt/libhugetlbfs/tests/obj64/heap-overflow"

#PREFIX="$NEWLINKER --library-path /opt/libc6-preload/lib/x86_64-linux-gnu:/opt/libc6-preload/lib/:/lib:/lib/x86_64-linux-gnu/:/lib64"
PREFIX=""
PROGRAM="$PREFIX $PROGRAM"

# no libhugetlbfs being used
#
# $PROGRAM
# HUGETLB_MORECORE=yes $PROGRAM
# HUGETLB_MORECORE=yes HUGETLB_MORECORE_SHRINK=yes $PROGRAM

# libhugetlbfs shrink tests
#
# $PROGRAM
# LD_PRELOAD="libheapshrink.so" $PROGRAM
# LD_PRELOAD="libhugetlbfs.so" HUGETLB_MORECORE=yes $PROGRAM
# LD_PRELOAD="libhugetlbfs.so libheapshrink.so" HUGETLB_MORECORE=yes $PROGRAM
# LD_PRELOAD="libheapshrink.so" HUGETLB_MORECORE=yes HUGETLB_MORECORE_SHRINK=yes $PROGRAM
# LD_PRELOAD="libhugetlbfs.so libheapshrink.so" HUGETLB_MORECORE_SHRINK=yes HUGETLB_MORECORE=yes $PROGRAM

# WORKAROUND (or fix ?)

# export GLIBC_TUNABLES=glibc.malloc.tcache_count=0

# REAL SHRINK TEST
LD_PRELOAD="libhugetlbfs.so libheapshrink.so" HUGETLB_MORECORE=yes HUGETLB_MORECORE_SHRINK=yes $PROGRAM
# LD_PRELOAD="libhugetlbfs.so" HUGETLB_MORECORE=1G $PROGRAM
