#!/bin/bash

EMSDK_DIR="$1"
EMSDK_VERSION="$2"

if [ "$EMSDK_DIR" == "" ]; then
    EMSDK_DIR=$(pwd)/upstream/emsdk
fi

# If we don't have a copy of emsdk, make one
if [ ! -d $EMSDK_DIR/ ]; then
    git clone https://github.com/emscripten-core/emsdk.git "$EMSDK_DIR/"

    pushd $EMSDK_DIR/

    ./emsdk install $EMSDK_VERSION
    ./emsdk activate $EMSDK_VERSION

    popd
fi
source $EMSDK_DIR/emsdk_env.sh
