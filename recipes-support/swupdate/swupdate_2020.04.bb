require swupdate.inc

SRCREV = "1a6dfbb5a0be978ac1a159758e278ab4d44167e2"

SRC_URI += "file://0001-diskpart-force-kernel-to-reread-partition-table.patch \
	    file://0001-Shellscript-stops-before-completing.patch \
	    file://0001-diskpart-fix-adding-more-as-4-partitions.patch \
	    "

# Building out of tree is broken in this version
B = "${S}"
