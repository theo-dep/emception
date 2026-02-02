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
echo "NODE_JS='$EMSDK_NODE'" >> ./.emscripten
echo "LLVM_ROOT='$EMSDK/upstream/bin'" >> ./.emscripten
echo "BINARYEN_ROOT='$EMSDK/upstream'" >> ./.emscripten
# Keep only relevant libraries (time to build and error at runtime with too much symlinks)
declare -a cache_to_build
while IFS= read -r line; do
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
        cache_to_build+=("$line")
    fi
done < "$SRC/cache_to_build.txt"
rm -rf ./cache
python3 embuilder.py build ${cache_to_build[@]} #ALL

cp $SRC/config ./.emscripten

# We won't support closure-compiler, remove it from the dependencies
npm uninstall google-closure-compiler html-minifier-terser

# Patch emscripten to:
# * avoid invalidating the cache
patch -p2 < $SRC/emscripten.patch

# Remove a bunch of things we won't use
rm -rf \
    ./__pycache__ \
    ./cache/sysroot/lib/cmake \
    ./cache/sysroot/lib/pkgconfig \
    ./cache/ports/*.zip \
    ./cache/ports/*.tar* \
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

node "$SRC/split_packages.cjs"
