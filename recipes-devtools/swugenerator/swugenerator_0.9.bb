SUMMARY = "Generator of SWU update packages for SWUpdate"
DESCRIPTION = "swugenerator creates, signs and encrypts SWU files from a \
sw-description template, and wraps them into Mender Artifacts."
HOMEPAGE = "https://github.com/sbabic/swugenerator"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

SRC_URI[sha256sum] = "ce83be33dc5d3a01db8a10ac31c432166ea3c878e071241b13c6e9ab2aa5653d"

inherit pypi python_setuptools_build_meta

# openssl signs and encrypts, gzip, xz and zstd compress the artifacts;
# for native, gzip comes from pigz-native, as in image_types.bbclass:
# gzip-native is provided by both gzip and pigz
RDEPENDS:${PN}:class-target += "python3-core python3-compression python3-crypt \
    python3-json python3-logging python3-shell python3-libconf \
    openssl-bin gzip xz zstd"
RDEPENDS:${PN}:class-nativesdk += "python3-core python3-compression python3-crypt \
    python3-json python3-logging python3-shell python3-libconf \
    nativesdk-openssl-bin nativesdk-gzip nativesdk-xz nativesdk-zstd"
RDEPENDS:${PN}:class-native += "python3-native python3-libconf-native openssl-native \
    pigz-native xz-native zstd-native"

BBCLASSEXTEND = "native nativesdk"
