# Copyright (C) 2021 Robotic Eyes
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.

ARG TIMEZONE="Europe/Vienna"
ARG _BASE_IMAGE_NAME="debian"
ARG _BASE_IMAGE_VERSION="10.7-slim"

# Number of processors used for compilation
ARG NPROC=4

ARG _BASE_IMAGE="${_BASE_IMAGE_NAME}:${_BASE_IMAGE_VERSION}"

###############################################################################
# TIMEZONE
###############################################################################
FROM ${_BASE_IMAGE} as timezone

RUN \
  apt-get update && \
  apt-get -y install tzdata && \
  rm -rf /var/lib/apt/lists/*

###############################################################################
# ROOT
###############################################################################
FROM ${_BASE_IMAGE} as root
ARG NPROC

RUN \
  apt-get update && \
  apt-get -y install \
    build-essential cmake \
    bash \
    tini \
    wget \
    git \
    vim && \
  rm -rf /var/lib/apt/lists/*

WORKDIR "/tmp/build"

# Build gRPC
RUN \
  git clone --recurse-submodules -b v1.35.0 https://github.com/grpc/grpc && \
  cd grpc && \
  mkdir -p build && \
  cd build && \
  cmake -DgRPC_INSTALL=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=/usr \
      .. && \
  make -j${NPROC} && \
  make install && \
  cd ../.. && \
  rm -rf grpc
