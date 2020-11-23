#!/bin/bash
set -euo pipefail

for TARGET in ${BUILD_TARGETS:-x86_64-unknown-linux-musl x86_64-unknown-linux-gnu i686-unknown-linux-musl i686-unknown-linux-gnu i586-unknown-linux-musl i586-unknown-linux-gnu aarch64-unknown-linux-musl aarch64-unknown-linux-gnu armv7-unknown-linux-gnueabihf armv7-unknown-linux-musleabihf arm-unknown-linux-gnueabi arm-unknown-linux-gnueabihf arm-unknown-linux-musleabi arm-unknown-linux-musleabihf armv5te-unknown-linux-gnueabi armv5te-unknown-linux-musleabi x86_64-pc-windows-gnu x86_64-linux-android i686-linux-android aarch64-linux-android armv7-linux-androideabi arm-linux-androideabi mips64el-unknown-linux-gnuabi64 mips64-unknown-linux-gnuabi64 mipsel-unknown-linux-gnu mipsel-unknown-linux-musl mips-unknown-linux-gnu mips-unknown-linux-musl powerpc64le-unknown-linux-gnu powerpc-unknown-linux-gnu riscv64gc-unknown-linux-gnu s390x-unknown-linux-gnu x86_64-sun-solaris sparcv9-sun-solaris x86_64-unknown-netbsd}
do
    if echo "$TARGET" | grep -E '(^s390x|^thumb|solaris$|^x86_64-unknown-dragonfly$|^x86_64-unknown-netbsd$)' >/dev/null
    then
        DISABLE_TESTS=1 TARGET="$TARGET" "$@"
    else
        TARGET="$TARGET" "$@"
    fi
done
