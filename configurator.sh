#!/bin/bash
#set -x
version="1.1.1"
ext2_min_version="3.6"
ignore="/dev/null 2>&1"

check_version=`wget -O- -q https://raw.github.com/mbugaiov/myrepo/master/configurator.sh | head -3 | grep -w version | cut -d= -f2 | tr -d '"'`

if [[ "$check_version" != "$version" ]]; then
	tput setaf 4; echo "There is newest version on the GitHub"; tput sgr0
	echo "You are running the $version version of the script"
	echo "There is available the $check_version version on the GitHub"
	exit 1
fi

function helper {

tput setaf 4;	echo "You are in the HELP MENU:"; tput sgr0
		echo ""
tput setaf 2;   echo "--install/-i     - to create default configuration scheme for testing"; tput sgr0
		echo 	EXAMPLE :   ./configurator.sh --install --disk=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
		echo 	NOTE    :   You need to specify 5 disks in one row, devided by "","" without using spaces, 
		echo "       or use "default" array of disks --disk=default in this case configurator will use such disk letters - sdb,sdc,sdd,sde,sdf"
		echo ""
tput setaf 3;	echo "--clean/-c       - to clean up default configuration scheme for testing"; tput sgr0
		echo 	EXAMPLE :   ./configurator.sh --clean --disk=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
		echo "       or ./configurator.sh --clean --disk=default to use default array of disks"
		echo ""
                echo "       use -f=UUID or --format=UUID to write notes to fstab by disks UUIDs"
                echo "       use -v or --version to get version of the script"
                echo "       use -h or --help to get full help page of this script"
                echo ""
		echo "Default partition is shown below. Please note, that script will use disks from the command line.
That is why, instead of sdb, sdc, sdd, sde, sdf script will use disks you have provided."
		echo "Please note, that this script has been tested under following OS:
		     - Ubuntu 16.10 - passed
		     - Ubuntu 16.04 - passed
		     - Oracle 7.1   - passed
		     - Centos 7.3   - passed
		     - Centos 7.4   - passed
		     - SLES 12 SP2  - passed
		     - Ubuntu 17.04 - passed
		     - Ubuntu 12.04 - failed  - lvm2 has old version"
		echo "

		     "
}

if [[ -z $@ ]]; then
        tput setaf 1; echo "ERROR: No arguments"; tput sgr0
		echo ""
        helper  
        exit 1
fi


for i in "$@"
do
case $i in
    -h|--help)
    HELP=y
    echo ""
    helper
    exit 0
    ;;
    -c|--clean)
    CLEAN=y
    shift # past argument=value
    ;;
    -i|--install)
    INSTALL=y
    shift # past argument=value
    ;;
    -d=*|--disk=*)
    DISK=`echo ${i#*=} | tr '[:upper:]' '[:lower:]'`
    shift # past argument=value
    ;;
    -v|--version)
    VERSION=y
    echo ""
    echo $version
    exit 0
    ;;
    -e|--extended)
    EXTENDED=y
    shift
    ;;
    -f=*|--format=*)
    FORMAT=`echo ${i#*=} | tr '[:upper:]' '[:lower:]'`
    shift # past argument=value
    ;;
    *)	
    tput setaf 1; echo "ERROR: Incorrect argument"; tput sgr0
    echo ""
    helper
    exit 1          # unknown option
    ;;
esac
done

function check_and_parse_disks {

if [[ $DISK = "default" ]]; then
   	DISK=(/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf)
fi

IFS_OLD=$IFS
IFS=","; disks=( $DISK ) #create array seen outside of the function. In some case of the lvm and raid function we are using it. Needs to be reviwed.
IFS=$IFS_OLD

if [[ -z "${disks[0]}" || -z "${disks[1]}" || -z "${disks[2]}" || -z "${disks[3]}" || -z "${disks[4]}" ]] && [[ -n $INSTALL || -n $CLEAN ]]; then
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
        capacity=`blockdev --getsz $i` # gets size of the disk in the 512 block size
        block_size="512" # see before. We gets 512 block size
        disk_size+=(`blockdev --getsz $i`)
        partition_size=$(($capacity*$block_size/1024/7))  
        size+=($partition_size)
    done
}

function clean_disk_extended {
umount /mnt/md127p2--mirror--md--lvm
umount /mnt/md-mirror-md-lvm
mdadm --stop /dev/md/md-mirror-md-lvm
mdadm --zero-superblock /dev/md/linear_lvm_part0p1
mdadm --zero-superblock /dev/md/linear_lvm_part0p3
mdadm --zero-superblock /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p1
mdadm --zero-superblock /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p3
wipefs --force --all /dev/md127p2--liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p2/mirror-md-lvm
wipefs --force --all /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p3
wipefs --force --all /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p1
wipefs --force --all /dev/md/linear_lvm_part0p3
wipefs --force --all /dev/md/linear_lvm_part0p1
mdadm --remove /dev/md/md-mirror-md-lvm
partprobe
lvremove -f /dev/mapper/md127p2----liner_vg2_disk5_6_part2_3--liner_lv2_disk5_6_part2_3p2-mirror--md--lvm
wipefs --force --all /dev/mapper/md127p2--liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p2
vgremove -ff md127p2--liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p2
partprobe
(echo d; echo ; echo d; echo ; echo d; echo ; echo w;) | fdisk /dev/md/linear_lvm_part0
partprobe
mdadm --stop /dev/md/linear_lvm_part0
mdadm --zero-superblock /dev/mapper/liner_vg_disk5_6_part1_4-liner_lv_disk5_6_part1_4
mdadm --zero-superblock /dev/mapper/striped_vg2_disk5_6_part5_1-striped_lv2_disk5_6_part5_1
wipefs --force --all /dev/mapper/liner_vg_disk5_6_part1_4-liner_lv_disk5_6_part1_4
mdadm --remove /dev/md/linear_lvm_part0
partprobe
lvremove -f /dev/mapper/liner_vg_disk5_6_part1_4-liner_lv_disk5_6_part1_4
(echo d; echo ; echo d; echo ; echo d; echo ; echo w;) | fdisk /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3
mdadm --zero-superblock /dev/mapper/striped_vg2_disk5_6_part5_1-striped_lv2_disk5_6_part5_1
partprobe
wipefs --force --all /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3
partprobe

mdadm --remove /dev/md/mirror_lvm_part2*
mdadm --remove /dev/md/linear_lvm_part0*

list_lvms=(
/dev/mapper/liner_vg_disk5_6_part1_4-liner_lv_disk5_6_part1_4
/dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3
/dev/mapper/striped_vg1_disk5_6_part3_2-striped_lv1_disk5_6_part3_2
/dev/mapper/striped_vg2_disk5_6_part5_1-striped_lv2_disk5_6_part5_1
/dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3
/dev/mapper/striped_vg2_disk5_6_part5_1-striped_lv2_disk5_6_part5_1
/dev/mapper/striped_vg2_disk5_6_part5_1-striped_lv2_disk5_6_part5_1
/dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3
/dev/mapper/liner_vg_disk5_6_part1_4-liner_lv_disk5_6_part1_4
/dev/mapper/liner_vg_disk5_6_part1_4-liner_lv_disk5_6_part1_4
/dev/mapper/striped_vg2_disk5_6_part5_1-striped_lv2_disk5_6_part5_1
/dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p1
/dev/mapper/striped_vg1_disk5_6_part3_2-striped_lv1_disk5_6_part3_2p1)
/dev/liner_vg2_disk5_6_part2_3/liner_lv2_disk5_6_part2_3
for i in ${list_lvms[@]}
do
	wipefs --force --all $i
done

for i in ${list_lvms[@]}
do
	lvremove -f $i
done

vgremove -ff striped_vg2_disk5_6_part5_1
vgremove -ff striped_vg1_disk5_6_part3_2
vgremove -ff liner_vg_disk5_6_part1_4
vgremove -ff liner_vg2_disk5_6_part2_3
vgremove -ff liner_vg_disk5_6_part1_4

for i in 0 1 2 3 4
do
	dd if=/dev/zero of=${disks[$i]} bs=10MB count=2
	sgdisk -Z ${disks[$i]}
done

}


function clean_disks {


if [[ -n $EXTENDED ]]; then
	clean_disk_extended >/dev/null 2>&1
	exit 0
fi

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

list_mount_points=(
/mnt/linear_xfs
/mnt/linear_ext4
/mnt/striped_xfs
/mnt/striped_ext4
/mnt/mirrored_xfs
/mnt/mirrored_ext4
/mnt/mirror_separate
/mnt/md0-linear_0
/mnt/md0-stripe_0
/mnt/md0-mirror_0
/mnt/md5p1
/mnt/thinlvm
)

for i in ${list_mount_points[@]}
do
	umount $i
	rm -rf $i
done

list_devices=(
/dev/linear_xfs/linear_xfs
/dev/linear_ext4/linear_ext4
/dev/striped_xfs/striped_xfs
/dev/striped_ext4/striped_ext4
/dev/mirrored_xfs/mirrored_xfs
/dev/mirrored_ext4/mirrored_ext4
/dev/mirror_separate/mirror_separate
/dev/mapper/pool-thinlvm
/dev/pool/lvmpool
)

for i in ${list_devices[@]}
do
	wipefs --force --all $i
	lvremove -f $i
done

for i in linear_xfs linear_ext4 striped_xfs striped_ext4 mirrored_xfs mirrored_ext4 mirror_separate pool
do
	vgremove -f $i
done

list_raid=($(mdadm --detail -scan | grep 'linear_0\|stripe_0\|mirror_0\|md5p1\|md5' | awk '{print $2}'))
list_inc=(1 2 3 5) #list of the partitions used for the raid
k=0
for i in ${list_raid[@]}
do
	mdadm --stop $i
	mdadm --zero-superblock ${disks[3]}${list_inc[$k]} ${disks[4]}${list_inc[$k]}
	wipefs --force --all ${disks[3]}${list_inc[$k]}
	wipefs --force --all ${disks[4]}${list_inc[$k]}
	mdadm --remove $i
	let k=$k+1
done

(echo d; echo w;) | fdisk /dev/md/md5 # to complete clean of the /dev/md/md5p1


sed -i.bak '/linear_0\|stripe_0\|mirror_0\|md5/d' /etc/mdadm/mdadm.conf
sed -i.bak '/linear_0\|stripe_0\|mirror_0\|md5/d' /etc/mdadm.conf
partprobe

	for i in {1..8}
	do

		(echo d; echo $i; echo w;) | fdisk ${disks[0]} >> /dev/null 2>&1
                sleep 0.2
		wipefs --force --all ${disks[0]}$i
                #umount $disk2$i
                (echo d; echo $i; echo w;) | fdisk ${disks[1]} >> /dev/null 2>&1
                sleep 0.2
		wipefs --force --all ${disks[1]}$i
		#umount $disk3$i
	        (echo d; echo $i; echo w;) | fdisk ${disks[2]} >> /dev/null 2>&1
        	sleep 0.2
		wipefs --force --all ${disks[2]}$i
		#umount $disk4$i
		(echo d; echo $i; echo w;) | fdisk ${disks[3]} >> /dev/null 2>&1
	        sleep 0.2
		wipefs --force --all ${disks[3]}$i
		#umount $disk5$i
		(echo d; echo $i; echo w;) | fdisk ${disks[4]} >> /dev/null 2>&1
        	sleep 0.2
		wipefs --force --all ${disks[4]}$i
	done

sed -i.bak '/_ext2\|_ext3\|_ext4\|_xfs\|_btrfs\|-linear_0\|-stripe_0\|-mirror_0\|_separate\|partition-ext4\|md5p1\|thinlvm\|md127p2-\|md-mirror-md-lvm/d' /etc/fstab


for i in 0 1 2 3 4
do
	        dd if=/dev/zero of=${disks[$i]} bs=10MB count=2
		sgdisk -Z ${disks[$i]}
done


partprobe >> /dev/null 2>&1

echo "Clean has been completed"

}


function activate_disks {
    	for i in `ls /sys/class/scsi_host/`; do
       		exists=`grep mpt /sys/class/scsi_host/$i/proc_name`
		if [[ ! -z $exists ]]; then
			echo "- - -" > /sys/class/scsi_host/$i/scan
		fi
	done
}

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

function needed_packages {
if [ "`rpm -? >> /dev/null 2>&1; echo $?`" == "0" ]; then
	pacman="rpm -qa"
else
	pacman="dpkg --list"
fi

if [[ "`$pacman | grep lvm2 >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep bl >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep btrfs >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep xfsprogs >> /dev/null; echo $?`" -ne "0" || "`$pacman | grep mdadm >> /dev/null; echo $?`" -ne "0" ]]; then
	echo "Not all packages are installed: lvm2, mdadm, btrfs-progs, xfsprogs, bc, thin-provisioning-tools"
	echo ""
	$pacman | grep -w 'lvm2\|mdadm\|btrfs-progs\|xfsprogs\|bc\|thin-provisioning-tools'
	exit 1
fi
}

function needed_disk_size {
if [[ "${disk_size[0]}" < "10737418240" || "${disk_size[1]}" < "10737418240" || "${disk_size[2]}" < "10737418240" || "${disk_size[3]}" < "10737418240" || "${disk_size[4]}" < "10737418240" ]]; then
	echo "Not all disks have minimum needed size : 10737418240"
	echo ""
	echo ${disks[0]} : ${disk_size[0]}
	echo ${disks[1]} : ${disk_size[1]}
	echo ${disks[2]} : ${disk_size[2]}
	echo ${disks[3]} : ${disk_size[3]}
	echo ${disks[4]} : ${disk_size[4]}
	exit 1
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
	echo "===================================="
	echo ${disk_partition_sectors[1]}
	echo ${disk_partition_sectors[2]}
    echo ${disk_partition_sectors[3]}
    echo ${disk_partition_sectors[4]}
    echo ${disk_partition_sectors[5]}

	for m in 1 2 3
	do
		for i in {1..3}
		do
			echo "${disk_partition_sectors[$m]}"
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

function mkfs_primary_first_disk {
	echo "I am here"
	declare -A disk=();
	disk[1]="${disks[0]}"
	echo ${disk[1]}
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
		echo "${disk_partition_sectors[$m]}"
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
    wipefs --force --all ${disks[3]}$i
    wipefs --force --all ${disks[4]}$i
    mdadm --zero-superblock ${disks[3]}$i ${disks[4]}$i
done

RAID=() # create an array with the list of the created raids

mdadm --create --verbose /dev/md/md0-linear_0 --level=linear --raid-devices=2 ${disks[3]}1 ${disks[4]}1
if [ -b /dev/md/md0-linear_0 ]; then
	mdadm --assemble --verbose /dev/md/md0-linear_0 ${disks[3]}1 ${disks[4]}1
	mkdir /mnt/md0-linear_0
	RAID+=('md0-linear_0')
else
	echo /dev/md/md0-linear_0 was not created. Skipped assemble of this device.
fi

partprobe
mdadm --create /dev/md/md0-stripe_0 --level=stripe --raid-devices=2 ${disks[3]}2 ${disks[4]}2

if [ -b /dev/md/md0-stripe_0 ]; then
	mdadm --assemble --verbose /dev/md/md0-stripe_0 ${disks[3]}2 ${disks[4]}2
	mkdir /mnt/md0-stripe_0
	RAID+=('md0-stripe_0')
else
	echo /dev/md/md0-stripe_0 was not created. Skipped assemble of this device
fi

partprobe
yes | mdadm --create /dev/md/md0-mirror_0 --level=mirror --raid-devices=2 ${disks[3]}3 ${disks[4]}3

if [ -b /dev/md/md0-mirror_0 ]; then
	mdadm --assemble /dev/md/md0-mirror_0 ${disks[3]}3 ${disks[4]}3
	mkdir /mnt/md0-mirror_0
	RAID+=('md0-mirror_0')
else
	echo /dev/md/md0-mirror_0 was not created. Skipped assemble of this device
fi


yes | mdadm --create --verbose /dev/md/md5 --level=1 --raid-devices=2 ${disks[3]}5 ${disks[4]}5
if [ -b /dev/md/md5 ]; then
    (echo n; echo p; echo 1; echo ; echo ; echo w) | fdisk /dev/md/md5
	mkdir /mnt/md5p1
	RAID+=('md5p1')
else
    echo /dev/md/md5 was not created. Skipped assemble of this device.
fi

partprobe

if [ -e /etc/mdadm/mdadm.conf ]; then
	mdadm --detail --scan >> /etc/mdadm/mdadm.conf
fi

if [ -e /etc/mdadm.conf ]; then
	mdadm --detail --scan >> /etc/mdadm.conf
fi

for raid in ${RAID[@]}; do
	if [ "$raid" != "md5" ]; then
	    mkfs.ext4 -F /dev/md/$raid
	    mount /dev/md/$raid /mnt/$raid
	fi
done
}

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
	wipefs --force --all /dev/linear_xfs/linear_xfs
	linear_xfs=/dev/linear_xfs/linear_xfs
	mkdir /mnt/linear_xfs; linear_xfs_mp=/mnt/linear_xfs
	sleep 0.2
	mkfs.xfs -f /dev/linear_xfs/linear_xfs
	mount $linear_xfs $linear_xfs_mp

	pvcreate  "${disk[2]}5" "${disk[3]}5"
	vgcreate linear_ext4 "${disk[2]}5" "${disk[3]}5"
	lvcreate -Zy -l 100%VG -n linear_ext4 linear_ext4
	wipefs --force --all /dev/linear_ext4/linear_ext4
	linear_ext4=/dev/linear_ext4/linear_ext4
	mkdir /mnt/linear_ext4; linear_ext4_mp=/mnt/linear_ext4
	sleep 0.2
	mkfs.ext4 -F /dev/linear_ext4/linear_ext4
	mount $linear_ext4 $linear_ext4_mp

	pvcreate  "${disk[2]}2" "${disk[3]}2"
	vgcreate striped_xfs "${disk[2]}2" "${disk[3]}2"
	lvcreate -Zy -l 100%VG -i2 -I64 -n striped_xfs striped_xfs
	striped_xfs=/dev/striped_xfs/striped_xfs
	wipefs --force --all "$striped_xfs"
	mkdir /mnt/striped_xfs; striped_xfs_mp=/mnt/striped_xfs
	sleep 0.2
	mkfs.xfs -f /dev/striped_xfs/striped_xfs
	mount $striped_xfs $striped_xfs_mp

	pvcreate  "${disk[2]}6" "${disk[3]}6"
	vgcreate striped_ext4 "${disk[2]}6" "${disk[3]}6"
	lvcreate -Zy -l 100%VG -i2 -I64 -n striped_ext4 striped_ext4
	striped_ext4=/dev/striped_ext4/striped_ext4
	wipefs --force --all "$striped_ext4"
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
	wipefs --force --all "$mirrored_xfs"
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
	wipefs --force --all "$mirrored_ext4"
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
	wipefs --force --all /dev/mirror_separate/mirror_separate >> /dev/null 2>&1;
	mkdir /mnt/mirror_separate
	sleep 0.2
	mkfs.ext4 -F /dev/mirror_separate/mirror_separate
	mount /dev/mirror_separate/mirror_separate /mnt/mirror_separate
	echo "------------------------------------------------------------------"

        pvcreate "${disk[5]}8" "${disk[5]}6" "${disk[4]}6"
        vgcreate pool "${disk[5]}8" "${disk[5]}6" "${disk[4]}6"
        lvcreate -l 100%VG -T pool/lvmpool
        wipefs --force --all /dev/mapper/lvmpool >> /dev/null 2>&1;
        lvcreate -V100G -T pool/lvmpool -n thinlvm
        wipefs --force --all /dev/mapper/pool-thinlvm
        mkfs.xfs -f /dev/mapper/pool-thinlvm
        mkdir /mnt/thinlvm
        #mount /dev/mapper/pool-thinlvm /mnt/thinlvm/

}


function extended {
	# Extended configuration should be used

	    size=()
        disk_size=()
        for i in ${disks[@]}
   		do
        disk_cut=$(echo $i | cut -d"/" -f3)
        capacity=`blockdev --getsz $i` # gets size of the disk in the 512 block size
        block_size="512" # see before. We gets 512 block size
        disk_size+=(`blockdev --getsz $i`)
        partition_size=$(($capacity*$block_size/1024/1024/1024)) # the disk size in GB
        size+=($partition_size)
    	done

        declare -A disk_partition_sectors=();
        # disk_partition_sectors[1]=$((${size[0]}/2/10))
        # disk_partition_sectors[2]=$((${size[0]}/2/5))
        # disk_partition_sectors[3]=$((${size[0]}/2 - ${disk_partition_sectors[2]}))
        # disk_partition_sectors[4]=$((${size[0]}/2 - ${disk_partition_sectors[1]}))

        declare -A disk=();
        disk[1]="${disks[0]}"
        disk[2]="${disks[1]}"
        disk[3]="${disks[2]}"
        disk[4]="${disks[3]}"
        disk[5]="${disks[4]}"
        echo "===================================="
        echo ${disk_partition_sectors[1]}
        echo ${disk_partition_sectors[2]}
        echo ${disk_partition_sectors[3]}
        echo ${disk_partition_sectors[4]}
        echo ${disk_partition_sectors[5]}

        for m in 1 3 5
        do
                echo ${disk[$m]} "IS MBR DISK"
                first="${size[0]}"
                echo $first " Is first size0"
                second="2"
                third1="10"
                third2="5"
                disk_partition_sectors[1]=`python -c "print $first*1024/$second/$third1"`
                disk_partition_sectors[2]=`python -c "print $first*1024/$second/$third2"`
                disk_partition_sectors[3]=`python -c "print $first*1024/$second - $first*1024/$second/$third2"`
                disk_partition_sectors[4]=`python -c "print $first*1024/$second - $first*1024/$second/$third1"`

                for i in {1..3}
                do
                        echo "${disk_partition_sectors[$i]}"
                        (echo n; echo p; echo $i; echo ; echo "+""${disk_partition_sectors[$i]}""M"; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1
                        sleep 0.2

                done
                sleep 0.2
                (echo n; echo e; echo ; echo ; echo w) | fdisk ${disk[$m]}
                sleep 0.2
                (echo n; echo ; echo ; echo w) | fdisk ${disk[$m]} >> /dev/null 2>&1

        partprobe

		done

        for m in 2 4
        do
                echo ${disk[$m]} "IS GPT DISK"
                first="${size[0]}"
                second="2"
                third1="10"
                third2="5"
                disk_partition_sectors[1]=`python -c "print $first*1024/$second/$third1"`
                disk_partition_sectors[2]=`python -c "print $first*1024/$second/$third2"`
                disk_partition_sectors[3]=`python -c "print $first*1024/$second - $first*1024/$second/$third2"`
                disk_partition_sectors[4]=`python -c "print $first*1024/$second - $first*1024/$second/$third1"`

                for i in {1..3}
                do
                        (echo n; echo ; echo ; echo "+""${disk_partition_sectors[$i]}""M"; echo ; echo w; echo y) | gdisk ${disk[$m]}
                        sleep 0.5

                done
                (echo n; echo ; echo ; echo ; echo ; echo w; echo y) | gdisk ${disk[$m]}
                sleep 0.5

        done

    partprobe

    pvcreate -f "${disk[1]}1" "${disk[2]}4"
    vgcreate -f liner_vg_disk5_6_part1_4 "${disk[1]}1" "${disk[2]}4"
    vgcreate -f liner_vg_disk5_6_part1_4 "${disk[1]}1" "${disk[2]}4"
    wipefs --force --all /dev/mapper/liner_lv_disk5_6_part1_4
    wipefs --force --all /dev/mapper/liner_vg_disk5_6_part1_4
    lvcreate -Zy -l 100%VG -n liner_lv_disk5_6_part1_4 liner_vg_disk5_6_part1_4    

    pvcreate -f "${disk[1]}2" "${disk[2]}3"
    vgcreate -f liner_vg2_disk5_6_part2_3 "${disk[1]}2" "${disk[2]}3"
    wipefs --force --all /dev/mapper/liner_lv2_disk5_6_part2_3
    wipefs --force --all /dev/mapper/liner_vg2_disk5_6_part2_3
    lvcreate -Zy -l 100%VG -n liner_lv2_disk5_6_part2_3 liner_vg2_disk5_6_part2_3

    pvcreate -f "${disk[1]}3" "${disk[2]}2"
    vgcreate -f striped_vg1_disk5_6_part3_2 "${disk[1]}3" "${disk[2]}2"
    wipefs --force --all /dev/mapper/striped_lv1_disk5_6_part3_2
    wipefs --force --all /dev/mapper/striped_vg1_disk5_6_part3_2
    lvcreate -Zy -l 100%VG -i2 -I64 -n striped_lv1_disk5_6_part3_2 striped_vg1_disk5_6_part3_2

    pvcreate -f "${disk[1]}5" "${disk[2]}1"
    vgcreate -f striped_vg2_disk5_6_part5_1 "${disk[1]}5" "${disk[2]}1"
    wipefs --force --all /dev/mapper/striped_lv2_disk5_6_part5_1
    wipefs --force --all /dev/mapper/striped_vg2_disk5_6_part5_1
    lvcreate -Zy -l 100%VG -i2 -I64 -n striped_lv2_disk5_6_part5_1 striped_vg2_disk5_6_part5_1
    #126 raild
    mdadm --create --verbose /dev/md/linear_lvm_part0 --level=linear --raid-devices=2 /dev/mapper/liner_vg_disk5_6_part1_4-liner_lv_disk5_6_part1_4 /dev/mapper/striped_vg2_disk5_6_part5_1-striped_lv2_disk5_6_part5_1
    partprobe
    (echo n; echo p; echo ; echo ; echo "+1G"; echo w) | fdisk "/dev/md/linear_lvm_part0" >> /dev/null 2>&1
    sleep 0.2
    (echo n; echo p; echo ; echo ; echo "+2G"; echo w) | fdisk "/dev/md/linear_lvm_part0" >> /dev/null 2>&1
    sleep 0.2
    (echo n; echo p; echo ; echo ; echo ; echo w) | fdisk "/dev/md/linear_lvm_part0" >> /dev/null 2>&1
    sleep 0.2
	
    (echo n; echo p; echo ; echo ; echo "+1G"; echo w) | fdisk "/dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3" >> /dev/null 2>&1
    sleep 0.2
    (echo n; echo p; echo ; echo ; echo "+2G"; echo w) | fdisk "/dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3" >> /dev/null 2>&1
    sleep 0.2
    (echo n; echo p; echo ; echo ; echo ; echo w) | fdisk "/dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3" >> /dev/null 2>&1
    sleep 0.2
	
    partprobe
    
    vgcreate md127p2--liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p2 /dev/md127p2  /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p2

    lvcreate -Zy -l 100%VG -m1 -n mirror-md-lvm md127p2--liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p2
    partprobe
    /usr/bin/yes | mdadm --create /dev/md/md-mirror-md-lvm --level=mirror --raid-devices=4 /dev/md127p1 /dev/md127p3 /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p1 /dev/mapper/liner_vg2_disk5_6_part2_3-liner_lv2_disk5_6_part2_3p3    
    partprobe
    mkfs.xfs -f /dev/md/md-mirror-md-lvm
    mkfs.ext4 /dev/mapper/md127p2----liner_vg2_disk5_6_part2_3--liner_lv2_disk5_6_part2_3p2-mirror--md--lvm 
    mkdir /mnt/md-mirror-md-lvm
    mount /dev/md/md-mirror-md-lvm /mnt/md-mirror-md-lvm
    mkdir /mnt/md127p2--mirror--md--lvm
    mount /dev/mapper/md127p2----liner_vg2_disk5_6_part2_3--liner_lv2_disk5_6_part2_3p2-mirror--md--lvm /mnt/md127p2--mirror--md--lvm

}

     function fstab {
     IFS_OLD=$IFS
     IFS=$'\n'
     set -o noglob
     
     fstab=( `cat /proc/mounts | grep '_ext2\|_ext3\|_ext4\|_xfs\|_btrfs\|-linear_0\|-stripe_0\|_separate\|-mirror_0\|partition-ext4\|md5p1\|thinlvm\|md-mirror-md-lvm\|md127p2-' | awk '{print $1,$2,$3}'` )
     	for ((i = 0; i < ${#fstab[@]}; i++)); do
      	  if [[ ! `cat /etc/fstab | grep "${fstab[$i]}" ` ]]; then
           if [[ $FORMAT = "uuid" ]]; then
              exp=$(echo ${fstab[$i]} | awk '{print $1}')
              uuid=$(blkid -o export $exp | grep "^UUID=") 
              mpfs=$(echo ${fstab[$i]} | awk '{print $2,$3}') 
              echo $uuid $mpfs defaults 0 0 >> /etc/fstab
           else
              if [[ "${fstab[$i]}" == "/dev/md124p1 /mnt/md5p1 ext4" ]]; then
                    fstab[$i]="/dev/md/md5p1 /mnt/md5p1 ext4" # since after reboot /dev/md124p1 becames /dev/md/md5p1 we use check for this device during mounting and use /dev/md/md5p1 as a default path for this device
              fi
              echo ${fstab[$i]} defaults 0 0 >> /etc/fstab
           fi
          
          fi
     	done
     
     IFS=$IFS_OLD
     mount -a
     }		


if [[ -z $INSTALL && -z $CLEAN && -z $EXTENDED ]] && [[ -n $DISK ]]; then
	tput setaf 1; echo "ERROR: No command specified for the devices"; tput sgr0 
	echo ""
	helper
	exit 1
fi

if [[ -n $INSTALL || -n $CLEAN || -n $EXTENDED ]] && [[ -z $DISK ]]; then
        tput setaf 1; echo "ERROR: You have not specified devices"; tput sgr0
        echo ""
        helper
        exit 1
fi


if [[ -n $DISK && -n $CLEAN ]]; then
	echo "1/3"
	check_and_parse_disks >/dev/null 2>&1
	echo "2/3"
	clean_disks >/dev/null 2>&1
	echo "3/3"
	exit 0
fi




if [[ -n $DISK && -n $INSTALL ]]; then
	activate_disks
	echo "1/10"
	check_and_parse_disks
	echo "2/10"
	needed_packages
	echo "3/10"
	needed_disk_size
	echo "4/10"
	ext2_check
	echo "5/10"
	disk_primary_partitions_create >/dev/null 2>&1
	echo "6/10"
	mkfs_primary_first_disk >/dev/null 2>&1
	echo "7/10"
	raid_partition >/dev/null 2>&1
	echo "8/10"
	lvm_partitions_create >/dev/null 2>&1
	echo "9/10"
	fstab
	echo "10/10"
	echo "COMPLETED"
	exit 0
fi


if [[ -n $DISK && -n $EXTENDED ]]; then
	activate_disks
	echo "1/7"
	check_and_parse_disks >/dev/null 2>&1
	echo "2/7"
	needed_packages >/dev/null 2>&1
	echo "3/7"
	needed_disk_size >/dev/null 2>&1
	echo "4/7"
	ext2_check >/dev/null 2>&1
	echo "5/7"
	extended >/dev/null 2>&1
	echo "6/7"
	# disk_primary_partitions_create >/dev/null 2>&1
	# echo "6/10"
	# mkfs_primary_first_disk >/dev/null 2>&1
	# echo "7/10"
	# raid_partition >/dev/null 2>&1
	# echo "8/10"
	# lvm_partitions_create >/dev/null 2>&1
	# echo "9/10"
	fstab
	echo "10/10"
	echo "COMPLETED"
	exit 0
fi


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
│   └─md124p1                                259:0    0  1,4G  0 md    /mnt/md5p1
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
│   └─md124p1                                259:0    0  1,4G  0 md     /mnt/md5p1
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
