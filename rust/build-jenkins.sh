#!/bin/bash
set -euxo pipefail

# this runs first arg or .jenkins/build.sh with env variable TARGET and DISABLE_TESTS set appropriately once for each target supported by cross
# this'll have to do until cross can run in docker containers backed by the btrfs driver...

# run like:
#   curl --compressed -sL https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/rust/build-jenkins.sh | bash
#   curl --compressed -sL https://raw.githubusercontent.com/moparisthebest/self-ci/master/rust/build-jenkins.sh | sed 's@https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master@https://raw.githubusercontent.com/moparisthebest/self-ci/master@g' | bash
# or with custom script:
#   curl --compressed -sL https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/rust/build-jenkins.sh | bash -s -- ./path/to/build.sh
#   curl --compressed -sL https://raw.githubusercontent.com/moparisthebest/self-ci/master/rust/build-jenkins.sh | sed 's@https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master@https://raw.githubusercontent.com/moparisthebest/self-ci/master@g' | bash -s -- ./path/to/build.sh

export BUILD_SCRIPT="${1-.jenkins/build.sh}"
shift
export RELEASE_SCRIPT="${1-.jenkins/release.sh}"

mkdir bin
cd bin
curl --compressed -sL -O https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/ci-release-helper.sh -O https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/rust/build.sh
chmod +x ci-release-helper.sh build.sh
cd ..
export PATH="$(pwd)/bin:$PATH"

build.sh "$BUILD_SCRIPT"

if [ -e "$RELEASE_SCRIPT" ]
then
    "$RELEASE_SCRIPT"
elif [ -d 'release' ]
then
    # default release script
    ci-release-helper.sh standard_pre_release
    find release/ -type f -print0 | xargs -0n1 -I {} ci-release-helper.sh standard_multi_release '{}' 'application/octet-stream'
fi

exit 0
