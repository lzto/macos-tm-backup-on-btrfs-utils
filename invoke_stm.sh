#!/bin/bash
# 2015-2018 Tong Zhang<ztong@vt.edu>
# invoke snapshot_tm.sh till success(or timeout)

cnt=0

while [ true ]; do
	/opt/bin/snapshot_tm.sh > /tmp/tm_snapshot_log
	r=`cat /tmp/tm_snapshot_status`
	if [ $r -ne 0 ];then
		echo ""
		let cnt=cnt+1
		if [ $cnt -eq 6 ];then
			echo "Failed!"
			exit $r
		fi
		#retry in 5min
		sleep 300
	else
		exit 0
	fi
done

