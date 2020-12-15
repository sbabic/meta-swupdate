#
# The key must be generated as described in doc
# with
# openssl enc -aes-256-cbc -k <PASSPHRASE> -P -md sha1 -nosalt
# The file is in the format
# key=
# iv=
# parameters: $1 = input file, $2 = output file
swu_encrypt_file() {
	input=$1
	output=$2
	key=`cat ${SWUPDATE_AES_FILE} | grep ^key | cut -d '=' -f 2`
	iv=`cat ${SWUPDATE_AES_FILE} | grep ^iv | cut -d '=' -f 2`
	if [ -z ${key} ] || [ -z ${iv} ];then
		bbfatal "SWUPDATE_AES_FILE=$SWUPDATE_AES_FILE does not contain valid keys"
	fi
	openssl enc -aes-256-cbc -in ${input} -out ${output} -K ${key} -iv ${iv} -nosalt
}

CONVERSIONTYPES += "enc"

CONVERSION_DEPENDS_enc = "openssl-native coreutils-native"
CONVERSION_CMD_enc="swu_encrypt_file ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${type} ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${type}.enc"
