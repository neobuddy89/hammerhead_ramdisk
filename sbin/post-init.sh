#!/sbin/busybox sh

BB=/sbin/busybox

# Mount root as RW to apply tweaks and settings
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /;
mount -o rw,remount /system

# Cleanup conflicts
if [ -e /system/etc/sysctl.conf ]; then
mv /system/etc/sysctl.conf /system/etc/sysctl.conf-bak;
fi;
if [ -e /system/bin/thermal-engine-hh ]; then
mv /system/bin/thermal-engine-hh /system/bin/thermal-engine-hh-bak;
fi;

# allow untrusted apps to read from debugfs
/system/xbin/supolicy --live \
	"allow untrusted_app debugfs file { open read getattr }" \
	"allow untrusted_app sysfs_lowmemorykiller file { open read getattr }" \
	"allow untrusted_app persist_file dir { open read getattr }" \
	"allow debuggerd gpu_device chr_file { open read getattr }" \
	"allow netd netd capability fsetid" \
	"allow netd { hostapd dnsmasq } process fork" \
	"allow { system_app shell } dalvikcache_data_file file write" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file dir { search r_file_perms r_dir_perms }" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file file { r_file_perms r_dir_perms }" \
	"allow system_server { rootfs resourcecache_data_file } dir { open read write getattr add_name setattr create remove_name rmdir unlink link }"\
	"allow system_server resourcecache_data_file file { open read write getattr add_name setattr create remove_name unlink link }"

# Make tmp folder
$BB mkdir /tmp;

# Give permissions to execute
$BB chown -R root:system /tmp/;
$BB chmod -R 777 /tmp/;
$BB chmod -R 777 /res/;
$BB chmod 6755 /res/synapse/actions/*;
$BB chmod 6755 /sbin/*;
$BB chmod 6755 /system/xbin/*;
$BB echo "Boot initiated on $(date)" > /tmp/bootcheck;

$BB echo "1536,2048,4096,16384,28672,32768" > /sys/module/lowmemorykiller/parameters/minfree
$BB echo 32 > /sys/module/lowmemorykiller/parameters/cost

ln -s /res/synapse/uci /sbin/uci
/sbin/uci
