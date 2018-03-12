#! /vendor/bin/sh

# Copyright (c) 2012-2013, 2016-2017, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#


# Set Memory paremeters.
#
# Set per_process_reclaim tuning parameters
# 2GB 64-bit will have aggressive settings when compared to 1GB 32-bit
# 1GB and less will use vmpressure range 50-70, 2GB will use 10-70
# 1GB and less will use 512 pages swap size, 2GB will use 1024
#
# Set Low memory killer minfree parameters
# 32 bit all memory configurations will use 15K series
# 64 bit up to 2GB with use 14K, and above 2GB will use 18K
#
# Set ALMK parameters (usually above the highest minfree values)
# 32 bit will have 53K & 64 bit will have 81K
#

MemTotalStr=`cat /proc/meminfo | grep MemTotal`
MemTotal=${MemTotalStr:16:8}

# Read adj series and set adj threshold for PPR and ALMK.
# This is required since adj values change from framework to framework.
adj_series=`cat /sys/module/lowmemorykiller/parameters/adj`
adj_1="${adj_series#*,}"
set_almk_ppr_adj="${adj_1%%,*}"

# PPR and ALMK should not act on HOME adj and below.
# Normalized ADJ for HOME is 6. Hence multiply by 6
# ADJ score represented as INT in LMK params, actual score can be in decimal
# Hence add 6 considering a worst case of 0.9 conversion to INT (0.9*6).
# For uLMK + Memcg, this will be set as 6 since adj is zero.
set_almk_ppr_adj=$(((set_almk_ppr_adj * 6) + 6))
echo $set_almk_ppr_adj > /sys/module/lowmemorykiller/parameters/adj_max_shift
echo $set_almk_ppr_adj > /sys/module/process_reclaim/parameters/min_score_adj

#Set other memory parameters
echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim
echo 70 > /sys/module/process_reclaim/parameters/pressure_max
echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff
echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
echo 10 > /sys/module/process_reclaim/parameters/pressure_min
echo 1024 > /sys/module/process_reclaim/parameters/per_swap_size
if [ $MemTotal -gt 2097152 ]; then
    echo "18432,23040,27648,32256,55296,80640" > /sys/module/lowmemorykiller/parameters/minfree
else
    echo "14746,18432,22118,25805,40000,55000" > /sys/module/lowmemorykiller/parameters/minfree
fi
echo 81250 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min

# Zram disk - 75% for Go devices.
# For 512MB Go device, size = 384MB
# For 1GB Go device, size = 768MB
# Others - 512MB size
# And enable lz4 zram compression for Go devices
zram_enable=`getprop ro.vendor.qti.config.zram`
if [ "$zram_enable" == "true" ]; then
    echo 8 > /sys/block/zram0/max_comp_streams
    echo lz4 > /sys/block/zram0/comp_algorithm
    echo 536870912 > /sys/block/zram0/disksize
    mkswap /dev/block/zram0
    swapon /dev/block/zram0
fi

if [ $MemTotal -le 2097152 ]; then
    #Enable B service adj transition for 2GB or less memory
    setprop ro.vendor.qti.sys.fw.bservice_enable true
    setprop ro.vendor.qti.sys.fw.bservice_limit 5
    setprop ro.vendor.qti.sys.fw.bservice_age 5000

    #Enable Delay Service Restart
    setprop ro.vendor.qti.am.reschedule_service true
fi


# ... here was too much shit


chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_rate
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/sampling_down_factor
chown -h system /sys/devices/system/cpu/cpufreq/ondemand/io_is_busy

emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot"
    in "true")
        chown -h system /sys/devices/platform/rs300000a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300000a7.65536/sync_sts
        chown -h system /sys/devices/platform/rs300100a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300100a7.65536/sync_sts
    ;;
esac

# Post-setup services
echo 256 > /sys/block/mmcblk0/bdi/read_ahead_kb
echo 256 > /sys/block/mmcblk0/queue/read_ahead_kb
echo 256 > /sys/block/dm-0/queue/read_ahead_kb
echo 256 > /sys/block/dm-1/queue/read_ahead_kb
echo 256 > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
echo 256 > /sys/block/mmcblk0rpmb/queue/read_ahead_kb
setprop sys.post_boot.parsed 1

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
    image_version="10:"
    image_version+=`getprop ro.build.id`
    image_version+=":"
    image_version+=`getprop ro.build.version.incremental`
    image_variant=`getprop ro.product.name`
    image_variant+="-"
    image_variant+=`getprop ro.build.type`
    oem_version=`getprop ro.build.version.codename`
    echo 10 > /sys/devices/soc0/select_image
    echo $image_version > /sys/devices/soc0/image_version
    echo $image_variant > /sys/devices/soc0/image_variant
    echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Change console log level as per console config property
console_config=`getprop persist.console.silent.config`
case "$console_config" in
    "1")
        echo "Enable console config to $console_config"
        echo 0 > /proc/sys/kernel/printk
        ;;
    *)
        echo "Enable console config to $console_config"
        ;;
esac

# Parse misc partition path and set property
misc_link=$(ls -l /dev/block/bootdevice/by-name/misc)
real_path=${misc_link##*>}
setprop persist.vendor.mmi.misc_dev_path $real_path



###########################
# User's area goes below
#

# Boeffla generic wakelock blocker, path "/sys/class/misc/boeffla_wakelock_blocker", files:
#  "wakelock_blocker", list of wakelocks to be blocked, separated by semicolons (default list is empty)
#  "debug", write 0|1 to switch off|on debug logging into dmesg, read to get current driver internals
# modify for your needs 1st line below and uncomment for activation, 2nd line is just for reference
#echo "sensor_ind;qcom_rx_wakelock;wlan;wlan_wow_wl;wlan_extscan_wl;netmgr_wl;NETLINK" > /sys/class/misc/boeffla_wakelock_blocker/wakelock_blocker
#echo "sensor_ind;qcom_rx_wakelock;wlan;wlan_wow_wl;wlan_extscan_wl;netmgr_wl;NETLINK" > /sys/class/misc/boeffla_wakelock_blocker/wakelock_blocker

# Vibrator intensity, path "/sys/devices/virtual/timed_output/vibrator", files
#  "vtg_min", used to get the minimum allowed voltage, 116
#  "vtg_max", used to get the maximum allowed voltage, 3596
#  "vtg_level", used to set the voltage within vtg_min and vtg_max range, 2726 (75%) by default
#echo 2726 > /sys/devices/virtual/timed_output/vibrator/vtg_level


#########
# Big thanks to @tweakradje at xda for nice tweaks
# https://forum.xda-developers.com/xiaomi-redmi-4x/how-to/guide-tweaks-redmi-4x-stock-rom-t3658724
#

PATH=/system/bin:$PATH

# increase digital playback volume from 88, also see "/vendor/etc/mixer_paths_qrd_sku1.xml"
#tinymix "RX1 Digital Volume" 92
#tinymix "RX2 Digital Volume" 92
#tinymix "RX3 Digital Volume" 92
# increase recording volume from 88
#tinymix "DEC1 Volume" 92
#tinymix "DEC2 Volume" 92

# https://www.bignerdranch.com/blog/diving-into-doze-mode-for-developers/ (test with dumpsys battery unplug)
# https://android.googlesource.com/platform/frameworks/base/+/android-n-preview-4/services/core/java/com/android/server/DeviceIdleController.java
# screen off/charge unplug/no motion: 0 sec -> light doze (5 min maintenance interval) -> after 15 min -> Deep doze (1 hour maintenance interval)
# apps NOT on whitelist can do their thing inside maintenance window !!!!!
# enable light doze too (mLightEnabled=true  mDeepEnabled=true)
#dumpsys deviceidle enable light
#dumpsys deviceidle enable deep
dumpsys deviceidle enable all
# add telegram, whatsapp and gmail to the whitelist
dumpsys deviceidle whitelist +org.telegram.messenger +com.whatsapp +com.google.android.gm
# remove these from the whitelist (I don't use e-mail!)
#dumpsys deviceidle whitelist -com.android.vending -com.android.providers.downloads -com.android.email
# Get all parameters with: dumpsys deviceidle
#    light_after_inactive_to=+5m0s0ms  (300000)
#    light_pre_idle_to=+10m0s0ms       (600000)
#    light_idle_to=+5m0s0ms            (300000)
#    light_idle_factor=2.0
#    light_max_idle_to=+15m0s0ms       (900000)
#    light_idle_maintenance_min_budget=+1m0s0ms
#    light_idle_maintenance_max_budget=+5m0s0ms
#    min_light_maintenance_time=+5s0ms
#    min_deep_maintenance_time=+30s0ms
#    inactive_to=+30m0s0ms             (deep idle start after last screen on)
#    sensing_to=+4m0s0ms
#    locating_to=+30s0ms
#    location_accuracy=20.0m
#    motion_inactive_to=+10m0s0ms
#    idle_after_inactive_to=+30m0s0ms
#    idle_pending_to=+5m0s0ms
#    max_idle_pending_to=+10m0s0ms
#    idle_pending_factor=2.0
#    idle_to=+1h0m0s0ms
#    max_idle_to=+6h0m0s0ms
#    idle_factor=2.0
#    min_time_to_alarm=+1h0m0s0ms
#    max_temp_app_whitelist_duration=+5m0s0ms
#    mms_temp_app_whitelist_duration=+1m0s0ms
#    sms_temp_app_whitelist_duration=+20s0ms
#    notification_whitelist_duration=+30s0ms
#####
# device in light mode directly after screen off (light_after_inactive_to=0)
# stay in light mode for 15 minutes
# after 15 minutes step into deep doze (inactive_to=900000)
# do not wait for any motion (locating_to,motion_inactive_to,sensing_to all 0)
# Phenotype_flags=alarm_manager_dummy_flags:device_idle_constants:phenotype_test_setting (not relevant, deviceidle service is looking for device_idle_constants)
#settings put global device_idle_constants motion_inactive_to=0,locating_to=0,sensing_to=0,idle_after_inactive_to=0,inactive_to=900000,light_after_inactive_to=0
settings put global device_idle_constants motion_inactive_to=0,locating_to=0,sensing_to=0,idle_after_inactive_to=0,inactive_to=900000,min_time_to_alarm=300000,light_after_inactive_to=0

# Battle with Google Play Services that reverts it back to defaults (WHY Google?)
#sqlite3 /data/data/com.google.android.gms/databases/phenotype.db "INSERT INTO FlagOverrides (packageName,user,flagType,name,stringVal) VALUES ('com.google.android.gms.settings.platform','','0' ,'device_idle_constants', 'motion_inactive_to=0,locating_to=0,sensing_to=0,i dle_after_inactive_to=0,inactive_to=900000,light_a fter_inactive_to=0');"
#sqlite3 /data/data/com.google.android.gms/databases/phenotype.db "DELETE FROM Flags WHERE name = 'device_idle_constants';"

# Perhaps solution for non rooted devices?
#pm disable --user 0 com.google.android.gms/.phenotype.service.sync.PhenotypeConfigurator
# there is also:
# com.google.android.gms/.phenotype.service.PhenotypeService
# com.google.android.gms/.common.config.PhenotypeCheckinService


# check if you have color LED!
echo 1 > /sys/class/leds/purple/blink; sleep 1
echo 1 > /sys/class/leds/cyan/blink; sleep 1
echo 0 > /sys/class/leds/purple/blink; sleep 1
echo 0 > /sys/class/leds/cyan/blink
