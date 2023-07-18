CONVERSIONTYPES += "zck zckheader"

CONVERSION_CMD:zck = "zck --output ${IMAGE_NAME}.${type}.zck -u --chunk-hash-type sha256 ${IMAGE_NAME}.${type}"
CONVERSION_CMD:zckheader = "dd if=${IMAGE_NAME}.${type} of=${IMAGE_NAME}.${type}.zckheader count=1 bs=`zck_read_header -v ${IMAGE_NAME}.${type} | grep 'Header size' | cut -d ':' -f 2 | tr -d '[:space:]'`"

CONVERSION_DEPENDS_zck = "zchunk-native"
CONVERSION_DEPENDS_zckheader = "zchunk-native"
