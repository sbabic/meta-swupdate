# Copyright (C) 2015-2022 Stefano Babic
#
# SPDX-License-Identifier: GPLv3

DEPENDS += "python3-magic-native zstd-native"

def swupdate_encrypt_file(f, out, key, ivt):
    import subprocess
    encargs = ["openssl", "enc", "-aes-256-cbc", "-in", f, "-out", out]
    encargs += ["-K", key, "-iv", ivt, "-nosalt"]
    subprocess.run(encargs, check=True)

def swupdate_extract_keys(keyfile_path):
    try:
        with open(keyfile_path, 'r') as f:
            lines = f.readlines()
    except IOError:
        bb.fatal("Failed to open file with keys %s" % (keyfile))

    data = {}
    for _ in lines:
        k,v = _.split('=',maxsplit=1)
        data[k.rstrip()] = v

    key = data['key'].rstrip('\n')
    iv = data['iv'].rstrip('\n')

    return key,iv

def swupdate_get_sha256(d, s, filename):
    import hashlib

    m = hashlib.sha256()

    with open(os.path.join(s, filename), 'rb') as f:
        while True:
            data = f.read(1024)
            if not data:
                break
            m.update(data)
    return m.hexdigest()

def swupdate_sign_file(d, s, filename):
    import subprocess
    import magic
    import base64

    fname = os.path.join(s, filename)
    mime = magic.Magic(mime=True)
    ftype = mime.from_file(fname)

    if ftype == 'application/zstd':
       zcmd = 'zstdcat'
    elif ftype == 'application/gzip':
       zcmd = 'zcat'
    else:
       zcmd = 'cat'

    privkey = d.getVar('SWUPDATE_SIGN_PRIVATE_KEY')

    dump = subprocess.run([ zcmd, fname ], check=True, capture_output=True)

    signature = subprocess.run([ "openssl", "dgst", "-keyform", "PEM", "-sha256", "-sign", privkey ] + \
              get_pwd_file_args(d, 'SWUPDATE_SIGN_PASSWORD_FILE'), check=True, capture_output=True, input=dump.stdout)

    hash = base64.b64encode(signature.stdout).decode()

    # SWUpdate accepts attribute with a maximum size of 255. If the hash
    # exceeds this value, returns sha256 of the generated hash
    #  
    if len(hash) > 255:
       m = hashlib.sha256()
       m.update(hash)
       hash = m.hexdigest()

    return hash

def swupdate_get_pkgvar(d, s, parms):
    import re
    import oe.packagedata

    def get_package_name(group):
        package = None

        pkgvar = group.split('@')
        package = pkgvar[0]
        if len(pkgvar) > 1:
            varname = pkgvar[1]
        else:
            varname = 'PV'

        return (package, varname)

    if parms is None:
        return "undefined"

    group = parms

    (package, key) = get_package_name(group)

    bb.debug(2, "Package %s defined %s" %(package, key))

    pkg_info = os.path.join(d.getVar('PKGDATA_DIR'), 'runtime-reverse', package)
    pkgdata = oe.packagedata.read_pkgdatafile(pkg_info)

    if not key in pkgdata.keys():
        bb.warn("\"%s\" not set for package %s - using \"1.0\"" % (key, package))
        version = "1.0"
    else:
        version = pkgdata[key].split('+')[0]

    return version
