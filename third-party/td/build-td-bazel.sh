#!/bin/sh

set -e
set -x

ARCH="$1"

SOURCE_DIR="$2"
BUILD_DIR=$(echo "$(cd "$(dirname "$3")"; pwd -P)/$(basename "$3")")
OPENSSL_DIR="$4"

# bazel genrule 的 PATH 只有 /bin:/usr/bin:/usr/local/bin，
# 因此 runner 上的 ccache / sysctl 都可能不可用。
#
#  - td 的 CMake 会把 ccache 当作编译器 launcher，找不到就直接以
#    "ccache: command not found" 让每个编译动作以 127 失败。
#    这里提供一个透传式垫片（等价于不缓存），保证编译能真正跑起来。
#  - sysctl 缺失会让 "-j$(sysctl -n hw.ncpu)" 变成 "-j"，
#    并行度退化为 1，构建极慢。这里做多级回退。
NCPU=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
case "$NCPU" in
  ''|*[!0-9]*) NCPU=4 ;;
esac
export NCPU

if ! command -v ccache >/dev/null 2>&1; then
  SHIM_DIR="$BUILD_DIR/bin-shim"
  mkdir -p "$SHIM_DIR"
  cat > "$SHIM_DIR/ccache" <<'SHIM'
#!/bin/sh
# ccache 垫片：忽略缓存参数，直接执行真实编译器。
exec "$@"
SHIM
  chmod +x "$SHIM_DIR/ccache"
  PATH="$SHIM_DIR:$PATH"
  export PATH
  echo "ccache not found; using pass-through shim at $SHIM_DIR/ccache"
fi

openssl_crypto_library="${OPENSSL_DIR}/lib/libcrypto.a"
options=""
options="$options -DOPENSSL_FOUND=1"
options="$options -DOPENSSL_CRYPTO_LIBRARY=${openssl_crypto_library}"
options="$options -DOPENSSL_INCLUDE_DIR=${OPENSSL_DIR}/src/include"
options="$options -DCMAKE_BUILD_TYPE=Release"
options="$options -DIOS_DEPLOYMENT_TARGET=13.0"

cd "$BUILD_DIR"

# Generate source files
mkdir native-build
cd native-build
cmake -DTD_GENERATE_SOURCE_FILES=ON ../td
cmake --build . -- -j$NCPU
cd ..

if [ "$ARCH" = "arm64" ]; then
  IOS_PLATFORMDIR="$(xcode-select -p)/Platforms/iPhoneOS.platform"
  IOS_SYSROOT=($IOS_PLATFORMDIR/Developer/SDKs/iPhoneOS*.sdk)
  export CFLAGS="-arch arm64 --target=arm64-apple-ios13.0 -miphoneos-version-min=13.0 -w"
elif [ "$ARCH" = "sim_arm64" ]; then
  IOS_PLATFORMDIR="$(xcode-select -p)/Platforms/iPhoneSimulator.platform"
  IOS_SYSROOT=($IOS_PLATFORMDIR/Developer/SDKs/iPhoneSimulator*.sdk)
  export CFLAGS="-arch arm64 --target=arm64-apple-ios13.0-simulator -miphonesimulator-version-min=13.0 -w"
elif [ "$ARCH" = "macos_arm64" ]; then
  IOS_PLATFORMDIR="$(xcode-select -p)/Platforms/MacOSX.platform"
  IOS_SYSROOT=($IOS_PLATFORMDIR/Developer/SDKs/MacOSX*.sdk)
  export CFLAGS="-arch arm64 --target=arm64-apple-macosx14.0 -mmacosx-version-min=14.0 -w"
else
  echo "Unsupported architecture $ARCH"
  exit 1
fi
export CXXFLAGS="$CFLAGS"

# Common build steps
mkdir build
cd build

touch toolchain.cmake
echo "set(CMAKE_SYSTEM_NAME Darwin)" >> toolchain.cmake
echo "set(CMAKE_SYSTEM_PROCESSOR aarch64)" >> toolchain.cmake
echo "set(CMAKE_C_COMPILER $(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang)" >> toolchain.cmake

cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake -DCMAKE_OSX_SYSROOT=${IOS_SYSROOT[0]} ../td $options
make tde2e -j$NCPU
