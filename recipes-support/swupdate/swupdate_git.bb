require swupdate.inc

inherit update-rc.d

# this is 2016.10-rc1
SRCREV = "8abacd3613410002c0cd05a12e82d695d3e4bf6f"

SRC_URI += "file://swupdate"

do_install_append() {
  install -d ${D}${sysconfdir}/init.d
  install -m 755 ${WORKDIR}/swupdate ${D}${sysconfdir}/init.d
}

INITSCRIPT_NAME = "swupdate"
INITSCRIPT_PARAMS = "defaults 70"
