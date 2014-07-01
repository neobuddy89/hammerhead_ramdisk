#!/system/xbin/bash

# Kernel tuning by NeoBuddy89

BB=/sbin/busybox

# Mount root as RW to apply tweaks and settings
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /;
#$BB chmod -R 777 /sys/module;

# Make temp folder for multi-purpose
$BB mkdir /tmp;

# Give permissions to execute
$BB chown -R root:system /tmp/;
$BB chmod -R 777 /tmp/;
$BB chmod 6755 /sbin/ext/*;
$BB chmod -R 777 /res/;
$BB echo "Boot initiated on $(date)" > /tmp/bootcheck;

# Specify Lock File
LOCK_FILE="/data/.chaos/restore_running";
rm -f $LOCK_FILE > /dev/null;

# OOM Perm fix
$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;

# Protect important processes from OOM
echo "-1000" > /proc/1/oom_score_adj;
PIDOFINIT=$(pgrep -f "/sbin/ext/post-init.sh");
echo "-600" > /proc/"$PIDOFINIT"/oom_score_adj;

# Chaos specific tweaks
echo "0" > /proc/sys/kernel/panic_on_oops;
#echo "2" > /proc/sys/kernel/sysrq;
#echo "0" > /proc/sys/kernel/kptr_restrict;

# Make sure powersuspend use kernel mode instead of userspace
echo "0" > /sys/kernel/power_suspend/power_suspend_mode

# Init.d support
(
	$BB sh /sbin/ext/run-init-scripts.sh;
)&

if [ ! -d /data/.chaos ]; then
	$BB mkdir -p /data/.chaos;
fi;

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a$ccxmlsum" != "a`cat /data/.chaos/.ccxmlsum`" ]; then
	rm -f /data/.chaos/*.profile;
	echo "$ccxmlsum" > /data/.chaos/.ccxmlsum;
fi;

# disable sysctl.conf to prevent ROM interference with tunables
[ -e /system/etc/sysctl.conf ] && mv /system/etc/sysctl.conf /system/etc/sysctl.conf.bak;

# reset profiles auto trigger to be used by kernel ADMIN, in case of need, if new value added in default profiles
# just set numer $RESET_MAGIC + 1 and profiles will be reset one time on next boot with new kernel.
RESET_MAGIC=26;
if [ ! -e /data/.chaos/reset_profiles ]; then
	echo "0" > /data/.chaos/reset_profiles;
fi;
if [ "$(cat /data/.chaos/reset_profiles)" -eq "$RESET_MAGIC" ]; then
	echo "No need to reset NXTweaks profiles." >> /tmp/bootcheck;
else
	$BB echo "Resetting NXTweaks profiles." >> /tmp/bootcheck;
	rm -f /data/.chaos/*.profile;
	echo "$RESET_MAGIC" > /data/.chaos/reset_profiles;
fi;

[ ! -f /data/.chaos/default.profile ] && cp -a /res/customconfig/default.profile /data/.chaos/default.profile;
[ ! -f /data/.chaos/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.chaos/battery.profile;
[ ! -f /data/.chaos/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.chaos/performance.profile;

$BB chmod -R 0777 /data/.chaos/;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;
PROFILE=`cat /data/.chaos/.active.profile`;
source /data/.chaos/${PROFILE}.profile;

# Let morpheus watch over
if [ $(pgrep -f "morpheus.sh" | wc -l) -eq "0" ]; then
	nohup /sbin/ext/morpheus.sh > /dev/null 2>&1;
fi;
CORTEX=$(pgrep -f "/sbin/ext/morpheus.sh");
echo "-900" > /proc/"$CORTEX"/oom_score_adj;

(
	# stop uci.sh from running all the PUSH Buttons in stweaks on boot
	$BB mount -t rootfs -o remount,rw rootfs;
	$BB mount -o remount,rw /;
	$BB chown -R root:system /res/customconfig/actions/;
	$BB chmod -R 6755 /res/customconfig/actions/;
	$BB mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
	$BB chmod 6755 /res/no-push-on-boot/*;

	# apply NXTweaks settings
	NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
	if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
		# Killing NXTweaks!
		pkill -f "com.gokhanmoral.stweaks.app";
	fi;
	. /res/uci.sh restore;
	echo "uci done" > $LOCK_FILE;

	# restore all the PUSH Button Actions back to there location
	$BB mount -t rootfs -o remount,rw rootfs;
	$BB mount -o remount,rw /;
	$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	rm -f $LOCK_FILE;
	NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
	if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
		# Killing NXTweaks!
		pkill -f "com.gokhanmoral.stweaks.app";
	fi;

	$BB echo "Settings loaded" >> /tmp/bootcheck;

	# disable debugging on some modules
	if [ "$logger" == "off" ]; then
		echo "0" > /sys/module/kernel/parameters/initcall_debug;
		echo "0" > /sys/module/alarm/parameters/debug_mask;
		echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
		echo "0" > /sys/module/binder/parameters/debug_mask;
		echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
	fi;

	# Disable RIL power collapse
	setprop ro.ril.disable.power.collapse 1

	# Disable Google OTA Update checkin
	setprop ro.config.nocheckin 1

	# ROM Tuning
	setprop pm.sleep_mode 1
	setprop af.resampler.quality 4
	setprop audio.offload.buffer.size.kb 32
	setprop audio.offload.gapless.enabled false
	setprop av.offload.enable true

	# correct tuning, if changed by apps/rom
	$BB sh /res/uci.sh oom_config_screen_on $oom_config_screen_on;
	$BB sh /res/uci.sh oom_config_screen_off $oom_config_screen_off;

	$BB echo "ROM Tuning done" >> /tmp/bootcheck;

	# Restore mount settings for security purposes
	$BB mount -t rootfs -o remount,ro rootfs;
	$BB mount -o remount,ro /;

	exit;
)&
