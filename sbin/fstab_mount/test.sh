#!/sbin/busybox sh

BB=/sbin/busybox
$BB mount -t rootfs -o remount,rw rootfs;
$BB mount -o remount,rw /;
$BB touch /sbin/fstab_mount/okay;
