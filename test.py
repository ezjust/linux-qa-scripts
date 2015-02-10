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

def test(device):
	global device_mp
	for line in open('/proc/mounts', 'r'):
		if device in line:
			device_mp = line.split()[1]
			print (device_mp)

test(device)
print (device_mp)
print ("mount point of ", device, " is ", device_mp)

def uname():
	uname = os.uname()
	print ("***************")
	print ("operating system name" + str(uname.sysname))
	print (uname.nodename) 
	print (uname.release)
	print (uname.version)
	print (uname.machine)
	print ("===============")
uname()

def device_info(device_mp):
	device_info = os.statvfs(device_mp)
	print ("***************")
	print ("preferred file system block size: " + str(device_info.f_bsize))
	print ("fundamental file system block size: " + str(device_info.f_frsize))
	print ("total number of blocks in filesystem: " + str(device_info.f_blocks))
	print ("total number of free blocks: " + str(device_info.f_bfree))
	print ("free blocks available to non-super user: " + str(device_info.f_bavail))
	print ("total number of file nodes: " + str(device_info.f_files))
	print ("total number of free file nodes: " + str(device_info.f_ffree))
	print ("free nodes available to non-super user: " + str(device_info.f_favail))
	print ("flags: " + str(device_info.f_flag))
	print ("miximum file name length: " + str(device_info.f_namemax))
	print ("~~~~~~~~~~calculation of device_info usage:~~~~~~~~~~")
	totalBytes = float(device_info.f_bsize*device_info.f_blocks)
	print ("total space: %d Bytes = %.2f KBytes = %.2f MBytes = %.2f GBytes" % (totalBytes, totalBytes/1024, totalBytes/1024/1024, totalBytes/1024/1024/1024))
	totalUsedSpace = float(device_info.f_bsize*(device_info.f_blocks-device_info.f_bfree))
	print ("used space: %d Bytes = %.2f KBytes = %.2f MBytes = %.2f GBytes" % (totalUsedSpace, totalUsedSpace/1024, totalUsedSpace/1024/1024, totalUsedSpace/1024/1024/1024))
	totalAvailSpace = float(device_info.f_bsize*device_info.f_bfree)
	print ("available space: %d Bytes = %.2f KBytes = %.2f MBytes = %.2f GBytes" % (totalAvailSpace, totalAvailSpace/1024, totalAvailSpace/1024/1024, totalAvailSpace/1024/1024/1024))
	totalAvailSpaceNonRoot = float(device_info.f_bsize*device_info.f_bavail)
	print ("available space for non-super user: %d Bytes = %.2f KBytes = %.2f MBytes = %.2f GBytes " % (totalAvailSpaceNonRoot, totalAvailSpaceNonRoot/1024, totalAvailSpaceNonRoot/1024/1024, totalAvailSpaceNonRoot/1024/1024/1024) )
	print ("===============")


device_info(device_mp)

#def get():
#	devicedata = [subprocess.getoutput("df -hT")]
#	devicedata = devicedata[0]
#	print (devicedata)
#	for line in devicedata():
#		print line
#		if $device in line:
#			print line
#get()

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