#!/bin/bash
# /data/tmbk/check_and_cleanup.sh
# 2015-2018 Tong Zhang<ztong@vt.edu>
# btrfs snapshot cleanup script
# run this script in PWD=/data/tmbk

mount_point="/data/tmbk"

echo "$mount_point"

btrfs scrub status . >/dev/null 2>&1
disk_status="$?"

if [ "$disk_status" == "0" ]; then
    echo -e "DISK: \e[42m HEALTHY \e[49m"
else
    echo -e "DISK: \e[101m ERROR \e[49m (check disk scrub status)"
fi

################################################################################

dfinfo=`df -h ${mount_point} | tail -1 | awk '{print $2,$3,$4}'`
total_space=`echo $dfinfo | cut -d' ' -f1`
used_space=`echo $dfinfo | cut -d' ' -f2`
free_space=`echo $dfinfo | cut -d' ' -f3`

echo "usage total:$total_space used:$used_space free:$free_space"

################################################################################

prefix="tm_snapshot"

snapshots=`btrfs subvol list .|grep tm_snapshot|cut -d'/' -f2-|sort -n -t"_" -k1 -k2 -k3|tac`

echo "available snapshots(by date)"
echo "----------------------------"

cnt=0

for snapshot in ${snapshots[@]};do
    echo -e "\e[32m $snapshot \e[39m"
    let "cnt=cnt+1"
done

echo "Total: ${cnt}"


################################################################################

if [ "$disk_status" != "0" ]; then
    echo -e "\e[101m cleanup canceled due to a disk error\e[49m"
    exit 1
fi

purge_list=`echo "$snapshots"| tail -n +8`

if [ "$purge_list" == "" ]; then
    echo -e "\e[43m Nothing to purge \e[49m"
else
    echo "----------"
    echo "purge list"
    for dsnap in ${purge_list[@]};do
        echo -e "\e[101m $dsnap \e[49m"
    done
    echo "going to purge those snapshots in 60 seconds. Cancel with Ctrl-C."
    sleep 60
    for dsnap in ${purge_list[@]};do
        dsnap_path="${prefix}/${dsnap}"
        echo btrfs subvol del ${dsnap_path}
        btrfs subvol del ${dsnap_path}
    done
fi

echo "Done"
exit 0

