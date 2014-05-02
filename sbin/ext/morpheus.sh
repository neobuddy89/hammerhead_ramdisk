#!/sbin/busybox sh

mount -o remount,rw /;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
DATA_DIR=/data/.chaos;

# ==============================================================
# INITIATE
# ==============================================================

# get values from profile
PROFILE=$(cat $DATA_DIR/.active.profile);
. "$DATA_DIR"/"$PROFILE".profile;

CPUFREQ_FIX()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "$scheduler" > /sys/block/mmcblk0/queue/scheduler
		if [ "$scaling_max_freq" -eq "2265600" ] && [ "$scaling_max_freq_oc" -gt "2265600" ]; then
			MAX_FREQ="$scaling_max_freq_oc";	
		else
			MAX_FREQ="$scaling_max_freq";
		fi;
		echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
		echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
		echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
		echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
		echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
		echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
		echo "$scaling_min_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
	elif [ "$state" == "sleep" ]; then
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
		echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
		echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
		echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
		echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
		echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
		echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
		echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
		echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
		echo "$suspend_scheduler" > /sys/block/mmcblk0/queue/scheduler
	fi;

	log -p i -t "$FILE_NAME" "*** CPU IMMUNIZED FOR $state MODE ***";
}

THERMAL_CTRL()
{
	local state="$1";

	echo "$freq_step" > /sys/module/msm_thermal/parameters/freq_step

	if [ "$state" == "awake" ]; then
		echo "$limit_temp" > /sys/module/msm_thermal/parameters/limit_temp
		echo "$core_limit_temp" > /sys/module/msm_thermal/parameters/core_limit_temp
	elif [ "$state" == "sleep" ]; then
		echo "$limit_temp_suspend" > /sys/module/msm_thermal/parameters/limit_temp
		echo "$core_limit_temp_suspend" > /sys/module/msm_thermal/parameters/core_limit_temp
	fi;

	echo "$temp_hysteresis" > /sys/module/msm_thermal/parameters/temp_hysteresis
	echo "$core_temp_hysteresis" > /sys/module/msm_thermal/parameters/core_temp_hysteresis

	log -p i -t "$FILE_NAME" "*** THERMAL CONTROL IMMUNIZED FOR $state MODE ***";
}

# if crond used, then give it root perent - if started by NXTweaks, then it will be killed in time
CROND_SAFETY()
{
	if [ "$crontab" == "on" ]; then
		pkill -f "crond";
		/res/crontab_service/service.sh;

		log -p i -t "$FILE_NAME" "*** CROND_SAFETY ***";

		return 1;
	else
		return 0;
	fi;
}

MEM_CLEANER()
{
	if [ "$morpheus_memcleaner" == "on" ]; then
		MEM_ALL=`free | grep Mem | awk '{ print $2 }'`;
		MEM_USED=`free | grep Mem | awk '{ print $3 }'`;
		MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

		# do clean cache only if cache uses more than 90% of free memory.
		if [ "$MEM_USED_CALC" -gt "90" ]; then
			sync;
			sysctl -w vm.drop_caches=3;
			log -p i -t "$FILE_NAME" "*** Morpheus: Memory hog detected and cleaned. ***";
		fi;
	fi;
}

TOUCH_FIX()
{
	# Override these values everytime, in case changed by external app
	echo "$pwrkey_suspend" > /sys/module/qpnp_power_on/parameters/pwrkey_suspend;
	echo "$wake_timeout" > /sys/android_touch/wake_timeout;
	echo "$doubletap2wake" > /sys/android_touch/doubletap2wake;
	echo "$doubletap2wake_feather" > /sys/android_touch/doubletap2wake_feather;
	echo "$s2w_s2sonly" > /sys/android_touch/s2w_s2sonly;
	echo "$sweep2wake" > /sys/android_touch/sweep2wake;

	log -p i -t "$FILE_NAME" "*** WAKE CONTROL IMMUNIZED ***";
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	CPUFREQ_FIX "awake";
	THERMAL_CTRL "awake";
	TOUCH_FIX;
	log -p i -t "$FILE_NAME" "*** Morpheus: Wake mode activated. ***";
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	TOUCH_FIX;
	CROND_SAFETY;
	CPUFREQ_FIX "sleep";
	THERMAL_CTRL "sleep";
	MEM_CLEANER;
	log -p i -t "$FILE_NAME" "*** Morpheus: Sleep mode activated. ***";
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
morpheus_background_process=1;

if [ "$morpheus_background_process" -eq "1" ]; then
	echo "Morpheus mode initiating!";
	(while true; do
		while [ "$(cat /sys/power/autosleep)" != "off" ]; do
			sleep "2";
		done;
		# AWAKE State. All system ON
		AWAKE_MODE;

		while [ "$(cat /sys/power/autosleep)" != "mem" ]; do
			sleep "10";
		done;
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done &);
else
	echo "Morpheus mode disabled!"
fi;
