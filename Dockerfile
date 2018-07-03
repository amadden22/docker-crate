## -*- docker-image-name: "docker-crate" -*-
#
# Crate Dockerfile
# https://github.com/crate/docker-crate
#

#changed to rhel 
FROM rhel7:latest

MAINTAINER Crate.IO GmbH office@crate.io

#license needed to pass scan
COPY LICENSE.txt /license

ENV GOSU_VERSION 1.9

RUN set -x \
#rhel version of installing gosu	
	\
	yum -y install epel-release; \
        yum -y install wget dpkg; \
        \
        dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
        wget -O /usr/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
        wget -O /tmp/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
        \
# verify the signature
        export GNUPGHOME="$(mktemp -d)"; \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
        gpg --batch --verify /tmp/gosu.asc /usr/bin/gosu; \
        rm -r "$GNUPGHOME" /tmp/gosu.asc; \
        \
        chmod +x /usr/bin/gosu; \
# verify that the binary works
        gosu nobody true; \
        \
        yum -y remove wget dpkg; \
        rm -rf /var/cache/yum; \
        yum clean all

#changed addgroup -> groupadd, adduser -> useradd, changed -H -> -h
RUN groupadd crate && useradd -G crate -h crate -D


# install crate
ENV CRATE_VERSION 3.0.3
RUN set -x \

     \
     yum -y install openjdk8-jre-base; \
     yum -y install python3; \
     yum -y install openssl; \
     yum -y install curl; \
     yum -y install gnupg; \
     yum -y install tar; \
     
     curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz; \
     curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz.asc; \
     export GNUPGHOME="$(mktemp -d)"; \
     gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 90C23FC6585BC0717F8FBFC37FAAE51A06F6EAEB; \
     gpg --batch --verify crate-$CRATE_VERSION.tar.gz.asc crate-$CRATE_VERSION.tar.gz; \
     rm -rf "$GNUPGHOME" crate-$CRATE_VERSION.tar.gz.asc; \
     mkdir /crate; \
     tar -xf crate-$CRATE_VERSION.tar.gz -C /crate --strip-components=1; \
     rm crate-$CRATE_VERSION.tar.gz; \
     ln -s /usr/bin/python3 /usr/bin/python; \
#changed from apk del -> yum remove
       yum remove .build-deps

ENV PATH /crate/bin:$PATH
# Default heap size for Docker, can be overwritten by args
ENV CRATE_HEAP_SIZE 512M

# This healthcheck indicates if a CrateDB node is up and running. It will fail
# if we cannot get any response from the CrateDB (connection refused, timeout
# etc). If any response is received (regardless of http status code) we
# consider the node as running.
HEALTHCHECK --timeout=30s --interval=30s CMD curl --fail --max-time 25 $(hostname):4200

RUN mkdir -p /data/data /data/log

VOLUME /data

ADD config/crate.yml /crate/config/crate.yml
ADD config/log4j2.properties /crate/config/log4j2.properties
COPY entrypoint_3.0.sh /docker-entrypoint.sh

WORKDIR /data

# http: 4200 tcp
# transport: 4300 tcp
# postgres protocol ports: 5432 tcp
EXPOSE 4200 4300 5432

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crate"]
