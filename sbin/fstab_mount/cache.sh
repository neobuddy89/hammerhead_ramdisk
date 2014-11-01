#!/sbin/busybox sh

BB=/sbin/busybox

CACHE=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/cache | $BB grep "f2fs" | $BB wc -l)
PERSIST=$($BB blkid /dev/block/platform/msm_sdcc.1/by-name/persist | $BB grep "f2fs" | $BB wc -l)

if [ "${CACHE}" -eq "1" ]; then
	$BB mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/cache /cache -o nosuid,nodev;
else
	$BB mount -t ext4 /dev/block/platform/msm_sdcc.1/by-name/cache /cache -o noatime,nosuid,nodev,barrier=1,data=ordered,nomblk_io_submit,noauto_da_alloc,errors=panic;
fi;

if [ "${PERSIST}" -eq "1" ]; then
	$BB mount -t f2fs /dev/block/platform/msm_sdcc.1/by-name/persist /persist -o nosuid,nodev;
else
	$BB mount -t ext4 /dev/block/platform/msm_sdcc.1/by-name/persist /persist -o nosuid,nodev,barrier=1,data=ordered,nodelalloc,nomblk_io_submit,errors=panic;
fi;
