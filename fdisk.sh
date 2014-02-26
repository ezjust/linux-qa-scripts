#!/bin/bash
#This script is written by Maxim Bugaiov.
#It should provide you ablity to specify default volume for testing. By default you need to do it here in script. "device=/dev/sd*" - is example
#Script should install the newest agent from all existing on your test machine and run all services
#Firts one it should attach volume to the bsctl and run bsrw to the /dev/null
#We will calculate time of creating data-store for testing volume and detecting any issues during bsctl and bsrw processes.


if [ `whoami` != "root" ]; then
	echo "You do not have rights to run this script. Please, use "root" user."
	exit 1;
fi
function fdisk {
	device=/dev/sdb # You can specify default device for testing
	umount $device
	(echo d; echo ; echo w) | grep $device # We will delete partition if it existes 
	sleep 1;
	(echo n; echo p; echo 1; echo ; echo ; echo w) | fdisk $device # Create new partition with all default settings using command line
}
#fdisk
function install_agent {
	findinstallers=`find /home appassure-installer* | grep /appassure-installer`;
	echo "THERE IS A LIST OF INSTALLER ON YOUR MACHINE: "
	ls -t $findinstallers
	pathtoinstaller=`ls -t $findinstallers | head -n 1`;
	echo "=========================================================="
	echo $pathtoinstaller IS THE NEWEST VERSION THAT YOU HAVE ON THIS MACHINE.
	echo "=========================================================="
	$pathtoinstaller -f # It will run installer in non-interactive mode.

}
function services {
	MODULE="appassure_vss"
	echo "=========================================================="
	echo "CHECKING SERVICES:"
	if lsmod | grep $MODULE ; then
		echo "Module $MODULE is loaded"
		exit 0
	else 
		echo "Module $MODULE IS NOT loaded. I will do it"
		modprobe $MODULE
		exit 0
	fi
}
#install_agent
#services


