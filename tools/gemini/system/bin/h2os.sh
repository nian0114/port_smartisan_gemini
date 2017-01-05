#!/system/bin/sh
h2os_version_info=`getprop persist.nian.h2os`
if [ "$h2os_version_info" != "1" ]; then
    setprop persist.nian.h2os 1
    reboot
fi
