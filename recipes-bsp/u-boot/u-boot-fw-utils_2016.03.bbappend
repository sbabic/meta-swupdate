FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
    file://0001-tools-env-bug-config-structs-must-be-defined-in-tool.patch \
    file://0001-tools-env-fix-config-file-loading-in-env-library.patch \
    "
