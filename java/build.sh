#!/bin/bash
set -euo pipefail

BUILD_SCRIPT="$1"
shift
[ "" == "$BUILD_SCRIPT" ] && [ -f '.ci/build.sh' ] && BUILD_SCRIPT='.ci/build.sh'
[ "" == "$BUILD_SCRIPT" ] && [ -f '.jenkins/build.sh' ] && BUILD_SCRIPT='.jenkins/build.sh'

docker run --rm -v "$HOME/.netrc:/root/.netrc:ro" -v "$HOME/.m2:/m2" -v "$HOME/.npm:/npm" -v "$PWD:/build" -e BRANCH_NAME -e BUILD_UID=$UID -e BUILD_GID=$(id -g) moparisthebest/self-ci-java:latest /usr/bin/run-java-all "$BUILD_SCRIPT" "$@"
