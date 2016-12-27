#!/usr/bin/bash
#Done by M.Bugaiov.
# This script needs to be placed into /opt/apprecovery/scripts.
# You can track how it works by `dmesg | grep PostTransferScript`
# The script will be run for all attached devices in the "attached-devices" file
# bs and count may be changed depends from you request
while read line; do 
	MP=`findmnt -nr -o target -S $line`
	#echo $line
	#echo $MP
	if [[ $MP == "/boot" ]]; then
		#echo "I am boot device"
		rm -f $MP/test1 >> /dev/null
		dd if=/dev/urandom of=$MP/test1 bs=10MB count=10
	else
		#echo " NOT BOOT"
		rm -f $MP/test1 >> /dev/null
		dd if=/dev/urandom of=$MP/test1 bs=10MB count=100
	fi
done < /.blksnap/attached-devices

echo "Completed PostTransferScript" >> /dev/kmsg
