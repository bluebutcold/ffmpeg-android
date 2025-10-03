#!/bin/bash

build_zlib() {
	echo "[+] Building zlib for $ARCH..."
	cd "$BUILD_DIR/zlib" || exit 1
	
	export CHOST="$HOST"
	CFLAGS="$CFLAGS" ./configure --prefix="$PREFIX" --static
	make -j"$(nproc)" CFLAGS="$CFLAGS"
	make install
	
	echo "✔ zlib built successfully"
}

build_iconv() {
    cd "$BUILD_DIR/iconv"
    ./configure \
        --prefix="$PREFIX" \
        --enable-static \
        --disable-shared \
        --host="$HOST" \
        CC="$CC" \
        CXX="$CXX" \
        CFLAGS="$CFLAGS" \
        CXXFLAGS="$CXXFLAGS" \
        LDFLAGS="$LDFLAGS"
    make -j$(nproc)
    make install

	generate_pkgconfig "libiconv" "GNU libiconv" "1.17" "-L$PREFIX/lib -liconv" "-I$PREFIX/include"
}

build_shine() {
    autotools_build_autoreconf "shine" "$BUILD_DIR/shine"
}

build_zvbi() {

	cd "$BUILD_DIR/zvbi"
	autoreconf -fvi
       export ac_cv_func_malloc_0_nonnull=yes
       export ac_cv_func_realloc_0_nonnull=yes

       export ac_cv_lib_pthread_pthread_create=yes
       export am_cv_func_iconv=yes
	  ./configure \
	    "--prefix=$PREFIX" \
     	"--host=$HOST" \
	    --enable-static \
	    --disable-shared \
	    --disable-tests \
        --disable-examples \
        --disable-proxy \
        --disable-dvb \
        --disable-v4l \
        --disable-bktr \
		LDFLAGS="$LDFLAGS -liconv"

		find . -name 'Makefile' -exec sed -i 's/-lpthread//g' {} +

		make -j$(nproc) && make install

}


build_lz4() {
    echo "Building LZ4..."
    make -C "$BUILD_DIR/lz4" lib CC="$CC" CFLAGS="$CFLAGS" || exit 1
    make -C "$BUILD_DIR/lz4" install PREFIX="$PREFIX" || exit 1
}

build_liblzma() {
	autotools_build "liblzma" "$BUILD_DIR/xz" \
		CC="$CC_ABS" \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_zstd() {
	meson_build "zstd" "$BUILD_DIR/zstd/build/meson" "$CROSS_FILE_TEMPLATE"
}

build_openssl() {
	echo "[+] Building OpenSSL for $ARCH..."
	cd "$BUILD_DIR/openssl" || exit 1
	
	local openssl_target
	case "$ARCH" in
		aarch64) openssl_target="android-arm64" ;;
		armv7) openssl_target="android-arm" ;;
		x86) openssl_target="android-x86" ;;
		x86_64) openssl_target="android-x86_64" ;;
		riscv64) openssl_target="linux-generic64" ;;
		*)
			echo "Unknown architecture: $ARCH" >&2
			exit 1
			;;
	esac
	
	(make clean && make distclean) || true
	
	CC="$CC_ABS" ./Configure "$openssl_target" -fPIC \
		no-shared no-tests \
		${ASM:+$ASM} \
		--prefix="$PREFIX" \
		--openssldir="$PREFIX/ssl" \
		--with-zlib-include="$PREFIX/include" \
		--with-zlib-lib="$PREFIX/lib"
	
	make -j"$(nproc)"
	make install_sw
	
	[ "$ARCH" = "x86_64" ] && [ -d "$PREFIX/lib64" ] && cp -r "$PREFIX/lib64/"* "$PREFIX/lib/"
	
	echo "✔ OpenSSL built successfully"
}

build_x264() {
	echo "[+] Building x264 for $ARCH..."
	cd "$BUILD_DIR/x264" || exit 1
	
	(make clean && make distclean) || true
	
	local cfg_host="$HOST"
	local asm_flags=""
	
	if [ "$ARCH" = "riscv64" ]; then
		cfg_host="riscv64-unknown-linux-gnu"
		sed -i 's/unknown/ok/' configure
		asm_flags="--disable-asm"
	elif [ "$ARCH" = "x86" ]; then
		asm_flags="--disable-asm"
	fi
	
	./configure \
		--prefix="$PREFIX" \
		--host="$cfg_host" \
		--enable-static \
		--disable-cli \
		--disable-opencl \
		--enable-pic \
		$asm_flags \
		--extra-cflags="$CFLAGS -I$PREFIX/include" \
		--extra-ldflags="$LDFLAGS -L$PREFIX/lib"
	
	make -j"$(nproc)"
	make install
	
	echo "✔ x264 built successfully"
}

build_twolame() {
	echo "[+] Building twolame for $ARCH..."
	cd "$BUILD_DIR/twolame" || exit 1
	
	(make clean && make distclean) || true
	autoreconf -fi
	
	./configure \
		"${COMMON_AUTOTOOLS_FLAGS[@]}" \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"
	
	make -C libtwolame -j"$(nproc)"
	make -C libtwolame install
	
	echo "✔ twolame built successfully"
}

build_libgsm() {
	echo "[+] Building libgsm for $ARCH..."
	cd "$BUILD_DIR/libgsm" || exit 1
	
	(make clean && make distclean) || true
	
	CC="$CC" AR="$AR" RANLIB="$RANLIB" STRIP="$STRIP" \
		CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" \
		make -j"$(nproc)" CC="$CC"
	
	make install INSTALL_ROOT="$PREFIX"
	
	local header_dst_dir="$PREFIX/include/gsm"
	mkdir -p "$header_dst_dir"
	find "$BUILD_DIR/libgsm" -type f -name '*.h' -exec cp {} "$header_dst_dir/" \;
	
	generate_pkgconfig "gsm" "GSM 06.10 lossy speech compression" "1.0.22" "-lgsm" "-I\${includedir}"
	
	echo "✔ libgsm built successfully"
}

build_libvpx() {
	echo "[+] Building libvpx for $ARCH..."
	cd "$BUILD_DIR/libvpx" || exit 1
	
	find . -name '*.d' -delete
	
	local vpx_target
	case "$ARCH" in
		x86_64) vpx_target="x86_64-android-gcc" ;;
		x86) vpx_target="x86-android-gcc" ;;
		armv7) vpx_target="armv7-android-gcc" ;;
		aarch64) vpx_target="arm64-android-gcc" ;;
		*) vpx_target="generic-gnu" ;;
	esac
	
	./configure \
		--prefix="$PREFIX" \
		--target="$vpx_target" \
		--disable-examples \
		--disable-tools \
		--disable-docs \
		--disable-unit-tests \
		--enable-pic \
		--enable-vp8 \
		--enable-vp9 \
		--enable-static \
		--disable-shared \
		--disable-runtime-cpu-detect \
		--extra-cflags="$CFLAGS -I$PREFIX/include"
	
	make -j"$(nproc)"
	make install
	
	echo "✔ libvpx built successfully"
}

build_lame() {
	autotools_build "LAME" "$BUILD_DIR/lame" \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"
}

build_opus() {
	autotools_build "Opus" "$BUILD_DIR/opus" \
		--disable-doc \
		--disable-extra-programs \
		--with-pic \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"
}

build_vorbis() {
	echo "[+] Building libvorbis for $ARCH..."
	cd "$BUILD_DIR/vorbis" || exit 1
	
	(make clean && make distclean) || true
	
	if [ "$ARCH" = "x86" ]; then
		[ -f configure.ac.bak ] && cp configure.ac.bak configure.ac
		cp configure.ac configure.ac.bak
		sed -i 's/-mno-ieee-fp//g' configure.ac
		autoreconf -fi
	fi
	
	autotools_build "libvorbis" "$BUILD_DIR/vorbis" \
		--with-ogg="$PREFIX" \
		--disable-oggtest \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"
}

build_ogg() {
	autotools_build "libogg" "$BUILD_DIR/ogg" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_speex() {
	autotools_build "Speex" "$BUILD_DIR/speex" \
		--disable-oggtest \
		--with-ogg="$PREFIX" \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"
}

build_libpng() {
	echo "[+] Building libpng for $ARCH..."
	cd "$BUILD_DIR/libpng" || exit 1
	
	export CPPFLAGS="-I$PREFIX/include"
	export LDFLAGS="-L$PREFIX/lib"
	
	autotools_build "libpng" "$BUILD_DIR/libpng" \
		--with-zlib-prefix="$PREFIX"
}

build_libass() {
	echo "[+] Building libass for $ARCH..."
	cd "$BUILD_DIR/libass" || exit 1
	
	local asm_flags=""
	[ "$ARCH" = "x86" ] && [ -z "$FFMPEG_STATIC" ] && asm_flags="--disable-asm"
	
	autotools_build "libass" "$BUILD_DIR/libass" \
		--disable-require-system-font-provider \
		$asm_flags
}

build_libxml2() {
	echo "[+] Building libxml2 for $ARCH..."
	cd "$BUILD_DIR/libxml2" || exit 1
	
	(make clean && make distclean) || true
	./autogen.sh || true
	
	autotools_build "libxml2" "$BUILD_DIR/libxml2" \
		--without-python \
		--without-lzma \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"
}

build_libexpat() {
	autotools_build "expat" "$BUILD_DIR/libexpat" \
		--without-examples \
		--without-tests \
		--without-docbook \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_libtheora() {
	echo "[+] Building libtheora for $ARCH..."
	cd "$BUILD_DIR/theora" || exit 1
	
	(make clean && make distclean) || true
	[ ! -f "configure" ] && autoreconf -fi
	
	local extra_flags=()
	[ "$ARCH" = "armv7" ] && extra_flags+=(--disable-asm)
	
	autotools_build "libtheora" "$BUILD_DIR/theora" \
		--disable-examples \
		--disable-oggtest \
		--disable-vorbistest \
		"${extra_flags[@]}" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_libwebp() {
	echo "[+] Building libwebp for $ARCH..."
	cd "$BUILD_DIR/libwebp" || exit 1
	
	(make clean && make distclean) || true
	./autogen.sh
	
	set_autotools_env
	
	./configure \
		"${COMMON_AUTOTOOLS_FLAGS[@]}" \
		CC="$CC_ABS" \
		CXX="$CXX_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		STRIP="$STRIP_ABS" \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"
	
	make -j"$(nproc)" && make install
	echo "✔ libwebp built successfully"
}

build_libzimg() {
	echo "[+] Building libzimg for $ARCH..."
	cd "$BUILD_DIR/zimg" || exit 1
	
	(make clean && make distclean) || true
	./autogen.sh
	
	autotools_build "libzimg" "$BUILD_DIR/zimg" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_openmpt() {
	autotools_build "openmpt" "$BUILD_DIR/openmpt" \
		--disable-openmpt123 \
		--disable-tests \
		--without-mpg123 \
		--without-ogg \
		--without-vorbis \
		--without-pulseaudio \
		--without-portaudio \
		--without-sndfile \
		--without-flac \
		--without-portaudiocpp \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_libvo_amrwbenc() {
	autotools_build_autoreconf "vo-amrwbenc" "$BUILD_DIR/vo-amrwbenc" \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_opencore_amr() {
	echo "[+] Building opencore-amr for $ARCH..."
	cd "$BUILD_DIR/opencore-amr" || exit 1
	
	(make distclean && make clean) || true
	
	[ -f "configure.ac.bak" ] && cp "configure.ac.bak" "configure.ac"
	cp "configure.ac" "configure.ac.bak"
	sed -i '/AC_FUNC_MALLOC/d' configure.ac
	
	autotools_build_autoreconf "opencore-amr" "$BUILD_DIR/opencore-amr" \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"
}

build_aribb24() {
	echo "[+] Building aribb24 for $ARCH..."
	cd "$BUILD_DIR/aribb24" || exit 1
	
	make distclean >/dev/null 2>&1 || true
	autoreconf -fi
	
	./configure \
		"${COMMON_AUTOTOOLS_FLAGS[@]}" \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="-static -Os -ffunction-sections -fdata-sections -DNDEBUG" \
		LDFLAGS="-static -Wl,--gc-sections -Wl,--strip-all -Wl,--allow-multiple-definition"
	
	make -j"$(nproc)"
	make install
	
	echo "✔ aribb24 built successfully"
}

build_xvidcore() {
	echo "[+] Building xvidcore for $ARCH..."
	cd "$BUILD_DIR/xvidcore/build/generic" || exit 1
	
	(make distclean && make clean) || true
	
	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		CC="$CC_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		STRIP="$STRIP_ABS" \
		CFLAGS="$CFLAGS" \
		--disable-assembly \
		LDFLAGS="$LDFLAGS"
	
	make -j"$(nproc)"
	make install
	
	echo "✔ xvidcore built successfully"
}

build_kvazaar() {
	echo "[+] Building kvazaar for $ARCH..."
	cd "$BUILD_DIR/kvazaar" || exit 1
	
	[ -f configure.ac.bak ] && cp "configure.ac.bak" "configure.ac"
	cp "configure.ac" "configure.ac.bak"
	sed -i 's/\-lrt//g' configure.ac
	
	(make clean && make distclean) || true
	autoreconf -fiv
	
	autotools_build "kvazaar" "$BUILD_DIR/kvazaar"
}


build_xavs() {
	echo "Building xavs for $ARCH..."

	cd "$BUILD_DIR/xavs/trunk" || exit 1
	make distclean || true

	grep -q "extern void predict_8x8c_p_core_mmxext( src, i00, b, c );" common/i386/predict-c.c &&
		sed -i 's|extern void predict_8x8c_p_core_mmxext( src, i00, b, c );|extern void predict_8x8c_p_core_mmxext(uint8_t *src, int i00, int b, int c);|' common/i386/predict-c.c

	if grep -q "[^&]tmp\[[0-3]\]" common/i386/dct-c.c; then
		echo "Found unfixed tmp[] references, applying fix..."
		sed -i 's/\([^&]\)tmp\[\([0-3]\)\]/\1\&tmp[\2]/g' common/i386/dct-c.c
		echo "Fixed tmp[] references"
	else
		echo "All tmp[] references already fixed"
	fi

	EXTRA_CONFIGURE_FLAGS=""
	if [ "$ARCH" != "x86" ] || [ "$ARCH" != "x86_64" ]; then
		EXTRA_CONFIGURE_FLAGS="--disable-asm"
	fi

	./configure \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared \
		$EXTRA_CONFIGURE_FLAGS \
		CC="$CC_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		STRIP="$STRIP_ABS" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"

	make -j"$(nproc)" && make install
}


build_rtmp() {
	echo "[+] Building librtmp for $ARCH..."
	cd "$BUILD_DIR/rtmpdump/librtmp" || exit 1
	
	(make clean && make distclean) || true
	
	make librtmp.a \
		CC="$CC_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		CFLAGS="$CFLAGS -DUSE_OPENSSL -I$PREFIX/include -I$PREFIX/include/openssl" \
		LDFLAGS="$LDFLAGS" \
		XLIBS="-L$PREFIX/lib -lssl -lcrypto -lz -ldl -lpthread" \
		-j"$(nproc)"
	
	mkdir -p "$PREFIX/include/librtmp" "$PREFIX/lib"
	cp *.h "$PREFIX/include/librtmp/"
	cp librtmp.a "$PREFIX/lib/"
	
	generate_pkgconfig "librtmp" "RTMP implementation" "2.4" "-lrtmp" \
		"-I\${includedir}" "openssl zlib" "-lssl -lcrypto -lz -ldl -lpthread"
	
	echo "✔ librtmp built successfully"
}

build_rav1e() {
	echo "[+] Building rav1e for $ARCH..."
	cd "$BUILD_DIR/rav1e" || exit 1
	
	cargo clean
	mkdir -p .cargo
	
	cat >.cargo/config.toml <<EOF
[target.$RUST_TARGET]
linker = "$CC_ABS"
ar = "$AR_ABS"
rustflags = ["-C", "target-feature=+crt-static", "-C", "relocation-model=pic", "-C", "link-arg=-pie"]

[build]
target = "$RUST_TARGET"
EOF
	
	export CC="$CC_ABS"
	export CXX="$CXX_ABS"
	export AR="$AR_ABS"
	
	cargo cinstall --release \
		--target "$RUST_TARGET" \
		--prefix "$PREFIX" \
		--library-type staticlib \
		--no-default-features \
		--features "asm"
	
	echo "✔ rav1e built successfully"
}

build_librsvg_c() {
    echo "[+] Building librsvg for $ARCH..."
    cd "$BUILD_DIR/librsvg/librsvg-c" || exit 1
    
    mkdir -p .cargo
    cat >.cargo/config.toml <<EOF
[target.$RUST_TARGET]
linker = "$CC_ABS"
ar = "$AR_ABS"
rustflags = ["-C", "target-feature=+crt-static", "-C", "relocation-model=pic", "-C", "link-arg=-pie"]

[build]
target = "$RUST_TARGET"
EOF

    export CC="$CC_ABS"
    export CXX="$CXX_ABS"
    export AR="$AR_ABS"
    
    cargo cinstall --release \
        --target "$RUST_TARGET" \
        --prefix "$PREFIX" \
        --library-type staticlib

    # pkg-config fixup
    if [ -f "$PREFIX/lib/pkgconfig/librsvg_c.pc" ]; then
        cp "$PREFIX/lib/pkgconfig/librsvg_c.pc" "$PREFIX/lib/pkgconfig/librsvg-2.0.pc"
    else
        generate_pkgconfig \
          "librsvg-2.0" \
          "The GObject-based SVG rendering library" \
          "2.52.0" \
          "-lrsvg_2 -lcairo-gobject -lxml2 -lpangocairo-1.0 -lgmodule-2.0 -lpng16 -lpixman-1 -lpcre2-8 -lffi -lexpat -lharfbuzz -lcairo -ldl -lgio-2.0 -lpangoft2-1.0 -lfribidi -lpango-1.0 -lz -lfontconfig -lgobject-2.0 -lfreetype -lglib-2.0 -lintl -latomic -lm" \
          "-I\${includedir}/librsvg-2.0 -I\${includedir}/librsvg"
    fi


    mkdir -p "$PREFIX/include/librsvg-2.0/librsvg" "$PREFIX/include/librsvg"


    src=$(find "$BUILD_DIR/librsvg" -iname "rsvg.h" -type f | head -n 1)
    [ -n "$src" ] && cp "$src" "$PREFIX/include/librsvg-2.0/librsvg/"


    for h in rsvg-cairo.h rsvg-pixbuf.h; do
        src=$(find "$BUILD_DIR/librsvg" -iname "$h" -type f | head -n 1)
        [ -n "$src" ] && cp "$src" "$PREFIX/include/librsvg/"
    done

	cp "$BUILD_DIR/librsvg/include/librsvg/rsvg-features.h.in" "$PREFIX/include/librsvg/rsvg-features.h"

	VERSION=$(grep '^version\s*=' "$BUILD_DIR/librsvg/Cargo.toml" | head -n1 | sed 's/.*"\(.*\)".*/\1/')

    IFS='.' read -r LIBRSVG_MAJOR_VERSION LIBRSVG_MINOR_VERSION LIBRSVG_MICRO_VERSION <<< "$VERSION"
     sed \
  -e "s/@LIBRSVG_MAJOR_VERSION@/$LIBRSVG_MAJOR_VERSION/" \
  -e "s/@LIBRSVG_MINOR_VERSION@/$LIBRSVG_MINOR_VERSION/" \
  -e "s/@LIBRSVG_MICRO_VERSION@/$LIBRSVG_MICRO_VERSION/" \
  -e "s/@PACKAGE_VERSION@/$VERSION/" \
  "$BUILD_DIR/librsvg/include/librsvg/rsvg-version.h.in" \
  > "$PREFIX/include/librsvg/rsvg-version.h"

    PIXBUF=0 
sed \
  -e "s/@LIBRSVG_HAVE_PIXBUF@/$PIXBUF/" \
  "$BUILD_DIR/librsvg/include/librsvg/rsvg-features.h.in" \
  > "$PREFIX/include/librsvg/rsvg-features.h"

    echo "✔ built successfully"
}


build_xavs2() {
	local ASMMM=""
	
	case "$ARCH" in
	x86_64) ;;
	x86 | armv7 | aarch64 | riscv64)
		ASMMM="--disable-asm"
		;;
	esac
	
	autotools_build "xavs2" "$BUILD_DIR/xavs2/build/linux" \
		--disable-cli \
		--enable-strip \
		--enable-pic \
		"${ASMMM}"
}

build_davs2() {
	local ASMMM=""
	
	case "$ARCH" in
	x86_64) ;;
	armv7 | x86 | aarch64 | riscv64)
		ASMMM="--disable-asm"
		;;
	esac
	
	autotools_build "davs2" "$BUILD_DIR/davs2/build/linux" \
		--disable-cli \
		--enable-strip \
		--enable-pic \
		"${ASMMM}"
}

build_ocl_icd() {
	echo "[+] Building ocl-icd for $ARCH..."

	cd "$BUILD_DIR/ocl-icd" || exit 1
	if [ ! -f configure ]; then
		autoreconf -fiv
		if [ $? -ne 0 ]; then
			echo "Error: autoreconf failed"
			return 1
		fi
	fi
	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--enable-official-khronos-headers \
		--disable-debug \
		--enable-pthread-once \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes

	make -j"$(nproc)" || exit 1
	make install || exit 1

	echo "[+] ocl-icd built successfully"
	return 0
}


build_fdk_aac_free() {
	autotools_build "fdk-aac-free" "$BUILD_DIR/fdk-aac-free"
}

build_libbs2b() {
	echo "[+] Building libbs2b for $ARCH..."
	
	cd "$BUILD_DIR/libbs2b" || exit 1
	
	(make clean && make distclean) || true
	
	[ -f configure.ac.bak ] && cp configure.ac.bak configure.ac
	cp configure.ac configure.ac.bak
	
	sed -i '/PKG_CHECK_EXISTS(\[sndfile\]/,/])$/d' configure.ac
	sed -i 's/dist-lzma//g' configure.ac
	sed -i '/AC_FUNC_MALLOC/d' configure.ac
	
	autoreconf -fiv
	
	set_autotools_env
	
	./configure "${COMMON_AUTOTOOLS_FLAGS[@]}"
	
	sed -i '/^bin_PROGRAMS *=/d' src/Makefile.am
	sed -i '/bs2bconvert/d' src/Makefile.am
	make -j"$(nproc)"
	make install
	
	echo "✔ libbs2b built successfully"
}

build_quirc() {
	echo "[+] Building quirc for $ARCH"..........
	cd "$BUILD_DIR/quirc"
	(make clean && make distclean) || true
	make \
		CC="$CC_ABS" \
		AR="$AR_ABS" \
		STRIP="$STRIP_ABS" \
		CFLAGS="$CFLAGS -fPIC" \
		QUIRC_CFLAGS="-Ilib $CFLAGS -fPIC" \
		libquirc.a

	mkdir -p "$PREFIX/lib/pkgconfig" "$PREFIX/include"
	cp libquirc.a "$PREFIX/lib/"
	cp lib/quirc.h "$PREFIX/include/"

	generate_pkgconfig "quirc" "QR-code recognition library" "1.2" "-lquirc" 
}

build_ncurses() {
	cd "$BUILD_DIR/ncurses"
	
	set_autotools_env
	
	./configure \
		"${COMMON_AUTOTOOLS_FLAGS[@]}" \
		--without-ada \
		--without-cxx \
		--without-cxx-binding \
		--without-manpages \
		--without-progs \
		--without-tests \
		--with-fallbacks=linux,screen,screen-256color,tmux,tmux-256color,vt100,xterm,xterm-256color \
		--enable-widec \
		--disable-database \
		--with-default-terminfo-dir=/system/etc/terminfo
	
	make -j$(nproc)
	make install
	
	cd "$PREFIX/lib"
	ln -sf libtinfow.a libtinfo.a
	ln -sf libncursesw.a libncurses.a
	cd "$PREFIX/include" && ln -s ncursesw ncurses
	
	echo "✔ ncurses built successfully"
}

build_libcaca() {
	echo "[+] Building libcaca for $ARCH..."

	cd "$BUILD_DIR/libcaca"

	(make clean && make distclean) || true

	if ! grep -q '#include "../caca/caca_internals.h"' src/common-image.c; then
		sed -i '/^#include "caca\.h"$/a #include "../caca/caca_internals.h"' src/common-image.c
	fi

	if ! grep -q '#if defined(HAVE_FLDLN2) && !defined(__clang__)' caca/dither.c; then
		sed -i 's/#ifdef HAVE_FLDLN2/#if defined(HAVE_FLDLN2) \&\& !defined(__clang__)/' caca/dither.c
	fi

	autoreconf -fi

	CC="$CC_ABS" \
		CXX="$CXX_ABS -I$PREFIX/include/ncursesw" \
		CFLAGS="$CFLAGS -UHAVE_FLDLN2" \
		./configure \
		--host="$HOST" \
		--disable-java \
		--disable-ruby \
		--disable-python \
		--disable-csharp \
		--disable-cxx \
		--disable-doc \
		--disable-imlib2 \
		--disable-x11 \
		--disable-gl \
		--disable-slang \
		--enable-ncurses \
		--disable-vga \
		--disable-win32 \
		--disable-conio \
		--disable-doc \
		--prefix="$PREFIX"

	make -j"$(nproc)"
	make install
}


build_lcms() {
	autotools_build "Little-CMS" "$BUILD_DIR/Little-CMS" \
		--without-jpeg \
		--without-tiff \
		--without-zlib
}

build_libffi() {
	autotools_build "libffi" "$BUILD_DIR/libffi" \
		--prefix="$PREFIX" \
		--host="$HOST"
}

build_flite() {
	echo "[+] Building flite for $ARCH..."
	
	cd "$BUILD_DIR/flite" || exit 1
	
	(make clean && make distclean) || true
	
	bash tools/make_voice_list \
		usenglish cmu_us_awb cmu_us_kal cmu_us_kal16 cmu_us_rms cmu_us_slt \
		cmu_grapheme_lang cmu_indic_lang cmulex cmu_grapheme_lex cmu_indic_lex cmu_time_awb \
		>flite_voice_list.c
	
	bash tools/make_lang_list \
		usenglish cmu_grapheme_lang cmu_indic_lang \
		cmulex cmu_grapheme_lex cmu_indic_lex \
		>flite_lang_list.c
	
	cp flite_lang_list.c main/
	cp flite_voice_list.c main/
	
	autoreconf -fvi
	
	set_autotools_env
	
	./configure \
		"${COMMON_AUTOTOOLS_FLAGS[@]}" \
		--with-audio=none
	
	make
	make install
	
	echo "✔ flite built successfully"
}

#---------------------------------------------------------Meson-Builds--------------------------------------------------------#

build_highway() {
    local arch_opts=("-Darm7=false" "-Dsse2=false" "-Drvv=false")

    case "$ARCH" in
        x86)     arch_opts[1]="-Dsse2=true" ;;
        riscv64) arch_opts[2]="-Drvv=true" ;;
    esac

    meson_build "highway" "$BUILD_DIR/highway" "$CROSS_FILE_TEMPLATE" \
        -Dcontrib=disabled \
        -Dexamples=disabled \
        -Dtests=disabled \
        "${arch_opts[@]}"
}

build_pixman() {
    local simd_opts=""
    
    case "$ARCH" in
        x86)
            simd_opts="-Dmmx=enabled -Dsse2=enabled -Dssse3=enabled"
            ;;
        x86_64)
            simd_opts="-Dmmx=enabled -Dsse2=enabled -Dssse3=enabled"
            ;;
        armv7)
           # simd_opts="-Darm-simd=disabled -Dneon=enabled"
            ;;
        aarch64)
            simd_opts="-Da64-neon=enabled"
            ;;
        riscv64)
            simd_opts="-Drvv=enabled"
            ;;
        *)
            simd_opts=""
            ;;
    esac

    meson_build "pixman" "$BUILD_DIR/pixman" "$CROSS_FILE_TEMPLATE" \
        $simd_opts \
        -Dloongson-mmi=disabled \
        -Dvmx=disabled \
        -Dgnu-inline-asm=enabled \
        -Dtls=enabled \
        -Dcpu-features-path=$ANDROID_NDK_ROOT/sources/android/cpufeatures \
        -Dopenmp=disabled \
        -Dtimers=false \
        -Dgnuplot=false \
        -Dgtk=disabled \
        -Dtests=disabled \
        -Ddemos=disabled
}

build_cairo() {
    meson_build "Cairo" "$BUILD_DIR/cairo" "$CROSS_FILE_TEMPLATE" \
        -Ddwrite=disabled \
        -Dfontconfig=enabled \
        -Dfreetype=enabled \
        -Dpng=enabled \
        -Dquartz=disabled \
        -Dtee=disabled \
        -Dxcb=disabled \
        -Dxlib=disabled \
        -Dxlib-xcb=disabled \
        -Dzlib=enabled \
        -Dtests=disabled \
        -Dlzo=enabled \
        -Dgtk2-utils=disabled \
        -Dglib=enabled \
        -Dspectre=disabled \
        -Dsymbol-lookup=disabled \
        -Dgtk_doc=false \
		-Dc_link_args="$LDFLAGS -lbrotlidec -lbrotlienc -lbrotlicommon"
}


build_pango() {
     
	   rm -f "$BUILD_DIR/pango/glib.wrap"

    meson_build "Pango" "$BUILD_DIR/pango" "$CROSS_FILE_TEMPLATE" \
        -Ddocumentation=false \
        -Dman-pages=false \
        -Dintrospection=disabled \
        -Dbuild-testsuite=false \
        -Dbuild-examples=false \
        -Dfontconfig=enabled \
        -Dsysprof=disabled \
        -Dlibthai=disabled \
        -Dcairo=enabled \
        -Dxft=disabled \
        -Dfreetype=enabled \
		--wrap-mode=nodownload \
		-Dc_link_args="$LDFLAGS -lbrotlidec -lbrotlienc -lbrotlicommon -liconv"
}



build_gdk_pixbuf() {
    meson_build "GDK-Pixbuf" "$BUILD_DIR/gdk-pixbuf" "$CROSS_FILE_TEMPLATE" \
        -Dman=false \
        -Dgtk_doc=false \
        -Dinstalled_tests=false \
        -Dintrospection=disabled \
        -Dnative_windows_loaders=false \
        -Djpeg=disabled \
        -Dtiff=disabled \
        -Dpng=enabled \
        -Dbuiltin_loaders=all
}

build_dav1d() {
    local ASM_OPTION=""
    [ "$ARCH" = "riscv64" ] && ASM_OPTION="-Denable_asm=false"
    
    meson_build "dav1d" "$BUILD_DIR/dav1d" "$CROSS_FILE_TEMPLATE" $ASM_OPTION
}

build_freetype() {
    meson_build "FreeType" "$BUILD_DIR/freetype" "$CROSS_FILE_TEMPLATE" \
        -Dbrotli=enabled \
        -Dbzip2=enabled \
        -Dharfbuzz=disabled \
        -Dpng=enabled \
        -Dzlib=system \
        -Dtests=disabled \
        -Derror_strings=false
}

build_bzip2() {
    meson_build "bzip2" "$BUILD_DIR/bzip2" "$CROSS_FILE_TEMPLATE" \
	     -Ddocs=disabled
}

		  

build_harfbuzz() {
    meson_build "harfbuzz" "$BUILD_DIR/harfbuzz" "$CROSS_FILE_TEMPLATE" \
        -Dtests=disabled \
        -Ddocs=disabled \
        -Dbenchmark=disabled \
        -Dglib=disabled \
        -Dgobject=disabled \
        -Dicu=disabled \
        -Dgraphite=disabled \
        -Dfreetype=enabled \
        -Dutilities=disabled
}

build_fontconfig() {
    meson_build "fontconfig" "$BUILD_DIR/fontconfig" "$CROSS_FILE_TEMPLATE" \
        -Ddoc=disabled \
        -Dnls=disabled \
        -Dtests=disabled \
        -Dtools=disabled \
        -Dcache-build=disabled
}

build_udfread() {
    meson_build "libudfread" "$BUILD_DIR/budfread" "$CROSS_FILE_TEMPLATE"
}

build_bluray() {
    meson_build "libbluray" "$BUILD_DIR/bluray" "$CROSS_FILE_TEMPLATE" \
        -Denable_tools=false \
        -Dfreetype=disabled \
        -Djava9=false \
        -Dfontconfig=disabled \
        -Dlibxml2=disabled \
        -Dbdj_jar=disabled
}

build_vmaf() {
    local vmaf_cross_file="$BUILD_DIR/vmaf/toolchain-$ARCH.txt"
    create_meson_cross_file "$vmaf_cross_file" "android"
    
    meson_build "libvmaf" "$BUILD_DIR/vmaf/libvmaf" "$vmaf_cross_file"
}

build_libplacebo() {
    meson_build "libplacebo" "$BUILD_DIR/libplacebo" "$CROSS_FILE_TEMPLATE" \
        -Dtests=false \
        -Dshaderc=disabled \
        -Dvulkan=disabled \
        -Dglslang=disabled \
        -Dopengl=enabled
}

build_rubberband() {
    meson_build "rubberband" "$BUILD_DIR/rubberband" "$CROSS_FILE_TEMPLATE" \
        -Dfft=fftw \
        -Dresampler=speex \
        -Djni=disabled \
        -Dladspa=disabled \
        -Dlv2=disabled \
        -Dvamp=disabled \
        -Dcmdline=disabled \
        -Dtests=disabled
}


build_librist() {
    meson_build "librist" "$BUILD_DIR/librist" "$CROSS_FILE_TEMPLATE" \
        -Duse_mbedtls=false \
        -Dbuiltin_cjson=true \
        -Dtest=false \
        -Dbuilt_tools=false
}

build_vapoursynth() {
    local ASM_ENABLED=false
    case "$ARCH" in
        x86|x86_64) ASM_ENABLED=true ;;
    esac
    
    echo "[+] Building vapoursynth for $ARCH..."
    cd "$BUILD_DIR/vapoursynth" || exit 1
    
    (make clean && make distclean) || true

    meson_build "vapoursynth" "$BUILD_DIR/vapoursynth" "$CROSS_FILE_TEMPLATE.linux" \
        -Dstatic_build=true \
        -Dcore=true \
        -Dvsscript=false \
        -Dvspipe=false \
        -Dpython_module=false \
        -Dx86_asm=$ASM_ENABLED
}

build_glib() {
    meson_build "glib" "$BUILD_DIR/glib" "$CROSS_FILE_TEMPLATE" \
        -Dtests=false \
        -Dintrospection=disabled \
        -Dglib_debug=disabled \
        -Dlibmount=disabled \
        -Dselinux=disabled \
        -Dman-pages=disabled \
        -Dc_link_args="$LDFLAGS -liconv"
}


build_fribidi() {
    meson_build "FriBidi" "$BUILD_DIR/fribidi" "$CROSS_FILE_TEMPLATE" \
        -Dbin=false \
        -Ddocs=false \
        -Dtests=false \
        -Ddeprecated=false
}

build_liblc3() {
    echo "[+] Building liblc3 for $ARCH..."
    cd "$BUILD_DIR/liblc3" || exit 1
    
    rm -rf out
    
    meson setup out . \
        --cross-file="$CROSS_FILE_TEMPLATE" \
        --prefix="$PREFIX" \
        --buildtype=release \
        --default-library=static \
        -Dtools=false \
        -Dpython=false
        
    ninja -C out -j"$(nproc)"
    ninja -C out install
    
    echo "✔ liblc3 built successfully"
}
#------------------------------------CMKAE-BUILDS----------------------------------------#

build_brotli() {
	cmake_build "Brotli" "$BUILD_DIR/brotli" true \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DBUILD_SHARED_LIBS=OFF \
		-DBROTLI_BUNDLED_MODE=OFF \
		-DBROTLI_DISABLE_TESTS=ON
}

build_x265() {
	echo "[+] Building x265 for $ARCH..."
	cd "$BUILD_DIR/x265/source" || exit 1
	rm -rf build && mkdir build && cd build || exit 1

	local CMAKE_ARGS=()
	if [ "$ARCH" = "armv7" ]; then
		PROCESSOR=armv7l
		CMAKE_ARGS=("${COMMON_CMAKE_FLAGS[@]}")
		CMAKE_ARGS+=(-DCROSS_COMPILE_ARM=1)
	elif [ "$ARCH" = "aarch64" ]; then
		PROCESSOR=aarch64
		CMAKE_ARGS+=(-DCROSS_COMPILE_ARM64=1)
	elif [ "$ARCH" = "x86" ]; then
		PROCESSOR=i686
		CMAKE_ARGS+=(-DENABLE_ASSEMBLY=OFF)
	elif [ "$ARCH" = "x86_64" ]; then
		PROCESSOR=x86_64
	else
		PROCESSOR=$ARCH
	fi

	if [ "$ARCH" = "riscv64" ]; then
		CMAKE_ARGS+=(-DENABLE_ASSEMBLY=OFF)
	fi

	cmake .. -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_SYSTEM_PROCESSOR="$PROCESSOR" \
		-DENABLE_SHARED=OFF \
		-DENABLE_CLI=OFF \
		-DNATIVE_BUILD=OFF \
		-DSTATIC_LINK_CRT=ON \
		-DENABLE_PIC=ON \
		"${CMAKE_ARGS[@]}"

	ninja -j"$(nproc)"
	ninja install

	generate_pkgconfig \
    "x265" \
    "H.265/HEVC video encoder" \
    "3.5" \
    "-lx265"

	echo "✓ x265 built successfully"
}

build_aom() {
	echo "[+] Building libaom for $ARCH..."
	cd "$BUILD_DIR/aom" || exit 1
	rm -rf out && mkdir out && cd out

	cmake .. -G Ninja \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DCMAKE_C_COMPILER="$CC_ABS" \
		-DCMAKE_CXX_COMPILER="$CXX_ABS" \
		-DCMAKE_AR="$AR_ABS" \
		-DCMAKE_RANLIB="$RANLIB_ABS" \
		-DCMAKE_STRIP="$STRIP_ABS" \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_C_FLAGS="$CFLAGS -I$PREFIX/include" \
		-DCMAKE_CXX_FLAGS="$CXXFLAGS -I$PREFIX/include" \
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS -L$PREFIX/lib" \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_TESTS=OFF \
		-DENABLE_DOCS=OFF \
		"${ASM_F[@]}"

	ninja -j"$(nproc)"
	ninja install
	echo "✓ libaom (AV1) built successfully"
}

build_openjpeg() {
	cmake_build "OpenJPEG" "$BUILD_DIR/openjpeg" true \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_STATIC_LIBS=ON \
		-DBUILD_CODEC=OFF \
		-DBUILD_JAVA=OFF \
		-DBUILD_VIEWER=OFF \
		-DBUILD_THIRDPARTY=OFF \
		-DBUILD_TESTING=OFF
}

build_libmysofa() {
	cmake_ninja_build "libmysofa" "$BUILD_DIR/libmysofa" false \
		-DCMAKE_PREFIX_PATH="$PREFIX" \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTS=OFF \
		-DMATH='-lm'
}

build_soxr() {
	echo "[+] Building soxr for $ARCH..."
	cd "$BUILD_DIR/soxr" || exit 1
	
	cmake -B build -G Ninja . \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DWITH_OPENMP=OFF \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-Wno-dev

	ninja -C build -j"$(nproc)"
	ninja -C build install
	
	generate_pkgconfig "soxr" "High quality, one-dimensional sample-rate conversion library" "0.1.3" "-lsoxr"
	echo "✓ soxr built successfully"
}

build_svtav1() {
	cmake_build "SVT-AV1" "$BUILD_DIR/svtav1" true \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_APPS=OFF \
		-DENABLE_NEON_I8MM=OFF
}

build_libsrt() {
	cmake_build "libsrt" "$BUILD_DIR/srt" true \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DENABLE_STATIC=ON \
		-DENABLE_SHARED=OFF \
		-DENABLE_APPS=OFF \
		-DENABLE_CXX=ON
}

build_libzmq() {
	cmake_build "libzmq (ZeroMQ)" "$BUILD_DIR/libzmq" true \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DENABLE_CURVE=OFF \
		-DENABLE_DRAFTS=OFF \
		-DENABLE_SHARED=OFF \
		-DENABLE_STATIC=ON \
		-DBUILD_SHARED=OFF \
		-DBUILD_STATIC=ON \
		-DWITH_LIBSODIUM=OFF \
		-DBUILD_TESTS=OFF \
		-DZMQ_BUILD_TESTS=OFF
}

build_libilbc() {
	cmake_build "libilbc" "$BUILD_DIR/libilbc" true \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DBUILD_SHARED_LIBS=OFF
}

build_libcodec2_native() {
	echo "[+] Building native libcodec2 tools..."
	mkdir -p "$BUILD_DIR/libcodec2-native/build"
	cd "$BUILD_DIR/libcodec2-native/build" || exit 1

	cmake "$BUILD_DIR/libcodec2" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER="${HOST_CC}" \
		-DCMAKE_CXX_COMPILER="${HOST_CXX}" \
		-DUNITTEST=FALSE

	make -j"$(nproc)"
}

build_libcodec2() {
	echo "[+] Building libcodec2 for $ARCH..."
	cd "$BUILD_DIR/libcodec2" || exit 1
	rm -rf build && mkdir build && cd build

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DUNITTEST=FALSE \
		-DGENERATE_CODEBOOK="$BUILD_DIR/libcodec2-native/build/src/generate_codebook"

	make -j"$(nproc)" && make install
	
	generate_pkgconfig "libcodec2" "Low bit rate speech codec" "1.0" "-lcodec2"
	echo "✔ libcodec2 built successfully"
}

build_uavs3d() {
	echo "[+] Building uavs3d for $ARCH..."
	cd "$BUILD_DIR/uavs3d" || exit 1
	rm -rf build && mkdir build && cd build

	if [[ "$ARCH" == "x86" ]]; then
		cmake .. \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DCMAKE_SYSTEM_PROCESSOR=x86 \
			-DBUILD_SHARED_LIBS=OFF \
			-DCOMPILE_10BIT=OFF
	else
		cmake .. \
			"${COMMON_CMAKE_FLAGS[@]}" \
			-DCMAKE_SYSTEM_PROCESSOR="$ARCH" \
			-DBUILD_SHARED_LIBS=OFF \
			-DCOMPILE_10BIT=OFF
	fi

	cmake --build . --target uavs3d -j"$(nproc)"
	cmake --install .
	echo "✔ uavs3d built successfully"
}

build_libssh() {
	echo "[+] Building libssh for $ARCH..."
	cd "$BUILD_DIR/libssh" || exit 1
	
	for file in src/config.c src/bind_config.c; do
		grep -q '#define GLOB_TILDE' "$file" || sed -i '1i#ifndef GLOB_TILDE\n#define GLOB_TILDE 0\n#endif' "$file"
	done
	grep -q '#define S_IWRITE' src/misc.c || sed -i '1i#ifndef S_IWRITE\n#define S_IWRITE S_IWUSR\n#endif' src/misc.c
	
	cmake_build "libssh" "$BUILD_DIR/libssh" true \
		-DCMAKE_SYSTEM_PROCESSOR="$TARGET" \
		-DBUILD_SHARED_LIBS=OFF \
		-DWITH_GSSAPI=OFF \
		-DWITH_EXAMPLES=OFF \
		-DWITH_ZLIB=ON \
		-DHAVE_GLOB_TILDE=OFF \
		-DOPENSSL_ROOT_DIR="$PREFIX" \
		-DOPENSSL_INCLUDE_DIR="$PREFIX/include" \
		-DOPENSSL_LIBRARIES="$PREFIX/lib"
}

build_vvenc() {
	echo "[+] Building vvenc for $ARCH..."
	cd "$BUILD_DIR/vvenc" || exit 1
	rm -rf build && mkdir build && cd build

	local simd_flags=()
	if [[ "$ARCH" =~ ^(armv7|riscv64|x86)$ ]]; then
		simd_flags+=(
			-DVVENC_ENABLE_X86_SIMD=OFF
			-DVVENC_ENABLE_ARM_SIMD=OFF
			-DVVENC_ENABLE_ARM_SIMD_SVE=OFF
			-DVVENC_ENABLE_ARM_SIMD_SVE2=OFF
		)
	fi

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DVVENC_LIBRARY_ONLY=ON \
		-DVVENC_ENABLE_LINK_TIME_OPT=OFF \
		-DCMAKE_SYSTEM_PROCESSOR="${ARCH}" \
		"${simd_flags[@]}"

	cmake --build . --target install -- -j"$(nproc)"
	echo "✔ vvenc built successfully"
}

build_pcre2() {
	cmake_build "pcre2" "$BUILD_DIR/pcre2" true \
		-DBUILD_SHARED_LIBS=OFF \
		-DPCRE2_BUILD_PCRE2_16=OFF \
		-DPCRE2_BUILD_PCRE2_32=OFF \
		-DPCRE2_BUILD_TESTS=OFF \
		-DPCRE2_BUILD_PCRE2GREP=OFF \
		-DPCRE2_BUILD_PCRE2TEST=OFF \
		-DPCRE2_SUPPORT_JIT=OFF \
		-DPCRE2_STATIC_RUNTIME=ON
}

build_lensfun() {
	echo "[+] Building lensfun for $ARCH..."
	cd "$BUILD_DIR/lensfun" || exit 1
	rm -rf build && mkdir build && cd build

	local cmake_args=(
		"${MINIMAL_CMAKE_FLAGS[@]}"
		-DBUILD_STATIC=ON
		-DLF_ENABLE_PYTHON=OFF
		-DBUILD_LENSTOOL=OFF
		-DINSTALL_PYTHON_MODULE=OFF
		-DINSTALL_HELPER_SCRIPTS=OFF
	)

	case "$ARCH" in
		x86|x86_64|i686) ;;
		*)
			cmake_args+=(
				-DBUILD_FOR_SSE=OFF
				-DBUILD_FOR_SSE2=OFF
			)
			;;
	esac

	cmake ../ "${cmake_args[@]}"
	make -j"$(nproc)" && make install

	[ -f "$PREFIX/include/lensfun/lensfun.h" ] && ln -snf "$PREFIX/include/lensfun/lensfun.h" "$PREFIX/include/lensfun.h"
	echo "✔ lensfun built successfully"
}

build_libgme() {
	cmake_build "libgme" "$BUILD_DIR/game-music-emu" true \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DCMAKE_SYSTEM_PROCESSOR="$TARGET" \
		-DBUILD_SHARED_LIBS=OFF
}


build_libjxl() {
	echo "[+] Building libjxl for $ARCH..."
	cd "$BUILD_DIR/libjxl" || exit 1
	rm -rf build && mkdir build && cd build

	cmake .. \
		"${MINIMAL_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
		-DCMAKE_C_FLAGS="$CFLAGS -I$PREFIX/include" \
		-DCMAKE_CXX_FLAGS="$CXXFLAGS -I$PREFIX/include" \
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS -L$PREFIX/lib" \
		-DCMAKE_ASM_COMPILER="$AS" \
		-DJPEGXL_ENABLE_TOOLS=OFF \
		-DJPEGXL_ENABLE_DEVTOOLS=OFF \
		-DJPEGXL_ENABLE_FUZZERS=OFF \
		-DJPEGXL_ENABLE_BENCHMARK=OFF \
		-DJPEGXL_ENABLE_EXAMPLES=OFF \
		-DJPEGXL_ENABLE_VIEWERS=OFF \
		-DJPEGXL_ENABLE_MANPAGES=OFF \
		-DJPEGXL_ENABLE_DOXYGEN=OFF \
		-DJPEGXL_ENABLE_JNI=OFF \
		-DJPEGXL_ENABLE_PLUGINS=OFF \
		-DJPEGXL_ENABLE_JPEGLI_LIBJPEG=OFF \
		-DJPEGXL_INSTALL_JPEGLI_LIBJPEG=OFF \
		-DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
		-DJPEGXL_FORCE_SYSTEM_HWY=ON \
		-DJPEGXL_FORCE_SYSTEM_LCMS2=ON \
		-DJPEGXL_ENABLE_TESTS=OFF \
		-DBUILD_TESTING=OFF \
		-DJPEGXL_TEST_TOOLS=OFF \
		-DJXL_ENABLE_SKCMS=OFF \
		-DJPEGXL_FORCE_SYSTEM_GTEST=OFF \
		-DZLIB_LIBRARY="$PREFIX/lib/libz.a" \
		-DZLIB_INCLUDE_DIR="$PREFIX/include"

	make -j"$(nproc)" && make install
	echo "✔ libjxl built successfully"
}

build_libqrencode() {
	cmake_build "libqrencode" "$BUILD_DIR/libqrencode" true \
		-DWITH_TOOLS="NO" \
		-DBUILD_SHARED_LIBS="NO" \
		-DZLIB_LIBRARY="$PREFIX/lib/libz.a" \
		-DZLIB_INCLUDE_DIR="$PREFIX/include"
}

build_fftw() {
	cmake_build "fftw" "$BUILD_DIR/fftw" true \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_FLOAT=OFF \
		-DENABLE_LONG_DOUBLE=OFF \
		-DENABLE_THREADS=OFF
}

build_chromaprint() {
	cmake_build "Chromaprint" "$BUILD_DIR/chromaprint" true \
		-DCMAKE_PREFIX_PATH="$PREFIX" \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TOOLS=OFF \
		-DBUILD_TESTS=OFF \
		-DFFT_LIB=fftw3
}

build_lzo() {
	cmake_build "lzo" "$BUILD_DIR/lzo" true \
        -DENABLE_STATIC=ON \
        -DENABLE_SHARED=OFF
}

build_snappy() {
    cmake_build "Snappy" "$BUILD_DIR/snappy" true \
        -DBUILD_SHARED_LIBS=OFF \
        -DSNAPPY_BUILD_TESTS=OFF \
        -DSNAPPY_BUILD_BENCHMARKS=OFF \
        -DSNAPPY_FUZZING_BUILD=OFF \
        -DSNAPPY_INSTALL=ON \
        -DSNAPPY_REQUIRE_AVX=OFF \
        -DSNAPPY_REQUIRE_AVX2=OFF
}

build_avisynth() {
	echo "[+] Building AviSynth+ for $ARCH..."
	cd "$BUILD_DIR/AviSynthPlus" || exit 1
	rm -rf build && mkdir build && cd build

	local simd_option
	case "$ARCH" in
		x86|x86_64) simd_option=ON ;;
		*) simd_option=OFF ;;
	esac

	cmake ../ \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_PROCESSOR="$ARCH" \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_CXX_COMPILER="$CXX_ABS" \
		-DENABLE_PLUGINS=OFF \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_INTEL_SIMD="$simd_option"

	make -j"$(nproc)" && make install
	echo "✔ AviSynth+ built successfully"
}

build_lcevcdec() {
	echo "[+] Building LCEVCdec for $ARCH..."
	cd "$BUILD_DIR/LCEVCdec" || exit 1
	rm -rf out && mkdir out && cd out

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DVN_SDK_EXECUTABLES=OFF \
		-DVN_SDK_UNIT_TESTS=OFF \
		-DVN_SDK_BENCHMARK=OFF \
		-DVN_SDK_DOCS=OFF

	make -j"$(nproc)" && make install

	local pc_file="$PREFIX/lib/pkgconfig/lcevc_dec.pc"
	if [ -f "$pc_file" ]; then
		local version_line=$(grep -E '^Version:' "$pc_file")
		if [ -z "$(echo "$version_line" | cut -d' ' -f2)" ]; then
			sed -i 's/^Version:.*/Version: 5.0.1/' "$pc_file"
		fi
	fi
	echo "✔ LCEVCdec built successfully"
}

build_xeve() {
	echo "[+] Building XEVE for $ARCH..."
	echo "v0.5.1" > "$BUILD_DIR/xeve/version.txt"
	cd "$BUILD_DIR/xeve" || exit 1
	rm -rf out && mkdir out && cd out

	local arm_flag=FALSE
	[[ "$ARCH" == "aarch64" ]] && arm_flag=TRUE

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DSET_PROF=MAIN \
		-DARM="$arm_flag"

	make -j"$(nproc)" && make install

	[ ! -e "$PREFIX/lib/libxeve.a" ] && [ -f "$PREFIX/lib/xeve/libxeve.a" ] && \
		ln -s "$PREFIX/lib/xeve/libxeve.a" "$PREFIX/lib/libxeve.a"
	echo "✔ XEVE built successfully"
}

build_xevd() {
	echo "[+] Building XEVD for $ARCH..."
	cd "$BUILD_DIR/xevd" || exit 1
	
	[ ! -f "version.txt" ] && echo "v0.5.1" > version.txt
	rm -rf out && mkdir out && cd out

	local arm_flag=FALSE
	[[ "$ARCH" =~ ^(armv7|aarch64)$ ]] && arm_flag=TRUE

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DSET_PROF=MAIN \
		-DARM="$arm_flag"

	make -j"$(nproc)" && make install

	[ ! -e "$PREFIX/lib/libxevd.a" ] && [ -f "$PREFIX/lib/xevd/libxevd.a" ] && \
		ln -s "$PREFIX/lib/xevd/libxevd.a" "$PREFIX/lib/libxevd.a"
	echo "✔ XEVD built successfully"
}

build_libmodplug() {
	cmake_build "libmodplug" "$BUILD_DIR/libmodplug" true \
		-DBUILD_SHARED_LIBS=OFF
}

install_opencl_headers() {
	cmake_build "OpenCL-Headers" "$BUILD_DIR/OpenCL-Headers" false \
		-DCMAKE_INSTALL_PREFIX="$PREFIX"
}

build_vidstab() {
	echo "[+] Building vid.stab for $ARCH..."
	cd "$BUILD_DIR/vid.stab" || exit 1
	
	rm -rf CMakeCache.txt CMakeFiles/ cmake_install.cmake build.ninja .ninja_deps .ninja_log

	cmake . -G Ninja \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DCMAKE_POLICY_DEFAULT_CMP0091=NEW \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_SHARED=OFF \
		-DENABLE_STATIC=ON \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5

	ninja -v && ninja install
	echo "✔ vid.stab built successfully"
}

build_libklvanc () {
meson_build "libklvanc" "$BUILD_DIR/libklvanc" "$CROSS_FILE_TEMPLATE"

generate_pkgconfig \
    "libklvanc" \
    "Library for KLV ANC data processing" \
    "1.0.0" \
    "-lklvanc" \
    "-I\${includedir}" \
    "" \
    ""
	
}

