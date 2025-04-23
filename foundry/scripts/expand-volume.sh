#!/bin/bash
#
# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.
#
# Expand LVM logical volume and underlying ext4 filesystem

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

PV=/dev/sda3
LV=/dev/ubuntu-vg/ubuntu-lv

growpart $(sed -E "s/([0-9]+)$/ \1/" <<< $PV)
pvresize $PV
lvextend -l +100%FREE $LV
resize2fs $LV
