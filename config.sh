#!/bin/bash

# for Docker
UBUNTU_VERSION=25.10

# For emception
EMSCRIPTEN_VERSION=4.0.23

# emscripten dependencies
# https://github.com/emscripten-core/emscripten/blob/main/tools/building.py#L56
BINARYEN_VERSION=version_125
# https://github.com/emscripten-core/emscripten/tree/main/system/lib/libcxx
LLVM_VERSION=llvmorg-20.1.8

# project dependencies
QUICKJSPP_VERSION=01cdd3047ced48265b127790848a0ca88204f2c7

# v3.14 is not compatible with higher emscripten version yet
# see https://github.com/emscripten-core/emscripten/issues/26132
# and various use of the emscripten private API in Python/emscripten_syscalls.c
EMSDK_VERSION=4.0.12
CPYTHON_VERSION=v3.14.2
