#!/bin/bash
FILE="TC.log"
username="dev-softheme"
password="123asdQ"
branch="7.1.0"
link="https://tc.appassure.com/viewType.html?buildTypeId=AppAssure_Linux_RebrandedDevelop_AgentBuilds_Debian8x64"
wget --auth-no-challenge --no-check-certificate --user=$username --password=$password $link -O "$FILE" > /dev/null 2>&1
id=`cat TC.log | grep "build:" | grep -E -o "buildId=[[:digit:]]*" | sort -n -r | cut -d "=" -f2 | sed -n 2p`
build=`cat $FILE | grep -E -o "#develop-7.1.0.[[:digit:]]*" | cut -d "." -f4 | sed -n 1p`
echo "Retrieving of the $branch.$build LiveDVD"
#rm -r $FILE # cleanup html page, since it is not needed anymore
function build {
	build_link="https://tc.appassure.com/repository/download/AppAssure_Linux_RebrandedDevelop_AgentBuilds_Debian8x64/$id:id/rapidrecovery-livedvd-$branch.$build.iso"
}
build
error_code=`wget --auth-no-challenge --no-check-certificate --user=$username --password=$password -q --spider $build_link; echo $?`

echo $build_link

while [ $error_code != 0 ]
do
	build=$(($build -1))
	build
	error_code=`wget --auth-no-challenge --no-check-certificate --user=$username --password=$password -q --spider $build_link; echo $?`
	echo $build_link
	echo "Retrieving of the $branch.$build LiveDVD"
done

echo "Retrieving of the $branch.$build LIVEDVD iso has been completed. $branch.$build LiveDVD starts to be downloaded."
aria2c -x 16 --http-user=$username --http-passwd=$password $build_link --out="Livedvd.iso"

