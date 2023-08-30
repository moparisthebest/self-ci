#!/bin/sh

BUILD_SCRIPT="$1"
shift

# this will be 0 if podman, or 1 if docker
PODMAN_NOT_DOCKER="$1"
shift

[ "" == "$BUILD_SCRIPT" ] && [ -f '.ci/build.sh' ] && BUILD_SCRIPT='.ci/build.sh'

if [ "" == "$PODMAN_NOT_DOCKER" ]
then
    # if it's not set, we are going to prefer podman
    which podman >/dev/null 2>/dev/null
    PODMAN_NOT_DOCKER=$?
fi

set -euxo pipefail

# this assists in cleanup, ie if a job was terminated, to be run in a jenkins finally {} or similar
if [ "$BUILD_SCRIPT" == "docker-chown" ]
then
    if [ $PODMAN_NOT_DOCKER -eq 0 ]
    then
        # we don't have to do anything here
        exit 0
    else
        # chown everything in this directory to this uid/gid
        docker run --rm -v "$(pwd)":/tmp alpine chown -R "$UID:$(id -g)" /tmp
        exit $?
    fi
fi

docker_build() {
    export ARCH="$1"
    shift
    DOCKER_IMAGE="$1"
    shift
    
    if [ $PODMAN_NOT_DOCKER -eq 0 ]
    then
        # just run it and don't chown
        podman run --rm -e ARCH -e BRANCH_NAME -v "$(pwd)":/tmp -w /tmp "$DOCKER_IMAGE" sh -c "umask a=rwx; \"\$@\"" -- "$@"
    else
        # run it, but after, chown anything left in /tmp to *this* uid/gid, otherwise we can't delete them later...
        docker run --rm -e ARCH -e BRANCH_NAME -e BUILD_UID="$UID" -e BUILD_GID="$(id -g)" -v "$(pwd)":/tmp -w /tmp "$DOCKER_IMAGE" sh -c "umask a=rwx; \"\$@\"; exit=\$?; chown -R '$UID:$(id -g)' /tmp; exit \$exit" -- "$@"
    fi
}

docker_build 'amd64'   'docker.io/alpine'                                 "$BUILD_SCRIPT" "$@"

# before first multiarch image, must register binfmt handlers, for rootless podman we require sudo
if [ $PODMAN_NOT_DOCKER -eq 0 ]
then
    # to securely enable this run `visudo` and add this where `jenkins` is your user:
    # jenkins ALL=(ALL:ALL) NOPASSWD: /usr/bin/podman run --rm --privileged docker.io/multiarch/qemu-user-static\:register --reset
    sudo podman run --rm --privileged docker.io/multiarch/qemu-user-static:register --reset
else
    docker run --rm --privileged docker.io/multiarch/qemu-user-static:register --reset
fi

docker_build 'i386'    'docker.io/multiarch/alpine:i386-latest-stable'    "$BUILD_SCRIPT" "$@"
docker_build 'aarch64' 'docker.io/multiarch/alpine:aarch64-latest-stable' "$BUILD_SCRIPT" "$@"
docker_build 'armv7'   'docker.io/multiarch/alpine:armv7-latest-stable'   "$BUILD_SCRIPT" "$@"
docker_build 'armhf'   'docker.io/multiarch/alpine:armhf-latest-stable'   "$BUILD_SCRIPT" "$@"
docker_build 'ppc64le' 'docker.io/multiarch/alpine:ppc64le-latest-stable' "$BUILD_SCRIPT" "$@"
