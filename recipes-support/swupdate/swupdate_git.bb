require swupdate.inc

DEFAULT_PREFERENCE = "-1"

do_compile() {
  unset LDFLAGS

  oe_runmake
  cp swupdate_unstripped swupdate
  cp tools/progress_unstripped progress

}
