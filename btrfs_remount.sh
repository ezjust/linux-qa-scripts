#!/bin/bash
#For this test any device may be used, but device should be already formated.
device=$1
mp=`df -HT | grep $device | awk '{print $7}'`
echo $device $mp
before=`df -HT | grep $mp | awk '{print $1}'`
echo $before
bsctl -a $device
bsctl --create-data-store $device
bsctl --map-data-store $device
bsctl --map-metadata-store $device
bsctl --create-chlog-store $device
bsctl --map-chlog-store $device
bsctl -s $device
bsctl -l
after=`df -HT | grep $mp | awk '{print $1}'`
echo $after
if [ "$before" = "$after" ]; then
	echo "Issue with btrfs is fixed"
else
	echo "Issue IS STILL REPRODUCIBLE"
fi

