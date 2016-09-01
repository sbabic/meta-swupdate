require swupdate.inc

inherit update-rc.d

SRC_URI = "git://github.com/sbabic/swupdate.git;protocol=git;tag=2016.07 \
     file://defconfig \
     file://swupdate \
     file://swupdate.service \
     "

INITSCRIPT_NAME = "swupdate"
INITSCRIPT_PARAMS = "defaults 70"
