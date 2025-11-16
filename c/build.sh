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
    
    if [ $PODMAN_NOT_DOCKER -eq 0 ]
    then
        # just run it and don't chown
        podman run --rm --arch "$ARCH" -e ARCH -e BRANCH_NAME -v "$(pwd)":/tmp -w /tmp 'docker.io/alpine' sh -c "umask a=rwx; \"\$@\"" -- "$@"
    else
        # run it, but after, chown anything left in /tmp to *this* uid/gid, otherwise we can't delete them later...
        docker run --rm --arch "$ARCH" -e ARCH -e BRANCH_NAME -e BUILD_UID="$UID" -e BUILD_GID="$(id -g)" -v "$(pwd)":/tmp -w /tmp 'docker.io/alpine' sh -c "umask a=rwx; \"\$@\"; exit=\$?; chown -R '$UID:$(id -g)' /tmp; exit \$exit" -- "$@"
    fi
}

# before first multiarch image, must register binfmt handlers, for arch run:
# pacman -S qemu-user-static-binfmt qemu-user-static

for arch in amd64 i386 armhf ppc64le riscv64
# s390x is currently broken, hangs during configure
do
    docker_build "$arch" "$BUILD_SCRIPT" "$@"
done
