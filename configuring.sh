#!/bin/bash
set -x


if [ `which apt-get >> /dev/null; echo $?` == "0" ]
then 
	PackMan="apt-get"
	Package="dpkg --list"
elif [ `which yum >> /dev/null; echo $?` == "0" ]
then 
	PackMan="yum"
	Package="rpm -qa"
elif [ `which zypper >> /dev/null; echo $?` == "0" ]
then 
	PackMan=zypper
	Package="rpm -qa"
else
	echo "ERROR::Distibutive is not known"
fi

echo $PackMan
$PackMan update
$PackMan install -y openssh-server mc jenkins
$Package | grep openssh
$Package | grep mc
$Package | grep jenkins

 
