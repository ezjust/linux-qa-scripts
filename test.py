#!/usr/bin/python3
import subprocess
import os
import sys
from datetime import datetime
now = datetime.now()

# TO DO: 
# 1) Add parser, to provide ability to specify device for testing directly from command line, when sript is calling
# 2) Add interactive mode, in case if device hasn`t been specified from command line. In this case, device may be selected from the available from the lsitofdevice function.

def user_root():
	user = os.getegid()
	if user != 0:
		print ("You are running using non-root user")
		sys.exit()
user_root()

def status_appassure_vss():
	log = subprocess.getstatusoutput("lsmod | grep appassure_vss")
	log = log[0]
	if log == 0:
		print ("MODULE IS LOADED")
	else:
		print ("YOUR APPASSURE_VSS MODULE IS NOT LOADED")
status_appassure_vss()


def listofdevices():
	df = [subprocess.getoutput("df -HT | grep /dev/ | awk '{print $1}'")]
	df = df[0]
	for item in df.split():
		print (item)
		print ("+")
listofdevices()

# Mount point list from system "df" command. In future can be rewritten to use /proc/.
def listofmps():
	mp = [subprocess.getoutput("df -HT | grep /dev/ | awk '{print $7}'")]
	mp = mp[0]
	for item in mp.split():
		print (item)
		print ("+")
listofmps()

device = '/dev/sda5'



def getdeviceinfo():
	
getdeviceinfo()

#def detach

#def mount 



#def module_restart():
#	print "Hello World"
#	module_status = subprocess.call("grep " + "'appassure_vss'" + " /proc/modules", shell=True)
#	if module_status == True:
#		print "Module is loaded"
#	else:
#		print "Module ISN'T loaded"
#	return()

#module_restart()