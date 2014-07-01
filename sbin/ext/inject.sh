#!/system/xbin/bash

BB=/sbin/busybox

# Are we ready?
if [ ! -e /data/app ]; then
	exit;
fi;

# Mount root as RW
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /;

# Copy cron files
$BB cp -a /res/crontab/ /data/
$BB rm -rf /data/crontab/cron/ > /dev/null 2>&1;
if [ ! -e /data/crontab/custom_jobs ]; then
	$BB touch /data/crontab/custom_jobs;
	$BB chmod 777 /data/crontab/custom_jobs;
fi;

if [ -f /data/app/NXTweaks.apk ]; then
	nxmd5sum=$($BB md5sum /data/app/NXTweaks.apk | $BB awk '{print $1}');
	nxmd5sum_kernel=$(cat /res/nxtweaks_md5);
	if [ "$nxmd5sum" != "$nxmd5sum_kernel" ]; then
		$BB rm -f /data/app/NXTweaks.apk > /dev/null 2>&1;
		$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
		$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB cp /res/misc/payload/NXTweaks.apk /data/app/;
	fi;
else
	$BB rm -f /data/app/com.gokhanmoral.*weak*.apk > /dev/null 2>&1;
	$BB rm -r /data/data/com.gokhanmoral.*weak*/* > /dev/null 2>&1;
	$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
	$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
	$BB cp -a /res/misc/payload/NXTweaks.apk /data/app/;
fi;

# Apply permissions
$BB chown 0.0 /data/app/NXTweaks.apk;
$BB chmod 755 /data/app/NXTweaks.apk;
$BB chmod -R 777 /sbin;

# Payload not needed anymore, make some space
$BB rm -rf /res/misc/payload > /dev/null 2>&1;

(
	$BB sh /sbin/ext/post-init.sh;	
)&
