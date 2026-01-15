cmake_minimum_required(VERSION 3.16)

project(quicknode VERSION 0.1 LANGUAGES CXX)
set(CMAKE_CXX_EXTENSIONS OFF)

option(QUICKJSPP_VERSION "" "")

include(FetchContent)
FetchContent_Declare(
  upstream_quickjspp
  GIT_REPOSITORY https://github.com/ftk/quickjspp.git
  GIT_TAG        ${QUICKJSPP_VERSION}
)
FetchContent_MakeAvailable(upstream_quickjspp)

add_executable(quicknode main.cpp)
target_link_libraries(quicknode quickjspp quickjs)
target_compile_features(quicknode PUBLIC cxx_std_17)