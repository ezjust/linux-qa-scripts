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
umount /mnt/thinlvm
rm -rf /mnt/thinlvm


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
wipefs -a /dev/mapper/pool-thinlvm
lvremove -f /dev/mapper/pool-thinlvm
wipefs -a /dev/pool/lvmpool
lvremove -f /dev/pool/lvmpool



vgremove -f linear_xfs
vgremove -f linear_ext4
vgremove -f striped_xfs
vgremove -f striped_ext4
vgremove -f mirrored_xfs
vgremove -f mirrored_ext4
vgremove -f mirror_separate
vgremove -f pool


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

#(echo d; echo w;) | fdisk /dev/md/md5p1
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

sed -i.bak '/_ext2\|_ext3\|_ext4\|_xfs\|_btrfs\|-linear_0\|-stripe_0\|-mirror_0\|_separate\|partition-ext4\|md5p1\|thinlvm/d' /etc/fstab


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

function ext2_check {

ext2_maj="`echo $ext2_min_version | cut -d "." -f 1`"
ext2_min="`echo $ext2_min_version | cut -d "." -f 2`"

kernel_maj="`uname -r | cut -d "." -f 1`"
kernel_min="`uname -r | cut -d "." -f 2`"

if [[ "$ext2_maj" -lt "$kernel_maj" || "$ext2_maj" -eq "$kernel_maj" ]]; then
        if [[ "$ext2_min" -lt "$kernel_min" || "$ext2_min" -eq "$kernel_min" ]]; then
            return 0 # True
        fi
else
        tput setaf 3; echo "mount of the ext2 partition is skipped. We do not support it for kernels less $ext2_min_version"; tput sgr0
	return 1 # False
fi

}


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

        pvcreate "${disk[5]}8" "${disk[5]}6" "${disk[4]}6"
        vgcreate pool "${disk[5]}8" "${disk[5]}6" "${disk[4]}6"
        lvcreate -l 100%VG -T pool/lvmpool
        wipefs -a /dev/mapper/lvmpool >> /dev/null 2>&1;
        lvcreate -V100G -T pool/lvmpool -n thinlvm
        wipefs -a /dev/mapper/pool-thinlvm
        mkfs.xfs -f /dev/mapper/pool-thinlvm
        mkdir /mnt/thinlvm
        #mount /dev/mapper/pool-thinlvm /mnt/thinlvm/

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

        if ext2_check; then
	    mkfs.ext2 -F "${disk[1]}5"
	    mkdir /mnt/$(echo "${disk[1]}5" | cut -d"/" -f3)_ext2
	    mount "${disk[1]}5" /mnt/$(echo "${disk[1]}5" | cut -d"/" -f3)_ext2
        fi
	mkfs.btrfs -f "${disk[1]}6"
	mkdir /mnt/$(echo "${disk[1]}6" | cut -d"/" -f3)_btrfs
	mount -o nodatasum,nodatacow,device="${disk[1]}6" "${disk[1]}6" /mnt/$(echo "${disk[1]}6" | cut -d"/" -f3)_btrfs


	mkfs.ext4 -b 2052 -F "${disk[1]}7"
	mkdir /mnt/$(echo "${disk[1]}7" | cut -d"/" -f3)_ext4_unaligned
	mount "${disk[1]}7" /mnt/$(echo "${disk[1]}7" | cut -d"/" -f3)_ext4_unaligned
}

mkfs_primary_first_disk


function raid_partition {


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

data=($(ls -l /dev/md | grep ^lrw | awk '{print $9}'))
for array in ${data[@]}; do
	if [ "$array" != "md5" ]; then
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
fstab=($(cat /proc/mounts | grep '_ext2\|_ext3\|_ext4\|_xfs\|_btrfs\|-linear_0\|-stripe_0\|_separate\|-mirror_0\|partition-ext4\|md5p1\|thinlvm' | awk '{print $1,$2,$3}'))
for ((i = 0; i < ${#fstab[@]}; i++)); do
	echo ${fstab[$i]} defaults 0 0 >> /etc/fstab
done
IFS=$IFS_OLD
mount -a
}

fstab
: '
Partition table  should have the following view:
We should have 5 disks
sdb                                            8:16   0   10G  0 disk
├─sdb1                                         8:17   0  1,4G  0 part   /mnt/sdb1_ext3
├─sdb2                                         8:18   0  1,4G  0 part   /mnt/sdb2_ext4
├─sdb3                                         8:19   0  1,4G  0 part   /mnt/sdb3_xfs
├─sdb4                                         8:20   0  512B  0 part
├─sdb5                                         8:21   0  1,4G  0 part   /mnt/sdb5_ext2
├─sdb6                                         8:22   0  1,4G  0 part   /mnt/sdb6_btrfs
├─sdb7                                         8:23   0  1,4G  0 part   /mnt/sdb7_ext4_unaligned
└─sdb8                                         8:24   0  1,4G  0 part
  └─mirror_separate-mirror_separate_mlog     253:16   0    4M  0 lvm
    └─mirror_separate-mirror_separate        253:19   0  1,4G  0 lvm    /mnt/mirror_separate
sdc                                            8:32   0   10G  0 disk
├─sdc1                                         8:33   0  1,4G  0 part
│ └─linear_xfs-linear_xfs                    253:2    0  2,9G  0 lvm    /mnt/linear_xfs
├─sdc2                                         8:34   0  1,4G  0 part
│ └─striped_xfs-striped_xfs                  253:4    0  2,9G  0 lvm    /mnt/striped_xfs
├─sdc3                                         8:35   0  1,4G  0 part
│ ├─mirrored_xfs-mirrored_xfs_rmeta_0        253:6    0    4M  0 lvm
│ │ └─mirrored_xfs-mirrored_xfs              253:10   0  1,4G  0 lvm    /mnt/mirrored_xfs
│ └─mirrored_xfs-mirrored_xfs_rimage_0       253:7    0  1,4G  0 lvm
│   └─mirrored_xfs-mirrored_xfs              253:10   0  1,4G  0 lvm    /mnt/mirrored_xfs
├─sdc4                                         8:36   0  512B  0 part
├─sdc5                                         8:37   0  1,4G  0 part
│ └─linear_ext4-linear_ext4                  253:3    0  2,9G  0 lvm    /mnt/linear_ext4
├─sdc6                                         8:38   0  1,4G  0 part
│ └─striped_ext4-striped_ext4                253:5    0  2,9G  0 lvm    /mnt/striped_ext4
├─sdc7                                         8:39   0  1,4G  0 part
│ ├─mirrored_ext4-mirrored_ext4_rmeta_0      253:11   0    4M  0 lvm
│ │ └─mirrored_ext4-mirrored_ext4            253:15   0  1,4G  0 lvm    /mnt/mirrored_ext4
│ └─mirrored_ext4-mirrored_ext4_rimage_0     253:12   0  1,4G  0 lvm
│   └─mirrored_ext4-mirrored_ext4            253:15   0  1,4G  0 lvm    /mnt/mirrored_ext4
└─sdc8                                         8:40   0  1,4G  0 part
sdd                                            8:48   0   10G  0 disk
├─sdd1                                         8:49   0  1,4G  0 part
│ └─linear_xfs-linear_xfs                    253:2    0  2,9G  0 lvm    /mnt/linear_xfs
├─sdd2                                         8:50   0  1,4G  0 part
│ └─striped_xfs-striped_xfs                  253:4    0  2,9G  0 lvm    /mnt/striped_xfs
├─sdd3                                         8:51   0  1,4G  0 part
│ ├─mirrored_xfs-mirrored_xfs_rmeta_1        253:8    0    4M  0 lvm
│ │ └─mirrored_xfs-mirrored_xfs              253:10   0  1,4G  0 lvm    /mnt/mirrored_xfs
│ └─mirrored_xfs-mirrored_xfs_rimage_1       253:9    0  1,4G  0 lvm
│   └─mirrored_xfs-mirrored_xfs              253:10   0  1,4G  0 lvm    /mnt/mirrored_xfs
├─sdd4                                         8:52   0  512B  0 part
├─sdd5                                         8:53   0  1,4G  0 part
│ └─linear_ext4-linear_ext4                  253:3    0  2,9G  0 lvm    /mnt/linear_ext4
├─sdd6                                         8:54   0  1,4G  0 part
│ └─striped_ext4-striped_ext4                253:5    0  2,9G  0 lvm    /mnt/striped_ext4
├─sdd7                                         8:55   0  1,4G  0 part
│ ├─mirrored_ext4-mirrored_ext4_rmeta_1      253:13   0    4M  0 lvm
│ │ └─mirrored_ext4-mirrored_ext4            253:15   0  1,4G  0 lvm    /mnt/mirrored_ext4
│ └─mirrored_ext4-mirrored_ext4_rimage_1     253:14   0  1,4G  0 lvm
│   └─mirrored_ext4-mirrored_ext4            253:15   0  1,4G  0 lvm    /mnt/mirrored_ext4
└─sdd8                                         8:56   0  1,4G  0 part
sde                                            8:64   0   10G  0 disk
├─sde1                                         8:65   0  1,4G  0 part
│ └─md127                                      9:127  0  2,9G  0 linear /mnt/md0-linear_0
├─sde2                                         8:66   0  1,4G  0 part
│ └─md126                                      9:126  0  2,9G  0 raid0  /mnt/md0-stripe_0
├─sde3                                         8:67   0  1,4G  0 part
│ └─md125                                      9:125  0  1,4G  0 raid1  /mnt/md0-mirror_0
├─sde4                                         8:68   0  512B  0 part
├─sde5                                         8:69   0  1,4G  0 part
│ └─md124                                      9:124  0  1,4G  0 raid1
│   └─md124p1                                259:0    0  1,4G  0 md
├─sde6                                         8:70   0  1,4G  0 part
│ └─pool-lvmpool_tdata                       253:21   0  4,3G  0 lvm
│   └─pool-lvmpool-tpool                     253:22   0  4,3G  0 lvm
│     ├─pool-lvmpool                         253:23   0  4,3G  0 lvm
│     └─pool-thinlvm                         253:24   0  100G  0 lvm    /mnt/thinlvm
├─sde7                                         8:71   0  1,4G  0 part
│ └─mirror_separate-mirror_separate_mimage_0 253:17   0  1,4G  0 lvm
│   └─mirror_separate-mirror_separate        253:19   0  1,4G  0 lvm    /mnt/mirror_separate
└─sde8                                         8:72   0  1,4G  0 part
sdf                                            8:80   0   10G  0 disk
├─sdf1                                         8:81   0  1,4G  0 part
│ └─md127                                      9:127  0  2,9G  0 linear /mnt/md0-linear_0
├─sdf2                                         8:82   0  1,4G  0 part
│ └─md126                                      9:126  0  2,9G  0 raid0  /mnt/md0-stripe_0
├─sdf3                                         8:83   0  1,4G  0 part
│ └─md125                                      9:125  0  1,4G  0 raid1  /mnt/md0-mirror_0
├─sdf4                                         8:84   0  512B  0 part
├─sdf5                                         8:85   0  1,4G  0 part
│ └─md124                                      9:124  0  1,4G  0 raid1
│   └─md124p1                                259:0    0  1,4G  0 md
├─sdf6                                         8:86   0  1,4G  0 part
│ └─pool-lvmpool_tdata                       253:21   0  4,3G  0 lvm
│   └─pool-lvmpool-tpool                     253:22   0  4,3G  0 lvm
│     ├─pool-lvmpool                         253:23   0  4,3G  0 lvm
│     └─pool-thinlvm                         253:24   0  100G  0 lvm    /mnt/thinlvm
├─sdf7                                         8:87   0  1,4G  0 part
│ └─mirror_separate-mirror_separate_mimage_1 253:18   0  1,4G  0 lvm
│   └─mirror_separate-mirror_separate        253:19   0  1,4G  0 lvm    /mnt/mirror_separate
└─sdf8                                         8:88   0  1,4G  0 part
  ├─pool-lvmpool_tmeta                       253:20   0    8M  0 lvm
  │ └─pool-lvmpool-tpool                     253:22   0  4,3G  0 lvm
  │   ├─pool-lvmpool                         253:23   0  4,3G  0 lvm
  │   └─pool-thinlvm                         253:24   0  100G  0 lvm    /mnt/thinlvm
  └─pool-lvmpool_tdata                       253:21   0  4,3G  0 lvm
    └─pool-lvmpool-tpool                     253:22   0  4,3G  0 lvm
      ├─pool-lvmpool                         253:23   0  4,3G  0 lvm
      └─pool-thinlvm                         253:24   0  100G  0 lvm    /mnt/thinlvm
'
