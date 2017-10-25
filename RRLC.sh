#!/bin/bash

if [ `id -u` -ne  0  ]; then
	echo "You are not root"
	exit 1
fi


echo "Input the name of the archive with the logs: "
read archive_name
echo "Input IP of the remote machine you would like to tranfer logs:"
read IP
echo "Input the user for scp on the server you would like to send logs:"
read user
echo "Input the place, where logs will be placed on the remote server:
By default the is :~/.
Here is example of the user input: /home/mbugaiov/Desktop"
read path

if [  -z $path ]; then
	path="~/"
fi

LOGDIR="/tmp/RRLC"

mkdir $LOGDIR

files=(
	'/var/log/apprecovery'
	'/var/log/messages*'
	'/var/log/syslog*'

)

for i in ${files[@]}; do
	cp -R $i $LOGDIR > /dev/null 2>&1
done

lsblk >> $LOGDIR/lsblk > /dev/null 2>&1
df -HT >> $LOGDIR/df > /dev/null 2>&1
mount >> $LOGDIR/mount > /dev/null 2>&1

tar -cvzf $LOGDIR$archive_name $LOGDIR
scp $LOGDIR$archive_name $user@$IP:$path


rm -rf $LOGDIR
