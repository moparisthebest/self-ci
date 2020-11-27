#!/bin/bash

. /etc/environment

# support building with configurable UID/GID
if [ ! -z "${BUILD_UID:-}" ]
then
    BUILD_GID="${BUILD_GID:-$BUILD_UID}"
    groupadd -r -g "$BUILD_GID" ci
    useradd -r -u "$BUILD_UID" -g "$BUILD_GID" -s /bin/bash -m -d /root ci
    chown "$BUILD_UID":"$BUILD_GID" /root
    #exec runuser -m ci -- "$@"
    exec sudo -E -u ci -- "$@"
fi

# otherwise just run as root

# since we are running in a docker container, and outputting files in a volume, we want world everything
umask a=rwx

exec "$@"
