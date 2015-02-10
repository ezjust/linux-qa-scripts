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
echo $device is device
count=`echo $device | awk '{print length}'` >> /dev/null 2>&1
echo $count is count
null=` >> /dev/null 2>&1`
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
echo $sb is sb

sed -i "/^\/dev\/$sb/d" /etc/fstab ## removing string in fstab, matched by $device


partitionset=`cat /proc/partitions | grep $sb[1-9] | awk '{print $4}'`
echo $partitionset is partitionset
partnumbers=`egrep -oh "sdb[1-9]" /proc/partitions | cut -c4-`;  
echo $partnumbers is purtnumbers
sizeinblocks=`cat /proc/partitions | grep -w $sb | awk '{print $3}'`
echo $sizeinblocks is sizeinblocks
sizeinMB=`echo $sizeinblocks /1024 |bc`
echo $sizeinMB is size in MB
partsize=`echo $sizeinMB / 7 | bc`
echo $partsize is partsize
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

echo "Finish! FDISK!"

function makefolder {
	for i in $partitionset
	do
		if [ ! -d "/mnt/$i" ]; then
			mkdir /mnt/$i
		fi

	done
	echo "Mount points were created/updated"
}
makefolder
echo FOLDERS CREATED
function umountpart {
	for i in $partitionset
	do
		umount "/dev/"$i >> /dev/null 2>&1
	done
}
umountpart
echo UMOUNT PASSED
function mountpart {
	for i in $partitionset
	do
		echo  mount "/dev/"$i "/mnt/"$i
		mount "/dev/"$i "/mnt/"$i #>> /dev/null 2>&1
	done
}


function makefs {
makefsset=('ext3' 'ext4' 'xfs')
makepartset=( $partitionset )
echo ${makepartset[0]}
mkfs.${makefsset[0]} /dev/${makepartset[0]} #>> /dev/null 2>&1
sleep 0.2
mkfs.${makefsset[1]} /dev/${makepartset[1]} #>> /dev/null 2>&1
sleep 0.2
mkfs.${makefsset[2]} /dev/${makepartset[2]} #>> /dev/null 2>&1
sleep 0.2
mkfs.${makefsset[0]} /dev/${makepartset[4]} #>> /dev/null 2>&1
sleep 0.2
mkfs.${makefsset[1]} /dev/${makepartset[5]} #>> /dev/null 2>&1
sleep 0.2
mkfs.${makefsset[2]} /dev/${makepartset[6]} #>> /dev/null 2>&1
sleep 0.2
mkfs.${makefsset[0]} /dev/${makepartset[7]} #>> /dev/null 2>&1
echo "File systems have been created."
}

function fstab {
makefsset=('ext3' 'ext4' 'xfs')
makepartset=( $partitionset )
echo "/dev/${makepartset[0]}" "/mnt/${makepartset[0]}" "${makefsset[0]}" "defaults" "0" "2" >> /etc/fstab
echo "/dev/${makepartset[1]}" "/mnt/${makepartset[1]}" "${makefsset[1]}" "defaults" "0" "2" >> /etc/fstab
echo "/dev/${makepartset[2]}" "/mnt/${makepartset[2]}" "${makefsset[2]}" "defaults" "0" "2" >> /etc/fstab
echo "/dev/${makepartset[4]}" "/mnt/${makepartset[4]}" "${makefsset[0]}" "defaults" "0" "2" >> /etc/fstab
echo "/dev/${makepartset[5]}" "/mnt/${makepartset[5]}" "${makefsset[1]}" "defaults" "0" "2" >> /etc/fstab
echo "/dev/${makepartset[6]}" "/mnt/${makepartset[6]}" "${makefsset[2]}" "defaults" "0" "2" >> /etc/fstab
echo "/dev/${makepartset[7]}" "/mnt/${makepartset[7]}" "${makefsset[0]}" "defaults" "0" "2" >> /etc/fstab
}



makefs
echo MAKEFS
mountpart
echo MOUNTPART
fstab
echo FSTAB
echo "All tasks COMPLETED."

