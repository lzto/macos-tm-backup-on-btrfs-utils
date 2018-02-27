#!/bin/bash
# 2015-2018 Tong Zhang<ztong@vt.edu>
# check tm backup vol status
# and make snapshot of good backup

PATH=/sbin:/bin:/usr/sbin:/usr/bin

date=`date +%y_%m_%d`

DEV="/dev/sda1"

TGT_MOUNT_POINT="/data/timecapsule"

BK_MTPOINT="/data/tmbk"
TGT="${BK_MTPOINT}/current"
TGT_CHKVLD="${BK_MTPOINT}/current/tmuser/macos.sparsebundle/com.apple.TimeMachine.MachineID.plist"
BK_SNAPSHOT="tm_snapshot/${date}"
BK_SNAPSHOT_PATH="${BK_MTPOINT}/${BK_SNAPSHOT}"

#check whether I am root
r=`whoami`
if [ "$r" != "root" ]; then
	echo "this script must run with root permission"
	echo "1">/tmp/tm_snapshot_status
	exit
fi

# check usage
r=`lsof -n |grep "${TGT_MOUNT_POINT}"|wc -l`
if [ $r -ne 0 ];then
	echo "someone is using target: ${TGT_MOUNT_POINT}"
	echo "1">/tmp/tm_snapshot_status
	exit
fi

#stop rsync
systemctl stop rsync

# stop netatalk
echo "Stopping netatalk"
#/etc/init.d/netatalk stop
systemctl stop netatalk

sleep 1

#check whether netatalk is stopped
r=`systemctl  status netatalk | grep Active | grep dead | wc -l`
if [ "$r" == "0" ]; then
	echo "can not stop netatalk"
	echo "1" > /tmp/tm_snapshot_status
	exit
fi

#check whether the TimeMachine backup is valid

r=`cat "$TGT_CHKVLD" | grep integer | sed 's/[^0-9]*//g'`

if [ "$r" == "0" ]; then
	echo "VerificationState is ${r}"
elif [ "$r" == "1" ]; then
	echo "VerificationState is ${r}"
elif [ "$r" == "4" ]; then
	echo "VerificationState is ${r}"
else
	echo "VerificationState is ${r}. stop."
	echo "2">/tmp/tm_snapshot_status
	exit
fi

NOW=$(date +"%Y-%m-%d_%H:%M:%S")

#create subvol

#check subvol first
r=`btrfs subvolume list ${BK_MTPOINT}|grep ${BK_SNAPSHOT}|wc -l`
if [ "$r" != "0" ]; then
	#delete old subvolume
	echo "delete old subvolume"
	btrfs subvolume delete "${BK_SNAPSHOT_PATH}"
else
	echo "no old subvolume ? "
	echo $(btrfs subvolume list ${BK_MTPOINT})
fi

#create new snapshot
btrfs subvolume snapshot ${TGT} "${BK_SNAPSHOT_PATH}"
if [ $? -eq 0 ]; then
	echo "Created subvolume ${BK_SNAPSHOT_PATH} on $NOW"
else
	echo "Failed to create subvolume ${BK_SNAPSHOT_PATH} on $NOW"
fi

#restart rsync
systemctl start rsync

#restart netatalk
echo "Starting netatalk"
#/etc/init.d/netatalk start
systemctl start netatalk

sleep 1

#check whether netatalk is started successfully
r=`systemctl  status netatalk | grep Active | grep running | wc -l`
if [ "$r" == "0" ]; then
	echo "can not start netatalk"
	echo "1" > /tmp/tm_snapshot_status
	exit
fi      

echo "Success!"

echo "0">/tmp/tm_snapshot_status

sync &

