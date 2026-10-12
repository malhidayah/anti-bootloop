ui_print "- Anti-Bootloop v1.0"
ui_print "- Deteksi bootloop, nonaktifkan module bermasalah"
ui_print "- Tampil di F3 Hub WebUI (webroot)"

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
set_perm $MODPATH/cgi-bin/abl 0 0 0755
