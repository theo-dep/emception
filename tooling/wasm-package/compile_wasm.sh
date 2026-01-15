#!/bin/bash

SRC=$(dirname $0)
BUILD="$1"

if [ "$BUILD" == "" ]; then
    BUILD="."
fi

WASM_UTILS="$SRC/../wasm-utils"

SRC=$(realpath $SRC)
BUILD=$(realpath $BUILD)
WASM_UTILS=$(realpath $WASM_UTILS)

em++ \
    -sALLOW_MEMORY_GROWTH \
    -sEXPORTED_FUNCTIONS=_main,_free,_malloc \
    -sEXPORTED_RUNTIME_METHODS=FS,PROXYFS,ERRNO_CODES,HEAP32,HEAPU8,stringToNewUTF8 \
    -sENVIRONMENT=web \
    -sMODULARIZE \
    -sEXPORT_ES6 \
    -lproxyfs.js \
    --js-library=$SRC/../../emlib/fsroot.js \
    -lidbfs.js \
    -flto \
    -O3 \
    -I$WASM_UTILS -std=c++20 \
    $WASM_UTILS/*.cpp \
    $SRC/wasm-package.cpp \
    -o $BUILD/wasm-package.mjs
