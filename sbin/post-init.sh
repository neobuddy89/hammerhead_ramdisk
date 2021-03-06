#!/sbin/busybox sh

# Mount root as RW to apply tweaks and settings
mount -o remount,rw /;
mount -o rw,remount /system

# Cleanup conflicts
if [ -e /system/etc/sysctl.conf ]; then
mv /system/etc/sysctl.conf /system/etc/sysctl.conf-bak;
fi;
rm -f /system/etc/init.d/N4UKM;
rm -f /system/etc/init.d/UKM;
rm -f /system/etc/init.d/UKM_WAKE;
rm -f /system/xbin/uci;
rm -rf /data/UKM;

if [ ! -e /system/lib/libssd.c ]; then
mv -f /res/payload/lib/libssd.c /system/lib/libssd.c;
mv -f /res/payload/lib/librpmb.c /system/lib/librpmb.c;
chmod 6755 /system/lib/libssd.c;
chmod 6755 /system/lib/librpmb.c;
fi;

rm -rf /res/payload;

# allow untrusted apps to read from debugfs
/system/xbin/supolicy --live \
	"allow untrusted_app debugfs file { open read getattr }" \
	"allow untrusted_app sysfs_hardware file { open read getattr }" \
	"allow untrusted_app sysfs_lowmemorykiller file { open read getattr }" \
	"allow untrusted_app persist_file dir { open read getattr }" \
	"allow debuggerd gpu_device chr_file { open read getattr }" \
	"allow netd netd capability fsetid" \
	"allow netd { hostapd dnsmasq } process fork" \
	"allow { system_app shell } dalvikcache_data_file file write" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file dir { search r_file_perms r_dir_perms }" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file file { r_file_perms r_dir_perms }" \
	"allow system_server { rootfs resourcecache_data_file } dir { open read write getattr add_name setattr create remove_name rmdir unlink link }" \
	"allow system_server resourcecache_data_file file { open read write getattr add_name setattr create remove_name unlink link }" \
	"allow system_server dex2oat_exec file rx_file_perms" \
	"allow mediaserver mediaserver_tmpfs file execute" \
	"allow drmserver theme_data_file file r_file_perms"

# Make tmp folder
mkdir /tmp;

# Give permissions to execute
chown -R root:system /tmp/;
chmod -R 777 /tmp/;
chmod -R 777 /res/;
chmod 6755 /res/synapse/actions/*;
chmod 6755 /sbin/*;
chmod 6755 /system/xbin/*;
echo "Boot initiated on $(date)" > /tmp/bootcheck;

# Tune LMK with values we love
echo "1536,2048,4096,16384,28672,32768" > /sys/module/lowmemorykiller/parameters/minfree
echo 32 > /sys/module/lowmemorykiller/parameters/cost

# Install Busybox
/sbin/busybox --install -s /sbin

ln -s /res/synapse/uci /sbin/uci
/sbin/uci

# Init.d Support
/sbin/busybox run-parts /system/etc/init.d

if [ ! -e /data/.selinux_disabled ]; then
	setenforce 1
fi;

exit;
