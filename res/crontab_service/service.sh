#!/system/xbin/bash

mount -o remount,rw /;
mount -o remount,rw /system;

# allow custom user jobs
if [ ! -e /data/crontab/root ]; then
	mkdir /data/crontab/;
	cp /res/crontab_service/cron-root /data/crontab/root;
	chown 0:0 /data/crontab/root;
	chmod 777 /data/crontab/root;
fi;

if [ ! -e /system/etc/cron.d/crontabs ]; then
	mkdir -p /system/etc/cron.d/crontabs;
	cp -a /data/crontab/root /system/etc/cron.d/crontabs/;
	chown 0:0 /system/etc/cron.d/crontabs/*;
	chmod 777 /system/etc/cron.d/crontabs/*;
fi;
echo "root:x:0:0::/system/etc/cron.d/crontabs:/sbin/sh" > /etc/passwd;

# set timezone
TZ=UTC

# set cron timezone
export TZ

#Set Permissions to scripts
chown 0:0 /data/crontab/cron-scripts/*;
chmod 777 /data/crontab/cron-scripts/*;

# use /system/etc/cron.d/crontabs/ call the crontab file "root"
if [ -e /system/xbin/busybox ]; then
	chmod 6755 /system/xbin/busybox;
	nohup /system/xbin/busybox crond -c /system/etc/cron.d/crontabs/
elif [ -e /system/bin/busybox ]; then
	chmod 6755 /system/bin/busybox;
	nohup /system/bin/busybox crond -c /system/etc/cron.d/crontabs/
fi;
