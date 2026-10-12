#!/system/bin/sh
# Anti-Bootloop - uninstall.sh

BB=$(command -v busybox 2>/dev/null || echo /system/xbin/busybox)
rm -rf /data/adb/antibootloop
rm -rf /data/local/tmp/ctlpanel/mod_0antibootloop
rm -f /data/local/tmp/ctlpanel/cgi-bin/abl
exit 0
