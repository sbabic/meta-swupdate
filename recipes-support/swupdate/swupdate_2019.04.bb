require swupdate.inc

SRC_URI += " \
     file://swupdate.service \
     file://swupdate-usb.rules \
     file://swupdate-usb@.service \
     file://swupdate-progress.service \
     file://systemd-tmpfiles-swupdate.conf \
     "

SRCREV = "d39f4b8e00ef1929545b66158e45b82ea922bf81"

do_install_append () {
    # Rename the binaries installed by make install
    test -f ${D}${bindir}/progress && mv ${D}${bindir}/progress ${D}${bindir}/swupdate-progress
    test -f ${D}${bindir}/client && mv ${D}${bindir}/client ${D}${bindir}/swupdate-client
    test -f ${D}${bindir}/hawkbitcfg && mv ${D}${bindir}/hawkbitcfg ${D}${bindir}/swupdate-hawkbitcfg
    test -f ${D}${bindir}/sendtohawkbit && mv ${D}${bindir}/sendtohawkbit ${D}${bindir}/swupdate-sendtohawkbit

    install -d ${D}${systemd_system_unitdir}
    install -m 644 ${WORKDIR}/swupdate.service ${D}${systemd_system_unitdir}
    install -m 644 ${WORKDIR}/swupdate-usb@.service ${D}${systemd_system_unitdir}
    install -m 644 ${WORKDIR}/swupdate-progress.service ${D}${systemd_system_unitdir}
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${libdir}/tmpfiles.d
        install -m 0644 ${WORKDIR}/systemd-tmpfiles-swupdate.conf ${D}${libdir}/tmpfiles.d/swupdate.conf
        install -d ${D}${sysconfdir}/udev/rules.d
        install -m 0644 ${WORKDIR}/swupdate-usb.rules ${D}${sysconfdir}/udev/rules.d/
    fi
}
