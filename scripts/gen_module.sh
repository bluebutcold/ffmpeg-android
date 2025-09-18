#!/bin/bash
BASE_DIR="${ROOT_DIR}/module"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1
CHANGELOG=${ROOT_DIR}/changelog.md
[ -f "${CHANGELOG}" ] && rm "${CHANGELOG}"
echo "# Build Changelog" > "${CHANGELOG}"
echo "" >> "${CHANGELOG}"
cd "$BUILD_DIR/FFmpeg" && git log -1 --pretty=format:"**Commit:** %H%n**Author:** %an <%ae>%n**Date:** %ad%n%n%s%n%n%b" >> ${CHANGELOG}
echo "- Generating Module"
cp "${CHANGELOG}" "${BASE_DIR}"/
# Get FFmpeg commit hash
COMMIT_SUFFIX=""
if [ -n "$LATEST_GIT" ] && [ -d "${BUILD_DIR}/FFmpeg/.git" ]; then
    FFMPEG_COMMIT=$(cd "${BUILD_DIR}/FFmpeg" && git rev-parse --short HEAD 2>/dev/null)
	cd "$BUILD_DIR/FFmpeg" && git rev-parse HEAD > "${BASE_DIR}/ffmpeg_commit.txt"
 
    if [ -n "$FFMPEG_COMMIT" ]; then
        COMMIT_SUFFIX="-${FFMPEG_COMMIT}"
    fi
fi


if [ -n "$FFMPEG_STATIC" ]; then
	type="Static"
else
	type="Dynamic"
fi

if [ -n "$LATEST_GIT" ]; then
FFMPEG_V=8.0-git-${COMMIT_SUFFIX}
else
FFMPEG_V=8.0
fi
UPDATE_JSON=${ROOT_DIR}/updateJsons/${ARCH}/${type}/updateJson
UPDATE_URL=https://raw.githubusercontent.com/bluebutcold/ffmpeg-android/main/updateJsons/${ARCH}/${type}/updateJson

current_vcode=$(grep -oP '"versionCode":\s*\K\d+' "$UPDATE_JSON")

vcode=$((current_vcode + 1))

cat >module.prop <<EOF
id=FFmpeg
name=FFmpeg
version=${FFMPEG_V}
versionCode=${vcode}
author=rhythmcache.t.me
description=FFmpeg for android | ${type}
updateJson=${UPDATE_URL}
EOF

cat >customize.sh <<EOF
FFMPEG_ARCH="${ANDROID_ABI}"
type="${type}"
API="${API_LEVEL}"

[ "\${type}" = "Dynamic" ] && [ "\$(getprop ro.build.version.sdk)" -lt "\${API}" ] && ui_print "- WARNING: API Mismatch, Expected >= \${API}, is \$(getprop ro.build.version.sdk)"


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

    set_perm_recursive "\$SYSTEM_DIR" 0 0 0755 0644
    chmod 755 "\$SYSTEM_DIR/bin"/*
    export LD_LIBRARY_PATH="\$SYSTEM_DIR/\$libdir:\$LD_LIBRARY_PATH"


    ui_print "- Testing..."
    for bin in "\$SYSTEM_DIR/bin/ffmpeg" "\$SYSTEM_DIR/bin/ffprobe"; do
        if [ -x "\$bin" ]; then
            "\$bin" -version >/dev/null 2>&1
            if [ \$? -eq 0 ]; then
                ui_print "  \$bin works!"
            else
                ui_print "- WARNING: \$bin failed to run!"
            fi
        else
            ui_print "- WARNING: \$bin not executable!"
            abort "Aborting Installation: Your Device Might Not be Supported"
        fi
    done
fi


rm -f "\${MODPATH}/ffmpeg.tar.xz"
EOF

chmod +x customize.sh

mkdir -p "${BASE_DIR}/META-INF/com/google/android"
cd "${BASE_DIR}/META-INF/com/google/android" || exit 1

cat >update-binary <<'EOF'
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

cat >updater-script <<EOF
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
	[ "$ARCH" = "armv7" ] && CLANG_TRIPLE=arm-linux-androideabi
	libcpp="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_OS}-x86_64/sysroot/usr/lib/${CLANG_TRIPLE}/libc++_shared.so"
	cp "$libcpp" "$libdir/"
	ffmpeg_libs=(libavdevice.so libavfilter.so libavformat.so libavcodec.so libswresample.so libswscale.so libavutil.so libOpenCL.so)
	for lib in "${ffmpeg_libs[@]}"; do
		src="$PREFIX/lib/$lib"
		if [ -f "$src" ]; then
			cp -a "$src" "$libdir/"
			$STRIP "$libdir"/*
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


FINAL_ZIP="${FFMPEG_VERSION}${COMMIT_SUFFIX}-${type}-android-${ANDROID_ABI}.zip"
extra=""
[ -n "$LATEST_GIT" ] && extra=ffmpeg_commit.txt

cp "${BUILD_DIR}/FFmpeg/COPYING.GPLv2" ./LICENSE
zip -r "${FINAL_ZIP}" META-INF ffmpeg.tar.xz customize.sh module.prop changelog.md LICENSE "$extra"
shopt -s extglob
rm -rf !("$FINAL_ZIP")
shopt -u extglob
