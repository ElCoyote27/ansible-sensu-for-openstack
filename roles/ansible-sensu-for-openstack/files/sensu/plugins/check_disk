#!/bin/sh
#
# Version 0.0.2 - Jan/2009
# Changes: df -P (to avoid it from breaking long lines)
#
# by Thiago Varela - thiago@iplenix.com

function help {
	echo -e "\n\tThis plugin shows the % of used space of a mounted partition, using the 'df' utility\n\n\t$0:\n\t\t-c <integer>\tIf the % of used space is above <integer>, returns CRITICAL state\n\t\t-w <integer>\tIf the % of used space is below CRITICAL and above <integer>, returns WARNING state\n\t\t-d <device>\tThe partition or mountpoint to be checked. eg. "/dev/sda1", "/home", "/""
	exit -1
}

# Getting parameters:
while getopts "d:w:c:h" OPT; do
	case $OPT in
		"d") device=$OPTARG;;
		"w") warning=$OPTARG;;
		"c") critical=$OPTARG;;
		"h") help;;
	esac
done

# Checking parameters:
( [ "$warning" == "" ] || [ "$critical" == "" ] ) && echo "ERROR: You must specify warning and critical levels" && help
[ "$device" == "" ]  && echo "ERROR: You must specify the partition to be checked" && help
[[ "$warning" -ge  "$critical" ]] && echo "ERROR: Critical level must be highter than warning level" && help

# Assuring the device was correctly specified:
( [[ `df | grep -w $device | wc -l` -gt 1 ]] || [[ `df | grep -w $device | wc -l` -lt 1 ]] ) && echo "ERROR: Partition incorrectly specified" && help

# Doing the actual check:
used=`df -P | grep -w $device | awk '{ print $5 }' | cut -d% -f1`

# Comparing the result and setting the correct level:
if [[ $used -ge $critical ]]; then
        msg="CRITICAL"
        status=2
else if [[ $used -ge $warning ]]; then
        msg="WARNING"
        status=1
     else
        msg="OK"
        status=0
     fi
fi

# Printing the results:
echo "$msg - $device space used=$used% | '$device usage'=$used%;$warning;$critical;"

# Bye!
exit $status
