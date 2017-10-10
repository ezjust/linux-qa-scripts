#!/bin/bash
#set -x
configuration=$1
disks=$2
ext2_min_version="3.6"
ignore="/dev/null 2>&1"

if [[ "$configuration" != "--create" && "$configuration" != "--clean" ]]; then
tput setaf 1;	echo "You have not specified available options:"; tput sgr0
		echo ""
tput setaf 2;   echo "--create  -   to create default configuration scheme for testing"; tput sgr0
		echo 	EXAMPLE :   ./configuration.sh --create /dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
		echo 	NOTE    :   You need to specify 5 disks in one row, devided by "","" without using spaces.
		echo ""
tput setaf 3;	echo "--clean   -   to clean up default configuration scheme for testing"; tput sgr0
		echo 	EXAMPLE :   ./configuration.sh --clean /dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
		echo ""
		echo "Default partition is shown below. Please note, that script will use disks from the command line.
That is why, instead of sdb, sdc, sdd, sde, sdf script will use disks you have provided."
		echo "Please note, that this script has been tested under following OS:
		     - Ubuntu 16.10 - passed
		     - Ubuntu 16.04 - passed
		     - Oracle 7.1   - passed
		     - Ubuntu 12.04 - failed  - lvm2 has old version"
		echo "

		     "
	exit 1
fi


function activate_disks {
    	for i in `ls /sys/class/scsi_host/`; do
       		exists=`grep mpt /sys/class/scsi_host/$i/proc_name`
		if [[ ! -z $exists ]]; then
			echo "- - -" > /sys/class/scsi_host/$i/scan
		fi
	done
}

activate_disks


if [ "`rpm -? >> /dev/null 2>&1; echo $?`" == "0" ]; then
	pacman="rpm -qa"
else
	pacman="dpkg --list"
fi

if [[ "`$pacman | grep lvm2 >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep bl >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep btrfs >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep xfsprogs >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep mdadm >> /dev/null; echo $?`" -ne "0" ]]; then
	echo "Not all packages are installed: lvm2, mdadm, btrfs-progs, xfsprogs, bc"
	echo ""
	$pacman | grep -w 'lvm2\|mdadm\|btrfs-progs\|xfsprogs\|bc'
	exit 1
fi

if [[ -n "${disks}"   ]]; then
	IFS_OLD=$IFS
	IFS=","; declare -a disks=($2)
	IFS=$IFS_OLD
fi

if [[ -z "${disks[0]}" || -z "${disks[1]}" || -z "${disks[2]}" || -z "${disks[3]}" || -z "${disks[4]}" ]] && [[ "$configuration" == "--create" ]]; then
        echo "You have not specified all 5 needed disks for default partition creation. You have the following disks:"
	    echo "${disks[0]}"
        echo "${disks[1]}"
        echo "${disks[2]}"
        echo "${disks[3]}"
        echo "${disks[4]}"
        exit 1
fi

#disk1="${disks[0]}" >> $ignore
#disk1_size=$(fdisk -l "$disk1" | grep Disk | awk '{print $5}') >> $ignore
#disk1_=$(echo $disk1 | cut -d"/" -f3)
#disk1_sectors=$(cat /sys/block/$disk1_/size)  >> $ignore
#disk1_partition_sectors="$(($disk1_sectors/7))" >> $ignore
#disk2=${disks[1]} >> $ignore
#disk2_size=$(fdisk -l $disk2 | grep Disk | awk '{print $5}') >> $ignore
#disk2_=$(echo $disk2 | cut -d"/" -f3)
#disk2_sectors=$(cat /sys/block/$disk2_/size)  >> $ignore
#disk2_partition_sectors=$(($disk2_sectors/7)) >> $ignore
#disk3=${disks[2]} >> $ignore
#disk3_size=$(fdisk -l $disk3 | grep Disk | awk '{print $5}') >> $ignore
#disk3_=$(echo $disk3 | cut -d"/" -f3)
#disk3_sectors=$(cat /sys/block/$disk3_/size)  >> $ignore
#disk3_partition_sectors=$(($disk3_sectors/7)) >> $ignore
#disk4=${disks[3]} >> $ignore
#disk4_size=$(fdisk -l $disk4 | grep Disk | awk '{print $5}') >> $ignore
#disk4_=$(echo $disk4 | cut -d"/" -f3)
#disk4_sectors=$(cat /sys/block/$disk4_/size)  >> $ignore
#disk4_partition_sectors=$(($disk4_sectors/7)) >> $ignore
#disk5=${disks[4]} >> $ignore
#disk5_size=$(fdisk -l $disk5 | grep Disk | awk '{print $5}') >> $ignore
#disk5_=$(echo $disk5 | cut -d"/" -f3)
#disk5_sectors=$(cat /sys/block/$disk5_/size)  >> $ignore
#disk5_partition_sectors=$(($disk5_sectors/7)) >> $ignore



size=()
disk_size=()
for i in ${disks[@]}
    do
        disk_cut=$(echo $i | cut -d"/" -f3)
        capacity=`cat /sys/block/$disk_cut/size`
	block_size=`cat /sys/block/sdb/queue/physical_block_size`
        disk_size+=(`cat /sys/block/$disk_cut/size`)
        partition_size=$(($capacity*$block_size/1024/7))
        #echo partition size is : $partition_size
        size+=($partition_size)
    done

if [[ -n "${disks}" && "$configuration" == "--clean" ]]; then

umount /mnt/$(echo ${disks[0]}1 | cut -d"/" -f3)_ext3
rm -rf /mnt/$(echo ${disks[0]}1 | cut -d"/" -f3)_ext3
umount /mnt/$(echo ${disks[0]}2 | cut -d"/" -f3)_ext4
rm -rf /mnt/$(echo ${disks[0]}2 | cut -d"/" -f3)_ext4
umount /mnt/$(echo ${disks[0]}3 | cut -d"/" -f3)_xfs
rm -rf /mnt/$(echo ${disks[0]}3 | cut -d"/" -f3)_xfs
umount /mnt/$(echo ${disks[0]}5 | cut -d"/" -f3)_ext2
rm -rf /mnt/$(echo ${disks[0]}5 | cut -d"/" -f3)_ext2
umount /mnt/$(echo ${disks[0]}6 | cut -d"/" -f3)_btrfs
rm -rf /mnt/$(echo ${disks[0]}6 | cut -d"/" -f3)_btrfs
umount /mnt/$(echo ${disks[0]}7 | cut -d"/" -f3)_ext4_unaligned
rm -rf /mnt/$(echo ${disks[0]}7 | cut -d"/" -f3)_ext4_unaligned

umount /mnt/linear_xfs
rm -rf /mnt/linear_xfs
umount /mnt/linear_ext4
rm -rf /mnt/linear_ext4
umount /mnt/striped_xfs
rm -rf /mnt/striped_xfs
umount /mnt/striped_ext4
rm -rf /mnt/striped_ext4
umount /mnt/mirrored_xfs
rm -rf /mnt/mirrored_xfs
umount /mnt/mirrored_ext4
rm -rf /mnt/mirrored_ext4
umount /mnt/mirror_separate
rm -rf /mnt/mirror_separate

umount /mnt/md0-linear_0
rm -rf /mnt/md0-linear_0
umount /mnt/md0-stripe_0
rm -rf /mnt/md0-stripe_0
umount /mnt/md0-mirror_0
rm -rf /mnt/md0-mirror_0
umount /mnt/md5p1
rm -rf /mnt/md5p1


wipefs -a /dev/linear_xfs/linear_xfs
lvremove -f /dev/linear_xfs/linear_xfs
wipefs -a /dev/linear_ext4/linear_ext4
lvremove -f /dev/linear_ext4/linear_ext4
wipefs -a /dev/striped_xfs/striped_xfs
lvremove -f /dev/striped_xfs/striped_xfs
wipefs -a /dev/striped_ext4/striped_ext4
lvremove -f /dev/striped_ext4/striped_ext4
wipefs -a /dev/mirrored_xfs/mirrored_xfs
lvremove -f /dev/mirrored_xfs/mirrored_xfs
wipefs -a /dev/mirrored_ext4/mirrored_ext4
lvremove -f /dev/mirrored_ext4/mirrored_ext4
wipefs -a /dev/mirror_separate/mirror_separate
lvremove -f /dev/mirror_separate/mirror_separate

vgremove -f linear_xfs
vgremove -f linear_ext4
vgremove -f striped_xfs
vgremove -f striped_ext4
vgremove -f mirrored_xfs
vgremove -f mirrored_ext4
vgremove -f mirror_separate


mdadm --stop /dev/md/md0-linear_0
mdadm --zero-superblock ${disks[3]}1 ${disks[4]}1
wipefs -a ${disks[3]}1
wipefs -a ${disks[4]}1
mdadm --remove /dev/md/md0-linear_0



mdadm --stop /dev/md/md0-stripe_0
mdadm --zero-superblock ${disks[3]}2 ${disks[4]}2
wipefs -a ${disks[3]}2
wipefs -a ${disks[4]}2
mdadm --remove /dev/md/md0-stripe_0


mdadm --stop /dev/md/md0-mirror_0
mdadm --zero-superblock ${disks[3]}3 ${disks[4]}3
wipefs -a ${disks[3]}3
wipefs -a ${disks[4]}3
mdadm --remove /dev/md/md0-mirror_0

(echo d; echo w;) | fdisk /dev/md/md5p1
mdadm --stop /dev/md/md5p1
mdadm --zero-superblock ${disks[3]}5 ${disks[4]}5
wipefs -a ${disks[3]}5
wipefs -a ${disks[4]}5
mdadm --remove /dev/md/md5
(echo d; echo w;) | fdisk /dev/md/md5


sed -i.bak '/linear_0\|stripe_0\|mirror_0\|md5/d' /etc/mdadm/mdadm.conf
sed -i.bak '/linear_0\|stripe_0\|mirror_0\|md5/d' /etc/mdadm.conf
partprobe

	for i in {1..8}
	do

		(echo d; echo $i; echo w;) | fdisk ${disks[0]} >> /dev/null 2>&1
                sleep 0.2
		wipefs -a ${disks[0]}$i
                #umount $disk2$i
                (echo d; echo $i; echo w;) | fdisk ${disks[1]} >> /dev/null 2>&1
                sleep 0.2
		wipefs -a ${disks[1]}$i
		#umount $disk3$i
	        (echo d; echo $i; echo w;) | fdisk ${disks[2]} >> /dev/null 2>&1
        	sleep 0.2
		wipefs -a ${disks[2]}$i
		#umount $disk4$i
		(echo d; echo $i; echo w;) | fdisk ${disks[3]} >> /dev/null 2>&1
	        sleep 0.2
		wipefs -a ${disks[3]}$i
		#umount $disk5$i
		(echo d; echo $i; echo w;) | fdisk ${disks[4]} >> /dev/null 2>&1
        	sleep 0.2
		wipefs -a ${disks[4]}$i
	done

sed -i.bak '/_ext2\|_ext3\|_ext4\|_xfs\|_btrfs\|-linear_0\|-stripe_0\|-mirror_0\|_separate\|partition-ext4/d' /etc/fstab


partprobe >> /dev/null 2>&1

echo "Clean has been completed"

exit 0

fi




if [[ "${disk_size[0]}" < "10737418240" || "${disk_size[1]}" < "10737418240" || "${disk_size[2]}" < "10737418240" || "${disk_size[3]}" < "10737418240" || "${disk_size[4]}" < "10737418240" ]]; then
	echo "Not all disks have needed size : 10737418240"
	echo ""
	echo ${disks[0]} : ${disk_size[0]}
	echo ${disks[1]} : ${disk_size[1]}
	echo ${disks[2]} : ${disk_size[2]}
	echo ${disks[3]} : ${disk_size[3]}
	echo ${disks[4]} : ${disk_size[4]}
	exit 1
fi

function disk_primary_partitions_create {
	declare -A disk_partition_sectors=();
	disk_partition_sectors[1]="${size[0]}";
	disk_partition_sectors[2]="${size[1]}";
	disk_partition_sectors[3]="${size[2]}";
	disk_partition_sectors[4]="${size[3]}";
	disk_partition_sectors[5]="${size[4]}";

	declare -A disk=();
	disk[1]="${disks[0]}"
	disk[2]="${disks[1]}"
   	disk[3]="${disks[2]}"
	disk[4]="${disks[3]}"
	disk[5]="${disks[4]}"
#	echo "===================================="
#	echo ${disk_partition_sectors[1]}
#	echo ${disk_partition_sectors[2]}
#        echo ${disk_partition_sectors[3]}
#        echo ${disk_partition_sectors[4]}
#        echo ${disk_partition_sectors[5]}

	for m in 1 2 3
	do
		for i in {1..3}
		do
			#echo "${disk_partition_sectors[$m]}"
			(echo n; echo p; echo $i; echo ; echo "+""${disk_partition_sectors[$m]}""K"; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
			sleep 0.2

		done

		(echo n; echo e; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1

		for i in {5..7}
		do
			(echo n; echo ; echo "+""${disk_partition_sectors[$m]}""K"; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
			sleep 0.5
		done

		(echo n; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
	done
}


disk_primary_partitions_create

function lvm_partitions_create {
	declare -A disk=();
        disk[1]="${disks[0]}"
	disk[2]="${disks[1]}"
	disk[3]="${disks[2]}"
	disk[4]="${disks[3]}"
        disk[5]="${disks[4]}"


	pvcreate  "${disk[2]}1" "${disk[3]}1"
	vgcreate linear_xfs "${disk[2]}1" "${disk[3]}1"
	lvcreate -Zy -l 100%VG -n linear_xfs linear_xfs
	wipefs -a /dev/linear_xfs/linear_xfs
	linear_xfs=/dev/linear_xfs/linear_xfs
	mkdir /mnt/linear_xfs; linear_xfs_mp=/mnt/linear_xfs
	sleep 0.2
	mkfs.xfs -f /dev/linear_xfs/linear_xfs
	mount $linear_xfs $linear_xfs_mp

	pvcreate  "${disk[2]}5" "${disk[3]}5"
	vgcreate linear_ext4 "${disk[2]}5" "${disk[3]}5"
	lvcreate -Zy -l 100%VG -n linear_ext4 linear_ext4
	wipefs -a /dev/linear_ext4/linear_ext4
	linear_ext4=/dev/linear_ext4/linear_ext4
	mkdir /mnt/linear_ext4; linear_ext4_mp=/mnt/linear_ext4
	sleep 0.2
	mkfs.ext4 -F /dev/linear_ext4/linear_ext4
	mount $linear_ext4 $linear_ext4_mp

	pvcreate  "${disk[2]}2" "${disk[3]}2"
	vgcreate striped_xfs "${disk[2]}2" "${disk[3]}2"
	lvcreate -Zy -l 100%VG -i2 -I64 -n striped_xfs striped_xfs
	striped_xfs=/dev/striped_xfs/striped_xfs
	wipefs -a "$striped_xfs"
	mkdir /mnt/striped_xfs; striped_xfs_mp=/mnt/striped_xfs
	sleep 0.2
	mkfs.xfs -f /dev/striped_xfs/striped_xfs
	mount $striped_xfs $striped_xfs_mp

	pvcreate  "${disk[2]}6" "${disk[3]}6"
	vgcreate striped_ext4 "${disk[2]}6" "${disk[3]}6"
	lvcreate -Zy -l 100%VG -i2 -I64 -n striped_ext4 striped_ext4
	striped_ext4=/dev/striped_ext4/striped_ext4
	wipefs -a "$striped_ext4"
	mkdir /mnt/striped_ext4; striped_ext4_mp=/mnt/striped_ext4
	sleep 0.2
	mkfs.ext4 -F /dev/striped_ext4/striped_ext4
	mount $striped_ext4 $striped_ext4_mp

	pvcreate  "${disk[2]}3" "${disk[3]}3"
	vgcreate mirrored_xfs "${disk[2]}3" "${disk[3]}3"
	lvcreate -Zy -l 100%VG -m1 -n mirrored_xfs mirrored_xfs
	mirrored_xfs_exit_code=$(lvcreate -Zy -l 100%VG -m1 -n mirrored_xfs mirrored_xfs >> /dev/null 2>&1; echo $?)
        if [[ "$mirrored_xfs_exit_code" -eq "5" ]]; then
                lvcreate -Zy -l 50%VG -m1 --mirrorlog core -n mirrored_xfs mirrored_xfs
        fi
        mirrored_xfs=/dev/mirrored_xfs/mirrored_xfs
	wipefs -a "$mirrored_xfs"
	mkdir /mnt/mirrored_xfs; mirrored_xfs_mp=/mnt/mirrored_xfs
	sleep 0.2
	mkfs.xfs -f /dev/mirrored_xfs/mirrored_xfs
	mount $mirrored_xfs $mirrored_xfs_mp

	pvcreate  "${disk[2]}7" "${disk[3]}7"
	vgcreate mirrored_ext4 "${disk[2]}7" "${disk[3]}7"
	lvcreate -Zy -l 100%VG -m1 -n mirrored_ext4 mirrored_ext4
	mirrored_ext4_exit_code=$(lvcreate -Zy -l 100%VG -m1 -n mirrored_ext4 mirrored_ext4 >> /dev/null 2>&1; echo $?)
    	if [[ "$mirrored_ext4_exit_code" -eq "5" ]]; then
	        lvcreate -Zy -l 50%VG -m1 --mirrorlog core  -n mirrored_ext4 mirrored_ext4
	fi
	mirrored_ext4=/dev/mirrored_ext4/mirrored_ext4
	wipefs -a "$mirrored_ext4"
	mkdir /mnt/mirrored_ext4; mirrored_ext4_mp=/mnt/mirrored_ext4
	sleep 0.2
	mkfs.ext4 -F /dev/mirrored_ext4/mirrored_ext4
	mount $mirrored_ext4 $mirrored_ext4_mp

	#pvcreate "${disk[5]}5" "${disk[5]}6"
	echo "=================================================================="
	vgcreate mirror_separate "${disk[1]}8" "${disk[4]}7" "${disk[5]}7"
	lvcreate --type mirror -l 100%VG -m 1 -n mirror_separate mirror_separate
	mirror_separate_exit_code=$(lvcreate --type mirror -l 49%VG -m 1 -n mirror_separate mirror_separate >> /dev/null 2>&1; echo $?)
	if [[ "$mirror_separate_exit_code" -eq "5" ]]; then
        	lvcreate --type mirror -l 33%VG -m 1 -n mirror_separate mirror_separate
	fi
	wipefs -a /dev/mirror_separate/mirror_separate >> /dev/null 2>&1;
	mkdir /mnt/mirror_separate
	sleep 0.2
	mkfs.ext4 -F /dev/mirror_separate/mirror_separate
	mount /dev/mirror_separate/mirror_separate /mnt/mirror_separate
	echo "------------------------------------------------------------------"
}

function mkfs_primary_first_disk {

declare -A disk=();
	disk[1]="${disks[0]}"
	mkfs.ext3 -F "${disk[1]}1"
	mkdir /mnt/$(echo "${disk[1]}1" | cut -d"/" -f3)_ext3
	mount "${disk[1]}1" /mnt/$(echo "${disk[1]}1" | cut -d"/" -f3)_ext3


	mkfs.ext4 -F "${disk[1]}2"
	mkdir /mnt/$(echo "${disk[1]}2" | cut -d"/" -f3)_ext4
	mount "${disk[1]}2" /mnt/$(echo "${disk[1]}2" | cut -d"/" -f3)_ext4


	mkfs.xfs -f "${disk[1]}3"
	mkdir /mnt/$(echo "${disk[1]}3" | cut -d"/" -f3)_xfs
	mount "${disk[1]}3" /mnt/$(echo "${disk[1]}3" | cut -d"/" -f3)_xfs

    	kernel=`uname -r | cut -c1-3`
    	result=`echo $kernel'>'$ext2_min_version | bc -l`

    	if [ "$result" != "0" ]; then
	    mkfs.ext2 -F "${disk[1]}5"
	    mkdir /mnt/$(echo "${disk[1]}5" | cut -d"/" -f3)_ext2
	    mount "${disk[1]}5" /mnt/$(echo "${disk[1]}5" | cut -d"/" -f3)_ext2
	else
	    tput setaf 3; echo "mount of the ext2 partition is skipped. We do not support it for kernels less $ext2_min_version"; tput sgr0
    	fi

	mkfs.btrfs -f "${disk[1]}6"
	mkdir /mnt/$(echo "${disk[1]}6" | cut -d"/" -f3)_btrfs
	mount -o nodatasum,nodatacow,device="${disk[1]}6" "${disk[1]}6" /mnt/$(echo "${disk[1]}6" | cut -d"/" -f3)_btrfs


	mkfs.ext4 -b 2052 -F "${disk[1]}7"
	mkdir /mnt/$(echo "${disk[1]}7" | cut -d"/" -f3)_ext4_unaligned
	mount "${disk[1]}7" /mnt/$(echo "${disk[1]}7" | cut -d"/" -f3)_ext4_unaligned
}

mkfs_primary_first_disk


raid_partition() {


declare -A disk_partition_sectors=();
disk_partition_sectors[4]="${size[3]}";
disk_partition_sectors[5]="${size[4]}";

declare -A disk=();
disk[4]="${disks[3]}"
disk[5]="${disks[4]}"
for m in 4 5
do
	for i in {1..3}
	do
		#echo "${disk_partition_sectors[$m]}"
		(echo n; echo p; echo $i; echo ; echo "+""${disk_partition_sectors[$m]}""K"; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
		sleep 0.5

	done
	(echo n; echo e; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
	for i in {5..7}
	do
		(echo n; echo ; echo "+""${disk_partition_sectors[$m]}""K"; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
		sleep 0.5
	done

	(echo n; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
done
partprobe

for i in 1 2 3 5
do
    wipefs -a ${disks[3]}$i
    wipefs -a ${disks[4]}$i
    mdadm --zero-superblock ${disks[3]}$i ${disks[4]}$i
done

mdadm --create --verbose /dev/md/md0-linear_0 --level=linear --raid-devices=2 ${disks[3]}1 ${disks[4]}1
if [ -b /dev/md/md0-linear_0 ]; then
	mdadm --assemble --verbose /dev/md/md0-linear_0 ${disks[3]}1 ${disks[4]}1
	mkdir /mnt/md0-linear_0
else
	echo /dev/md/md0-linear_0 was not created. Skipped assemble of this device.
fi

partprobe
mdadm --create /dev/md/md0-stripe_0 --level=stripe --raid-devices=2 ${disks[3]}2 ${disks[4]}2

if [ -b /dev/md/md0-stripe_0 ]; then
	mdadm --assemble --verbose /dev/md/md0-stripe_0 ${disks[3]}2 ${disks[4]}2
	mkdir /mnt/md0-stripe_0
else
	echo /dev/md/md0-stripe_0 was not created. Skipped assemble of this device
fi

partprobe
yes | mdadm --create /dev/md/md0-mirror_0 --level=mirror --raid-devices=2 ${disks[3]}3 ${disks[4]}3

if [ -b /dev/md/md0-mirror_0 ]; then
	mdadm --assemble /dev/md/md0-mirror_0 ${disks[3]}3 ${disks[4]}3
	mkdir /mnt/md0-mirror_0
else
	echo /dev/md/md0-mirror_0 was not created. Skipped assemble of this device
fi


yes | mdadm --create --verbose /dev/md/md5 --level=1 --raid-devices=2 ${disks[3]}5 ${disks[4]}5
if [ -b /dev/md/md5 ]; then
        (echo n; echo p; echo 1; echo ; echo ; echo w) | fdisk /dev/md/md5
	mkdir /mnt/md5p1
else
        echo /dev/md/md5 was not created. Skipped assemble of this device.
fi





mdadm --detail --scan >> /etc/mdadm/mdadm.conf
mdadm --detail --scan >> /etc/mdadm.conf

echo "========================="
data=($(ls -l /dev/md | grep ^lrw | awk '{print $9}'))
for array in ${data[@]}; do
	if [ "$array" != "md5"]; then
		mkfs.ext4 -F /dev/md/$array
	        mount /dev/md/$array /mnt/$array
	fi
done
}
raid_partition
lvm_partitions_create



function fstab {
IFS_OLD=$IFS
IFS=$'\n'
set -o noglob
fstab=($(cat /proc/mounts | grep '_ext2\|_ext3\|_ext4\|_xfs\|_btrfs\|-linear_0\|-stripe_0\|_separate\|-mirror_0\|partition-ext4\|md5p1' | awk '{print $1,$2,$3}'))
for ((i = 0; i < ${#fstab[@]}; i++)); do
	echo ${fstab[$i]} defaults 0 0 >> /etc/fstab
done
IFS=$IFS_OLD
mount -a
}

fstab
: '
Partition table  should have the following view:
We should have 5 disks:
sdb->
	sdb1 - ext3
	sdb2 - ext4
	sdb3 - xfs
	sdb4 - extended
		sdb5 - ext2
		sdb6 - btrfs
		sdb7 - ext4 - block.size is 2K



sdc
	- lvm group -	lvm - ext2
sdd			lvm - ext3
			lvm - ext4
			lvm - xfs
			lvm - btrfs



sde
	sde1 - raid-linear
	sde2 - raid0
	sde3 - raid1
	sde4 - extended
		sde5 - unaligned 101 and 2048 BS ext3
		sde6 - unaligned 102 and 2048 BS ext4
		sde7 - unaligned 103 and 1024 BS xfs
		sde8 - free
			sde1, sdf1 - raid-linear - ext3
			sde2, sdf2 - raid-0 - ext4
			sde3, sdf3 - raid-1 - xfs
			sde5, sdf5 -

sdf 	sdf1 - raid-linear
	sdf2 - raid0
	sdf3 - raid1
	sdf4 - extended
		sdf5 - reserved for lvpool
		sdf6 - reserved for lvpool
		sdf7 - reserved for mirrored log
		sdf8 - free







'