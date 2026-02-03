#!/bin/bash

SRC=$(dirname $0)
BUILD="$1"
EMSCRIPTEN_VERSION="$2"
CPYTHON_SRC="$3"

if [ "$BUILD" == "" ]; then
    BUILD=$(pwd)/build
fi

if [ "$CPYTHON_SRC" == "" ]; then
    CPYTHON_SRC=$(pwd)/upstream/cpython
fi

SRC=$(realpath "$SRC")
BUILD=$(realpath "$BUILD")

if [ ! -d $BUILD/emception/ ]; then
    mkdir -p $BUILD/emception/
fi

cp $SRC/src/* $BUILD/emception/

mkdir -p $BUILD/emception/llvm/
cp $BUILD/llvm/bin/llvm-box.{mjs,wasm} $BUILD/emception/llvm/

mkdir -p $BUILD/emception/binaryen/
cp $BUILD/binaryen/bin/binaryen-box.{mjs,wasm} $BUILD/emception/binaryen/

mkdir -p $BUILD/emception/quicknode/
cp $BUILD/quicknode/quicknode.{mjs,wasm} $BUILD/emception/quicknode/

mkdir -p $BUILD/emception/cpython/
cp $CPYTHON_SRC/cross-build/wasm32-emscripten/build/python/python*.{mjs,wasm,zip} $BUILD/emception/cpython/
cp $CPYTHON_SRC/Tools/wasm/emscripten/web_example/python.worker.mjs $BUILD/emception/cpython/

mkdir -p $BUILD/emception/wasm-package/
cp $BUILD/wasm-package/wasm-package.{mjs,wasm} $BUILD/emception/wasm-package/

$SRC/build-packs.sh "$BUILD" "$EMSCRIPTEN_VERSION"

mkdir -p $BUILD/emception/packages
cp $BUILD/packs/*.pack $BUILD/emception/packages

IMPORTS=""
EXPORTS=""
for PACK in $BUILD/emception/packages/*.pack; do
    PACK=$(basename "$PACK")
    NAME=$(basename "$PACK" .pack | sed 's/[^a-zA-Z0-9_]/_/g')
    if [[ "$NAME" == emscripten* ]]; then
        FOLDER="emscripten"
    else
        FOLDER="$NAME"
    fi
    IMPORTS=$(printf \
        "%s\nimport %s from \"./packages/%s\";" \
        "$IMPORTS" "$NAME" "$PACK" \
    )
    EXPORTS=$(printf \
        "%s\n    \"%s\": { url: %s, folder: \"%s\" }," \
        "$EXPORTS" "$NAME" "$NAME" "$FOLDER" \
    )
done
printf '%s\nexport default {%s\n};' "$IMPORTS" "$EXPORTS" > "$BUILD/emception/packs.mjs"
