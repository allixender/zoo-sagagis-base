#!/bin/bash

export RUNTIME_PACKAGES="wget libxml2 curl openssl apache2 libfcgi0ldbl libcairo2 libgeotiff2 libtiff5 \
libgdal1h libgeos-3.4.2 libgeos-c1 libgd-dev libwxbase3.0-0 libgfortran3 libmozjs185-1.0 libproj0 \
wx-common zip libwxgtk3.0-0 libjpeg62 libpng3 libxslt1.1 python2.7 apache2"

apt-get update -y \
      && apt-get install -y --no-install-recommends $RUNTIME_PACKAGES

export BUILD_PACKAGES="subversion unzip flex bison libxml2-dev autotools-dev autoconf libmozjs185-dev python-dev \
build-essential libxslt1-dev software-properties-common libgdal-dev automake libtool libcairo2-dev \
 libgd-gd2-perl libgd2-xpm-dev ibwxbase3.0-dev  libwxgtk3.0-dev wx3.0-headers wx3.0-i18n \
libproj-dev libnetcdf-dev libfreetype6-dev libxslt1-dev libfcgi-dev \
libtiff5-dev libgeotiff-dev"

apt-get install -y --no-install-recommends $BUILD_PACKAGES

# for mapserver
export CMAKE_C_FLAGS=-fPIC
export CMAKE_CXX_FLAGS=-fPIC

# useful declarations
export BUILD_ROOT=/opt/build
export ZOO_BUILD_DIR=/opt/build/zoo-project
export CGI_DIR=/usr/lib/cgi-bin
export CGI_DATA_DIR=$CGI_DIR/data
export CGI_TMP_DIR=$CGI_DATA_DIR/tmp
export CGI_CACHE_DIR=$CGI_DATA_DIR/cache
export WWW_DIR=/var/www/html

# should build already there from base
# mkdir -p $BUILD_ROOT \
#   && mkdir -p $CGI_DIR \
#   && mkdir -p $CGI_DATA_DIR \
#   && mkdir -p $CGI_TMP_DIR \
#   && mkdir -p $CGI_CACHE_DIR \
#   && ln -s /usr/lib/x86_64-linux-gnu /usr/lib64

wget -nv -O $BUILD_ROOT/liblas_1.2.1.orig.tar.gz https://launchpad.net/ubuntu/+archive/primary/+files/liblas_1.2.1.orig.tar.gz
wget -nv -O $BUILD_ROOT/liblas_1.2.1-5.1ubuntu1.diff.gz https://launchpad.net/ubuntu/+archive/primary/+files/liblas_1.2.1-5.1ubuntu1.diff.gz

cd $BUILD_ROOT && gunzip liblas_1.2.1-5.1ubuntu1.diff.gz \
  && tar -xzf liblas_1.2.1.orig.tar.gz \
  && patch -p0 < liblas_1.2.1-5.1ubuntu1.diff || exit 1

cd $BUILD_ROOT/liblas-1.2.1 \
  && patch -p1 < debian/patches/gcc4.5 \
  && patch -p1 < debian/patches/autoreconf \
  && patch -p1 < debian/patches/missing.diff \
  && patch -p1 < debian/patches/format-security \
  && patch -p1 < debian/patches/iterator.hpp \
  && patch -p1 < debian/patches/noundefined \
  && ./configure --prefix=/usr --exec-prefix=/usr \
    --with-gdal=/usr/bin/gdal-config --with-geotiff=/usr \
  && make -j2 && make install && cd $BUILD_ROOT && ldconfig || exit 1

wget -nv -O $BUILD_ROOT/saga_2.1.4.tar.gz "http://downloads.sourceforge.net/project/saga-gis/SAGA%20-%202.1/SAGA%202.1.4/saga_2.1.4.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fsaga-gis%2Ffiles%2FSAGA%2520-%25202.1%2FSAGA%25202.1.4%2F&ts=1460433920&use_mirror=heanet"

cd $BUILD_ROOT && tar -xzf saga_2.1.4.tar.gz \
  && cd saga-2.1.4 \
  && ./configure --prefix=/usr --exec-prefix=/usr \
  && make -j2 \
  && make install || exit 1

  # install SAGA GIS config
  cd $BUILD_ROOT/thirds/saga2zcfg \
    && make \
    && mkdir zcfgs \
    && cd zcfgs \
    && ../saga2zcfg \
    && mkdir -p $CGI_DIR/SAGA \
    && cp -r * $CGI_DIR/SAGA || exit 1

  # however, auto additonal packages won't get removed
  # maybe auto remove is a bit too hard
  # RUN apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
  # ENV AUTO_ADDED_PACKAGES $(apt-mark showauto)
  # RUN apt-get remove --purge -y $BUILD_PACKAGES $AUTO_ADDED_PACKAGES

  apt-get remove --purge -y $BUILD_PACKAGES \
    && rm -rf /var/lib/apt/lists/*

  # do we need to consider /usr/lib/saga ?
  # 611M    /opt/build/saga-2.1.4 ouch
  rm -rf $BUILD_ROOT/saga-2.1.4
  rm -rf $BUILD_ROOT/saga_2.1.4.tar.gz
