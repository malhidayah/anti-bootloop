#!/system/bin/sh
# Anti-Bootloop - service.sh (late_start)
# Tandai boot sukses bila sys.boot_completed=1, lalu pasang WebUI ke F3 Hub.

MODDIR=${0%/*}
BASE=/data/adb/antibootloop
CONFIG=$MODDIR/config.sh
[ -f "$CONFIG" ] && . "$CONFIG"
mkdir -p "$BASE"

LOG=$BASE/log.txt
OKFLAG=$BASE/boot_ok

log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

i=0
while [ "$i" -lt 30 ]; do
  [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
  sleep 2; i=$((i + 1))
done

if [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ]; then
  touch "$OKFLAG"
  log "BOOT COMPLETE"

  # --- snapshot modul aktif: untuk deteksi "berubah sejak boot sukses terakhir" ---
  SNAP=$BASE/snapshot
  : > "$SNAP"
  for d in /data/adb/modules/*/; do
    id=${d%/}; id=${id##*/}
    [ -f "$d/disable" ] && continue
    [ -f "$d/remove" ] && continue
    [ -f "$d/module.prop" ] || continue
    mt=$(stat -c %Y "$d/module.prop" 2>/dev/null || echo 0)
    echo "$id $mt" >> "$SNAP"
  done

  # modul offender yang kini aktif & berhasil boot -> terbukti sehat, hapus dari offenders
  OFF=$BASE/offenders
  if [ -s "$OFF" ]; then
    sort -u "$OFF" | while IFS= read -r oid; do
      [ -z "$oid" ] && continue
      if [ -d "/data/adb/modules/$oid" ] && [ ! -f "/data/adb/modules/$oid/disable" ]; then
        log "module '$oid' aktif setelah boot sukses -> hapus dari daftar bermasalah"
      else
        echo "$oid"
      fi
    done > "$OFF.t"
    mv "$OFF.t" "$OFF"
  fi
else
  log "late_start tercapai tapi boot_completed!=1 (belum dianggap sukses)"
fi

# Pasang/segarkan WebUI ke panel F3 Hub (lewat /data/local/tmp/ctlpanel).
PANEL=/data/local/tmp/ctlpanel
if [ -d "$PANEL" ]; then
  mkdir -p "$PANEL/mod_0antibootloop" "$PANEL/cgi-bin"
  cp -f "$MODDIR/webroot/index.html" "$PANEL/mod_0antibootloop/index.html" 2>/dev/null
  cp -f "$MODDIR/cgi-bin/abl" "$PANEL/cgi-bin/abl" 2>/dev/null
  chmod 755 "$PANEL/cgi-bin/abl" 2>/dev/null
  log "WebUI dipasang ke F3 Hub"
fi
