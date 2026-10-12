#!/system/bin/sh
# Anti-Bootloop - post-fs-data.sh
# Berjalan paling awal tiap boot (id "0antibootloop" urut pertama).
# Deteksi bootloop = boot sebelumnya tidak pernah mencapai sys.boot_completed=1.

MODDIR=${0%/*}
BASE=/data/adb/antibootloop
CONFIG=$MODDIR/config.sh
[ -f "$CONFIG" ] && . "$CONFIG"
: ${THRESHOLD:=2}
: ${MODE:=disable}

mkdir -p "$BASE"
LOG=$BASE/log.txt
COUNT=$BASE/count
OKFLAG=$BASE/boot_ok
DISABLED=$BASE/disabled
SUSPECT=$BASE/suspect

log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

# rotasi log agar tak membengkak
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 51200 ]; then
  tail -n 200 "$LOG" > "$LOG.t"; mv "$LOG.t" "$LOG"
fi

if [ ! -f "$COUNT" ]; then
  # boot pertama setelah install: belum ada riwayat, jangan dihitung gagal
  echo 0 > "$COUNT"
  log "BOOT START (boot pertama, tidak ada riwayat)"
elif [ -f "$OKFLAG" ]; then
  # boot sebelumnya selesai -> reset counter
  rm -f "$OKFLAG"
  echo 0 > "$COUNT"
  log "BOOT START (boot sebelumnya OK, counter reset)"
else
  # boot sebelumnya TIDAK selesai -> bootloop
  n=$(cat "$COUNT" 2>/dev/null); n=$((n + 1)); echo "$n" > "$COUNT"
  log "BOOT START (boot sebelumnya TIDAK selesai) count=$n/$THRESHOLD"
  if [ "$n" -ge "$THRESHOLD" ]; then
    # tersangka = module yang paling baru diubah, non-aktifkan, bukan kita.
    # ponytail: heuristik "baru dipasang/diubah" -> upgrade: simpan hash per-modul
    #           tiap boot sukses & bandingkan untuk tahu siapa yang berubah.
    best=""; bestt=0
    for d in /data/adb/modules/*/; do
      id=${d%/}; id=${id##*/}
      [ "$id" = "0antibootloop" ] && continue
      [ -f "$d/disable" ] && continue
      [ -f "$d/remove" ] && continue
      [ -f "$d/module.prop" ] || continue
      t=$(stat -c %Y "$d/module.prop" 2>/dev/null || echo 0)
      [ "$t" -gt "$bestt" ] && { bestt=$t; best=$id; }
    done
    if [ -n "$best" ]; then
      if [ "$MODE" = "remove" ]; then
        touch "/data/adb/modules/$best/remove"; act=removed
      else
        touch "/data/adb/modules/$best/disable"; act=disabled
      fi
      echo "$best $(date '+%s')" >> "$DISABLED"
      echo "$best" >> "$BASE/offenders"
      echo "$best" > "$SUSPECT"
      log "BOOTLOOP terkonfirmasi -> $act module '$best'"
      echo 0 > "$COUNT"
    else
      log "tidak ada module tersisa untuk dinonaktifkan"
    fi
  fi
fi
