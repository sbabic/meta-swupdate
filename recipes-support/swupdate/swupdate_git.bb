require swupdate.inc
require swupdate_tools.inc

DEFAULT_PREFERENCE = "-1"

# If a recipe sets SRCREV to ${AUTOREV}, bitbake tries
# a git ls-remote. This breaks when a mirror is built
# and BB_NO_NETWORK is set.
# To work-around the issue, sets the revision for the git
# version to a fix commit (not relevant)
# In casethe _git version is chosen, sets the revision
# to TOT to test with last commit-id.
def version_git(d):
    version = d.getVar("PREFERRED_VERSION_%s" % d.getVar('PN', False), False)
    if version is not None and "git" in version:
        return d.getVar('AUTOREV', False)
    else:
        return "c0fec16b3fc82b0db12d8ac58be7055ed1b8d439"

SRCREV ?= '${@version_git(d)}'
