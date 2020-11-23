#!/bin/bash
set -euxo pipefail

# this'll have to do until cross can run in docker containers backed by the btrfs driver
# run like: curl https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/rust/build-jenkins.sh | bash

mkdir bin
cd bin
curl -O https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/ci-release-helper.sh -O https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/rust/build.sh
chmod +x ci-release-helper.sh build.sh
cd ..
export PATH="$(pwd)/bin:$PATH"
ci-release-helper.sh standard_pre_release
exec build.sh .jenkins/build.sh
