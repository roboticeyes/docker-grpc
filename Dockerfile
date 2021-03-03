# Copyright (C) 2021 Robotic Eyes
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.

ARG BASE_IMAGE_NAME="debian"
ARG BASE_IMAGE_VERSION="10.7-slim"
ARG BASE_IMAGE="${BASE_IMAGE_NAME}:${BASE_IMAGE_VERSION}"

FROM ${BASE_IMAGE}

ARG GRPC_VERSION="v1.35.0"

RUN \
  apt-get update && \
  apt-get -y install \
    build-essential \
    cmake \
    wget \
    git \
    vim && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

WORKDIR "/tmp/build"

RUN \
  git clone --recurse-submodules -b ${GRPC_VERSION} https://github.com/grpc/grpc && \
  cd grpc && \
  mkdir -p build && \
  cd build && \
  cmake -DgRPC_INSTALL=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=/usr \
      .. && \
  make -j$(nproc) && \
  make install && \
  cd ../.. && \
  rm -rf grpc

# Download and install buf (https://buf.build/)
ARG BUF_VERSION="v0.38.0"
ARG BUF_URL="https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/buf-Linux-x86_64"

RUN \
  wget -O /usr/bin/buf -r ${BUF_URL} && chmod +x /usr/bin/buf
