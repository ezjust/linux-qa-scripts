#!/usr/bin/env bash
set -x
configuration=$1
disks=$2

ignore="/dev/null 2>&1"


if [[ -n "${disks}"   ]]; then
	IFS=","; declare -a disks=($2)
	echo "${disks[@]}"
	echo "${disks[0]}"
	echo "${disks[1]}"
	echo "${disks[2]}"
	echo "${disks[3]}"
	echo "${disks[4]}"
fi

if [[ -z "${disks[0]}" || -z "${disks[1]}" || -z "${disks[2]}" || -z "${disks[3]}" || -z "${disks[4]}" ]] && [[ "$configuration" == "create" ]]; then
        echo "You have not specified all 5 needed disks for default partition creation. You have the following disks:"
	echo "${disks[0]}"
        echo "${disks[1]}"
        echo "${disks[2]}"
        echo "${disks[3]}"
        echo "${disks[4]}"
        exit 1
fi

disk1="${disks[0]}" >> $ignore
disk1_size=$(fdisk -l "$disk1" | grep Disk | awk '{print $5}') >> $ignore
disk1_sectors=$(fdisk -l $disk1 | grep Disk | awk '{print $7}')  >> $ignore
disk1_partition_sectors="$(($disk1_sectors/7))" >> $ignore
disk2=${disks[1]} >> $ignore
disk2_size=$(fdisk -l $disk2 | grep Disk | awk '{print $5}') >> $ignore
disk2_sectors=$(fdisk -l $disk2 | grep Disk | awk '{print $7}') >> $ignore
disk2_partition_sectors=$(($disk2_sectors/7)) >> $ignore
disk3=${disks[2]} >> $ignore
disk3_size=$(fdisk -l $disk3 | grep Disk | awk '{print $5}') >> $ignore
disk3_sectors=$(fdisk -l $disk3 | grep Disk | awk '{print $7}') >> $ignore
disk3_partition_sectors=$(($disk3_sectors/7)) >> $ignore
disk4=${disks[3]} >> $ignore
disk4_size=$(fdisk -l $disk4 | grep Disk | awk '{print $5}') >> $ignore
disk4_sectors=$(fdisk -l $disk4 | grep Disk | awk '{print $7}') >> $ignore
disk4_partition_sectors=$(($disk4_sectors/7)) >> $ignore
disk5=${disks[4]} >> $ignore
disk5_size=$(fdisk -l $disk5 | grep Disk | awk '{print $5}') >> $ignore
disk5_sectors=$(fdisk -l $disk5 | grep Disk | awk '{print $7}') >> $ignore
disk5_partition_sectors=$(($disk5_sectors/7)) >> $ignore

if [[ -n "${disks}" && "$configuration" == "clean" ]]; then

	for i in {1..8}
	do 
		umount /mnt/"${disk[1]}1"_ext3 
		rm -rf /mnt/"${disk[1]}1"_ext3 
		umount /mnt/"${disk[1]}2"_ext4
		rm -rf /mnt/"${disk[1]}2"_ext4
		umount /mnt/"${disk[1]}3"_xfs
		rm -rf /mnt/"${disk[1]}3"_xfs
		umount /mnt/"${disk[1]}5"_ext2
		rm -rf /mnt/"${disk[1]}5"_ext2
		umount /mnt/"${disk[1]}6"_btrfs
		rm -rf /mnt/"${disk[1]}6"_btrfs
		umount /mnt/"${disk[1]}7"_ext4_unaligned
		rm -rf /mnt/"${disk[1]}7"_ext4_unaligned

		(echo d; echo $i; echo w;) | fdisk $disk1 >> /dev/null 2>&1
		sleep 0.2
		umount $disk2$i
        (echo d; echo $i; echo w;) | fdisk $disk2 >> /dev/null 2>&1
        sleep 0.2

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
        
        lvremove -f /dev/linear_xfs/linear_xfs
		lvremove -f /dev/linear_ext4/linear_ext4
		lvremove -f /dev/striped_xfs/striped_xfs
		lvremove -f /dev/striped_ext4/striped_ext4
		lvremove -f /dev/mirrored_xfs/mirrored_xfs
		lvremove -f /dev/mirrored_ext4/mirrored_ext4
		vgremove -f linear_xfs
		vgremove -f linear_ext4
		vgremove -f striped_xfs
		vgremove -f striped_ext4
		vgremove -f mirrored_xfs
		vgremove -f mirrored_ext4
		umount $disk3$i
        (echo d; echo $i; echo w;) | fdisk $disk3 >> /dev/null 2>&1
        sleep 0.2
		umount $disk4$i
		(echo d; echo $i; echo w;) | fdisk $disk4 >> /dev/null 2>&1
        sleep 0.2
		umount $disk5$i
		(echo d; echo $i; echo w;) | fdisk $disk5 >> /dev/null 2>&1
        sleep 0.2
	done

partprobe >> /dev/null 2>&1

echo "Clean has been completed"

exit 0

fi




if [[ "$disk1_size" < "10737418240" || "$disk2_size" < "10737418240" || "$disk3_size" < "10737418240" || "$disk4_size" < "10737418240" || "$disk5_size" < "10737418240" ]]; then
	echo "Not all disks have needed size : 10737418240"
	echo ""
	echo $disk1 : $disk1_size
	echo $disk2 : $disk2_size
	echo $disk3 : $disk3_size
	echo $disk4 : $disk4_size
	echo $disk5 : $disk5_size
	exit 1
fi

function disk_primary_partitions_create {
	declare -A disk_partition_sectors=();
	disk_partition_sectors[1]="$disk1_partition_sectors";
	disk_partition_sectors[2]="$disk2_partition_sectors";
    disk_partition_sectors[3]="$disk3_partition_sectors";
	disk_partition_sectors[4]="$disk4_partition_sectors";
    disk_partition_sectors[5]="$disk5_partition_sectors";

	declare -A disk=();
	disk[1]="$disk1"
	disk[2]="$disk2"
    disk[3]="$disk3"
    disk[4]="$disk4"
    disk[5]="$disk5"


	for m in 1 2 3
	do
		for i in {1..3}
		do 
			echo "${disk_partition_sectors[$m]}"
			(echo n; echo p; echo $i; echo ; echo "+""${disk_partition_sectors[$m]}"; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
			sleep 0.2
		
		done

		(echo n; echo e; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1

		for i in {5..7}
		do
			(echo n; echo ; echo "+"${disk_partition_sectors[$m]}; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
			sleep 0.5
		done

		(echo n; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
	done
}


disk_primary_partitions_create

function lvm_partitions_create {
	declare -A disk=();
	disk[3]="$disk3"
	disk[4]="$disk4"

	pvcreate  "${disk[3]}1" "${disk[4]}1"
	vgcreate linear_xfs "${disk[3]}1" "${disk[4]}1"
	lvcreate -l 100%VG -n linear_xfs linear_xfs
	linear_xfs=/dev/linear_xfs/linear_xfs
	mkdir /mnt/linear_xfs; linear_xfs_mp=/mnt/linear_xfs
	mount $linear_xfs $linear_xfs_mp

	pvcreate  "${disk[3]}5" "${disk[4]}5"
    vgcreate linear_ext4 "${disk[3]}5" "${disk[4]}5"
    lvcreate -l 100%VG -n linear_ext4 linear_ext4
    linear_ext4=/dev/linear_ext4/linear_ext4
	mkdir /mnt/linear_ext4; linear_ext4_mp=/mnt/linear_ext4
	mount $linear_ext4 $linear_ext4_mp

	pvcreate  "${disk[3]}2" "${disk[4]}2"
    vgcreate striped_xfs "${disk[3]}2" "${disk[4]}2"
    lvcreate -l 100%VG -i2 -I64 -n striped_xfs striped_xfs
    striped_xfs=/dev/striped_xfs/striped_xfs
	mkdir /mnt/striped_xfs; striped_xfs_mp=/mnt/striped_xfs
	mount $striped_xfs $striped_xfs_mp

	pvcreate  "${disk[3]}6" "${disk[4]}6"
    vgcreate striped_ext4 "${disk[3]}6" "${disk[4]}6"
    lvcreate -l 100%VG -i2 -I64 -n striped_ext4 striped_ext4
    striped_ext4=/dev/striped_ext4/striped_ext4
	mkdir /mnt/striped_ext4; striped_ext4_mp=/mnt/striped_ext4
	mount $striped_ext4 $striped_ext4_mp

	pvcreate  "${disk[3]}3" "${disk[4]}3"
    vgcreate mirrored_xfs "${disk[3]}3" "${disk[4]}3"
    lvcreate -l 100%VG -m1 -n mirrored_xfs mirrored_xfs
    mirrored_xfs=/dev/mirrored_xfs/mirrored_xfs
	mkdir /mnt/mirrored_xfs; mirrored_xfs_mp=/mnt/mirrored_xfs
	mount $mirrored_xfs $mirrored_xfs_mp

	pvcreate  "${disk[3]}7" "${disk[4]}7"
    vgcreate mirrored_ext4 "${disk[3]}7" "${disk[4]}7"
    lvcreate -l 100%VG -m1 -n mirrored_ext4 mirrored_ext4
    mirrored_ext4=/dev/mirrored_ext4/mirrored_ext4
	mkdir /mnt/mirrored_ext4; mirrored_ext4_mp=/mnt/mirrored_ext4
	mount $mirrored_ext4 $mirrored_ext4_mp


}

lvm_partitions_create

function mkfs_lvm {

mkfs.ext4 -f /dev/linear_ext4/linear_ext4
mkfs.ext4 -f /dev/striped_ext4/striped_ext4
mkfs.ext4 -f /dev/mirrored_ext4/mirrored_ext4

mkfs.xfs -f /dev/linear_xfs/linear_xfs
mkfs.xfs -f /dev/striped_xfs/striped_xfs
mkfs.xfs -f /dev/mirrored_xfs/mirrored_xfs

}

function mkfs_primary_first_disk {

declare -A disk=();
	disk[1]="$disk1"
	mkfs.ext3 -f "${disk[1]}1"
	mkdir /mnt/"${disk[1]}1"_ext3
	mount "${disk[1]}1" /mnt/"${disk[1]}1"_ext3 


	mkfs.ext4 -f "${disk[1]}2"
	mkdir /mnt/"${disk[1]}2"_ext4
	mount "${disk[1]}2" /mnt/"${disk[1]}2"_ext4


	mkfs.xfs -f "${disk[1]}3"
	mkdir /mnt/"${disk[1]}3"_xfs
	mount "${disk[1]}3" /mnt/"${disk[1]}3"_xfs


	mkfs.ext2 -f "${disk[1]}5"
	mkdir /mnt/"${disk[1]}5"_ext2
	mount "${disk[1]}5" /mnt/"${disk[1]}5"_ext2


	mkfs.btrfs -f "${disk[1]}6"
	mkdir /mnt/"${disk[1]}6"_btrfs
	mount "${disk[1]}6" /mnt/"${disk[1]}6"_btrfs


	mkfs.ext4 -b 2048 -f "${disk[1]}7"
	mkdir /mnt/"${disk[1]}1"_ext4_unaligned
	mount "${disk[1]}7" /mnt/"${disk[1]}1"_ext4_unaligned
}




function raid_partition {


	declare -A disk_partition_sectors=();
	disk_partition_sectors[4]="$disk4_partition_sectors";
    disk_partition_sectors[5]="$disk5_partition_sectors";

	declare -A disk=();
    disk[4]="$disk4"
    disk[5]="$disk5"


	for m in 4 5
	do
		for i in {1..3}
		do 
			echo "${disk_partition_sectors[$m]}"
			(echo n; echo p; echo $i; echo ; echo "+""${disk_partition_sectors[$m]}"; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
			sleep 0.2
		
		done

		(echo n; echo e; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1

		for i in {5..7}
		do
			sector=$(sfdisk -f ${disk[m]} | sed -n '/Start/{n;p;}' | awk '{print $1}')
			echo $sector
			sector=$(($sector + 3))
			echo sector
			(echo n; echo $sector; echo "+"${disk_partition_sectors[$m]}; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
			sleep 0.5
		done

		(echo n; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
	done


}


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
		sdf5 - free
		sdf6 - free
		sdf7 - free
		sdf8 - free







'
