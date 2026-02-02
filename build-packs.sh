#!/bin/bash

SRC=$(dirname $0)
BUILD="$1"
EMSCRIPTEN_VERSION="$2"

if [ "$BUILD" == "" ]; then
    BUILD=$(pwd)/build
fi

SRC=$(realpath "$SRC")
BUILD=$(realpath "$BUILD")

if [ ! -d $BUILD/packs/ ]; then
    mkdir -p $BUILD/packs/
fi

$SRC/packs/emscripten/package.sh "$BUILD" "$EMSCRIPTEN_VERSION"
