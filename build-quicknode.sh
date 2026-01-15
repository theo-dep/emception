#!/bin/bash

SRC=$(dirname $0)

BUILD="$1"
QUICKNODE_SRC="$2"
QUICKJSPP_VERSION="$3"

if [ "$QUICKNODE_SRC" == "" ]; then
    QUICKNODE_SRC="$SRC"/quicknode
fi

if [ "$BUILD" == "" ]; then
    BUILD=$(pwd)/build
fi

SRC=$(realpath "$SRC")
BUILD=$(realpath "$BUILD")
QUICKNODE_BUILD=$BUILD/quicknode

if [ ! -d $QUICKNODE_BUILD/ ]; then
    CXXFLAGS="
        -fexceptions \
        -sDISABLE_EXCEPTION_CATCHING=0 \
    " \
    LDFLAGS="\
        -fexceptions \
        -sDISABLE_EXCEPTION_CATCHING=0 \
        -sALLOW_MEMORY_GROWTH \
        -sEXPORTED_FUNCTIONS=_main,_free,_malloc \
        -sEXPORTED_RUNTIME_METHODS=FS,PROXYFS,ERRNO_CODES,HEAP32,HEAPU8,stringToNewUTF8 \
        -sENVIRONMENT=web \
        -sMODULARIZE \
        -sEXPORT_ES6 \
        -lproxyfs.js \
        --js-library=$SRC/emlib/fsroot.js \
    " emcmake cmake -G Ninja \
        -S $QUICKNODE_SRC/ \
        -B $QUICKNODE_BUILD/ \
        -DQUICKJSPP_VERSION="${QUICKJSPP_VERSION}" \
        -DCMAKE_BUILD_TYPE=Release

    # Make sure we build js modules (.mjs).
    # The patch-ninja.sh script assumes that.
    sed -i -E 's/\.js/.mjs/g' $QUICKNODE_BUILD/build.ninja

    # The mjs patching is over zealous, and patches some source JS files rather than just output files.
    # Undo that.
    sed -i -E 's/(pre|post|proxyfs|fsroot)\.mjs/\1.js/g' $QUICKNODE_BUILD/build.ninja
fi
cmake --build $QUICKNODE_BUILD/ -- quicknode
