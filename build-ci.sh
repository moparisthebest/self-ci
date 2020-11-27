#!/bin/bash

# first arg is $BUILD_LANG, currently supported:
# 1. rust, this runs $BUILD_SCRIPT with env variable TARGET and DISABLE_TESTS set appropriately once for each target supported by cross
#    this'll have to do until cross can run in docker containers backed by the btrfs driver...
# 2. c, this runs $BUILD_SCRIPT inside an alpine linux container, once for each ARCH supported by build.sh here
# 3. java, this runs $BUILD_SCRIPT inside docker container moparisthebest/self-ci-java:latest once for each version of Java currently supported

# run like (for rust):
#   curl --compressed -sL https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/build-ci.sh | bash -s -- -l rust
#   curl --compressed -sL https://raw.githubusercontent.com/moparisthebest/self-ci/master/build-ci.sh | sed 's@https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master@https://raw.githubusercontent.com/moparisthebest/self-ci/master@g' | bash -s -- -l rust

BUILD_LANG=''
RELEASE_SCRIPT='.ci/release.sh'
BUILD_SCRIPT='.ci/build.sh'
DEFAULT_RELEASE_DIR='release'

function usage {
        echo "$@"
        echo
        echo "Usage: build-ci.sh [-l BUILD_LANG] [-r RELEASE_SCRIPT] [-d DEFAULT_RELEASE_DIR] [-b BUILD_SCRIPT]" 2>&1
        echo 'Build a project with self-ci.'
        echo '   -l BUILD_LANG           Specify the language build script to grab+execute (must be one of: rust, c, java)'
        echo '   -r RELEASE_SCRIPT       Specify the release script in this directory to run after build is successful'
        echo '   -d DEFAULT_RELEASE_DIR  If RELEASE_SCRIPT not specified, and this directory exists after successful build'
        echo '                           then run default release script on all files in it'
        echo '   -b BUILD_SCRIPT         Specify the build script in this directory to run with above language script'
        exit 1
}

while getopts 'l:b:r:d:' arg; do
  case ${arg} in
    l)
      BUILD_LANG="${OPTARG}"
      [ "" == "$(echo "$BUILD_LANG" | grep -E '^(rust|c|java)$')" ] && usage "Invalid lang $BUILD_LANG, must be one of: rust, c, java"
      ;;
    b)
      BUILD_SCRIPT="${OPTARG}"
      ;;
    r)
      RELEASE_SCRIPT="${OPTARG}"
      [ ! -e "$RELEASE_SCRIPT" ] && usage "Release script $RELEASE_SCRIPT does not exist"
      ;;
    d)
      DEFAULT_RELEASE_DIR="${OPTARG}"
      ;;
    ?)
      usage "Invalid option: -${OPTARG}."
      ;;
  esac
done

shift "$((OPTIND-1))"

# for all currently supported langs, this must exist in *this* directory
[ ! -e "$BUILD_SCRIPT" ] && usage "Build script $BUILD_SCRIPT does not exist"

# a bit of deterministic smarts to auto-detect BUILD_LANG
[ "$BUILD_LANG" == "" ] && [ -e pom.xml -o -e build.gradle ] && BUILD_LANG=java
[ "$BUILD_LANG" == "" ] && [ -e Cargo.toml ] && BUILD_LANG=rust
[ "$BUILD_LANG" == "" ] && [ -e Makefile ] && BUILD_LANG=c

[ "$BUILD_LANG" == "" ] && usage "-l BUILD_LANG autodetection failed, must be set manually"

echo "build-ci.sh: BUILD_LANG=$BUILD_LANG RELEASE_SCRIPT=$RELEASE_SCRIPT BUILD_SCRIPT=$BUILD_SCRIPT remaining args:" "$@"

set -euxo pipefail

mkdir -p bin
cd bin
curl --compressed -sL -O 'https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/ci-release-helper.sh' -O "https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/$BUILD_LANG/build.sh"
chmod +x ci-release-helper.sh build.sh
cd ..

export PATH="$(pwd)/bin:$PATH"
export BRANCH_NAME="$BRANCH_NAME"
export BUILD_UID="$UID"
export BUILD_GID="$(id -g)"

build.sh "$BUILD_SCRIPT" "$@"

if [ -e "$RELEASE_SCRIPT" ]
then
    "$RELEASE_SCRIPT" "$@"
elif [ -d "$DEFAULT_RELEASE_DIR" ]
then
    # default release script
    ci-release-helper.sh standard_pre_release
    cd "$DEFAULT_RELEASE_DIR"
    find -type f ! -path ./sha256sum.txt -print0 | xargs -0 sha256sum > sha256sum.txt
    gpg --clearsign sha256sum.txt
    ci-release-helper.sh standard_multi_release 'sha256sum.txt' 'text/plain'
    ci-release-helper.sh standard_multi_release 'sha256sum.txt.asc' 'text/plain'
    rm -f sha256sum.txt sha256sum.txt.asc
    find -type f -print0 | xargs -0n1 -I {} ci-release-helper.sh standard_multi_release '{}' 'application/octet-stream'
fi

exit 0
