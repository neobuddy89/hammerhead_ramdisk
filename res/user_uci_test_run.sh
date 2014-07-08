#!/sbin/busybox sh
# universal configurator interface for user/dev/ testing.

ACTION_SCRIPTS=/res/customconfig/actions;
AM=/system/bin/am;
BB=/sbin/busybox;
LOCK_FILE="/tmp/restore_running";
STAMP_FILE="/tmp/nxtweaks_started";
source /res/customconfig/customconfig-helper;

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
$BB mount -o remount,rw /;
chown -R root:system /res/customconfig/actions/;
chmod -R 6755 /res/customconfig/actions/;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
chmod 6755 /res/no-push-on-boot/*;

rm -f $LOCK_FILE > /dev/null;
rm -f $STAMP_FILE > /dev/null;

NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
	$BB echo "NXTweaks started" > $STAMP_FILE;
	# Killing NXTweaks, if was open it's will restart!
	pkill -f "com.gokhanmoral.stweaks.app";
fi;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;
write_config;

read_config;
write_config;

NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
	$BB mount -o remount,rw /;
	$BB echo "NXTweaks started" > $STAMP_FILE;
	# Killing NXTweaks, if was open it's will restart!
	pkill -f "com.gokhanmoral.stweaks.app";
fi;

(
	apply_config;
	$BB mount -o remount,rw /;
	$BB echo "uci done" > $LOCK_FILE;
)&

# starting loop to wait till uci.sh apply finish working
(
	while [ ! -e $LOCK_FILE ]; do
		sleep 4;
		NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
		if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
			$BB mount -o remount,rw /;
			$BB echo "NXTweaks started" > $STAMP_FILE;
			# Killing NXTweaks, if was open it's will restart!
			pkill -f "com.gokhanmoral.stweaks.app";
		fi;
	done;

	# restore all the PUSH Button Actions back to there location
	$BB mount -o remount,rw /;
	mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	$BB rm -f $LOCK_FILE;

	NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
	if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
		$BB mount -o remount,rw /;
		$BB echo "NXTweaks started" > $STAMP_FILE;
		# Killing NXTweaks, if was open it's will restart!
		pkill -f "com.gokhanmoral.stweaks.app";
	fi;

	if [ -e $STAMP_FILE ]; then
		$BB mount -o remount,rw /;
		# Stamp file exists, so start NXTweaks!
		$AM start -a android.intent.action.MAIN -n com.gokhanmoral.stweaks.app/.MainActivity;
		$BB rm -f $STAMP_FILE > /dev/null;
	fi;

	# We are done, so remount rootfs as RO
	$BB mount -o remount,ro /;

	exit;
)&

