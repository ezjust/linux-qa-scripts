#!/bin/bash
#set -x
if [ -z "$1" ]
then
	echo "Please specify the integer"	
	exit 1
else
	x=$1
	echo $x
fi
a=0
b=1

while [[ "$a" -le "$x" ]]
do
	let c="$a"+"$b"
	let a="$c"+"$b"
	let b="$c"+"$a"
	if [[ "$x" -eq "$c" ]] || [[ "$x" -eq "$b" ]] || [[ "$x" -eq "$a" ]]
	then
		echo $x is FIBONACHINE
	
	fi
done
	
if [[ "$a" -ne "$x" ]] && [[ "$b" -ne "$x" ]] && [[ "$c" -ne "$x" ]]
then
	echo $x is NOT fibonachi
fi		


