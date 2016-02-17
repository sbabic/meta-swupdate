FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-Allow-fw-env-tools-to-be-available-as-library.patch"

do_install_append() {
    install -d ${D}${libdir}
    install -m 644  ${S}/tools/env/lib.a ${D}${libdir}/libubootenv.a
}
