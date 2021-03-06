#!/usr/bin/env bash
#set -x
ver="1.0.3"

check_version=`wget -O- -q https://raw.github.com/mbugaiov/myrepo/master/agent_install.sh | head -3 | grep -w ver | cut -d= -f2 | tr -d '"'`

if [[ "$check_version" != "$ver" ]]; then
	echo "There is newest version on the GitHub"
	echo "You are running the $ver version of the script"
	echo "There is available the $check_version version on the GitHub"
	exit 1
fi


function helper {

        echo "This script is used by the Linux QA Team to run everyday tasks."
        echo "Usage: agent_install [options] <argv>"
        echo ""
        echo "       -h                      Show help options."
        echo "       -v                      Print current version of the script."
        echo "       -c/--clean          Perfrom unsinstall of the rr-agent and suggested packages. For this option repo package also will be removed."
        echo "       -i/--install        <Version>, <Repo file> You will need to specify version of the branch to install the newest available package or you can specify dedicated repo file to be installed."
        echo "                               <Repo file> - if this argv is used, please, make sure that repo file is executable. To make file executable, please do the next: "chmod +x file"."
        echo ""
        echo "Example: "
        echo "       agent_install -h/--help"
        echo "       agent_install -v/--version"
        echo "       agent_install -l/--logs"
        echo "       agent_install -c/--clean"
        echo "       agent_install -i/--install -b/--branch=7.0.0/7.1.0"
        echo "       agent_install --install --branch=7.1.0"
}

if [[ -z $@ ]]; then
        tput setaf 1; echo "ERROR: No arguments"; tput sgr0
	echo ""
        helper  
        exit 1
fi


for i in "$@"
do
case $i in
    -h|--help)
    HELP=y
    shift # past argument=value
    ;;
    -c|--clean)
    CLEAN=y
    shift # past argument=value
    ;;
    -i|--install)
    INSTALL=y
    shift # past argument=value
    ;;
    -b=*|--branch=*)
    BRANCH="${i#*=}"
    shift # past argument=value
    ;;
    -k=*|--kernel=*)
    kernel="${i#*=}"
    shift # past argument=value
    ;;
    -l|--logs)
    LOGS=y
    shift # past argument=value
    ;;
     -v|--version)
    VERSION=y
    shift # past argument=value
    ;;
    *)
    tput setaf 1; echo "ERROR: Incorrect argument"; tput sgr0
    echo ""
    helper
    exit 1          # unknown option
    ;;
esac
done


if [[ -n $HELP ]]; then
	helper
	exit 0
fi

package_name=rapidrecovery-agent
rr_config=/usr/bin/rapidrecovery-config


function repo_cleaner {
echo "Repository cleaner"
if [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]
then
operator="apt-get"
package="dpkg"
installed="dpkg -l"
fi

if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]
then
operator="yum"
package="rpm"
installed="rpm -qa"
fi

if [ -f /etc/SuSE-release ]
then
operator="zypper"
package="rpm"
installed="rpm -qa"
fi

/etc/init.d/rapidrecovery-agent stop 1>&2 2>/dev/null
systemctl stop repidrecovery-agent 1>&2 2>/dev/null
rmmod rapidrecovery-vss 1>&2 2>/dev/null

if [ "$operator" = "zypper" ]
then
	$operator remove -y rapidrecovery-agent
	$operator remove -y rapidrecovery-mono
	$operator remove -y dkms
	$operator remove -y rapidrecovery-repo
	$operator remove -y nbd
	rmmod rapidrecovery-vss
	$operator clean
else
	$operator -y remove rapidrecovery-agent
	$operator -y remove rapidrecovery-mono
	$operator -y remove dkms
	$operator -y remove rapidrecovery-vss
	$operator -y remove rapidrecovery-repo
	rmmod rapidrecovery-vss
	$operator clean all
fi

not_removed=`$installed | grep rapid | awk '{print $2}'`
if [ -z $not_removed ]
then 
	tput setaf 2; echo "All RR packages were removed"; tput sgr0
		else 
			echo $not_removed package is not REMOVED. Will try to remove it with configuration files.
			$operator -y purge $not_removed
			if [ -z `$installed | grep $not_removed | awk '{print $2}'` ]
			then 
		 		tput setaf 3; echo $not_removed package has been removed with configuration files; tput sgr0
				return 0	
					else 
						tput setaf 1; echo "Package has not been removed even using configuration option. PLEASE INVESTIGATE THIS FACT."; tput sgr0
						return 1
			fi
fi

}

echo $BRANCH

if [[ -n $CLEAN ]]
then
	repo_cleaner
	exit 0	
fi


function get_installation_info {

	echo "Agent Installer Script"
if [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]
then
operator="apt-get"
list="dpkg -l"
install="dpkg -i"
os="debian"
	if [[ `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "18"  || `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "17"  || `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "16"  || `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "15" || `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "9" || `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "8" ]]; then
	version="8"
	fi
	
	if [[ `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "12"  || `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "14" || `cat /etc/os-release | grep VERSION_ID | awk -F '["/.]' '{print $2}'` -eq "7" ]]; then
	version="7"
	fi

arch=$(arch)
if [ "$arch" == "i686" ]; then
	arch="x86_32"
fi
package="deb"
fi

if [ -f /etc/redhat-release ]
then
operator="yum"
list="rpm -qa"
install="rpm -i"
os=rhel
version=$(cat /etc/os-release | grep -w VERSION_ID= | awk -F '["/.]' '{print $2}')
if [ -z $version ]; then
        version=$(cat /etc/centos-release | awk '{print$3}'| awk -F '["/.]' '{print $1}')
        if [ -z $version ]; then
                version=$(cat /etc/redhat-release | awk '{print$7}'| awk -F '["/.]' '{print $1}')
                if [ -z $version ]; then
        			echo "Error occured to identify OS version"
        			exit 1
				fi
        fi
fi

arch=$(arch)

if [ "$arch" == "i686" ]; then
        arch="x86_32"
fi
package="rpm"
fi

if [ -f /etc/SuSE-release ] || [ -f /etc/SUSE-brand ]
then
operator="zypper"
list="rpm -qa"
install="rpm -i"
os=sles
version=$(cat /etc/SuSE-release | grep VERSION | awk '{print $3}')
if [ -z $version ]; then
	version=$(cat /etc/SUSE-brand | grep VERSION | awk '{print $3}')
fi
if [ "$version" == "13.3" ]; then
	version="12"
fi
arch=$(arch)
if [ "$arch" == "i686" ]; then
        arch="x86_32"
fi
package="rpm"
fi

echo $operator

echo "List of the packages before installation"
$list | grep 'rapid\|nbd\|dkms'	

}


function install_repo {
get_installation_info
if [ "${#BRANCH}" -gt "5" ]
then 
	$install $BRANCH
	if [ $? -ne "0" ]
	then
		echo "$BRANCH is not available for installation."
		exit 1
	fi
else
	wget "https://s3.amazonaws.com/repolinux/$BRANCH/repo-packages/rapidrecovery-repo-$os$version-$arch.$package" -O "repo.file"

	if [ $? -ne "0" ]
	then
		echo "$BRANCH is not available for installation"
		exit 1
	fi
	chmod +x repo.file
	$install repo.file 
		
fi
}




function installation {

if [ $operator = "zypper" ]
then
$operator clean --all
        if [ "$version" -lt "12" ]
        then
        $operator install -y $package_name
                if [ "$?" -eq "1" ]
                then
                echo "Errors occurred during packages downloading"
                exit 1
                fi
        else
        $operator --no-gpg-check install -y $package_name
                if [ "$?" -eq "1" ]
                then
                echo "Errors occurred during packages downloading"
                exit 1
                fi
        fi
else
        $operator clean all
        echo "n" | $operator update >> /dev/null
        $operator install "-y" $package_name
        if [ "$?" -eq "1" ]
        then
            echo "Errors occurred during packages downloading"
            exit 1

        # block belowe should prevent us from the Release file not found on the install agent stage.
        
        elif [[ "$?" -eq "100" ]]; then
            counter=0
            while [[ $error_code != "0" ]] && [[ $counter -le 10 ]]; do
                $operator install "-y" $package_name
                error_code=`$?`
                let 'counter=counter+1'
                sleep 60
                echo 'sleeping'
            done
        fi

fi
}



function update {
echo "update"
}


function check_install {


packages_result=`$list | grep -w 'rapidrecovery-agent\|rapidrecovery-mono\|rapidrecovery-repo' | wc -l`
configuration_result=`less /var/log/apprecovery/configuration_tmp.log | grep Fail >> /dev/null; echo $?`
installation_result=`cat /var/log/apprecovery/agent.installation.log | grep Fail >> /dev/null; echo $?`
if [[ "$packages_result" -eq "3" && "$configuration_result" -ne "0" && "$installation_result" -ne "0" ]]
then
    echo "All packages are installed"
else
    tput setaf 1; echo "Errors occured in agent install"; tput sgr0
exit 1
fi

}



function configuration {
user=rr
password=123asdQ
port=8006
string=`cut -d: -f1 /etc/passwd` # get list of all users
sudoers=`sudo cat /etc/sudoers`
useradd $user
groupadd $user
useradd -G $user $user

check_firewall_status=$($rr_config -f list >> /dev/null; echo $?)
if [[ "$check_firewall_status" -eq "0" ]]; then
        firewall=$($rr_config -f list | grep manual| awk -F'[_/]' '{print $1}')  # grep manual is temporary solution to avoid failing state. For now list commands returns not only the list of the firewalls.
fi

#   We use two available option:
#    all - for building module for all kernels
#    current - to build fo the current module only
#   All other option should return an error.

if [[ -z $kernel ]] || [[ "$kernel" = "all" ]]; then
    kernel_to_build="all"
else
    if [[ "$kernel" = "current" ]]; then
        kernel_to_build=`sudo rapidrecovery-config -m -1 | grep current | awk {'print $1'} | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"`
    elif [[ "$kernel" = "no" ]]; then
        kernel_to_build=""
    else
        echo "Incorrect kernel number is used for the rapidrecovery-config. The number was: $kernel"
    fi
fi

#echo "1 $port" | $rr_config # configure default port for transfering

echo $user:$password | chpasswd

echo "2 $user" | $rr_config # add new user to allow to use it for protection

if [[ -n $kernel_to_build ]]; then                # check that variable is not NONE. Somethimes we do not want to build module
    (echo 4 $kernel_to_build;) | $rr_config # install rapidrecovery-vss into system kernels
fi
echo "5" | $rr_config # allow to start agent immediately

if [[ -n $firewall ]]; then # In case if firewall is not Null - means enabled.
        echo "3 $firewall" | $rr_config # use first available option to configure firewall.
fi

if echo $string | grep -w vagrant >> /dev/null; then
	echo "2 vagrant" | $rr_config # add vagrant user as a user allowed for the protection. Used in autotests.
fi
}



function details {
IP=$(ip addr show | grep '10.10' | awk '{print $2}' | cut -d'/' -f1)

echo "$IP"
echo "$user::$password"
echo "$(uname -r)"
 
}


function get_logs {
log_dir=/home/$user/Logs
mkdir $log_dir
cp -R /var/log/apprecovery $log_dir
cp /var/log/messages $log_dir >> /dev/null
cp /var/log/syslog $log_dir >> /dev/null
tar -zcvf Logs-$IP-$(date | awk {'print $5'}) $log_dir
}

if [[ -n $LOGS ]]; then
	get_logs
	echo "LOGS"
	exit 0
fi

if [[ -n $VERSION ]]; then
	echo $ver
	exit 0
fi

#function 

echo *********************************
echo $os$version
echo *********************************
install_repo
installation # we run installation process
configuration # user added; rapidrecovery-vss is built for all available kernels; agent started;
details # details are provided for further protection
check_install # parse logs for the errors
