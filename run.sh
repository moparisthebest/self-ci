#!/bin/bash

. /etc/environment

# support building with configurable UID/GID
if [ ! -z "${BUILD_UID:-}" ]
then
    BUILD_GID="${BUILD_GID:-$BUILD_UID}"
    groupadd -r -g "$BUILD_GID" jenkins
    useradd -r -u "$BUILD_UID" -g "$BUILD_GID" -s /bin/bash -m -d /root jenkins
    chown "$BUILD_UID":"$BUILD_GID" /root
    #exec runuser -m jenkins -- "$@"
    exec sudo -E -u jenkins -- "$@"
fi

# otherwise just run as root

# since we are running in a docker container, and outputting files in a volume, we want world everything
umask a=rwx

exec "$@"
