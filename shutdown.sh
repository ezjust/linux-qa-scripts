#!/bin/bash

case $1 in
	-a|archivelog)
  	mode=on
  	;;
	-n|noarchivelog)
  	mode=off
	;;
	*)
  	echo "I seem to be running with an nonexistent parameter..."
	exit 1
  	;;
esac

source oracle.txt

echo $DATABASE

IFS_OLD=$IFS
IFS=","; databases=( $DATABASE )
IFS=$IFS_OLD

archivelog_mode () {
	export ORACLE_SID=$3
	sqlplus /nolog << EOF 2>&1
	connect $1/$2 as sysdba
	WHENEVER SQLERROR EXIT SQL.SQLCODE
	shutdown immediate;
	startup mount;
	alter database archivelog;
	alter database open;
	select name, log_mode from v\$database; 
	exit;
EOF

}

noarchivelog_mode () {
        export ORACLE_SID=$3
        sqlplus /nolog << EOF 2>&1
        connect $1/$2 as sysdba
        WHENEVER SQLERROR EXIT SQL.SQLCODE
	shutdown immediate;
        startup mount;
        alter database noarchivelog;
        alter database open;
        select name, log_mode from v\$database; 
        exit;
EOF

}





for i in ${databases[@]}; do
	_database=`echo $i | cut -d':' -f1`
        echo "The database name is : $_database"
	login=`echo $i | cut -d':' -f2`
        echo "The database login is : $login"
	password=`echo $i | cut -d':' -f3`
        echo "The database password is : $password"
	if [[ $mode == "on" ]]; then
		archivelog_mode $login $password $_database || exit_code=$?
	elif [[ $mode == "off" ]]; then
		noarchivelog_mode $login $password $_database || exit_code=$?
	else:
		echo "No known mode selected. Exit 2"
		exit 2
	fi
	if [ "$exit_code" ]; then
		echo "Script has failed with the $exit_code error code"
		exit $exit_code
	fi
done

