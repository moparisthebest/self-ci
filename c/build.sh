#!/bin/sh
set -euxo pipefail

export BUILD_SCRIPT="${1-.jenkins/build.sh}"

docker_build() {
    export ARCH="$1"
    shift
    DOCKER_IMAGE="$1"

    # run it, but after, chown anything left in /tmp to *this* uid/gid, otherwise we can't delete them later...
    docker run --rm -e ARCH -v "$(pwd)":/tmp "$DOCKER_IMAGE" sh -c "'/tmp/$BUILD_SCRIPT'; exit=\$?; chown -R '$UID:$(id -g)' /tmp; exit \$exit"
}

docker_build 'amd64'   'alpine'

# before first multiarch image, must register binfmt handlers
docker run --rm --privileged multiarch/qemu-user-static:register --reset

docker_build 'i386'    'multiarch/alpine:i386-latest-stable'
docker_build 'aarch64' 'multiarch/alpine:aarch64-latest-stable'
docker_build 'armv7'   'multiarch/alpine:armv7-latest-stable'
docker_build 'ppc64le' 'multiarch/alpine:ppc64le-latest-stable'
