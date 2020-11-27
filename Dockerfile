

FROM archlinux/base:latest

ENV PACMAN_MIRROR https://burtrum.org/archlinux

ENV TZ=America/New_York

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    mkdir /build && \
    # add my custom aur repo
    pacman-key --init && \
    curl --pinnedpubkey 'sha256//eEHQC9au2QRAP1FnvcYEsmvXT7511EXQ2gw8ppBfseM=' https://burtrum.org/aur/aur.sh | bash && \
    # use my local pacman mirror
    echo -e "Server = $PACMAN_MIRROR/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist && \
    echo "TZ=$TZ" > /etc/environment && \
    pacman -Syu --noconfirm --needed sed grep gawk sudo git which jq && \
    echo 'ci ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ci

COPY ./run.sh ./ci-release-helper.sh /usr/bin/

VOLUME [ "/build" ]

WORKDIR /build
ENTRYPOINT ["/usr/bin/run.sh"]
CMD ["/usr/bin/bash"]
