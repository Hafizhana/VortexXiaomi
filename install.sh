#!/system/bin/sh
export PATH=$PATH:/data/adb/magisk
SKIPMOUNT=false
PROPFILE=true
POSTFSDATA=false
LATESTARTSERVICE=true
REPLACE=""

MODULE="VortexXiaomi"

MIUI_VERSION=$(getprop ro.miui.ui.version.name)
HYPEROS_VERSION=$(getprop ro.hyperos.version)
DEVICE=$(getprop ro.product.model)
ANDROID=$(getprop ro.build.version.release)
BRAND=$(getprop ro.product.brand)
CPU=$(getprop ro.hardware)
GPU=$(getprop ro.hardware.egl)
RAM=$(grep "MemTotal" /proc/meminfo | awk '{print $2 / 1024 " MB"}')
SERIAL=$(getprop ro.serialno)
SDK=$(getprop ro.build.version.sdk)

ui_print "===================================="
ui_print "        VortexXiaomi MODULE           "
ui_print "       Copyright (c) 2026 Amili       "
ui_print "===================================="
ui_print " WARNING:                             "
ui_print " - Use at your own risk!              "
ui_print " - Only for MIUI and HyperOS                      "
ui_print " - Don't combone this module with other performance modules!"
ui_print " - This module is only for Mediatek."
ui_print "===================================="

sleep 10

if [ -z "$(getprop ro.hardware | grep -i mt)" ] && [ -z "$(getprop ro.board.platform | grep -i mt)" ]; then
    ui_print "===================================="
    ui_print " ERROR: Non-MediaTek device detected!"
    ui_print " Platform: $(getprop ro.board.platform)"
    ui_print " Installation Aborted!"
    ui_print "===================================="
    exit 1
fi

if [ -z "$MIUI_VERSION" ] && [ -z "$HYPEROS_VERSION" ]; then
    ui_print "===================================="
    ui_print "WARNING: $MODULE requires MIUI or HyperOS."
    ui_print "Detected device: $DEVICE"
    ui_print "Android version: $ANDROID"
    ui_print "Installation Aborted!"
    ui_print "===================================="
    exit 1
fi

if [ -n "$MIUI_VERSION" ]; then
    ROM_TYPE="MIUI"
elif [ -n "$HYPEROS_VERSION" ]; then
    ROM_TYPE="HyperOS"
fi

ui_print "===================================="
ui_print "- Installing $MODULE Module"
ui_print "- Brand: $BRAND"
ui_print "- Device: $DEVICE"
ui_print "- Android: $ANDROID (SDK $SDK)"
ui_print "- ROM: $ROM_TYPE $MIUI_VERSION"
ui_print "- CPU: $CPU"
ui_print "- GPU: $GPU"
ui_print "- RAM: $RAM"
ui_print "- Serial: $SERIAL"
ui_print "===================================="
sleep 5
ui_print "===================================="
ui_print "- Applying Tweaks..."
ui_print "- Done! Please Reboot."
ui_print "===================================="