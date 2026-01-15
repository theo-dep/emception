#!/bin/bash

SRC=$(dirname $0)

BUILD="$1"
LLVM_SRC="$2"
LLVM_VERSION="$3"

if [ "$LLVM_SRC" == "" ]; then
    LLVM_SRC=$(pwd)/upstream/llvm-project
fi

if [ "$BUILD" == "" ]; then
    BUILD=$(pwd)/build
fi

SRC=$(realpath "$SRC")
BUILD=$(realpath "$BUILD")
LLVM_BUILD=$BUILD/llvm
LLVM_NATIVE=$BUILD/llvm-native

# If we don't have a copy of LLVM, make one
if [ ! -d $LLVM_SRC/ ]; then
    git clone --branch $LLVM_VERSION --depth 1 https://github.com/llvm/llvm-project.git "$LLVM_SRC/"

    # The clang driver will sometimes spawn a new process to avoid memory leaks.
    # Since this complicates matters quite a lot for us, just disable that.
    git -C "$LLVM_SRC" apply $SRC/patches/llvm-project.patch
fi

# Cross compiling llvm needs a native build of "llvm-tblgen" and "clang-tblgen"
if [ ! -d $LLVM_NATIVE/ ]; then
    cmake -G Ninja \
        -S $LLVM_SRC/llvm/ \
        -B $LLVM_NATIVE/ \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_TARGETS_TO_BUILD=WebAssembly \
        -DLLVM_ENABLE_PROJECTS="clang"
fi
cmake --build $LLVM_NATIVE/ -- llvm-tblgen clang-tblgen

if [ ! -d $LLVM_BUILD/ ]; then
    CXXFLAGS="-Dwait4=__syscall_wait4" \
    LDFLAGS="\
        -sLLD_REPORT_UNDEFINED=1 \
        -sALLOW_MEMORY_GROWTH \
        -sEXPORTED_FUNCTIONS=_main,_free,_malloc \
        -sEXPORTED_RUNTIME_METHODS=FS,PROXYFS,ERRNO_CODES,HEAP32,HEAPU8,stringToNewUTF8 \
        -sENVIRONMENT=web \
        -sMODULARIZE \
        -sEXPORT_ES6 \
        -lproxyfs.js \
        --js-library=$SRC/emlib/fsroot.js \
    " emcmake cmake -G Ninja \
        -S $LLVM_SRC/llvm/ \
        -B $LLVM_BUILD/ \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_TARGETS_TO_BUILD=WebAssembly \
        -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra" \
        -DLLVM_ENABLE_DUMP=OFF \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_ENABLE_EXPENSIVE_CHECKS=OFF \
        -DLLVM_ENABLE_BACKTRACES=OFF \
        -DLLVM_BUILD_TOOLS=OFF \
        -DLLVM_ENABLE_THREADS=OFF \
        -DLLVM_BUILD_LLVM_DYLIB=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_TABLEGEN=$LLVM_NATIVE/bin/llvm-tblgen \
        -DCLANG_TABLEGEN=$LLVM_NATIVE/bin/clang-tblgen

    # Make sure we build js modules (.mjs).
    # The patch-ninja.sh script assumes that.
    sed -i -E 's/\.js/.mjs/g' $LLVM_BUILD/build.ninja

    # The mjs patching is over zealous, and patches some source JS files rather than just output files.
    # Undo that.
    sed -i -E 's/(pre|post|proxyfs|fsroot)\.mjs/\1.js/g' $LLVM_BUILD/build.ninja

    # Patch the build script to add the "llvm-box" target.
    # This new target bundles many executables in one, reducing the total size.
    pushd $SRC
    TMP_FILE=$(mktemp)
    ./patch-ninja.sh \
        $LLVM_BUILD/build.ninja \
        llvm-box \
        $BUILD/tooling \
        clang lld llvm-nm llvm-ar llvm-objcopy llc \
        > $TMP_FILE
    cat $TMP_FILE >> $LLVM_BUILD/build.ninja
    popd
fi
cmake --build $LLVM_BUILD/ -- llvm-box
