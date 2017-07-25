require swupdate.inc

DEFAULT_PREFERENCE = "-1"

do_compile() {
  unset LDFLAGS

  oe_runmake
  cp swupdate_unstripped swupdate
  cp tools/progress_unstripped progress

}

do_install_append () {

  install -m 0755 tools/client_unstripped ${D}${bindir}/client
  install -m 0755 tools/progress_unstripped ${D}${bindir}/progress
  install -m 0755 tools/hawkbitcfg_unstripped ${D}${bindir}/hawkbitcfg
  install -m 0755 tools/sendtohawkbit_unstripped ${D}${bindir}/sendtohawkbit

}
