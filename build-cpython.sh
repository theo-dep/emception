#!/bin/bash

CPYTHON_SRC="$1"
CPYTHON_VERSION="$2"

if [ "$CPYTHON_SRC" == "" ]; then
    CPYTHON_SRC=$(pwd)/upstream/cpython
fi

CPYTHON_BUILD=$CPYTHON_SRC/cross-build/build
CPYTHON_HOST=$CPYTHON_SRC/cross-build/wasm32-emscripten/build/python

# If we don't have a copy of cpython, make one
if [ ! -d $CPYTHON_SRC/ ]; then
    git clone --branch $CPYTHON_VERSION --depth 1 https://github.com/python/cpython.git "$CPYTHON_SRC/"
fi

if [ ! -d $CPYTHON_BUILD/ ]; then
    python3 "$CPYTHON_SRC/Tools/wasm/emscripten" configure-build-python
fi
python3 "$CPYTHON_SRC/Tools/wasm/emscripten" make-build-python

if [ ! -d $CPYTHON_SRC/cross-build/wasm32-emscripten/build/libffi-* ]; then
    python3 "$CPYTHON_SRC/Tools/wasm/emscripten" make-libffi
fi
if [ ! -d $CPYTHON_SRC/cross-build/wasm32-emscripten/build/mpdecimal-* ]; then
    python3 "$CPYTHON_SRC/Tools/wasm/emscripten" make-mpdec
fi

if [ ! -d $CPYTHON_HOST/ ]; then
    python3 "$CPYTHON_SRC/Tools/wasm/emscripten" configure-host
fi
python3 "$CPYTHON_SRC/Tools/wasm/emscripten" make-host
