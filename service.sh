#!/system/bin/sh

sleep 40
MODDIR=${0%/*}
GAMES_FILE="$MODDIR/gamelist.txt"
export PATH=$PATH:/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin

apply_perf() {
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        MAX=$(cat $policy/cpuinfo_max_freq)
        if [ "$MAX" -gt 2000000 ]; then
            echo "performance" > $policy/scaling_governor
            echo $((MAX * 70 / 100)) > $policy/scaling_min_freq
        else
            echo "schedutil" > $policy/scaling_governor
            echo $((MAX * 50 / 100)) > $policy/scaling_min_freq
        fi
    done

    for pid in $(pidof com.roblox.client surfaceflinger); do
        renice -n -20 -p $pid
        ionice -c 1 -n 0 -p $pid
    done

    [ -f /sys/class/misc/mali0/device/power_policy ] && echo "always_on" > /sys/class/misc/mali0/device/power_policy
    [ -f /sys/class/misc/mali0/device/js_throttling_mode ] && echo 0 > /sys/class/misc/mali0/device/js_throttling_mode
    [ -f /sys/module/mali_kbase/parameters/mali_dvfs_policy ] && echo 1 > /sys/module/mali_kbase/parameters/mali_dvfs_policy

    echo 0 > /proc/sys/net/ipv4/tcp_low_latency
    echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
    echo 1 > /proc/sys/net/ipv4/tcp_timestamps
    echo 1 > /proc/sys/net/ipv4/tcp_sack
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle
    echo 250000 > /proc/sys/net/core/netdev_max_backlog
    echo 16384 > /proc/sys/net/core/somaxconn
    echo 65536 > /proc/sys/net/ipv4/ipfrag_high_thresh
    echo 49152 > /proc/sys/net/ipv4/ipfrag_low_thresh

    for rate in /sys/devices/system/cpu/cpu*/cpufreq/schedutil/up_rate_limit_us; do
        [ -f $rate ] && echo 0 > $rate
    done

    for rate in /sys/devices/system/cpu/cpu*/cpufreq/schedutil/down_rate_limit_us; do
        [ -f $rate ] && echo 80000 > $rate
    done

    echo 1 > /proc/sys/kernel/sched_boost
    echo 0 > /proc/sys/kernel/sched_tunable_scaling

    [ -f /proc/sys/vm/swappiness ] && echo 20 > /proc/sys/vm/swappiness
    [ -f /proc/sys/vm/vfs_cache_pressure ] && echo 80 > /proc/sys/vm/vfs_cache_pressure
    [ -f /proc/sys/vm/min_free_kbytes ] && echo 24576 > /proc/sys/vm/min_free_kbytes
    [ -f /proc/sys/vm/extra_free_kbytes ] && echo 24576 > /proc/sys/vm/extra_free_kbytes
    [ -f /proc/sys/vm/dirty_ratio ] && echo 25 > /proc/sys/vm/dirty_ratio
    [ -f /proc/sys/vm/dirty_background_ratio ] && echo 10 > /proc/sys/vm/dirty_background_ratio

    [ -f /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk ] && echo 0 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
    echo 0 > /sys/module/lowmemorykiller/parameters/debug_level

    [ -d /dev/cpuset/top-app ] && echo "0-7" > /dev/cpuset/top-app/cpus

    for i in /sys/block/*/queue; do
        [ -f "$i/scheduler" ] && echo mq-deadline > $i/scheduler
        echo 512 > $i/read_ahead_kb
        echo 0 > $i/add_random
        echo 0 > $i/iostats
        echo 1 > $i/nomerges
        echo 0 > $i/rotational
        echo 1 > $i/rq_affinity
        echo 1024 > $i/nr_requests
    done

    for dcs in /sys/class/devfreq/*mediatek,main_pmic*/governor; do
        [ -f $dcs ] && echo "performance" > $dcs
    done

    for gpu_gov in /sys/class/kgsl/kgsl-3d0/devfreq/governor /sys/module/pvrsrvkm/parameters/gpu_governor; do
        [ -f $gpu_gov ] && echo "performance" > $gpu_gov
    done

    setprop debug.sf.latch_unsignaled 1
    setprop debug.sf.disable_backpressure 1
    setprop debug.hwui.renderer skiavk
    setprop vendor.perf.frame_pacing 1
    setprop vendor.perf.gesture_boost 1
    setprop power.sustained_performance_mode 1
    setprop persist.sys.thermal.config 0
    setprop debug.cpurend.precompile 1

    setprop wifi.supplicant_scan_interval 3000
    setprop wifi.power_save 0
    setprop ro.ril.fast.dormancy.rule 0
    setprop Boost.Wi-Fi True

    echo 4096 87380 16777216 > /proc/sys/net/ipv4/tcp_rmem
    echo 4096 65536 16777216 > /proc/sys/net/ipv4/tcp_wmem
    echo bbr > /proc/sys/net/ipv4/tcp_congestion_control

    setprop wifi.wme_ac_be 7
    setprop wifi.wme_ac_bk 3
    setprop wifi.wme_ac_vi 7
    setprop wifi.wme_ac_vo 7

    for IFACE in $(ls /sys/class/net | grep wlan); do
        [ -d /sys/class/net/$IFACE/device/power ] && echo on > /sys/class/net/$IFACE/device/power/control
        [ -f /sys/class/net/$IFACE/queues/tx-0/xps_cpus ] && echo 0xff > /sys/class/net/$IFACE/queues/tx-0/xps_cpus
    done

    echo "0 0 0 0" > /proc/sys/kernel/printk

    fstrim -v /data
    fstrim -v /system
    fstrim -v /cache
}

disable_thermal() {
    setprop persist.sys.thermal.config 0
    setprop persist.vendor.thermal.config 0
    for thermal in /sys/class/thermal/thermal_zone*; do
        [ -f "$thermal/mode" ] && echo "disabled" > "$thermal/mode"
    done
    for thermal_node in /sys/module/thermal/parameters/enabled; do
        [ -f "$thermal_node" ] && echo "N" > "$thermal_node"
    done
    [ -f /vendor/bin/thermal-engine ] && stop thermal-engine
    [ -f /vendor/bin/hw/android.hardware.thermal@2.0-service.mediatek ] && stop android.hardware.thermal@2.0-service.mediatek
    [ -f /sys/kernel/debug/fps_go/common/force_onoff ] && echo 1 > /sys/kernel/debug/fps_go/common/force_onoff
}

game_monitor() {
    while true; do
        GAME_RUNNING=0
        CURRENT_APP=$(dumpsys window | grep -E 'mCurrentFocus' | cut -d'/' -f1 | rev | cut -d' ' -f1 | rev)
        
        if [ "$CURRENT_APP" = "com.roblox.client" ]; then
            GAME_RUNNING=1
            PID=$(pidof com.roblox.client)
            if [ ! -z "$PID" ]; then
                if ! iptables -t mangle -C OUTPUT -p udp -m owner --pid-owner $PID -j DSCP --set-dscp-class CS6 2>/dev/null; then
                    iptables -t mangle -A OUTPUT -p udp -m owner --pid-owner $PID -j DSCP --set-dscp-class CS6
                    iptables -t mangle -A OUTPUT -p udp -m owner --pid-owner $PID -j TOS --set-tos 0x10
                fi
            fi
        elif [ -f "$GAMES_FILE" ]; then
            while read -r APP; do
                PID=$(pidof $APP)
                if [ ! -z "$PID" ]; then
                    GAME_RUNNING=1
                    if ! iptables -t mangle -C OUTPUT -p udp -m owner --pid-owner $PID -j DSCP --set-dscp-class CS6 2>/dev/null; then
                        iptables -t mangle -A OUTPUT -p udp -m owner --pid-owner $PID -j DSCP --set-dscp-class CS6
                        iptables -t mangle -A OUTPUT -p udp -m owner --pid-owner $PID -j TOS --set-tos 0x10
                    fi
                fi
            done < "$GAMES_FILE"
        fi

        if [ "$GAME_RUNNING" -eq 1 ]; then
            disable_thermal
            for policy in /sys/devices/system/cpu/cpufreq/policy*; do
                echo "performance" > $policy/scaling_governor
            done
        else
            iptables -t mangle -F OUTPUT 2>/dev/null
            for policy in /sys/devices/system/cpu/cpufreq/policy*; do
                echo "schedutil" > $policy/scaling_governor
            done
        fi
        
        sleep 20
    done
}

apply_perf
game_monitor &