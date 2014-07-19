#!/system/xbin/bash

# Kernel tuning by NeoBuddy89

BB=/sbin/busybox

# Mount root as RW to apply tweaks and settings
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /;
#$BB chmod -R 777 /sys/module;

# Make tmp folder to support NXTweaks smooth execution
$BB mkdir /tmp;

# Give permissions to execute
$BB chown -R root:system /tmp/;
$BB chmod -R 777 /tmp/;
$BB chmod 6755 /sbin/ext/*;
$BB chmod -R 777 /res/;
$BB echo "Boot initiated on $(date)" > /tmp/bootcheck;

# OOM Perm fix
$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;

# Protect important process from OOM
echo "-1000" > /proc/1/oom_score_adj;

# Chaos specific tweaks
echo "0" > /proc/sys/kernel/panic_on_oops;
#echo "2" > /proc/sys/kernel/sysrq;
#echo "0" > /proc/sys/kernel/kptr_restrict;

# Make sure powersuspend use kernel mode instead of userspace
echo "0" > /sys/kernel/power_suspend/power_suspend_mode

# Init.d support
$BB sh /sbin/ext/run-init-scripts.sh;

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
RESET_MAGIC=27;
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

PROFILE=`cat /data/.chaos/.active.profile`;
source /data/.chaos/${PROFILE}.profile;

# This script will take care of everything.
$BB sh /res/user_uci_test_run.sh > /dev/null;

$BB echo "Settings started loading." >> /tmp/bootcheck;

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

$BB echo "ROM Tuning done" >> /tmp/bootcheck;
