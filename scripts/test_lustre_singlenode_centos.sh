#!/bin/bash

# See Whamcloud's JIRA LU-10424 card
truncate --size=64M /tmp/lustre-{mdt1,ost1,ost2}

sudo FSTYPE=zfs /usr/lib64/lustre/tests/llmount.sh
sudo FSTYPE=zfs /usr/lib64/lustre/tests/llmountcleanup.sh
