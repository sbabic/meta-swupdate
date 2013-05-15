FILES_${PN}-staticdev += "ubi-utils/libubi.a ${libdir}/*.a"

do_install_append () {
	install -d ${D}${includedir}/mtd/
	install -d ${D}${libdir}/
	install -m 0644 ubi-utils/include/libubi.h ${D}${includedir}/mtd/
	install -m 0644 include/libmtd.h ${D}${includedir}/mtd/
	install -m 0644 include/mtd/ubi-media.h ${D}${includedir}/mtd/
	oe_libinstall -a -C ubi-utils libubi ${D}${libdir}/
	oe_libinstall -a -C lib libmtd ${D}${libdir}/
}

BBCLASSEXTEND += "native"
