#!/bin/bash

patch_ffmpeg() {
	cd "$BUILD_DIR/FFmpeg"
	if ! grep -q "int ff_dec_init(" fftools/ffmpeg_dec.c; then
		sed -i 's/int dec_init(/int ff_dec_init(/g' fftools/ffmpeg_dec.c
		sed -i 's/int dec_init(/int ff_dec_init(/g' fftools/ffmpeg.h
		sed -i 's/dec_init(/ff_dec_init(/g' fftools/ffmpeg_demux.c
	fi

	LC_FILE="libavfilter/vf_lcevc.c"
	if grep -q "LCEVC_SendDecoderEnhancementData(lcevc->decoder, in->pts, 0, sd->data, sd->size)" "$LC_FILE"; then
		sed -i 's/LCEVC_SendDecoderEnhancementData(lcevc->decoder, in->pts, 0, sd->data, sd->size)/LCEVC_SendDecoderEnhancementData(lcevc->decoder, in->pts, sd->data, sd->size)/' "$LC_FILE"
	fi
	if grep -q "LCEVC_SendDecoderBase(lcevc->decoder, in->pts, 0, picture, -1, in)" "$LC_FILE"; then
		sed -i 's/LCEVC_SendDecoderBase(lcevc->decoder, in->pts, 0, picture, -1, in)/LCEVC_SendDecoderBase(lcevc->decoder, in->pts, picture, 0, in)/' "$LC_FILE"
	fi
	LC_FILE="libavcodec/lcevcdec.c"
	if grep -q "LCEVC_SendDecoderEnhancementData(lcevc->decoder, in->pts, 0, sd->data, sd->size)" "$LC_FILE"; then
		sed -i 's/LCEVC_SendDecoderEnhancementData(lcevc->decoder, in->pts, 0, sd->data, sd->size)/LCEVC_SendDecoderEnhancementData(lcevc->decoder, in->pts, sd->data, sd->size)/' "$LC_FILE"
	fi
	if grep -q "LCEVC_SendDecoderBase(lcevc->decoder, in->pts, 0, picture, -1, NULL)" "$LC_FILE"; then
		sed -i 's/LCEVC_SendDecoderBase(lcevc->decoder, in->pts, 0, picture, -1, NULL)/LCEVC_SendDecoderBase(lcevc->decoder, in->pts, picture, 0, NULL)/' "$LC_FILE"
	fi
}

build_ffmpeg() {
	echo "Building FFmpeg for $ARCH..."
	cd "$BUILD_DIR/FFmpeg" || exit 1

	FLAGS=()
	[ "$ARCH" != "riscv64" ] && FLAGS=(--enable-librav1e --enable-libxavs2)
	[ "$ARCH" != "armv7" ] && [ "$ARCH" != "riscv64" ] && FLAGS+=(--enable-libxeve --enable-libxevd)

	NEON=()
	[[ "$ARCH" == "aarch64" || "$ARCH" == "armv7" ]] && NEON=(--enable-neon)

	ASM_FLAG=()
	[ "$ARCH" = "x86" ] && [ -z "$FFMPEG_STATIC" ] && ASM_FLAG=(--disable-asm)

	if [ -n "$FFMPEG_STATIC" ]; then
		type=${ARCH}_static_build
		STATIC_FLAG=("-static")
		OTHER_FLAGS=(--disable-shared)
	else
		type=${ARCH}_dynamic_build
		STATIC_FLAG=()
		OTHER_FLAGS=(--enable-opencl
			--enable-mediacodec
			--enable-shared
			--enable-jni)
	fi
	(make clean && make distclean) || true

	EXTRA_VERSION="android_$type-[gh/tg]/rhythmcache"
	CONFIGURE_FLAGS=(
		--enable-cross-compile
		--prefix="$PREFIX"
		--host-cc="${HOST_CC}"
		--cc="$CC_ABS"
		--cxx="$CXX_ABS"
		--ar="$AR_ABS"
		--nm="$NM_ABS"
		--ranlib="$RANLIB_ABS"
		--strip="$STRIP_ABS"
		--arch="$ARCH"
		--target-os=android
		--pkg-config-flags=--static
		--extra-cflags="${CFLAGS}"
		--extra-ldflags="${LDFLAGS} ${STATIC_FLAG[@]}"
		--extra-libs="-lm -lstdc++ -lcrypto -lz -lfftw3 -ldl -llzma -lunwind"
		--extra-version=$EXTRA_VERSION
		--disable-debug
		--enable-pic
		--disable-doc
		--enable-gpl
		--enable-version3
		--enable-libx264
		--enable-libx265
		--enable-libvpx
		--enable-libaom
		--enable-libdav1d
		--enable-libharfbuzz
		--enable-libbs2b
		--enable-libgsm
		--enable-libtheora
		--enable-libopenjpeg
		--enable-libwebp
		--enable-libxvid
		--enable-libkvazaar
		--enable-libxavs
		--enable-libdavs2
		--enable-libmp3lame
		--enable-libvorbis
		--enable-libopus
		--enable-libtwolame
		--enable-libsoxr
		--enable-libvo-amrwbenc
		--enable-libopencore-amrnb
		--enable-libopencore-amrwb
		--enable-libvvenc
		--enable-libilbc
		--enable-libcodec2
		--enable-libmysofa
		--enable-libopenmpt
		--enable-libfreetype
		--enable-libfontconfig
		--enable-libfribidi
		--enable-libass
		--enable-libxml2
		--enable-openssl
		--enable-zlib
		--enable-bzlib
		--enable-libsrt
		--enable-libzmq
		--enable-librist
		--enable-libaribb24
		--enable-libvmaf
		--enable-libzimg
		--enable-liblensfun
		--enable-libflite
		--enable-libssh
		--enable-libsvtav1
		--enable-libuavs3d
		--enable-librtmp
		--enable-libgme
		--enable-libjxl
		--enable-vapoursynth
		--enable-libqrencode
		--enable-libquirc
		--enable-libcaca
		--enable-chromaprint
		--enable-libspeex
		--enable-libbluray
		--enable-lcms2
		--enable-avisynth
		--enable-liblc3
		--enable-liblcevc-dec
		--enable-libmodplug
		"${FLAGS[@]}"
		"${NEON[@]}"
		"${ASM_FLAG[@]}"
		"${OTHER_FLAGS[@]}"
	)

	./configure "${CONFIGURE_FLAGS[@]}"

	# strip out the messy toolchain/build flags from banner, keep only the library stuff
	sed -i "/#define FFMPEG_CONFIGURATION/c\\#define FFMPEG_CONFIGURATION \"$(echo "${CONFIGURE_FLAGS[@]}" | tr ' ' '\n' | grep -E '^--(enable|disable)-' | tr '\n' ' ' | sed 's/ *$//')\"" config.h

	make -j"$(nproc)"
	make install

	echo "[+] FFmpeg built successfully "
}
