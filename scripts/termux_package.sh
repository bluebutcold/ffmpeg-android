#!/bin/bash
TERMUX_DIR="${BASE_DIR}/termux"
TERMUX_PREFIX="${TERMUX_DIR}/data/data/com.termux/files/usr"
mkdir -p "${TERMUX_PREFIX}/bin"
mkdir -p "${TERMUX_PREFIX}/lib" 
mkdir -p "${TERMUX_PREFIX}/include" 
cd "$TERMUX_DIR"
echo "2.0" > debian-binary
cat >control <<EOF
Package: ffmpeg
Architecture: ${ARCH}
Version: ${FFMPEG_V}
Maintainer: bluebutcold
Homepage: https://ffmpeg.org
Breaks: ffmpeg-dev
Replaces: ffmpeg-dev
Description: Tools and libraries to manipulate a wide range of multimedia formats and protocols
EOF
cat >postinst <<EOF
EOF
cp "$libcpp" "$TERMUX_PREFIX/lib"/
cp "$PREFIX/bin/ffmpeg" "$TERMUX_PREFIX/bin"/
cp "$PREFIX/bin/ffprobe" "$TERMUX_PREFIX/bin"/
ffmpeg_libs=(libavdevice.so libavfilter.so libavformat.so libavcodec.so libswresample.so libswscale.so libavutil.so libOpenCL.so)
for lib in "${ffmpeg_libs[@]}"; do
src="$PREFIX/lib/$lib"
		if [ -f "$src" ]; then
		cp -a "$src" "${TERMUX_PREFIX}/lib"/
		$STRIP "${TERMUX_PREFIX}/lib"/*
        fi
done
mkdir -p "${TERMUX_PREFIX}/lib/pkgconfig"
ffmpeg_pcs=(libavdevice.pc libavfilter.pc libavformat.pc libavcodec.pc libswresample.pc libswscale.pc libavutil.pc)  
for pc in "${ffmpeg_pcs[@]}"; do
src="$PREFIX/lib/pkgconfig/$pc"
		if [ -f "$src" ]; then
		cp -a "$src" "${TERMUX_PREFIX}/lib/pkgconfig"/
        fi
done
ffmpeg_incs=(libavdevice libavfilter libavformat libavcodec libswresample libswscale libavutil)
for inc in "${ffmpeg_incs[@]}"; do
src="$PREFIX/include/$inc"
		if [ -d "$src" ]; then
		cp -r "$src" "${TERMUX_PREFIX}/include"/
        fi
done
tar -cJf control.tar.xz control postinst
tar -cJf data.tar.xz data/
ar rcs "termux-ffmpeg-${FFMPEG_V}-${ANDROID_ABI}.deb" debian-binary control.tar.xz data.tar.xz
rm control postinst control.tar.xz data.tar.xz debian-binary
cp "termux-ffmpeg-${FFMPEG_V}-${ANDROID_ABI}.deb" "$BASE_DIR"/





