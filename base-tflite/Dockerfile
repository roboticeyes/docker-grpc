###############################################################################
# Copyright (C) 2021 Robotic Eyes
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
# KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#
###############################################################################
#
# BASE-DOCKER (version 1.0)
#
#   pb-base (debian 11.0 slim)
#   eigen-3
#   grpc-v1.40.0
#   opencv-v4.5.3
#   buf-v0.56.0
#   go-v1.17
#   bazel=4.2.1
#   tensorflow=2.8.0
#
###############################################################################

ARG TIMEZONE="Europe/Vienna"
ARG _BASE_IMAGE_NAME="debian"
ARG _BASE_IMAGE_VERSION="11.0-slim"
ARG GRPC_VERSION="1.40.0"
ARG BUF_VERSION="0.56.0"
ARG OPENCV_VERSION="4.5.3"
ARG GO_VERSION="1.17"
ARG NPROC=8
ARG BAZEL_VERSION="4.2.1"
ARG TENSORFLOW_VERSION="2.8.0"
ARG BAZEL_N_JOBS=6

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
  gdb \
  bash \
  tini \
  wget \
  curl \
  git \
  libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
  libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
  libeigen3-dev \
  libtbb2 libtbb-dev libdc1394-22-dev \
  libavcodec-extra libavformat58 libswscale5 libv4l-0 \
  libxvidcore4 libjpeg62-turbo libpng16-16 libtiff5 \
  openexr libatlas-base-dev \
  libtbb2 \ 
  nano \
  pkg-config \
  zip \
  g++ \
  zlib1g-dev\
  unzip \
  build-essential \
  libtool \ 
  python \
  python3-dev \ 
  python3-pip && \
  rm -rf /var/lib/apt/lists/* && \
  ln -sf /usr/bin/python3 /usr/bin/python && \
  pip3 install numpy 


WORKDIR "/tmp/workdir"

#--------------------------------------------------------------
# Build gRPC
ARG GRPC_VERSION
ARG GRPC_INSTALL_DIR="/usr"
RUN \
  git clone --recurse-submodules -b v${GRPC_VERSION} https://github.com/grpc/grpc && \
  cd grpc && \
  mkdir -p build && \
  cd build && \
  cmake -DgRPC_INSTALL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DgRPC_BUILD_TESTS=OFF \
  -DCMAKE_INSTALL_PREFIX=${GRPC_INSTALL_DIR} \
  .. && \
  make -j${NPROC} && \
  make install && \
  cd .. && \
  mkdir -p third_party/abseil-cpp/cmake/build &&\
  cd third_party/abseil-cpp/cmake/build &&\
  cmake -DCMAKE_INSTALL_PREFIX=$GRPC_INSTALL_DIR \
  -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
  ../.. && \
  make -j${NPROC} && \
  make install && \
  cd ../../../../../ &&\
  rm -rf grpc

# Link plugin files
RUN \
  ln -s /usr/bin/grpc_cpp_plugin /usr/bin/protoc-gen-cpp-grpc && \
  ln -s /usr/bin/grpc_csharp_plugin /usr/bin/protoc-gen-csharp-grpc

#--------------------------------------------------------------
# Download and install buf (https://buf.build/)
ARG BUF_VERSION
ARG BUF_URL="https://github.com/bufbuild/buf/releases/download/v${BUF_VERSION}/buf-Linux-x86_64"

RUN \
  wget -O /usr/bin/buf -r ${BUF_URL} && chmod +x /usr/bin/buf

#--------------------------------------------------------------
# Install Go and GO gRPC
ARG GO_VERSION
ARG GO_URL="https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
RUN \
  wget -O go.tar.gz -r ${GO_URL} && \
  tar -C /usr -xvzf go.tar.gz && \
  rm go.tar.gz && \
  ln -s /usr/go/bin/go /usr/bin/go && \
  export GOPATH=/opt && \
  export GO111MODULE=on && \
  go get google.golang.org/protobuf/cmd/protoc-gen-go google.golang.org/grpc/cmd/protoc-gen-go-grpc

RUN \
  ln -s /opt/bin/protoc-gen-go /usr/bin/protoc-gen-go && \
  ln -s /opt/bin/protoc-gen-go-grpc /usr/bin/protoc-gen-go-grpc

#--------------------------------------------------------------
# Build OpenCV
ARG OPENCV_VERSION
ENV OPENCV_BASE_URL="https://github.com/opencv"
ENV OPENCV_PACKAGE="${OPENCV_BASE_URL}/opencv/archive/${OPENCV_VERSION}.tar.gz"
ENV OPENCV_CONTRIB_PACKAGE="${OPENCV_BASE_URL}/opencv_contrib/archive/${OPENCV_VERSION}.tar.gz"

RUN \
  wget -O package.tar.gz -r ${OPENCV_PACKAGE} && tar xvfz package.tar.gz && rm -r package.tar.gz && \
  wget -O package.tar.gz -r ${OPENCV_CONTRIB_PACKAGE} && tar xvfz package.tar.gz && rm -r package.tar.gz && \
  mkdir -p build && cd build && \
  cmake -DCMAKE_BUILD_TYPE=Release \
  -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib-${OPENCV_VERSION}/modules \
  -DINSTALL_C_EXAMPLES=OFF \
  -DPYTHON_DEFAULT_EXECUTABLE=/usr/bin/python3 \
  -DINSTALL_PYTHON_EXAMPLES=OFF \
  -DOPENCV_GENERATE_PKGCONFIG=ON \
  -DBUILD_EXAMPLES=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr \
  ../opencv-${OPENCV_VERSION} && \
  make -j${NPROC} && \
  make install && \
  cd .. && \
  rm -rf build && rm -rf opencv*


###############################################################################
# BUILD TFLITE
###############################################################################

#----------------------------------------------------------------------
# Install Bazel
#----------------------------------------------------------------------
ARG BAZEL_VERSION

WORKDIR "/tmp/workdir"
RUN mkdir bazel-tmp
RUN cd bazel-tmp && \
  wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh && \
  chmod +x bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh && \
  ./bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh --user && \
  ln -s /root/bin/bazel /usr/bin/bazel && \
  bazel --version && \
  rm -rf "/tmp/workdir/bazel-tmp"

#----------------------------------------------------------------------
# Install tensorflow
# NOTE: Please increase your swap to avoid system freezing, else, set the BAZEL_N_JOBS=1
#       Builds tensorflow with optimized CPU FLAGS (NO GPU!)
#----------------------------------------------------------------------
ARG BAZEL_N_JOBS
WORKDIR "/tmp/workdir"
ARG TENSORFLOW_VERSION
RUN mkdir tf-tmp
WORKDIR "/tmp/workdir/tf-tmp"
RUN wget https://github.com/tensorflow/tensorflow/archive/refs/tags/v${TENSORFLOW_VERSION}.zip && \
  unzip v${TENSORFLOW_VERSION}.zip && \
  cd /tmp/workdir/tf-tmp/tensorflow-${TENSORFLOW_VERSION}/ && \  
  ./configure && \
  CC=gcc bazel build -c opt \
  --jobs ${BAZEL_N_JOBS} \
  --copt=-mavx \
  --copt=-mavx2 \
  --copt=-mfma \
  --copt=-mfpmath=both \
  --copt=-msse4.2 \
  --define with_select_tf_ops=true \
  --define tflite_with_xnnpack=true \
  --define use_xnnpack=true \
  --define with_select_tf_ops=true \
  --config=monolithic \
  //tensorflow/lite:libtensorflowlite.so \
  //tensorflow/lite/delegates/flex:delegate && \
  cp bazel-bin/tensorflow/lite/libtensorflowlite.so /usr/local/lib/ && \
  mkdir /usr/local/include/tensorflow && \
  cp -RL tensorflow/lite/ /usr/local/include/tensorflow/ && \
  cp -RL bazel-bin/external/flatbuffers/src/_virtual_includes/flatbuffers/flatbuffers /usr/local/include/ && \
  rm -rf  "/root/.cache/" && \ 
  rm -rf "/tmp/"

