SUMMARY = "Recovery GUI application"
DESCRIPTION = "This recipe provides the GUI for recovery system and works with LVGL and framebuffer."

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=de4b1111cc7f3c8bc81546de6f9b24e4"

DEPENDS:append = " \
	lvgl \
	swupdate \
	"

SRC_URI = "git://github.com/sbabic/SWUpdateGUI.git;protocol=https;branch=main \
	file://swupdate-gui \
	file://swupdate-gui.service \
	"
SRCREV = "d6bd129b4cea1e5c53bcad077a7d25af8260ef84"

S = "${WORKDIR}/git"

inherit cmake update-rc.d systemd

TARGET_CFLAGS:append = " -I${STAGING_INCDIR}/lvgl"
TARGET_CFLAGS:append = " -I${STAGING_INCDIR}/lvgl/lv_drivers"

INITSCRIPT_NAME = "swupdate-gui"
INITSCRIPT_PARAMS = "defaults 90"
SYSTEMD_SERVICE:${PN} = "swupdate-gui.service"

do_install:append () {
        install -d ${D}${sysconfdir}/init.d
    	install -d ${D}${systemd_system_unitdir}
        install -m 0755 ${WORKDIR}/swupdate-gui ${D}${sysconfdir}/init.d/
    	install -m 644 ${WORKDIR}/swupdate-gui.service ${D}${systemd_system_unitdir}
        install -d ${D}${sysconfdir}/recovery_gui
        install -m 0644 ${S}/config/config.txt ${D}${sysconfdir}/recovery_gui/
        install -m 0755 ${S}/scripts/recovery-check-bridge-interface.sh ${D}${bindir}
        install -m 0755 ${S}/scripts/recovery-edit-default-gateway.sh ${D}${bindir}
        install -m 0755 ${S}/scripts/recovery-get-dhcp-status.sh ${D}${bindir}
        install -m 0755 ${S}/scripts/recovery-set-dhcp.sh ${D}${bindir}
        install -m 0755 ${S}/scripts/recovery-set-static.sh ${D}${bindir}
}

RDEPENDS:${PN}:append = " \
	swupdate \
	"
