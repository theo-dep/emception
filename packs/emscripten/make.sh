#!/bin/bash

if [ -d emscripten ]; then
    # nothing to do here
    exit
fi

SRC=$(dirname $0)
SRC=$(realpath "$SRC")

# Get prebuilt libraries
cp -r "$EMSDK/upstream/emscripten/" ./emscripten/

pushd emscripten/

# Create the cache directory
rm -rf ./cache
echo "NODE_JS='$EMSDK_NODE'" >> ./.emscripten
echo "LLVM_ROOT='$EMSDK/upstream/bin'" >> ./.emscripten
echo "BINARYEN_ROOT='$EMSDK/upstream'" >> ./.emscripten
python3 embuilder.py build ALL

cp $SRC/config ./.emscripten

# We won't support closure-compiler, remove it from the dependencies
npm uninstall google-closure-compiler html-minifier-terser

# Patch emscripten to:
# * avoid invalidating the cache
patch -p2 < $SRC/emscripten.patch

# Remove a bunch of things we won't use
rm -rf \
    ./__pycache__ \
    ./cmake \
    ./docs \
    ./media \
    ./test \
    ./third_party/closure-compiler \
    ./third_party/jni \
    ./third_party/ply \
    ./tools/__pycache__ \
    ./tools/scons \
    ./tools/websocket_to_posix_proxy \
    ./*.bat

popd

node "$SRC/split_packages.cjs" | bash