#!/usr/bin/env bash
# Build anaconda-webui RPMs from this checkout into ./rpms/, the way COPR
# would: SRPM via the upstream `make srpm`, then a clean rpmbuild. Meant to
# run inside a fresh Fedora container (see workflows/rpm.yml), which is what
# makes the build clean -- no mock needed.
#
# RELEASE (default 1) goes into the RPM Release so rebuilds of the same commit
# get a new NEVRA; the package registry refuses duplicate uploads. The
# ".quine" suffix makes e.g. 86-1.quine sort above Fedora's own 86-1.
set -euxo pipefail

RELEASE="${RELEASE:-1}"

dnf -y install git make npm diffutils rpm-build 'dnf5-command(builddep)'
git config --global --add safe.directory '*'

# The fork carries no tags, so `git describe` (which sets the version) would
# fall back to "1" and sort below Fedora's own anaconda-webui. Pull upstream's
# tags so the version comes out as e.g. 86.12.gabcdef0, just above release 86.
git fetch --no-write-fetch-head --tags --force https://github.com/rhinstaller/anaconda-webui.git
[ "$(git rev-parse --is-shallow-repository)" = false ] || git fetch --unshallow --no-write-fetch-head origin

make anaconda-webui.spec
sed -i "s/^Release:.*/Release:        ${RELEASE}.quine%{?dist}/" anaconda-webui.spec
make srpm

dnf -y builddep anaconda-webui-*.src.rpm
rpmbuild --rebuild --define "_rpmdir $PWD/rpms" anaconda-webui-*.src.rpm
mv anaconda-webui-*.src.rpm rpms/
find rpms -name '*.rpm'
