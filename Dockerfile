# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.18

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BEETS_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    cairo-dev \
    cargo \
    cmake \
    ffmpeg-dev \
    fftw-dev \
    git \
    gobject-introspection-dev \
    jpeg-dev \
    libpng-dev \
    mpg123-dev \
    openjpeg-dev \
    python3-dev && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    chromaprint \
    expat \
    ffmpeg \
    fftw \
    flac \
    gdbm \
    gobject-introspection \
    gst-plugins-good \
    gstreamer \
    jpeg \
    lame \
    libffi \
    libpng \
    mpg123 \
    nano \
    openjpeg \
    python3 \
    sqlite-libs && \
  echo "**** install beets ****" && \
  mkdir -p /tmp/beets && \
  if [ -z ${BEETS_VERSION+x} ] ; then \
    BEETS_VERSION=$(curl -sX GET "https://api.github.com/repos/beetbox/beets/commits/master" \
    | jq -r .sha); \
  fi && \
  curl -o \
    /tmp/beets.tar.gz -sL \
    "https://github.com/beetbox/beets/archive/${BEETS_VERSION}.tar.gz" && \
  tar xf \
    /tmp/beets.tar.gz -C \
    /tmp/beets --strip-components=1 && \
  echo "**** compile mp3gain ****" && \
  mkdir -p \
    /tmp/mp3gain-src && \
  curl -o \
    /tmp/mp3gain-src/mp3gain.zip -sL \
    https://sourceforge.net/projects/mp3gain/files/mp3gain/1.6.2/mp3gain-1_6_2-src.zip && \
  cd /tmp/mp3gain-src && \
  unzip -qq /tmp/mp3gain-src/mp3gain.zip && \
  sed -i "s#/usr/local/bin#/usr/bin#g" /tmp/mp3gain-src/Makefile && \
  make && \
  make install && \
  echo "**** compile mp3val ****" && \
  mkdir -p \
    /tmp/mp3val-src && \
  curl -o \
  /tmp/mp3val-src/mp3val.tar.gz -sL \
    https://downloads.sourceforge.net/mp3val/mp3val-0.1.8-src.tar.gz && \
  cd /tmp/mp3val-src && \
  tar xzf /tmp/mp3val-src/mp3val.tar.gz --strip 1 && \
  make -f Makefile.linux && \
  cp -p mp3val /usr/bin && \
  echo "**** install pip packages ****" && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    setuptools \
    wheel && \
  echo "**** install beets ****" && \
  cd /tmp/beets && \
  python3 setup.py build && \
  python3 setup.py install --prefix=/usr --root=/ && \
  echo "**** install pip packages ****" && \
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.18/ \
    beautifulsoup4 \
    beets-extrafiles \
    beetcamp \
    discogs-client \
    flask \
    PyGObject \
    pillow \
    pyacoustid \
    pylast \
    requests \
    requests_oauthlib \
    unidecode && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    $HOME/.cache \
    $HOME/.cargo

# environment settings
ENV BEETSDIR="/config" \
EDITOR="nano" \
HOME="/config"

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8337
VOLUME /config
