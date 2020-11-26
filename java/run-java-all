#!/bin/bash
set -euo pipefail

for jdk in ${BUILD_JDKS:-6 7 8 9 10 11 12 13 14 15 16}
do
    run-java "$jdk" "$@"
done
