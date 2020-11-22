#!/bin/bash
set -euo pipefail

for TARGET in ${BUILD_TARGETS:-x86_64-unknown-linux-musl}
do
    TARGET="$TARGET" "$@"
done
