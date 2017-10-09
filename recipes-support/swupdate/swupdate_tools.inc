PACKAGES =+ "${PN}-tools"

INSANE_SKIP_${PN}-tools = "ldflags"

FILES_${PN}-tools = "${bindir}/swupdate-client \
                    ${bindir}/swupdate-progress \
                    ${bindir}/swupdate-hawkbitcfg \
                    ${bindir}/swupdate-sendtohawkbit"

do_compile() {
  unset LDFLAGS

  oe_runmake
  cp swupdate_unstripped swupdate
}

do_install_append () {

  install -m 0755 tools/client_unstripped ${D}${bindir}/swupdate-client
  install -m 0755 tools/progress_unstripped ${D}${bindir}/swupdate-progress
  install -m 0755 tools/hawkbitcfg_unstripped ${D}${bindir}/swupdate-hawkbitcfg
  install -m 0755 tools/sendtohawkbit_unstripped ${D}${bindir}/swupdate-sendtohawkbit

}
