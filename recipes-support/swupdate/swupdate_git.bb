require swupdate.inc
require swupdate_tools.inc

DEFAULT_PREFERENCE = "-1"

SRCREV = "${AUTOREV}"

SRC_URI += "\
     file://swupdate-usb.rules \
     file://swupdate-usb@.service \
     file://swupdate-progress.service \
     "

do_compile_append() {
  oe_runmake
  unset LDFLAGS
}
