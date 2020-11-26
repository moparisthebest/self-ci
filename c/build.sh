#!/bin/sh
set -euxo pipefail

BUILD_SCRIPT="$1"
shift
[ "" == "$BUILD_SCRIPT" ] && [ -f '.ci/build.sh' ] && BUILD_SCRIPT='.ci/build.sh'
[ "" == "$BUILD_SCRIPT" ] && [ -f '.jenkins/build.sh' ] && BUILD_SCRIPT='.jenkins/build.sh'


# this assists in cleanup, ie if a job was terminated, to be run in a jenkins finally {} or similar
if [ "$BUILD_SCRIPT" == "docker-chown" ]
then
    # chown everything in this directory to this uid/gid
    docker run --rm -v "$(pwd)":/tmp alpine chown -R "$UID:$(id -g)" /tmp
    exit $?
fi

docker_build() {
    export ARCH="$1"
    shift
    DOCKER_IMAGE="$1"
    shift

    # run it, but after, chown anything left in /tmp to *this* uid/gid, otherwise we can't delete them later...
    docker run --rm -e ARCH -e BRANCH_NAME -e BUILD_UID="$UID" -e BUILD_GID="$(id -g)" -v "$(pwd)":/tmp -w /tmp "$DOCKER_IMAGE" sh -c "\"\$@\"; exit=\$?; chown -R '$UID:$(id -g)' /tmp; exit \$exit" -- "$@"
}

docker_build 'amd64'   'alpine'                                 "$BUILD_SCRIPT" "$@"

# before first multiarch image, must register binfmt handlers
docker run --rm --privileged multiarch/qemu-user-static:register --reset

docker_build 'i386'    'multiarch/alpine:i386-latest-stable'    "$BUILD_SCRIPT" "$@"
docker_build 'aarch64' 'multiarch/alpine:aarch64-latest-stable' "$BUILD_SCRIPT" "$@"
docker_build 'armv7'   'multiarch/alpine:armv7-latest-stable'   "$BUILD_SCRIPT" "$@"
docker_build 'ppc64le' 'multiarch/alpine:ppc64le-latest-stable' "$BUILD_SCRIPT" "$@"
