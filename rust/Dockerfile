
FROM moparisthebest/self-ci-base:latest

# set CROSS_DOCKER_IN_DOCKER to inform `cross` that it is executed from within a container
#ENV CROSS_DOCKER_IN_DOCKER=true

RUN mkdir /cargo && ln -sf /cargo/ /root/.cargo && \
    pacman -Syu --noconfirm --needed docker rustup gcc && \
    rustup install stable && rustup default stable && \
    cargo install --root / cross

COPY ./build.sh /usr/bin/

VOLUME [ "/build", "/var/run/docker.sock" ]

WORKDIR /build
ENTRYPOINT ["/usr/bin/run.sh"]
CMD ["/usr/bin/build.sh", "./.jenkins/build.sh"]
