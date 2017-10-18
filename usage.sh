#!/bin/bash

trap my_exit SIGINT SIGQUIT INT

function my_exit {
	exit 0
}

file=result.csv

for i in "$@"
do
case $i in
    -i=*|--interval=*)
    INTERVAL="${i#*=}"
    shift # past argument=value
    ;;
    -t=*|--time=*)
    TIME="${i#*=}"
    shift # past argument=value
    ;;
    -n=*|--network=*)
    NETWORK="${i#*=}"
    shift # past argument=value
    ;;
    -d=*|--device=*)
    DEVICE="${i#*=}"
    shift # past argument=value
    ;;

    *)
          # unknown option
    ;;
esac
done

if [[ -z $INTERVAL || -z $TIME || -z $NETWORK || -z $DEVICE ]]; then
tput setaf 1;	echo "You have not specified INTERVAL, TIME, NETWORK or DEVICE for the collection usage. Example: ./usage.sh -i=1 -t=2 -n=enp0s8 -d=dm-0"; tput sgr0
		echo "TIPS: Interaval should be set in seconds"
		echo "TIPS: Time should be set in hours and shoud be integer."
		echo "TIPS: Network interface can be found in 'ip addr show'. This interface will be used to measure network trafic"
		echo "TIPS: Device can be found in 'iostat' output in the 'device' column"
	exit 1
fi

if [ "$INTERVAL" -eq "$INTERVAL" ] 2>/dev/null
then
	true
else
    	tput setaf 1;   echo "INTERVAL should be integer. Example: ./usage.sh -i=1 -t=2"; tput sgr0
	exit 1
fi

if [ "$TIME" -eq "$TIME" ] 2>/dev/null
then
	true
else
        tput setaf 1;   echo "TIME should be integer. Example: ./usage.sh -i=1 -t=2"; tput sgr0
        exit 1
fi



interface_check_code=`ifconfig -a | grep -w $NETWORK >> /dev/null; echo $?`
if [ $interface_check_code -ne 0 ]; then
tput setaf 1;   echo "Specified Network interface is not valid. Please double-check. Example: ./usage.sh -i=1 -t=2 -n=enp0s8"; tput sgr0
	exit 1
fi

iostat_check_code=`iostat > /dev/null 2>&1; echo $?`
if [ $iostat_check_code -ne 0 ]; then
tput setaf 1;   echo "IOSTAT command is not found. Please install 'systat' package on your system."; tput sgr0
        exit 1
fi


device_check_code=`iostat | grep -w $DEVICE >> /dev/null; echo $?`
if [ $device_check_code -ne 0 ]; then
tput setaf 1;   echo "Specified Device is not valid. Please double-check. Example: ./usage.sh -i=1 -t=2 -n=enp0s8 -d=dm-0"; tput sgr0
        exit 1
fi





function convert_hours_sec {
	time_to_run=$(($TIME*3600))
	max_count=$(($time_to_run/$INTERVAL))

}
convert_hours_sec

function memory {
	result=`free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'`
	echo -ne "      $result,"
}

function disk_usage {
	result=`df -h | awk '$NF=="/"{printf "%d/%dGB (%s)\n", $3,$2,$5}'`
	echo -ne "      $result,"
}

function printer {
	echo "time_to_run: $time_to_run"
	echo "max_count: $max_count"
	echo " CPU,               MEMORY,           DISK_USAGE,                 NETWORK,                                      DISK" >> $file
}

function cpu {
	sleep $INTERVAL; result=`grep -w cpu /proc/stat | awk '{
        print (o2+o4-$2-$4)*100/(o2+o4+o5-$2-$4-$5)
        o2=$2;o4=$4;o5=$5}'`
	result=`echo $result | cut -c1-4 `"%"
	echo -ne "$result,"
}


function network {

	R1=`cat /sys/class/net/$NETWORK/statistics/rx_bytes`
        T1=`cat /sys/class/net/$NETWORK/statistics/tx_bytes`
        sleep $INTERVAL
        R2=`cat /sys/class/net/$NETWORK/statistics/rx_bytes`
        T2=`cat /sys/class/net/$NETWORK/statistics/tx_bytes`
        TBPS=`expr $T2 - $T1`
        RBPS=`expr $R2 - $R1`
        TKBPS=`expr $TBPS / 1024`
        RKBPS=`expr $RBPS / 1024`
        result=`echo "tx $1: $TKBPS kb/s rx $1: $RKBPS kb/s"`
	echo -ne "       $result,"

}

function device {
	result=`iostat | grep dm-0 | awk '{printf "tps:%d | kB_read/s:%d | kB_wrtn/s:%d | kB_read:%d | kB_wrtn:%d\n", $2,$3,$4,$5,$6}'`
	echo -ne "     $result"
}

printer
COUNTER=0
while [ $COUNTER -lt 10 ]; do
	cpu >> $file
	memory >> $file
	disk_usage >> $file
	network >> $file
	device >> $file
	echo "" >> $file
	let COUNTER=COUNTER+1
done
