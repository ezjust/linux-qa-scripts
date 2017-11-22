#!/usr/bin/env bash

if [ `id -u` -ne  0  ]; then
	echo "You are not root"
	exit 1
fi

if [ `virsh -v >> /dev/null 2>&1; echo $?` -ne 0 ]; then
	echo "KVM and other packages are not installed"
	exit 1
fi

a=()

dir="/tmp/virsh/"

mkdir $dir

output=`virsh list --all | awk '{print $2}' | tr -s '\n' '\n' | tail -n +2`

amount=`virsh list --all | awk '{print $2}' | tr -s '\n' '\n' | tail -n +2 | wc -l`

if [ $amount -lt 1 ]; then
	echo "There are no xml for the KVM machines"
	exit 1
fi
#debug output to make sure script works as expected
#output=`df -h | awk {'print $1'}`

i=0
for elem in $output; do
	a[i]=$elem
	i=$((i + 1))
done

echo ${a[@]}

for elem in ${a[@]}; do
	`sudo virsh dumpxml $elem >> $dir/$elem.xml`
done

find $dir -type f -name "*.xml" |  tar cJfTP $dir/virshxml.tar.gz -

if [ -e $dir/virshxml.tar.gz ]; then
	echo "$(tput setaf 2)Completed. Please provide virshxml archive to the support team.$(tput sgr0)"
	exit 0
else:
	echo "$(tput setaf 2)Some errors occured$(tput sgr0)"
	exit 1
fi
