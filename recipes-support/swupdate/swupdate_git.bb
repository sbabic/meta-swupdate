require swupdate.inc

inherit update-rc.d

SRCREV = "${AUTOREV}"

SRC_URI += "file://swupdate"

do_install_append() {
  install -d ${D}${sysconfdir}/init.d
  install -m 755 ${WORKDIR}/swupdate ${D}${sysconfdir}/init.d
}

INITSCRIPT_NAME = "swupdate"
INITSCRIPT_PARAMS = "defaults 70"
