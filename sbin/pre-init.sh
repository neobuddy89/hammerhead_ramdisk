#!/sbin/busybox sh

BB=/sbin/busybox

# Mount root as RW to apply tweaks and settings
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /;

# Give permissions to execute
$BB chmod 6755 /sbin/*;
$BB echo "FS initiated on $(date)" > /fstcheck;

SYSTEM=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/system | $BB grep "f2fs" | $BB wc -l);
DATA=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/userdata | $BB grep "f2fs" | $BB wc -l);
CACHE=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/cache  | $BB grep "f2fs" | $BB wc -l);

SYSTEM_TYPE=0;
DATA_TYPE=0;
CACHE_TYPE=0;

if [ "$SYSTEM" -eq "1" ]; then
	SYSTEM_TYPE=1;
fi;
if [ "$DATA" -eq "1" ]; then
	DATA_TYPE=1;
fi;
if [ "$CACHE" -eq "1" ]; then
	CACHE_TYPE=1;
fi;

if [ "$SYSTEM_TYPE" -eq "0" ] && [ "$DATA_TYPE" -eq "1" ] && [ "$CACHE_TYPE" -eq "1" ]; then
	$BB cp /sbin/fstab/fstab_cache_data.hammerhead /fstab.hammerhead;
else if [ "$SYSTEM_TYPE" -eq "1" ] && [ "$DATA_TYPE" -eq "1" ] && [ "$CACHE_TYPE" -eq "1" ]; then
	$BB cp /sbin/fstab/fstab_cache_data_system.hammerhead /fstab.hammerhead;
else
	$BB cp /sbin/fstab/fstab.hammerhead /fstab.hammerhead;
fi;
