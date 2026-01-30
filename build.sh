#!/bin/bash

SRC=$(dirname $0)
BUILD="$1"

if [ "$BUILD" == "" ]; then
    BUILD=$(pwd)/build
fi

SRC=$(realpath "$SRC")
BUILD=$(realpath "$BUILD")

if [ "$EMSDK_VERSION" == "" ]; then
    source config.sh
fi

source $SRC/fetch-emsdk.sh "$EMSDK_DIR" "$EMSDK_VERSION"

$SRC/build-tooling.sh "$BUILD"

$SRC/build-llvm.sh "$BUILD" "$LLVM_SRC" "$LLVM_VERSION"
$SRC/build-binaryen.sh "$BUILD" "$BINARYEN_SRC" "$BINARYEN_VERSION"
$SRC/build-cpython.sh "$BUILD" "$CPYTHON_SRC" "$CPYTHON_VERSION"
$SRC/build-quicknode.sh "$BUILD" "$QUICKNODE_SRC" "$QUICKJSPP_VERSION"

$SRC/build-emception.sh "$BUILD"
