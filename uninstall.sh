#!/system/bin/sh

sleep 5

for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    [ -f "$policy/scaling_governor" ] && echo "schedutil" > "$policy/scaling_governor"
    [ -f "$policy/scaling_min_freq" ] && cat "$policy/cpuinfo_min_freq" > "$policy/scaling_min_freq"
done

resetprop -n persist.sys.composition.type ""
resetprop -n persist.device_config.runtime_native.usap_pool_enabled ""
resetprop -n persist.sys.purgeable_assets ""
resetprop -n persist.vendor.mtk.setup.prio ""
resetprop -n persist.vendor.powerhal.prio.enable ""
resetprop -n persist.vendor.ged.optimize_for_latency ""
resetprop -n persist.vendor.ged.force_ext_low_latency ""
resetprop -n persist.vendor.network.low_latency ""
resetprop -n persist.vendor.radio.latency_optim ""
resetprop -n debug.cpurend.precompile ""
resetprop -n debug.hwui.renderer ""
resetprop -n debug.sf.latch_unsignaled ""

for rate in /sys/devices/system/cpu/cpu*/cpufreq/schedutil/up_rate_limit_us; do
    [ -f "$rate" ] && echo 500 > "$rate"
done

for rate in /sys/devices/system/cpu/cpu*/cpufreq/schedutil/down_rate_limit_us; do
    [ -f "$rate" ] && echo 20000 > "$rate"
done

[ -f /proc/sys/kernel/sched_boost ] && echo 0 > /proc/sys/kernel/sched_boost
[ -f /proc/sys/kernel/sched_tunable_scaling ] && echo 1 > /proc/sys/kernel/sched_tunable_scaling

if [ -d /dev/cpuset/top-app ]; then
    ALL_CPUS=$(cat /sys/devices/system/cpu/present)
    echo "$ALL_CPUS" > /dev/cpuset/top-app/cpus
fi

for queue in /sys/block/*/queue; do
    [ -f "$queue/scheduler" ] && echo "mq-deadline" > "$queue/scheduler"
    [ -f "$queue/read_ahead_kb" ] && echo 128 > "$queue/read_ahead_kb"
    echo 1 > $queue/add_random
    echo 1 > $queue/iostats
    echo 128 > $queue/nr_requests
done

[ -f /proc/sys/vm/swappiness ] && echo 60 > /proc/sys/vm/swappiness
[ -f /proc/sys/vm/vfs_cache_pressure ] && echo 100 > /proc/sys/vm/vfs_cache_pressure
[ -f /proc/sys/vm/dirty_ratio ] && echo 20 > /proc/sys/vm/dirty_ratio
[ -f /proc/sys/vm/dirty_background_ratio ] && echo 10 > /proc/sys/vm/dirty_background_ratio

[ -f /proc/sys/net/ipv4/tcp_congestion_control ] && echo "cubic" > /proc/sys/net/ipv4/tcp_congestion_control
echo 1 > /proc/sys/net/ipv4/tcp_low_latency

[ -f /sys/class/misc/mali0/device/power_policy ] && echo "coarse_demand" > /sys/class/misc/mali0/device/power_policy
[ -f /sys/class/misc/mali0/device/js_throttling_mode ] && echo 1 > /sys/class/misc/mali0/device/js_throttling_mode

setprop persist.sys.thermal.config 1
resetprop -n debug.cpurend.precompile ""
resetprop -n debug.hwui.renderer ""
resetprop -n debug.sf.latch_unsignaled ""
setprop persist.vendor.thermal.config 1

for thermal in /sys/class/thermal/thermal_zone*; do
    [ -f "$thermal/mode" ] && echo "enabled" > "$thermal/mode"
done

if [ -f /vendor/bin/thermal-engine ]; then
    start thermal-engine
fi

if [ -f /vendor/bin/hw/android.hardware.thermal@2.0-service.mediatek ]; then
    start android.hardware.thermal@2.0-service.mediatek
fi

resetprop -n persist.vendor.powerhal.thermal.control.enable ""
resetprop -n persist.vendor.thermal.core.control.enable ""

iptables -t mangle -F OUTPUT 2>/dev/null

for IFACE in $(ls /sys/class/net | grep wlan); do
    [ -d /sys/class/net/$IFACE/device/power ] && echo auto > /sys/class/net/$IFACE/device/power/control
done

echo "0 4 1 7" > /proc/sys/kernel/printk