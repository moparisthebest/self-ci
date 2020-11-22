self-ci-rust
------------

A docker container with rustup and [cross](https://github.com/rust-embedded/cross) that runs a script with every variant cross supports.

Meant to be ran in CI something like this:

```sh
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:/build" -e BRANCH_NAME -e BUILD_UID=$UID -e BUILD_GID=$(id -g) moparisthebest/self-ci-rust:latest
```

Without arguments it will execute `.jenkins/build.sh` once for each docker container cross supports, setting the env variables TARGET and DISABLE_TESTS appropriately so invocations of `cross` and `cargo` *just work*.  If you want to call another script each time:

```sh
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$PWD:/build" -e BRANCH_NAME -e BUILD_UID=$UID -e BUILD_GID=$(id -g) moparisthebest/self-ci-rust:latest build.sh ./path/to/your/script.sh
```
