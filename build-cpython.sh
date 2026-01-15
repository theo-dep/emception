#!/bin/bash

SRC=$(dirname $0)

BUILD="$1"
CPYTHON_SRC="$2"
CPYTHON_VERSION="$3"

if [ "$CPYTHON_SRC" == "" ]; then
    CPYTHON_SRC=$(pwd)/upstream/cpython
fi

if [ "$BUILD" == "" ]; then
    BUILD=$(pwd)/build
fi

SRC=$(realpath "$SRC")
BUILD=$(realpath "$BUILD")
CPYTHON_BUILD=$BUILD/cpython
CPYTHON_NATIVE=$BUILD/cpython-native

# If we don't have a copy of cpython, make one
if [ ! -d $CPYTHON_SRC/ ]; then
    git clone --branch $CPYTHON_VERSION --depth 1 https://github.com/python/cpython.git "$CPYTHON_SRC/"
fi

if [ ! -d $CPYTHON_NATIVE/ ]; then
    # Rever the cpython patch in case this runs after the wasm version reconfigures it.
    pushd $CPYTHON_SRC/
    git apply -R $SRC/patches/cpython.patch
    autoreconf -i
    popd

    mkdir -p $CPYTHON_NATIVE/

    pushd $CPYTHON_NATIVE/
    $CPYTHON_SRC/configure -C
    popd
fi

pushd $CPYTHON_NATIVE/
make -j$(nproc)
popd

if [ ! -d $CPYTHON_BUILD/ ]; then
    # Patch cpython to add a module to evaluate JS code.
    pushd $CPYTHON_SRC/
    git apply $SRC/patches/cpython.patch
    autoreconf -i
    popd

    mkdir -p $CPYTHON_BUILD/

    pushd $CPYTHON_BUILD/

    # Build cpython with asyncify support.
    # Disable sqlite3, zlib and bzip2, which cpython enables by default
    CONFIG_SITE=$CPYTHON_SRC/Tools/wasm/config.site-wasm32-emscripten \
    LIBSQLITE3_CFLAGS=" " LIBSQLITE3_LDLAGS=" " \
    BZIP2_CFLAGS=" " BZIP2_LDLAGS=" " \
    ZLIB_CFLAGS=" " ZLIB_LDLAGS=" " \
    LDFLAGS="\
        -sALLOW_MEMORY_GROWTH \
        -sEXPORTED_FUNCTIONS=_main,_free,_malloc \
        -sEXPORTED_RUNTIME_METHODS=FS,PROXYFS,ERRNO_CODES,HEAP32,HEAPU8,stringToNewUTF8 \
        -sENVIRONMENT=web,worker \
        -sMODULARIZE \
        -sEXPORT_ES6 \
        -sPROXY_TO_PTHREAD \
        -pthread \
        -lproxyfs.js \
        --js-library=$SRC/emlib/fsroot.js \
    " emconfigure $CPYTHON_SRC/configure -C \
        --host=wasm32-unknown-emscripten \
        --build=$($CPYTHON_SRC/config.guess) \
        --with-emscripten-target=browser \
        --disable-wasm-dynamic-linking \
        --enable-wasm-pthreads \
        --disable-wasm-preload \
        --with-suffix=".mjs" \
        --with-build-python=$CPYTHON_NATIVE/python

    popd
fi

pushd $CPYTHON_BUILD/
emmake make -j$(nproc)
popd
