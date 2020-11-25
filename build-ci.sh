#!/bin/bash

# first arg is $BUILD_LANG, currently supported:
# 1. rust, this runs $BUILD_SCRIPT with env variable TARGET and DISABLE_TESTS set appropriately once for each target supported by cross
#    this'll have to do until cross can run in docker containers backed by the btrfs driver...
# 2. c, this runs $BUILD_SCRIPT inside an alpine linux container, once for each ARCH supported by build.sh here

# run like (for rust):
#   curl --compressed -sL https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/build-ci.sh | bash -s -- rust
#   curl --compressed -sL https://raw.githubusercontent.com/moparisthebest/self-ci/master/build-ci.sh | sed 's@https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master@https://raw.githubusercontent.com/moparisthebest/self-ci/master@g' | bash -s -- rust

export BUILD_LANG="${1-rust}"
shift
export BUILD_SCRIPT="${1-.jenkins/build.sh}"
shift
export RELEASE_SCRIPT="${1-.jenkins/release.sh}"
shift

set -euxo pipefail

mkdir -p bin
cd bin
curl --compressed -sL -O 'https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/ci-release-helper.sh' -O "https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/$BUILD_LANG/build.sh"
chmod +x ci-release-helper.sh build.sh
cd ..
export PATH="$(pwd)/bin:$PATH"

build.sh "$BUILD_SCRIPT" "$@"

if [ -e "$RELEASE_SCRIPT" ]
then
    "$RELEASE_SCRIPT" "$@"
elif [ -d 'release' ]
then
    # default release script
    ci-release-helper.sh standard_pre_release
    cd release
    find -type f ! -path ./sha256sum.txt -print0 | xargs -0 sha256sum > sha256sum.txt
    gpg --clearsign sha256sum.txt
    ci-release-helper.sh standard_multi_release 'sha256sum.txt' 'text/plain'
    ci-release-helper.sh standard_multi_release 'sha256sum.txt.asc' 'text/plain'
    rm -f sha256sum.txt sha256sum.txt.asc
    find -type f -print0 | xargs -0n1 -I {} ci-release-helper.sh standard_multi_release '{}' 'application/octet-stream'
fi

exit 0
