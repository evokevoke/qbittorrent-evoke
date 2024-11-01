# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest AS unrar
FROM ghcr.io/linuxserver/baseimage-alpine:3.20

# Set version label
ARG BUILD_DATE
ARG VERSION
ARG QBITTORRENT_VERSION="4.6.7"
ARG LIBTORRENT_VERSION="1.2.19"
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thespad"

# Environment settings
ENV HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    XDG_DATA_HOME="/config"

# Copy patch file
COPY libtorrent-RC_1_2.patch /tmp/libtorrent-RC_1_2.patch

# Install runtime packages, build dependencies, and qBittorrent CLI
RUN \
  echo "**** install packages ****" && \
  apk add -U --no-cache \
    icu-libs \
    p7zip \
    python3 \
    qt6-qtbase-sqlite \
    cmake \
    boost-dev \
    openssl-dev \
    gcc \
    g++ \
    make \
    libtool \
    automake \
    autoconf \
    curl \
    jq && \
  echo "**** download and build libtorrent ****" && \
  curl -L "https://github.com/arvidn/libtorrent/releases/download/libtorrent-${LIBTORRENT_VERSION}/libtorrent-rasterbar-${LIBTORRENT_VERSION}.tar.gz" -o /tmp/libtorrent.tar.gz && \
  tar xf /tmp/libtorrent.tar.gz -C /tmp && \
  cd /tmp/libtorrent-rasterbar-${LIBTORRENT_VERSION} && \
  patch -p1 < /tmp/libtorrent-RC_1_2.patch && \
  cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && \
  cmake --build build --target install && \
  echo "**** install qbittorrent ****" && \
  curl -o /app/qbittorrent-nox -L "https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-${QBITTORRENT_VERSION}/x86_64-qbittorrent-nox" && \
  chmod +x /app/qbittorrent-nox && \
  echo "**** install qbittorrent-cli ****" && \
  mkdir /qbt && \
  QBT_CLI_VERSION=$(curl -sL "https://api.github.com/repos/fedarovich/qbittorrent-cli/releases/latest" | jq -r '. | .tag_name') && \
  curl -o /tmp/qbt.tar.gz -L "https://github.com/fedarovich/qbittorrent-cli/releases/download/${QBT_CLI_VERSION}/qbt-linux-alpine-x64-net6-${QBT_CLI_VERSION#v}.tar.gz" && \
  tar xf /tmp/qbt.tar.gz -C /qbt && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  rm -rf \
    /root/.cache \
    /tmp/*

# Add local files
COPY root/ /

# Add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# Ports and volumes
EXPOSE 8080 6881 6881/udp
VOLUME /config
