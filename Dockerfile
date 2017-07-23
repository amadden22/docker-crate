## -*- docker-image-name: "docker-crate" -*-
#
# CrateDB Dockerfile
# https://github.com/crate/docker-crate

FROM alpine:3.6
MAINTAINER Crate.io office@crate.io

RUN addgroup crate && adduser -G crate -H crate -D

# install crate
ENV CRATE_VERSION 2.0.5
ENV GPG_KEY 90C23FC6585BC0717F8FBFC37FAAE51A06F6EAEB
RUN apk add --no-cache --virtual .crate-rundeps \
        openjdk8-jre-base \
        openssl \
        python3 \
        sigar \
        su-exec \
    && apk add --no-cache --virtual .build-deps \
        curl \
        gnupg \
        tar \
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz \
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    || gpg --keyserver keyserver.pgp.com --recv-keys "$GPG_KEY" \
    || gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" \
    && gpg --batch --verify crate-$CRATE_VERSION.tar.gz.asc crate-$CRATE_VERSION.tar.gz \
    && mkdir /crate \
    && tar -xf crate-$CRATE_VERSION.tar.gz -C /crate --strip-components=1 \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm /crate/plugins/crate-sigar/libsigar-amd64-linux.so \
    #&& rm /crate/lib/sigar/libsigar-amd64-linux.so \
    && rm crate-$CRATE_VERSION.tar.gz crate-$CRATE_VERSION.tar.gz.asc \
    && rm -r "$GNUPGHOME" \
    && apk del .build-deps

ENV PATH /crate/bin:$PATH

VOLUME ["/data"]

ADD config/crate.yml /crate/config/crate.yml
ADD config/log4j2.properties /crate/config/log4j2.properties
COPY docker-entrypoint.sh /

WORKDIR /data

EXPOSE 4200 4300 5432

STOPSIGNAL USR2

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crate"]
