self-ci-java
------------

A docker container with every version of the Java JDK 6 to 16 installed in it, and maven to work with them all, for building and testing java applications across all versions.

Meant to be ran in CI something like this:

```sh
# docker directly
docker run --rm -v "$HOME/.m2:/m2" -v "$PWD:/build" -e BRANCH_NAME -e BUILD_UID=$UID -e BUILD_GID=$(id -g) moparisthebest/self-ci-java:latest

# through self-ci script hosted at code.moparisthebest.com
curl --compressed -sL https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master/build-ci.sh | bash -s -- java

# through self-ci script hosted at github
curl --compressed -sL https://raw.githubusercontent.com/moparisthebest/self-ci/master/build-ci.sh | sed 's@https://code.moparisthebest.com/moparisthebest/self-ci/raw/branch/master@https://raw.githubusercontent.com/moparisthebest/self-ci/master@g' | bash -s -- java
```

Without arguments it will execute `.jenkins/build.sh` once for each version of Java installed, setting the env variables JAVA_VERSION (a number), JAVA_HOME, M2_HOME, and PATH appropriately so invocations of `mvn` and `java` *just work*.  If you want to call another script each time:

```sh
docker run --rm -v "$HOME/.m2:/m2" -v "$PWD:/build" -e BRANCH_NAME -e BUILD_UID=$UID -e BUILD_GID=$(id -g) moparisthebest/self-ci-java:latest run-java-all ./path/to/your/script.sh
```
