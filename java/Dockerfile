
FROM moparisthebest/self-ci-base:latest

RUN mkdir /m2 /npm && ln -sf /m2/ /root/.m2 && ln -sf /npm/ /root/.npm && \
    echo "JAVA_HOME=/usr/lib/jvm/default" > /etc/environment && \
    pacman -Syu --noconfirm --needed maven \
    jdk6 \
    jdk7-openjdk \
    jdk8-openjdk \
    jdk11-openjdk \
    jdk-openjdk && \
    # always set default to latest
    archlinux-java set java-14-openjdk && \
    # java 6 requires this old version of maven
    curl https://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz | bsdtar -xf - -C /opt && \
    # get all the versions of java arch doesn't package
    curl https://download.java.net/openjdk/jdk9/ri/openjdk-9+181_linux-x64_ri.zip | bsdtar -xf - -C /usr/lib/jvm && \
    curl https://download.java.net/openjdk/jdk10/ri/openjdk-10+44_linux-x64_bin_ri.tar.gz | bsdtar -xf - -C /usr/lib/jvm && \
    curl https://download.java.net/openjdk/jdk12/ri/openjdk-12+32_linux-x64_bin.tar.gz | bsdtar -xf - -C /usr/lib/jvm && \
    curl https://download.java.net/openjdk/jdk13/ri/openjdk-13+33_linux-x64_bin.tar.gz | bsdtar -xf - -C /usr/lib/jvm && \
    curl https://download.java.net/openjdk/jdk15/ri/openjdk-15+36_linux-x64_bin.tar.gz | bsdtar -xf - -C /usr/lib/jvm && \
    curl https://download.java.net/java/early_access/jdk16/23/GPL/openjdk-16-ea+23_linux-x64_bin.tar.gz | bsdtar -xf - -C /usr/lib/jvm && \
    mv /usr/lib/jvm/java-se-9-ri/jdk-9 /usr/lib/jvm/ && rm -rf java-se-9-ri && chmod +x /usr/lib/jvm/jdk-9/bin/*

COPY ./run-java-all ./run-java /usr/bin/

VOLUME [ "/build", "/m2", "/npm", "/root/.netrc" ]

WORKDIR /build
ENTRYPOINT ["/usr/bin/run.sh"]
CMD ["/usr/bin/run-java-all", "./.ci/build.sh"]
