SUMMARY="Simple GUI for SWUpdate in rescue mode"
DESCRIPTION = "This is a simple GUI that allows to set network addresses \
	and start an install from local media. It shows progress on the HMI"
SECTION="swupdate"
LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

inherit update-rc.d

DEPENDS += "swupdate lua luafilesystem"
RDEPENDS_${PN} += "swupdate-tools swupdate-lua"

SRC_URI = "git://github.com/sbabic/SWUpdateGUI.git;protocol=https;branch=master \
     	   file://rescuegui \
	   file://config.lua \
	"

# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "a52b3d3bc315eb1195fc6311c8170651a54d7893"

S = "${WORKDIR}/git"

FILES_${PN} = "/opt ${sysconfdir}"

do_configure () {
	# Specify any needed configure commands here
	:
}

do_compile () {
	# Specify compilation commands here
	:
}

do_install () {
	install -d ${D}/opt/rescueGUI
	install -d ${D}/opt/rescueGUI/tek/ui/locale/SWUpdate/SWUpdate-GUI
	for f in ${S}/*.lua;do
		install -m 755 ${f} ${D}/opt/rescueGUI
	done
	for f in ${S}/tek/ui/locale/SWUpdate/SWUpdate-GUI/*;do
		install -m 644 ${f} ${D}/opt/rescueGUI/tek/ui/locale/SWUpdate/SWUpdate-GUI
	done
	
	install -m 644 ${S}/config.lua ${D}/opt/rescueGUI
	install -d ${D}/${sysconfdir}/init.d
	install -m 755 ${WORKDIR}/rescuegui ${D}${sysconfdir}/init.d
}

# Be sure to run the GUI after starting SWUpdate
INITSCRIPT_NAME = "rescuegui"
INITSCRIPT_PARAMS = "defaults 90"
