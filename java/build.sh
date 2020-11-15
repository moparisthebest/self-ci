#!/bin/bash
set -euo pipefail

for jdk in ${BUILD_JDKS:-java-6-jdk java-7-openjdk java-8-openjdk jdk-9 jdk-10 java-11-openjdk jdk-12 jdk-13 java-14-openjdk jdk-15 jdk-16}
do
    sudo archlinux-java set "$jdk"

    export JAVA_VERSION="$(echo "$jdk" | grep -Eo '[0-9]+')"
    export JAVA_HOME="/usr/lib/jvm/$jdk"

    export M2_HOME="/opt/maven"

    # maven 3.2.5 is the latest version supported by 6
    [ $JAVA_VERSION -eq 6 ] && export M2_HOME="/opt/apache-maven-3.2.5"

    export PATH="$JAVA_HOME/bin:$M2_HOME/bin:$PATH"
    echo "building with JAVA_VERSION='$JAVA_VERSION' JAVA_HOME='$JAVA_HOME'"
    "$@"
done
