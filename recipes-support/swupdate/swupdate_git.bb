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

do_install_append () {
  install -d ${D}${systemd_unitdir}/system
  install -m 644 ${WORKDIR}/swupdate-usb@.service ${D}${systemd_unitdir}/system
  install -m 644 ${WORKDIR}/swupdate-progress.service ${D}${systemd_unitdir}/system
  if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/swupdate-usb.rules ${D}${sysconfdir}/udev/rules.d/
  fi
}
