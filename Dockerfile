## -*- docker-image-name: "docker-crate" -*-
#
# Crate Dockerfile
# https://github.com/crate/docker-crate
#

FROM java:8-jre
MAINTAINER Crate Technology GmbH <office@crate.io>

RUN apt-get update && \
    apt-get install -y python3 && \
    rm -rf /var/lib/apt && \
    ln -s /usr/bin/python3 /usr/bin/python

# tmp folder on Crate CDN
ENV CDN_URL "https://cdn.crate.io/downloads/releases/tmp"
# Crate version
ENV CRATE_VERSION "0.55.0-201603160301-76d45ee"
ENV CRATE_URL "${CDN_URL}/crate-${CRATE_VERSION}.tar.gz"
# Commoncrawl Plugin version
ENV PLUGIN_VERSION "1.3-SNAPSHOT"
ENV PLUGIN_URL "${CDN_URL}/crate-commoncrawl-${PLUGIN_VERSION}.jar"

# download Crate
RUN mkdir -pv /crate && \
    wget -nv -O - ${CRATE_URL} | tar -xzC /crate --strip-components=1
# remove unused plugins and download commoncrawl plugin
RUN rm -rf /crate/plugins/aws && \
    rm -rf /crate/plugins/hdfs && \
    rm -rf /crate/lib/sigar/*.so && \
    rm -rf /crate/lib/sigar/*.dylib && \
    rm -rf /crate/lib/sigar/*.dll && \
    mkdir -pv /crate/plugins/commoncrawl && \
    wget -nv -O /crate/plugins/commoncrawl/crate-commoncrawl-${PLUGIN_VERSION}.jar ${PLUGIN_URL}

# add executable to path
ENV PATH /crate/bin:$PATH

VOLUME ["/data", "/data1", "/data2", "/data3"]

ADD config/crate.yml /crate/config/crate.yml
ADD config/logging.yml /crate/config/logging.yml

WORKDIR /data

# http: 4200 tcp
# transport: 4300 tcp
EXPOSE 4200 4300

CMD ["crate"]
