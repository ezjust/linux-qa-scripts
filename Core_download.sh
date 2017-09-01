#!/bin/bash
FILE="TC.log"
username="mbugaiov"
branch="7.1.0"
link="https://tc.appassure.com/viewType.html?buildTypeId=AppAssure_Windows_Develop20_FullBuild"
wget --no-check-certificate --user=mbugaiov --password=123asdQQ\!@#$ $link -O "$FILE" > /dev/null 2>&1
id=`cat TC.log | grep "build:" | grep -E -o "buildId=[[:digit:]]*" | sort -n -r | cut -d "=" -f2 | sed -n 1p`
build=`cat $FILE | grep -E -o "#develop-7.1.0.[[:digit:]]*" | cut -d "." -f4 | sed -n 1p`
echo "Retrieving of the $branch.$build Core"
#rm -r $FILE # cleanup html page, since it is not needed anymore
build_link="https://tc.appassure.com/repository/download/AppAssure_Windows_Develop20_FullBuild/$id:id/installers/Core-X64-$branch.$build.exe"
error_code=`wget --no-check-certificate --user=mbugaiov --password=123asdQQ\!@#$ -q --spider $build_link; echo $?`

echo $build_link

while [ $error_code != 0 ]
do
	build=$(($build -1))
	build_link="https://tc.appassure.com/repository/download/AppAssure_Windows_Develop20_FullBuild/$id:id/installers/Core-X64-$branch.$build.exe"
	error_code=`wget --no-check-certificate --user=mbugaiov --password=123asdQQ\!@#$ -q --spider $build_link; echo $?`
	echo $build_link
	echo "Retrieving of the $branch.$build Core"
done

echo "Retrieving of the $branch.$build Core build has been completed. $branch.$build Core starts to be downloaded."
aria2c -x 16 --http-user=$username --http-passwd=123asdQQ\!@#$ $build_link

