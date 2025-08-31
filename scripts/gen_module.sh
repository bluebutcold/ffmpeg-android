#!/bin/bash

echo "- Generating Module"
BASE_DIR="${ROOT_DIR}/module"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1

if [ -n "$FFMPEG_STATIC" ]; then
    type="Static"
else
    type="Dynamic"
fi

cat > module.prop << EOF
id=FFmpeg
name=FFmpeg
version=8.0
versionCode=8
author=rhythmcache.t.me
description=FFmpeg for android | ${type}
EOF

cat > customize.sh << EOF
cat > customize.sh <<'EOF'
FFMPEG_ARCH="${ANDROID_ABI}"
type="${type}"
ARCH=\$(getprop ro.product.cpu.abi)

if [ "\${FFMPEG_ARCH}" != "\${ARCH}" ]; then
    ui_print "- Device ABI is '\${ARCH}', Expected '\${FFMPEG_ARCH}'"
fi

SYSTEM_DIR="\$MODPATH/system"
mkdir -p "\$SYSTEM_DIR"
cd "\$SYSTEM_DIR" || exit 1

ui_print "- Extracting FFmpeg"
tar -xf "../ffmpeg.tar.xz"

if [ "\$type" = "Dynamic" ]; then
    ui_print "- Dynamic libraries detected for \$ARCH"

    # Determine library directory
    if echo "\$ARCH" | grep -q "64"; then
        libdir="lib64"
    else
        libdir="lib"
    fi

    mkdir -p "\$SYSTEM_DIR/\$libdir"

    if [ -f "/system/\$libdir/libOpenCL.so" ]; then
        cp -a "/system/\$libdir/libOpenCL.so" "\$SYSTEM_DIR/\$libdir/"
        ui_print "- Copied libOpenCL.so from /system/\$libdir"
    elif [ -f "/system/vendor/\$libdir/libOpenCL.so" ]; then
        cp -a "/system/vendor/\$libdir/libOpenCL.so" "\$SYSTEM_DIR/\$libdir/"
        ui_print "- Copied libOpenCL.so from /system/vendor/\$libdir"
    else
        ui_print "- libOpenCL.so not found in standard paths, searching /system..."
        found=\$(find -L /system -iname "libOpenCL.so" | grep "\$libdir" | head -n 1)
        if [ -n "\$found" ]; then
            cp -a "\$found" "\$SYSTEM_DIR/\$libdir/"
            ui_print "- Copied libOpenCL.so from \$found"
        else
            ui_print "- WARNING: libOpenCL.so not found for \$libdir!"
        fi
    fi


    export LD_LIBRARY_PATH="\$SYSTEM_DIR/\$libdir:\$LD_LIBRARY_PATH"


    ui_print "- Testing FFmpeg binaries..."
    for bin in "\$SYSTEM_DIR/bin/ffmpeg" "\$SYSTEM_DIR/bin/ffprobe"; do
        if [ -x "\$bin" ]; then
            "\$bin" -version >/dev/null 2>&1
            if [ \$? -eq 0 ]; then
                ui_print "  \$bin works!"
            else
                ui_print "  WARNING: \$bin failed to run!"
            fi
        else
            ui_print "  WARNING: \$bin not executable!"
        fi
    done
fi
set_perm_recursive "\$SYSTEM_DIR" 0 0 0755 0755

rm -f "\${MODPATH}/ffmpeg.tar.xz"
EOF

chmod +x customize.sh

mkdir -p "${BASE_DIR}/META-INF/com/google/android"
cd "${BASE_DIR}/META-INF/com/google/android" || exit 1

cat > update-binary << 'EOF'
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

cat > updater-script << EOF
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
    libcpp="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_OS}-x86_64/sysroot/usr/lib/${CLANG_TRIPLE}/libc++_shared.so"
    cp "$libcpp" "$libdir/"
    ffmpeg_libs=(libavdevice.so libavfilter.so libavformat.so libavcodec.so libswresample.so libswscale.so libavutil.so libOpenCL.so)
    for lib in "${ffmpeg_libs[@]}"; do
        src="$PREFIX/lib/$lib"
        if [ -f "$src" ]; then
            cp -a "$src" "$libdir/"
            $STRIP "$libdir/$lib"
            echo "- Copied $lib"
        else
            echo "- WARNING: $lib not found at $src"
        fi
    done
fi

if [ -n "$libdir" ]; then
    tar -caf ffmpeg.tar.xz bin "$libdir"
else
    tar -caf ffmpeg.tar.xz bin
fi

FINAL_ZIP="${FFMPEG_VERSION}-${type}-android-${ANDROID_ABI}.zip"
zip -r "${FINAL_ZIP}" META-INF ffmpeg.tar.xz customize.sh module.prop
shopt -s extglob
rm -rf !("$FINAL_ZIP")
shopt -u extglob
