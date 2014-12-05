#!/usr/bin/python2.7
import subprocess
import os
from datetime import datetime
now = datetime.now()

print 'Hello '
print "Today is "'%s-%s-%s' % (now.year, now.month, now.day)
p = subprocess.Popen(['bsctl', '-l'])
print (p)
df = subprocess.Popen(['df', '-HT'])
print ('Current disks in the system are:', df)
# Current implementation allows you to specify device for testing only directly in python test-script
td = '/dev/sda5'
print (td)
def module_restart():
	module_status = subprocess.call(['lsmod'], stdout=subprocess.PIPE)
	result_str = module_status.communicate()[0]
	status = subprocess.call(["grep" + "appassure_vss"], shell=True, stdin=module_status.stdout, stdout=subprocess.PIPE)
	print status.communicate()[0]
	return()

module_restart()

