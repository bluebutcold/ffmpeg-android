#!/bin/bash

BASE_DIR="${ROOT_DIR}/module"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1

if [ -n "$FFMPEG_STATIC" ]; then
    type="Static"
else
    type="Dynamic"
fi

cat > module.prop <<EOF
id=FFmpeg
name=FFmpeg
version=8.0
versionCode=8
author=rhythmcache.t.me
description=FFmpeg for android | ${type}
EOF


cat > customize.sh <<EOF
FFMPEG_ARCH="${ANDROID_ABI}"
ARCH=\$(getprop ro.product.cpu.abi)

if [ "\${FFMPEG_ARCH}" != "\${ARCH}" ]; then
    ui_print "- Device ABI is '\${ARCH}', Expected '\${FFMPEG_ARCH}'"
fi

SYSTEM_DIR="\${MODPATH}/system"
mkdir -p "\$SYSTEM_DIR"
cd "\$SYSTEM_DIR" || exit 1
ui_print "- Extracting FFmpeg"
tar -xf "../ffmpeg.tar.xz"

set_perm_recursive "\$SYSTEM_DIR" 0 0 0755 0755
rm -f "\${MODPATH}/ffmpeg.tar.xz"
EOF

chmod +x customize.sh

mkdir -p "${BASE_DIR}/META-INF/com/google/android"
cd "${BASE_DIR}/META-INF/com/google/android" || exit 1

cat > update-binary <<'EOF'
#!/sbin/sh
umask 022
ui_print() { echo "$1"; }
require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}
OUTFD=$2
ZIPFILE=$3
mount /data 2>/dev/null
[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ $MAGISK_VER_CODE -lt 20400 ] && require_new_magisk
install_module
exit 0
EOF

cat > updater-script <<EOF
#MAGISK
EOF

cd "$BASE_DIR" || exit 1
mkdir -p bin

for file in "$PREFIX/bin/ffmpeg" "$PREFIX/bin/ffprobe"; do
    cp "$file" bin/
done

libdir=""
if [ -z "$FFMPEG_STATIC" ]; then
    if echo "$ARCH" | grep -q 64; then
        libdir="lib64"
    else
        libdir="lib"
    fi
    mkdir -p "$libdir"
    libcpp="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${CLANG_TARGET}/libc++_shared.so"
    cp "$libcpp" "$libdir/"
    $STRIP "$libdir/libc++_shared.so"
fi

if [ -n "$libdir" ]; then
    tar -caf ffmpeg.tar.xz bin "$libdir"
else
    tar -caf ffmpeg.tar.xz bin
fi

zip -r "${FFMPEG_VERSION}-${type}-android-${ARCH}.zip" META-INF ffmpeg.tar.xz customize.sh module.prop
