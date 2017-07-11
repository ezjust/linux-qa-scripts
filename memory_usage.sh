#!/bin/bash

# Use: "nohup memory_usage.sh &" to run the script.
# To track results: cat $HOME/memory_usage
# Each restart of the agent is handled by the using appropriate pid.
# To stop script:
# ps axf | grep memory_usage
# kill -9 pid_of_the_script.


file_to_store="$HOME/memory_usage"
pid=`pidof /opt/apprecovery/mono/bin/mono`
timeout="300"

while [[ ! -z $pid ]]; do
	command=`echo $(top -n1 -b -p $pid | grep mono) $(date) >> $file_to_store`
	sleep $timeout
	pid=`pidof /opt/apprecovery/mono/bin/mono`
done
