FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PACKAGECONFIG += "fbdev gridnav"

SRC_URI += "file://clib-malloc.cfg"
