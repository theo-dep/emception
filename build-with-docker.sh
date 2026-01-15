#!/bin/bash

SRC=$(dirname $0)
SRC=$(realpath "$SRC")

UBUNTU_VERSION="$1"
if [ "$UBUNTU_VERSION" == "" ]; then
    source config.sh
fi

pushd $SRC/docker
docker build \
    --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \
    --tag emception_build \
    .
popd

docker run \
    -i --rm \
    -v $(pwd):$(pwd) \
    -u $(id -u):$(id -g) \
    $(id -G | tr ' ' '\n' | xargs -I{} echo --group-add {}) \
    emception_build:latest \
    bash -c "cd $(pwd) && ./build.sh"
