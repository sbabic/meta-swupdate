SUMMARY = "Different startup scripts"
SECTION = "base"
PR = "r0"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://rcS.swupdate \
	"

RPROVIDES_${PN} += "virtual/initscripts-swupdate"

S = "${WORKDIR}"

do_install () {
	install -d ${D}/${sysconfdir}/init.d
	install -d ${D}${base_sbindir}
	install -m 755 ${S}/rcS.swupdate ${D}${base_sbindir}/init
}

PACKAGES = "${PN}"
FILES_${PN} = "/"

inherit allarch

CONFFILES_${PN} = ""
