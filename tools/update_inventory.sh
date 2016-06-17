#!/bin/bash
# $Id: update_inventory.sh,v 1.3 2016/02/29 17:11:08 vcojot Exp vcojot $

# Support commands
#
[ "$BASH" ] && function whence
{
        type -p "$@"
}
#
PATH_SCRIPT="$(cd $(/usr/bin/dirname $(whence -- $0 || echo $0));pwd)"

IRONIC_CMD=/usr/bin/ironic
NOVA_CMD=/usr/bin/nova
GLANCE_CMD=/usr/bin/glance
declare -a tuids names ips profiles

# Image defaults
IRONIC_PROFILE_LIST=( compute control ceph-storage swift-storage )
ANSIBLE_PROFILE_LIST=( cmpt ctrl ceph strg )
SSH_OPTS="-t -a -q -o BatchMode=Yes"

usage() {
	echo -e "Usage: $0 <stack@instack_machine> ..."
	echo -e "Example:\n\t$0 stack@10.20.30.1"
	exit 122
}

# Check arg presence..
if [ $# -lt 1 -o $# -gt 1 ]; then
        echo "No instack specified!"
        usage
else
	sshhost=$1
fi      
#

i=0
# Process nodes and skip missing/invalid ones..
scp -q ${PATH_SCRIPT}/instack_payload.sh ${sshhost}:
ssh ${SSH_OPTS} ${sshhost} "source stackrc && /bin/bash ./instack_payload.sh && rm -f ./instack_payload.sh"

i=0

instackip=$(echo $sshhost|cut -d@ -f2)
stackuser=$(echo $sshhost|cut -d@ -f1)
instack_ipmi=$(ssh ${SSH_OPTS} ${sshhost} "/usr/bin/sudo /usr/bin/ipmitool lan print 1 2> /dev/null"| awk '{ if ( $1 == "IP" && $2 == "Address" && $3 == ":" ) { print $4} }')

echo -e "[sensu_server]\n$(hostname -s) ansible_ssh_host=$(ip route get 1 | awk '{print $NF;exit}') ansible_user=$(whoami)"

if [ "x${instack_ipmi}" != "x" ]; then
	echo -e "[instack]\n$(ssh ${SSH_OPTS} ${sshhost} hostname -s) ansible_ssh_host=$instackip ansible_user=$stackuser ipmi_lan_addr=${instack_ipmi}"
else
	echo -e "[instack]\n$(ssh ${SSH_OPTS} ${sshhost} hostname -s) ansible_ssh_host=$instackip ansible_user=$stackuser"
fi

exit 0
