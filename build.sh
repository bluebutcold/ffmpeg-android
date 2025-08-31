#!/bin/bash

set -xe

ARCH="${1:-$ARCH}"
API_LEVEL="${2:-$API_LEVEL}"
API_LEVEL="${API_LEVEL:-29}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VALID_ARCHES="aarch64 armv7 x86 x86_64 riscv64"

if [[ -z "$ARCH" || ! " $VALID_ARCHES " =~ $ARCH ]]; then
    echo "Usage: $0 <aarch64|armv7|x86|x86_64|riscv64> [API_LEVEL]"
    echo "Default API_LEVEL: 29"
    exit 1
fi


if [[ "$API_LEVEL" -gt 35 ]]; then
    echo "ERROR: API_LEVEL greater than 35 is not supported (got $API_LEVEL)"
    exit 1
fi

if [[ -z "$ANDROID_NDK_ROOT" ]]; then
    echo "ERROR: ANDROID_NDK_ROOT environment variable is not set"
    exit 1
fi

if [[ ! -d "$ANDROID_NDK_ROOT" ]]; then
    echo "ERROR: ANDROID_NDK_ROOT directory does not exist: $ANDROID_NDK_ROOT"
    exit 1
fi


if [[ "$ARCH" == "riscv64" && "$API_LEVEL" -lt 35 ]]; then
    export API_LEVEL=35
fi


source "${ROOT_DIR}/scripts/check_cmds.sh"


case "$(uname -s)" in
	Linux)  HOST_OS=linux ;;
	Darwin) HOST_OS=darwin ;;
	CYGWIN*|MINGW*|MSYS*) HOST_OS=windows ;;
	*)
		echo "ERROR: Unsupported host OS: $(uname -s)"
		exit 1
		;;
esac

case "$ARCH" in
aarch64)
    HOST=aarch64-linux-android
	ANDROID_ABI=arm64-v8a
	CLANG_TRIPLE=aarch64-linux-android
	RUST_TARGET=aarch64-linux-android
	;;
armv7)
    HOST=arm-linux-androideabi
	ANDROID_ABI=armeabi-v7a
	CLANG_TRIPLE=armv7a-linux-androideabi
	RUST_TARGET=armv7-linux-androideabi
	;;
x86)
    HOST=i686-linux-android
	ANDROID_ABI=x86
	CLANG_TRIPLE=i686-linux-android
	RUST_TARGET=i686-linux-android
	;;
x86_64)
    HOST=x86_64-linux-android
	ANDROID_ABI=x86_64
	CLANG_TRIPLE=x86_64-linux-android
	RUST_TARGET=x86_64-linux-android
	;;
riscv64)
    HOST=riscv64-linux-android
	ANDROID_ABI=riscv64
	CLANG_TRIPLE=riscv64-linux-android
	RUST_TARGET=riscv64-linux-android
	;;
*)
	echo "Unsupported architecture: $ARCH"
	exit 1
	;;
esac


mkdir -p ${ROOT_DIR}/out/android/${ARCH}
TOOLCHAIN_ROOT="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$HOST_OS-x86_64"

export CC="${TOOLCHAIN_ROOT}/bin/${CLANG_TRIPLE}${API_LEVEL}-clang"
export CXX="${TOOLCHAIN_ROOT}/bin/${CLANG_TRIPLE}${API_LEVEL}-clang++"
export AR="${TOOLCHAIN_ROOT}/bin/llvm-ar"
export RANLIB="${TOOLCHAIN_ROOT}/bin/llvm-ranlib"
export STRIP="${TOOLCHAIN_ROOT}/bin/llvm-strip"
export NM="${TOOLCHAIN_ROOT}/bin/llvm-nm"
export STRINGS="${TOOLCHAIN_ROOT}/bin/llvm-strings"
export OBJDUMP="${TOOLCHAIN_ROOT}/bin/llvm-objdump"
export OBJCOPY="${TOOLCHAIN_ROOT}/bin/llvm-objcopy"


case "$ARCH" in
	x86|x86_64)
		if command -v nasm >/dev/null 2>&1; then
			export AS=nasm
		else
			export AS="$CC"
		fi
		;;
	aarch64|armv7)
		export AS="$CC"
		;;
	*)
		echo "Warning: Unknown architecture for assembler setup: $ARCH"
		export AS="$CC"
		;;
esac

resolve_absolute_path() {
	local tool_name="$1"
	local abs_path
	
	if [[ "$tool_name" = /* ]]; then
		abs_path="$tool_name"
	else
		abs_path=$(which "$tool_name" 2>/dev/null)
	fi
	
	if [ -z "$abs_path" ] || [ ! -f "$abs_path" ]; then
		echo "ERROR: Tool '$tool_name' not found" >&2
		exit 1
	fi
	echo "$abs_path"
}

CC_ABS=$(resolve_absolute_path "$CC")
CXX_ABS=$(resolve_absolute_path "$CXX")
AR_ABS=$(resolve_absolute_path "$AR")
RANLIB_ABS=$(resolve_absolute_path "$RANLIB")
STRIP_ABS=$(resolve_absolute_path "$STRIP")
NM_ABS=$(resolve_absolute_path "$NM")


BUILD_DIR="$ROOT_DIR/build/android/$ARCH"
PREFIX="$BUILD_DIR/prefix"

mkdir -p "$BUILD_DIR" "$PREFIX"
mkdir -p "$PREFIX/lib/pkgconfig"
mkdir -p "$PREFIX/lib64/pkgconfig"

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:$PKG_CONFIG_PATH"

export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH


SIZE_CFLAGS="-O3 -ffunction-sections -fdata-sections"
SIZE_CXXFLAGS="-O3 -ffunction-sections -fdata-sections"
SIZE_LDFLAGS="-Wl,--gc-sections"


MATH_FLAGS="-fno-math-errno -fno-trapping-math -fassociative-math"
PERF_FLAGS="$MATH_FLAGS -funroll-loops -fomit-frame-pointer"


ANDROID_FLAGS="-fvisibility=default -fPIC"


CFLAGS="$SIZE_CFLAGS $PERF_FLAGS $ANDROID_FLAGS -DNDEBUG"
CXXFLAGS="$SIZE_CXXFLAGS $PERF_FLAGS $ANDROID_FLAGS -DNDEBUG"
CPPFLAGS="-I$PREFIX/include -DNDEBUG -fPIC"
LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib $SIZE_LDFLAGS -fPIC"


export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS



SYSROOT="$TOOLCHAIN_ROOT/sysroot"
export SYSROOT


COMMON_CMAKE_FLAGS=(
	"-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake"
	"-DANDROID_ABI=$ANDROID_ABI"
	"-DANDROID_PLATFORM=android-$API_LEVEL"
	"-DANDROID_NDK=$ANDROID_NDK_ROOT"
	"-DCMAKE_BUILD_TYPE=Release"
	"-DCMAKE_INSTALL_PREFIX=$PREFIX"
	"-DCMAKE_C_COMPILER=$CC_ABS"
	"-DCMAKE_CXX_COMPILER=$CXX_ABS"
	"-DCMAKE_C_FLAGS=$CFLAGS -I$PREFIX/include"
	"-DCMAKE_CXX_FLAGS=$CXXFLAGS -I$PREFIX/include"
	"-DCMAKE_EXE_LINKER_FLAGS=$LDFLAGS -L$PREFIX/lib"
	"-DCMAKE_AR=$AR_ABS"
	"-DCMAKE_RANLIB=$RANLIB_ABS"
	"-DCMAKE_STRIP=$STRIP_ABS"
	"-DCMAKE_FIND_ROOT_PATH=$SYSROOT;$PREFIX"
	"-DCMAKE_EXE_LINKER_FLAGS=$LDFLAGS"
	"-DCMAKE_SYSROOT=$SYSROOT"
)

DOWNLOADER_SCRIPT="${ROOT_DIR}/scripts/download_sources.sh"
BUILD_FUNCTIONS="${ROOT_DIR}/scripts/build_functions.sh"
FFMPEG_BUILDER="${ROOT_DIR}/scripts/ffmpeg.sh"


for script in "$DOWNLOADER_SCRIPT" "$BUILD_FUNCTIONS" "$FFMPEG_BUILDER"; do
	if [ -f "$script" ]; then
		source "$script"
	else
		echo "Warning: Script not found: $script (skipping)"
	fi
done

cleanup_pcfiles(){
find "$PREFIX" -iname "*.pc" -exec sed -i 's/\s*-lpthread\s*/ /g' {} +
find "$PREFIX" -iname "*.pc" -exec sed -i 's/\s*-lrt\b\s*/ /g' {} +
find "$PREFIX" -iname "*.pc" -exec sed -i 's/\s*-llog\b\s*/ /g' {} +
f="$PREFIX/lib/pkgconfig/x265.pc"; grep -q -- '-l-l:libunwind.a' "$f" && sed -i.bak 's/-l-l:libunwind.a/-lunwind/g' "$f"
find "$PREFIX" -iname "*.so" -delete
}


download_sources
prepare_sources
apply_extra_setup

if [ -z "$FFMPEG_STATIC" ]; then
install_opencl_headers
build_ocl_icd
fi
build_zlib
build_libcaca
build_udfread
build_bluray
build_openssl
build_x264
build_libvpx
build_xavs
[ "$ARCH" != "riscv64" ] && build_xavs2
build_davs2
build_libsrt
build_openjpeg
build_liblzma
build_zstd
build_pcre2
build_rtmp
build_libgsm
build_x265
build_lame
build_twolame
build_opus
build_ogg
build_vorbis
build_speex
build_aom
build_dav1d
build_fribidi
build_brotli
build_bzip2
build_freetype
build_libxml2
build_libexpat
build_libpng
build_harfbuzz
build_fontconfig
build_libass
build_libtheora
[ "$ARCH" != riscv64 ] && build_rav1e #rust doesn't support android riscv64 yet
build_lcms
build_libwebp
build_vmaf
build_libzimg
build_libmysofa
build_vidstab
build_soxr
build_openmpt
build_svtav1
build_libzmq
build_libplacebo
build_librist
build_libvo_amrwbenc
build_opencore_amr
build_libilbc
build_libcodec2_native
build_libcodec2
build_aribb24
build_uavs3d
build_xvidcore
build_kvazaar
build_vvenc
build_vapoursynth
build_libffi
build_glib
build_lensfun
build_flite
build_libbs2b
build_libssh
build_libgme
build_highway
build_libjxl
build_libqrencode
build_quirc
build_fftw
build_chromaprint
build_avisynth
build_fribidi
build_liblc3
build_lcevcdec
[ "$ARCH" != "armv7" ] && [ "$ARCH" != "riscv64" ] && build_xeve
[ "$ARCH" != "armv7" ] && [ "$ARCH" != "riscv64" ] && build_xevd
build_libmodplug
cleanup_pcfiles
patch_ffmpeg
build_ffmpeg
source "$ROOT_DIR/scripts/gen_module.sh"
