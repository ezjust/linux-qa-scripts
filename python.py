#!/usr/bin/python

import os
import platform

linux_distribution = platform.linux_distribution()[0]
#linux_distribution = "debian"

#print linux_distribution
#distribution = "None"
print linux_distribution, 'is the distribution'
def linux_distribution(linux_distribution):
	distribution = "None"
	linux_distribution = platform.linux_distribution()[0]
	if linux_distribution=="Ubuntu" or linux_distribution=="debian":
		distribution = "Ubuntu"
	elif linux_distribution=="CentOS Linux" or linux_distribution=="redhat":
		distribution = "CentOS"
	elif linux_distribution=="SuSE":
		distribution = "SuSE"
	print distribution
	return distribution




linux_distribution(linux_distribution)

#Update system
#os.system("sudo apt-get update 2>/dev/null 1>$2")
# Install of the rapidrecovery-agent with "Yes" options
#os.system("apt-get --yes --force-yes install rapidrecovery-agent")

#os.system("bsctl -l")