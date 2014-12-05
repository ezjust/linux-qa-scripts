#!  /usr/bin/python
import os
import subprocess as sp # using subprocess for executing bash scripts in Python 2.7
import hashlib # for calculating MD5 of the file
import sys
from optparse import OptionParser, SUPPRESS_HELP
parser = OptionParser(add_help_option=False)
parser.add_option("-h", "--help", action="help")
parser.add_option("-v", "--volume", dest="volume", help="Volume for testing", metavar="volume")
parser.add_option('-p', '--path', dest="path", help="Path, where image will be placed", metavar="path")
sys.argv[1:]
(options, args) = parser.parse_args (sys.argv[1:])
print sys.argv[1:]
if options.volume is None:
	print("Hello, what volume are you going to test?")
	print ('*********************************************')
	proc = sp.Popen(["df", "-h"], stdout=sp.PIPE) # It will provide you ability to see output of the bash command "df-h"
	for line in proc.stdout:
       		 print(line)
        volume = raw_input("Pls, input volume for testing:  ")
else:
        volume = str(options.volume)
if options.path is None:
	path = raw_input("pls, input path for image: ") # path where image will be writen
	print ('*********************************************')
	print path, 'was chosen for writing image'
	print('**********************************************')
else:
	path = str(options.path)


df = sp.Popen(["df", "-P"], stdout=sp.PIPE)
grep = sp.Popen(["grep " + volume], shell=True, stdin=df.stdout, stdout=sp.PIPE) # performed greping from user keyboard word in bash "df -P"
for line in grep.stdout:
	words = line.split() # performed splited array 
	print words[1], 'Size'
	print words[3], 'Available'

print words[3], 'Available for COW'
print words[5]

os.system("bsctl -l")
os.system("bsctl -e " + volume)
os.system("bsctl -x " + volume)
os.system("bsctl -d " + volume)
os.popen('rm -rf ' + words[5] + "/.blksnap")
os.system("bsctl -a " + volume)
os.system("bsctl --create-bitmap-store " + volume)
os.system("bsctl --map-bitmap-store " + volume)
os.system("bsctl --create-data-store " + volume)
os.system("bsctl --map-data-store " + volume)
# After last one operation device is ready for performing snapshots using bsrw

# I am going to create test file on original volume mount point. The size will be 1GB

mount_point = words[5] # in this step we adress mount point of the device for testing
size = 1024 * 1024 # with default block_size current size of test file will be 1GB


def file_create(size): # function of creating file for testing
        block = '0' * 1024 # 1KB
        fo = open(mount_point + 'python_test_file.img', "wb") # this operation will allow you to create/open file with "write binary" privileges.
        for x in range(size): # the range(size) provies you ability to perfom opearation each time while x < size
                fo.write(block) # it will give you ability to write in file block by block (in my case block is 1KB of '0' characters)
        fo.close()

file_create(size) # here we call function 
print mount_point + 'python_test_file.img' " was created with " + str(size) + " MB"

os.system("bsctl -s " + volume) # this command will freeze device
os.system("bsrw " + volume + " " + path) # this command will write image to "path"

bsctl = sp.Popen(["bsctl", "-l"], stdout=sp.PIPE)
snap_device = sp.Popen(["grep " + volume], shell=True, stdin=bsctl.stdout, stdout=sp.PIPE)
for line in snap_device.stdout:
	words = line.split()
print words[2]
print '/dev/'
print '/dev/' + str(words[2])
sn_device = str("/dev/") + str(words[2])


md5sum = [volume, path, sn_device]

for index in range(len(md5sum)):
 f = open(md5sum[index]) # open file for reading
 def md5sum_of_file(f, block_size=4096):   # created function for reading file using blocks
	md5 = hashlib.md5() 
	while True:
		data = f.read(block_size)  # reading file block by block
		if not data:
			break
		md5.update(data)  # updating md5 with full data
	return md5.hexdigest() 
 print 'The MD5 of the ', md5sum[index] + ' is : ', md5sum_of_file(f)

                                                                                                                                                                                     
~                                                                                                                                                                                     
~                                                                                                                                                                                     
~                               
	
