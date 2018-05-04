#!/bin/bash

case $1 in
	-a|--archivelog)
  	mode=on
  	;;
	-n|--noarchivelog)
  	mode=off
	;;
	-b|--begin)
	mode=begin
	;;
	-e|--end)
	mode=end
	;;
	*)
  	echo "I seem to be running with an nonexistent parameter..."
	echo "-a|--archivelog   - Turn to ARCHIVELOG MODE"
	echo "-n|--noarchivelog - Turn to NOARCHIVELOG MODE"
	echo "-b|--begin        - Begin backup"
	echo "-e|--end          - End backup"
	exit 1
  	;;
esac

<<COMMENT
The oracle.conf file is the file, where credentials to the oracle databases
are set.
Example of the file:
# The following description:
# databas name : user to login : password for the user

DATABASE=XE:sys:123,TEST:123:qwe 

Where:
 'DATABASE' is the string variable.
 'XE'      - the ORACLE_SID   (`ps -ef | grep -e _pmon_ | head -n 1 | awk '{print $8}' | cut -d'_' -f3`);
 'sys'     - login to the specified database instance;
 '123'     - Password for the login user to the specified database instance;
 ','       - Separator between databases;

COMMENT

if [ -f oracle.conf ]; then
    source oracle.conf
else
    echo "The configuration file oracle.conf is not found. This file needs to be in the same folder, where"
    echo "running snap_oracleDB.sh is."
    exit 1
fi

echo $DATABASE
sqlplus=`which sqlplus`

IFS_OLD=$IFS
IFS=","; databases=( $DATABASE )
IFS=$IFS_OLD

archivelog_mode () {
	export ORACLE_SID=$3
	$sqlplus /nolog << EOF 2>&1
	connect $1/$2 as sysdba
	WHENEVER SQLERROR EXIT SQL.SQLCODE;
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
        $sqlplus /nolog << EOF 2>&1
        connect $1/$2 as sysdba
        WHENEVER SQLERROR EXIT SQL.SQLCODE;
        shutdown immediate;
        startup mount;
        alter database noarchivelog;
        alter database open;
        select name, log_mode from v\$database; 
        exit;
EOF

}

begin_backup () {
        export ORACLE_SID=$3
        $sqlplus /nolog << EOF 2>&1
        connect $1/$2 as sysdba
        WHENEVER SQLERROR EXIT SQL.SQLCODE;
        alter database begin backup;
        select * from v\$database;
        select name, log_mode, open_mode from v\$database;
        SELECT INSTANCE_NAME, STATUS, DATABASE_STATUS FROM V\$INSTANCE;
        exit;
EOF

}

end_backup () {
        export ORACLE_SID=$3
        $sqlplus /nolog << EOF 2>&1
        connect $1/$2 as sysdba
        WHENEVER SQLERROR EXIT SQL.SQLCODE;
        alter database end backup;
        select * from v\$backup;
        select name, log_mode, open_mode from v\$database;
        SELECT INSTANCE_NAME, STATUS, DATABASE_STATUS FROM V\$INSTANCE;
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
        elif [[ $mode == "begin" ]]; then
		begin_backup $login $password $_database || exit_code=$?
        elif [[ $mode == "end" ]]; then
		end_backup $login $password $_database || exit_code=$?
        else
		echo "No known mode selected. Exit 2"
		exit 2
        fi
        if [ "$exit_code" ]; then
		echo "Script has failed with the $exit_code error code"
		exit $exit_code
        fi
done

