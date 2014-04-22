#!/sbin/busybox sh

BB=/sbin/busybox

# mount partitions to begin optimization
# reload fstab options since multirom modifies fstab
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /;
$BB mount -o remount,rw,barrier=1 /system;
$BB mount -o remount,rw,noatime,nosuid,nodev,barrier=1,data=ordered,noauto_da_alloc,journal_async_commit /data;
$BB mount -o remount,rw,noatime,nosuid,nodev,barrier=1,data=ordered,noauto_da_alloc,journal_async_commit /cache;

cd /;

sleep 10;

# copy cron files
$BB cp -a /res/crontab/ /data/
$BB rm -rf /data/crontab/cron/ > /dev/null 2>&1;
if [ ! -e /data/crontab/custom_jobs ]; then
	$BB touch /data/crontab/custom_jobs;
	$BB chmod 777 /data/crontab/custom_jobs;
fi;

if [ -f /system/app/Extweaks.apk ] || [ -f /data/app/com.darekxan.extweaks.ap*.apk ] || [ -f /system/app/Stweaks.apk ] || [ -f /system/app/NXTweaks.apk ]; then
	$BB rm -f /system/app/Extweaks.apk > /dev/null 2>&1;
	$BB rm -f /data/app/com.darekxan.extweaks.ap*.apk > /dev/null 2>&1;
	$BB rm -rf /data/data/com.darekxan.extweaks.app > /dev/null 2>&1;
	$BB rm -f /data/dalvik-cache/*com.darekxan.extweaks.app* > /dev/null 2>&1;
	$BB rm -f /system/app/NXTweaks.apk > /dev/null 2>&1;
	$BB rm -f /system/app/Stweaks.apk > /dev/null 2>&1;
fi;

STWEAKS_CHECK=$($BB find /data/app/ -name com.gokhanmoral.stweaks* | wc -l);

if [ "$STWEAKS_CHECK" -eq "1" ]; then
	$BB rm -f /data/app/com.gokhanmoral.stweaks* > /dev/null 2>&1;
	$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
fi;

if [ -f /system/app/NXTweaks.apk ]; then
	nxmd5sum=$($BB md5sum /system/priv-app/NXTweaks.apk | $BB awk '{print $1}');
	nxmd5sum_kernel=$(cat /res/nxtweaks_md5);
	if [ "$nxmd5sum" != "$nxmd5sum_kernel" ]; then
		$BB rm -f /system/priv-app/NXTweaks.apk > /dev/null 2>&1;
		$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
		$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB cp /res/misc/payload/NXTweaks.apk /system/priv-app/;
		$BB chown 0.0 /system/priv-app/NXTweaks.apk;
	fi;
else
	$BB rm -f /data/app/com.gokhanmoral.*weak*.apk > /dev/null 2>&1;
	$BB rm -r /data/data/com.gokhanmoral.*weak*/* > /dev/null 2>&1;
	$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
	$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
	$BB cp -a /res/misc/payload/NXTweaks.apk /system/priv-app/;
	$BB chown 0.0 /system/priv-app/NXTweaks.apk;
fi;

# Force copy xbox controller files to fix rotator issue
$BB cp -a /res/misc/payload/Vendor_045e_Product_0719.kcm /system/usr/keychars/;
$BB cp -a /res/misc/payload/Vendor_045e_Product_0291.kl /system/usr/keylayout/;
$BB chmod 755 /system/usr/keychars/Vendor_045e_Product_0719.kcm;
$BB chmod 755 /system/usr/keylayout/Vendor_045e_Product_0291.kl;

# Copy required binaries
if [ ! -e /system/xbin/zipalign ]; then
	$BB cp -a /res/misc/payload/zipalign /system/xbin/;
	$BB chmod 755 /system/xbin/zipalign;
fi;
if [ ! -e /system/xbin/bash ]; then
	$BB cp -a /res/misc/payload/bash /system/xbin/;
	$BB chmod 755 /system/xbin/bash;
fi;

# recheck
if [ ! -f /system/priv-app/NXTweaks.apk ]; then
	$BB cp /res/misc/payload/NXTweaks.apk /system/app/;
	$BB chmod 755 /system/app/NXTweaks.apk;
fi;

# Payload not needed anymore, make some space
rm -rf /res/misc/payload > /dev/null 2>&1;
chmod 755 /system/priv-app/NXTweaks.apk;

$BB mount -o remount,rw /;
$BB mount -o remount,rw /system;
