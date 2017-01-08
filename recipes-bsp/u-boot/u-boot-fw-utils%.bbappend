do_install_append() {
    install -d ${D}${libdir}
    install -m 644  ${S}/tools/env/lib.a ${D}${libdir}/libubootenv.a
}
