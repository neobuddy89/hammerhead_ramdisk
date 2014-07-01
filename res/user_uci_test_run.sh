#!/sbin/busybox sh
# universal configurator interface for user/dev/ testing.

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
/sbin/busybox mount -o remount,rw /;
chown -R root:system /res/customconfig/actions/;
chmod -R 6755 /res/customconfig/actions/;
NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
	# Killing NXTweaks, if was open it's will restart!
	pkill -f "com.gokhanmoral.stweaks.app";
fi;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
chmod 6755 /res/no-push-on-boot/*;

ACTION_SCRIPTS=/res/customconfig/actions;
LOCK_FILE="/data/.chaos/restore_running";
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;
# read the config from the active profile
read_config;
write_config;

read_config;
write_config;

NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
	# Killing NXTweaks, if was open it's will restart!
	pkill -f "com.gokhanmoral.stweaks.app";
fi;

(
	rm -f $LOCK_FILE > /dev/null;
	apply_config;
	echo "uci done" > $LOCK_FILE;
)&
# starting loop to wait till uci.sh apply finish working
(
	while [ ! -e $LOCK_FILE ]; do
		sleep 4;
		NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
		if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
			# Killing NXTweaks!
			pkill -f "com.gokhanmoral.stweaks.app";
		fi;
	done;

	# restore all the PUSH Button Actions back to there location
	$BB mount -o remount,rw /;
	mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	rm -f $LOCK_FILE;

	NXTWEAKSAPP_RUNNING=$(pgrep -f "com.gokhanmoral.stweaks.app" | wc -l)
	if [ "$NXTWEAKSAPP_RUNNING" != "0" ]; then
		# Killing NXTweaks, if was open it's will restart!
		pkill -f "com.gokhanmoral.stweaks.app";
	fi;
	am start -a android.intent.action.MAIN -n com.gokhanmoral.stweaks.app/.MainActivity;
)&

