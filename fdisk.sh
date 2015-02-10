#!/bin/bash
#__author__ = 'mbugaiov'
#__version__ = "1.0"
# This script is developed for Linux QA Team. The main goal is to help QAs to perform
# everyday tasks more fuster.
# In this script we receive parameter from command line and perform some checks to make
# sure that device matches all our parameters.
# Script will create 3 primary partitions and 4 extended partitions. 6 from them will have
# the same size, which is equal to "disk_size / 7". Last one extended partition will fill up
# all available free space on disk. 
# In new vesrion will be added:
# - File system creation for partitions
# - Mount point creation
# - Mounting partitions
# - Addition "fstab" with information about new disks.


clear  # clear terminal window
device=$1
count=`echo $device | awk '{print length}'` >> /dev/null 2>&1

if [ `whoami` != "root" ]; then
	echo "This sciprt needs to be run as ROOT."
	exit 0
fi

if [ -z "$device" ]; then 
	echo "You need to specify the path to the device you want to partition."
	echo "Here is an example how to do it:"
	echo ""
	echo "./fdisk /path.to.the.disk"
	exit 0
elif [ "$count" != "8" ]; then
	echo "Device must be like "/dev/sdb" without partition number"
	exit 0
elif [ -b "$device" ]; then 
	echo $device " is device we have received from command line and is going to be partitioned";  
else
	echo $device " does not exist"
	exit 0
fi


sb=`echo $device | cut -c6-`;

partitionset=`cat /proc/partitions | grep $sb[1-9] | awk '{print $4}'`

partnumbers=`egrep -oh "sdb[1-9]" /proc/partitions | cut -c4-`;  

sizeinblocks=`cat /proc/partitions | grep -w sdb | awk '{print $3}'`

sizeinMB=`echo $sizeinblocks /1024 |bc`

partsize=`echo $sizeinMB / 7 | bc`

function fdisk_delete {
	for i in $partnumbers
	do
		(echo d; echo $i; echo w) | fdisk $device >> /dev/null 2>&1
		sleep 0.2;
		echo "Partition $device$i has been removed"
	done
}
fdisk_delete

function fdisk_create {
# will be created 3 primary partitions with the size 4GB
	for i in {1..3}
	do 
		(echo n; echo p; echo $i; echo ; echo "+"$partsize"M"; echo w) | fdisk $device >> /dev/null 2>&1
		sleep 0.2
		echo "Primary partition $device$i with the size $partsize"M" has been created"
	done
# extended partition with number 4 will be created. 
	(echo n; echo e; echo ; echo ; echo w) | fdisk $device >> /dev/null 2>&1
	for i in {5..7}
	do
		(echo n; echo ; echo "+"$partsize"M"; echo w) | fdisk $device >> /dev/null 2>&1
		sleep 0.2
		echo "Extended partition $device$i with the size $partsize"M" has been created."	
	done
	(echo n; echo ; echo ; echo w) | fdisk $device >> /dev/null 2>&1
}
fdisk_create

echo "Finish!"
