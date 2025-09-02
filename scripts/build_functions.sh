#!/bin/bash

build_zlib() {
	echo "[+] Building zlib for $ARCH..."
	cd "$BUILD_DIR/zlib" || exit 1

	export CHOST="$HOST"

	CONFIGURE_CFLAGS="-fPIC --sysroot=$SYSROOT"

	CFLAGS="$CONFIGURE_CFLAGS" ./configure --prefix="$PREFIX" --static

	make -j"$(nproc)" CFLAGS="$CFLAGS"
	make install

	echo "[+] Zlib built successfully"
}

build_brotli() {
	echo "[+] Building Brotli for $ARCH..."
	cd "$BUILD_DIR/brotli" || exit 1
	rm -rf out
	mkdir -p out && cd out

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF \
		-DBROTLI_BUNDLED_MODE=OFF \
		-DBROTLI_DISABLE_TESTS=ON

	make -j"$(nproc)"
	make install

	echo "[+] Brotli built successfully"
}

build_liblzma() {
	echo "[+] Building liblzma for $ARCH"
	cd "$BUILD_DIR/xz" || exit 1
	CONFIGURE_CFLAGS="-O2"

	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared \
		CC="$CC_ABS" \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"
	make -j"$(nproc)"
	make install

}

build_zstd() {
	cd "$BUILD_DIR/zstd" || exit 1

	make clean || true

	make -j"$(nproc)" -C lib \
		CC="$CC_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS" \
		PREFIX="$PREFIX" \
		HAVE_THREAD=1 \
		ZSTD_LEGACY_SUPPORT=0 \
		libzstd.a

	make -C lib install-static install-includes install-pc \
		PREFIX="$PREFIX"
}

build_openssl() {
	echo "[+] Building OpenSSL for $ARCH"
	cd "$BUILD_DIR/openssl" || exit 1

	case "$ARCH" in
	aarch64) OPENSSL_TARGET="android-arm64" ;;
	armv7) OPENSSL_TARGET="android-arm" ;;
	x86) OPENSSL_TARGET="android-x86" ;;
	x86_64) OPENSSL_TARGET="android-x86_64" ;;
	riscv64) OPENSSL_TARGET="linux-generic64" ;;
	*)
		echo "Unknown architecture: $ARCH" >&2
		exit 1
		;;
	esac

	(make clean && make distclean || true)

	CC="$CC_ABS" ./Configure "$OPENSSL_TARGET" -fPIC \
		no-shared no-tests \
		${ASM:+$ASM} \
		--prefix="$PREFIX" \
		--openssldir="$PREFIX/ssl" \
		--with-zlib-include="$PREFIX/include" \
		--with-zlib-lib="$PREFIX/lib"

	make -j"$(nproc)"
	make install_sw

	([ "$ARCH" = "x86_64" ] && cp -r "$PREFIX/lib64/"* "$PREFIX/lib/") || true
	echo "OpenSSL built successfully"
}

build_x264() {
	echo "[+] Building x264 for $ARCH..."
	cd "$BUILD_DIR/x264" || exit 1

	(make clean && make distclean) || true

	ASM_FLAGS=""
	CFGHOST="$HOST"

	if [ "$ARCH" = "x86" ] || [ "$ARCH" = "riscv64" ]; then
		ASM_FLAGS="--disable-asm"
	fi

	if [ "$ARCH" = "riscv64" ]; then
		CFGHOST="riscv64-unknown-linux-gnu"
		sed -i 's/unknown/ok/' configure
	fi

	./configure \
		--prefix="$PREFIX" \
		--host="${CFGHOST}" \
		--enable-static \
		--disable-cli \
		--disable-opencl \
		--enable-pic \
		$ASM_FLAGS \
		--extra-cflags="$CFLAGS -I$PREFIX/include" \
		--extra-ldflags="$LDFLAGS -L$PREFIX/lib"

	make -j"$(nproc)"
	make install

	echo "✔ x264 built successfully for $ARCH"
}

build_x265() {
	cd "$BUILD_DIR/x265/source" || exit 1
	rm -rf build && mkdir build
	cd build || exit 1

	local CMAKE_ARGS=()
	if [ "$ARCH" = "armv7" ]; then
		PROCESSOR=armv7l
		CMAKE_ARGS=("${COMMON_CMAKE_FLAGS[@]}")
	elif [ "$ARCH" = "aarch64" ]; then
		PROCESSOR=aarch64
		CMAKE_ARGS+=(-DCROSS_COMPILE_ARM64=1)
	elif [ "$ARCH" = "x86" ]; then
		PROCESSOR=i686
	elif [ "$ARCH" = "x86_64" ]; then
		PROCESSOR=x86_64
	else
		PROCESSOR=$ARCH
	fi
	if [ "$ARCH" = "armv7" ]; then
		CMAKE_ARGS+=(-DCROSS_COMPILE_ARM=1)
	fi

	if [ "$ARCH" = "x86" ] || [ "$ARCH" = "riscv64" ]; then
		CMAKE_ARGS+=(-DENABLE_ASSEMBLY=OFF)
	fi

	cmake ../ \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_SYSTEM_PROCESSOR="$PROCESSOR" \
		-DENABLE_SHARED=OFF \
		-DENABLE_CLI=OFF \
		-DNATIVE_BUILD=OFF \
		-DSTATIC_LINK_CRT=ON \
		-DENABLE_PIC=ON \
		"${CMAKE_ARGS[@]}"

	make -j"$(nproc)"
	make install
	echo "✔ x265 built successfully"
}

build_twolame() {
	echo "[+] Building twolame for $ARCH..."
	cd "$BUILD_DIR/twolame" || exit 1
	(make clean && make distclean) || true

	autoreconf -fi || exit 1
	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS" || exit 1

	make -C libtwolame -j"$(nproc)" || exit 1
	make -C libtwolame install || exit 1
}

build_libgsm() {
	echo "[+] Building libgsm for $ARCH..."
	cd "$BUILD_DIR/libgsm" || exit 1

	(make clean && make distclean) || true

	CC="$CC" AR="$AR" RANLIB="$RANLIB" STRIP="$STRIP" \
		CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" \
		make -j"$(nproc)" CC="$CC" || exit 1

	make install INSTALL_ROOT="$PREFIX" || exit 1
	HEADER_SRC_DIR="$BUILD_DIR/libgsm"
	HEADER_DST_DIR="$PREFIX/include/gsm"
	mkdir -p "$HEADER_DST_DIR"
	find "$HEADER_SRC_DIR" -type f -name '*.h' -exec cp {} "$HEADER_DST_DIR/" \;

	PC_DIR="$PREFIX/lib/pkgconfig"
	PC_FILE="$PC_DIR/gsm.pc"

	if [ ! -f "$PC_FILE" ]; then
		echo "Generating gsm.pc..."

		mkdir -p "$PC_DIR"
		cat >"$PC_FILE" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include/gsm

Name: libgsm
Description: GSM 06.10 lossy speech compression
Version: 1.0.22
Libs: -L\${libdir} -lgsm
Cflags: -I\${includedir}
EOF
	fi

	echo " libgsm built successfully"
}

build_libvpx() {
	echo "[+] Building libvpx for $ARCH..."
	cd "$BUILD_DIR/libvpx" || exit 1

	find . -name '*.d' -delete

	case "$ARCH" in
	x86_64)
		VPX_TARGET="x86_64-android-gcc"
		;;
	x86)
		VPX_TARGET="x86-android-gcc"
		;;
	armv7)
		VPX_TARGET="armv7-android-gcc"
		;;
	aarch64)
		VPX_TARGET="arm64-android-gcc"
		;;
	*)
		VPX_TARGET=generic-gnu
		;;
	esac

	./configure \
		--prefix="${PREFIX}" \
		--target="${VPX_TARGET}" \
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

	echo " libvpx built successfully"
}

build_lame() {
	echo "[+] Building LAME for $ARCH..."
	cd "$BUILD_DIR/lame" || exit 1
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"

	make -j"$(nproc)"
	make install

	echo "✔ LAME built successfully"
}

build_opus() {
	echo "[+] Building Opus for $ARCH..."
	cd "$BUILD_DIR/opus" || exit 1
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--disable-shared \
		--enable-static \
		--disable-doc \
		--disable-extra-programs \
		--with-pic \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"

	make -j"$(nproc)"
	make install

	echo "✔ Opus built successfully"
}

build_vorbis() {
	echo "[+] Building libvorbis for $ARCH..."
	cd "$BUILD_DIR/vorbis" || exit 1
	(make clean && make distclean) || true

	[ -f configure.ac.bak ] && cp configure.ac.bak configure.ac
	cp configure.ac configure.ac.bak

	if [ "$ARCH" = "x86" ]; then
		sed -i 's/-mno-ieee-fp//g' configure.ac
		autoreconf -fi
	fi

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--with-ogg="$PREFIX" \
		--enable-static \
		--disable-shared \
		--disable-oggtest \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"

	make -j"$(nproc)"
	make install

	echo "✔ libvorbis built successfully"
}

build_ogg() {
	echo "[+] Building libogg for $ARCH..."
	cd "$BUILD_DIR/ogg" || exit 1
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"

	make -j"$(nproc)"
	make install

	echo "✔ libogg built successfully"
}

build_speex() {
	echo "[+] Building Speex for $ARCH..."
	cd "$BUILD_DIR/speex" || exit 1
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		--disable-oggtest \
		--with-ogg="$PREFIX" \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"

	make -j"$(nproc)"
	make install

	echo "✔ Speex built successfully"
}

build_aom() {
	echo "[+] Building libaom for $ARCH..."

	cd "$BUILD_DIR/aom" || exit 1
	rm -rf out
	mkdir -p out && cd out

	cmake .. \
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

	make -j"$(nproc)" && make install
	echo "✔ libaom (AV1) built successfully"
}

build_dav1d() {
	echo "[+] Building dav1d for $ARCH..."
	cd "$BUILD_DIR/dav1d" || exit 1
	rm -rf build && mkdir build && cd build

	format_flags() {
		local flags=()
		for flag in $1; do
			[ -n "$flag" ] && flags+=("'$flag'")
		done
		IFS=,
		echo "${flags[*]}"
	}

	local ASM_OPTION=""
	if [ "$ARCH" = "riscv64" ]; then
		ASM_OPTION="-Denable_asm=false"
	fi

	meson setup . .. \
		--cross-file <(
			cat <<EOF
[binaries]
c = '$CC_ABS'
ar = '$AR_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'

[built-in options]
c_args = [$(format_flags "$CFLAGS")]
cpp_args = [$(format_flags "$CXXFLAGS")]
c_link_args = [$(format_flags "$LDFLAGS")]
cpp_link_args = [$(format_flags "$LDFLAGS")]
EOF
		) \
		--prefix="$PREFIX" \
		--default-library=static \
		--buildtype=release \
		$ASM_OPTION

	ninja -j"$(nproc)"
	ninja install

	echo "✔ dav1d built successfully"
}

build_fribidi() {
	echo "[+] Building fribidi for $ARCH..."
	cd "$BUILD_DIR/fribidi" || exit 1
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"

	make -j"$(nproc)"
	make install

	echo "✔ fribidi built successfully"
}

build_bzip2() {
	echo "[+] Building bzip2 for $ARCH..."
	cd "$BUILD_DIR/bzip2" || exit 1

	make clean || true

	[ -f Makefile.bak ] && cp Makefile.bak Makefile
	cp Makefile Makefile.bak
	sed -i '/^test:/,/^$/c\test:\n\t@echo "Skipping tests during cross-compilation"' Makefile

	make -j"$(nproc)" \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		CFLAGS="$CFLAGS -I$PREFIX/include"

	make install PREFIX="$PREFIX"

	cat >"$PREFIX/lib/pkgconfig/bz2.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: bzip2
Description: Lossless data compression library
Version: 1.0.8
Libs: -L\${libdir} -lbz2
Cflags: -I\${includedir}
EOF

	echo "✔ bzip2 built successfully"
}

build_freetype() {
	echo "[+] Building FreeType for $ARCH..."

	cd "$BUILD_DIR/freetype" || exit 1
	rm -rf build && mkdir build

	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed '/^$/d; s/.*/'"'"'&'"'"'/' | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed '/^$/d; s/.*/'"'"'&'"'"'/' | paste -sd, -)

	meson setup build . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Ddefault_library=static \
		-Dbrotli=disabled \
		-Dbzip2=disabled \
		-Dharfbuzz=disabled \
		-Dpng=disabled \
		-Dzlib=system \
		-Dtests=disabled \
		-Derror_strings=false \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
c_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C build
	ninja -C build install
}

build_libpng() {
	echo "[+] Building libpng for $ARCH..."
	cd "$BUILD_DIR/libpng" || exit 1

	export CPPFLAGS="-I$PREFIX/include"
	export LDFLAGS="-L$PREFIX/lib"
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		--with-zlib-prefix="$PREFIX"

	make -j"$(nproc)"
	make install

	echo "✔ libpng built successfully"
}

build_libass() {
	echo "[+] Building libass for $ARCH..."
	cd "$BUILD_DIR/libass" || exit 1
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		--disable-require-system-font-provider

	make -j"$(nproc)"
	make install

	echo "✔ libass built successfully"
}

build_libxml2() {
	echo "[+] Building libxml2 for $ARCH..."
	cd "$BUILD_DIR/libxml2"
	(make clean && make distclean) || true

	./autogen.sh || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		--without-python \
		--without-lzma \
		CFLAGS="$CFLAGS -I$PREFIX/include" \
		LDFLAGS="$LDFLAGS -L$PREFIX/lib"

	make -j"$(nproc)"
	make install

	echo "✔ libxml2 built successfully"
}

build_libexpat() {
	echo "[+] Building expat for $ARCH..."
	cd "$BUILD_DIR/libexpat"
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		--without-examples \
		--without-tests \
		--without-docbook \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"

	make -j"$(nproc)"
	make install

	echo "✔ expat built successfully"
}

build_harfbuzz() {
	echo "[+] Building harfbuzz for $ARCH..."
	cd "$BUILD_DIR/harfbuzz"

	rm -rf build && mkdir build && cd build

	MESON_CFLAGS=$(echo "$CFLAGS" | sed "s/\s\+/\n/g" | grep -v '^$' | sed "s/.*/'&'/" | tr '\n' ',' | sed 's/,$//')
	MESON_CXXFLAGS=$(echo "$CXXFLAGS" | sed "s/\s\+/\n/g" | grep -v '^$' | sed "s/.*/'&'/" | tr '\n' ',' | sed 's/,$//')
	MESON_LDFLAGS=$(echo "$LDFLAGS" | sed "s/\s\+/\n/g" | grep -v '^$' | sed "s/.*/'&'/" | tr '\n' ',' | sed 's/,$//')

	meson setup . .. \
		--cross-file <(
			cat <<EOF
[binaries]
c = '$CC_ABS'
ar = '$AR_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'

[built-in options]
c_args = [$MESON_CFLAGS]
cpp_args = [$MESON_CXXFLAGS]
c_link_args = [$MESON_LDFLAGS]
cpp_link_args = [$MESON_LDFLAGS]
EOF
		) \
		--prefix="$PREFIX" \
		--default-library=static \
		--buildtype=release \
		-Dtests=disabled \
		-Ddocs=disabled \
		-Dbenchmark=disabled \
		-Dglib=disabled \
		-Dgobject=disabled \
		-Dicu=disabled \
		-Dgraphite=disabled \
		-Dfreetype=enabled \
		-Dutilities=disabled

	ninja
	ninja install

	echo "✔ harfbuzz built successfully with Meson"
}

build_fontconfig() {
	echo "[+] Building fontconfig for $ARCH..."
	cd "$BUILD_DIR/fontconfig"

	rm -rf build && mkdir build && cd build

	MESON_CFLAGS=$(echo "$CFLAGS" | sed "s/\s\+/\n/g" | grep -v '^$' | sed "s/.*/'&'/" | tr '\n' ',' | sed 's/,$//')
	MESON_CXXFLAGS=$(echo "$CXXFLAGS" | sed "s/\s\+/\n/g" | grep -v '^$' | sed "s/.*/'&'/" | tr '\n' ',' | sed 's/,$//')
	MESON_LDFLAGS=$(echo "$LDFLAGS" | sed "s/\s\+/\n/g" | grep -v '^$' | sed "s/.*/'&'/" | tr '\n' ',' | sed 's/,$//')

	meson setup . .. \
		--cross-file <(
			cat <<EOF
[binaries]
c = '$CC_ABS'
ar = '$AR_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'

[built-in options]
c_args = [$MESON_CFLAGS]
cpp_args = [$MESON_CXXFLAGS]
c_link_args = [$MESON_LDFLAGS]
cpp_link_args = [$MESON_LDFLAGS]
EOF
		) \
		--prefix="$PREFIX" \
		--default-library=static \
		--buildtype=release \
		-Ddoc=disabled \
		-Dnls=disabled \
		-Dtests=disabled \
		-Dtools=disabled \
		-Dcache-build=disabled

	ninja
	ninja install

	echo "Fontconfig built successfully with Meson"
}

build_udfread() {
	echo "[+] Building libudfread for $ARCH..."
	cd "$BUILD_DIR/budfread" || exit 1

	rm -rf build && mkdir build && cd build || exit 1

	MESON_CFLAGS=$(printf "'%s'," $CFLAGS | sed 's/,$//')
	MESON_CXXFLAGS=$(printf "'%s'," $CXXFLAGS | sed 's/,$//')
	MESON_LDFLAGS=$(printf "'%s'," $LDFLAGS | sed 's/,$//')

	CROSS_FILE=cross_file.txt
	cat >"$CROSS_FILE" <<EOF
[binaries]
c = '$CC_ABS'
ar = '$AR_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'

[built-in options]
c_args = [${MESON_CFLAGS}]
cpp_args = [${MESON_CXXFLAGS}]
c_link_args = [${MESON_LDFLAGS}]
cpp_link_args = [${MESON_LDFLAGS}]
EOF

	meson setup . .. \
		--cross-file "$CROSS_FILE" \
		--prefix="$PREFIX" \
		--default-library=static \
		--buildtype=release || exit 1

	ninja -j"$(nproc)"
	ninja install

	echo "✔ libudfread built successfully with Meson"
}

build_bluray() {
	echo "[+] Building libbluray for $ARCH..."

	cd "$BUILD_DIR/bluray"

	rm -rf build && mkdir build
	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_CXXFLAGS=$(echo "$CXXFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)

	meson setup build . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Ddefault_library=static \
		-Denable_tools=false \
		-Dfreetype=disabled \
		-Djava9=false \
		-Dfontconfig=disabled \
		-Dlibxml2=disabled \
		-Dbdj_jar=disabled \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
cpp_args = [${S_CXXFLAGS}]
c_link_args = [${S_LDFLAGS}]
cpp_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C build -j"$(nproc)"
	ninja -C build install

	echo "✔ libbluray built successfully"
}

build_libtheora() {
	echo "[+] Building libtheora for $ARCH..."
	cd "$BUILD_DIR/theora"
	(make clean && make distclean) || true
	[ ! -f "configure" ] && autoreconf -fi

	EXTRA_FLAGS=()
	if [ "$ARCH" = "armv7" ]; then
		EXTRA_FLAGS+=(--disable-asm)
	fi

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		--disable-examples \
		--disable-oggtest \
		--disable-vorbistest \
		"${EXTRA_FLAGS[@]}" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"

	make -j"$(nproc)"
	make install

	echo "✔ libtheora built successfully"
}

build_openjpeg() {
	echo " [+] Building OpenJPEG for $ARCH..."

	cd "$BUILD_DIR/openjpeg"
	rm -rf build && mkdir -p build && cd build
	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_STATIC_LIBS=ON \
		-DBUILD_CODEC=OFF \
		-DBUILD_JAVA=OFF \
		-DBUILD_VIEWER=OFF \
		-DBUILD_THIRDPARTY=OFF \
		-DBUILD_TESTING=OFF
	make -j"$(nproc)"
	make install

	echo " OpenJPEG built successfully"
}

build_libwebp() {
	echo "[+] Building libwebp for $ARCH..."
	cd "$BUILD_DIR/libwebp"
	(make clean && make distclean) || true

	./autogen.sh
	./configure \
		--prefix="$PREFIX" \
		--disable-shared \
		--enable-static \
		--host="$HOST" \
		CC="$CC_ABS" \
		CXX="$CXX_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		STRIP="$STRIP_ABS" \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"

	make -j"$(nproc)" && make install
}

build_vmaf() {
	echo "[+] Building libvmaf for $ARCH..."

	TOOLCHAIN_FILE="$BUILD_DIR/vmaf/toolchain-$ARCH.txt"

	cat >"$TOOLCHAIN_FILE" <<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'
ranlib = '$RANLIB_ABS'

[built-in options]
c_args = [$(printf "'%s', " $CFLAGS)]
cpp_args = [$(printf "'%s', " $CXXFLAGS)]
c_link_args = [$(printf "'%s', " $LDFLAGS)]
cpp_link_args = [$(printf "'%s', " $LDFLAGS)]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	cd "$BUILD_DIR/vmaf/libvmaf"
	rm -rf build
	meson setup build \
		--prefix="$PREFIX" \
		--default-library=static \
		--buildtype=release \
		--cross-file="$TOOLCHAIN_FILE"

	ninja -C build -j"$(nproc)"
	ninja -C build install
}

build_libzimg() {
	echo "[+] Building libzimg for $ARCH..."
	cd "$BUILD_DIR/zimg"
	(make clean && make distclean) || true

	./autogen.sh

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS"

	make -j"$(nproc)"
	make install
}

build_libmysofa() {
	echo "[+] Building libmysofa for $ARCH..."
	cd "$BUILD_DIR/libmysofa"
	rm -rf CMakeCache.txt CMakeFiles build
	mkdir -p build && cd build

	cmake .. -G Ninja \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_PREFIX_PATH="$PREFIX" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER="$CC_ABS" \
		-DCMAKE_AR="$AR_ABS" \
		-DCMAKE_RANLIB="$RANLIB_ABS" \
		-DCMAKE_STRIP="$STRIP_ABS" \
		-DCMAKE_C_FLAGS="$CFLAGS" \
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTS=OFF \
		-DMATH='-lm'

	ninja
	ninja install
}

build_vidstab() {
	echo "[+] Building vid.stab for $ARCH..."
	cd "$BUILD_DIR/vid.stab"

	rm -rf CMakeCache.txt CMakeFiles/ cmake_install.cmake build.ninja .ninja_deps .ninja_log

	echo "Using AR: $AR_ABS"

	cmake . -G Ninja \
		-DCMAKE_POLICY_DEFAULT_CMP0091=NEW \
		-DCMAKE_BUILD_TYPE=Release \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_SHARED=OFF \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-DENABLE_STATIC=ON

	ninja -v
	ninja install
}

build_soxr() {
	echo "[+] Building soxr for $ARCH..."
	cd "$BUILD_DIR/soxr"

	rm -rf build

	cmake -B build -G Ninja . \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_SYSTEM_NAME=Linux \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DWITH_OPENMP=OFF \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-Wno-dev

	cmake --build build
	cmake --install build

	PC_DIR="$PREFIX/lib/pkgconfig"
	PC_FILE="$PC_DIR/soxr.pc"

	if [ ! -f "$PC_FILE" ]; then
		echo "Generating soxr.pc..."
		mkdir -p "$PC_DIR"
		cat >"$PC_FILE" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: soxr
Description: High quality, one-dimensional sample-rate conversion library
Version: 0.1.3
Libs: -L\${libdir} -lsoxr
Cflags: -I\${includedir}
EOF
	fi

	echo "✔ soxr built successfully"
}

build_openmpt() {
	echo "[+] Building openmpt for $ARCH..."
	cd "$BUILD_DIR/openmpt"
	(make clean && make distclean) || true

	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--enable-static \
		--disable-shared \
		--disable-openmpt123 \
		--disable-tests \
		--without-mpg123 \
		--without-ogg \
		--without-vorbis \
		--without-pulseaudio \
		--without-portaudio \
		--without-sndfile \
		--without-flac \
		--without-mpg123 \
		--without-portaudio \
		--without-portaudiocpp \
		CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS"

	make -j"$(nproc)"
	make install
}

build_svtav1() {
	echo "[+] Building SVT-AV1 for $ARCH..."

	cd "$BUILD_DIR/svtav1"

	rm -rf build && mkdir build && cd build

	cmake .. \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DCMAKE_BUILD_TYPE=Release \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_APPS=OFF \
		-DENABLE_NEON_I8MM=OFF

	make -j"$(nproc)"
	make install
}

build_libsrt() {
	echo "[+] Building libsrt for $ARCH..."

	cd "$BUILD_DIR/srt"

	rm -rf build && mkdir build && cd build

	cmake .. \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DCMAKE_BUILD_TYPE=Release \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DENABLE_STATIC=ON \
		-DENABLE_SHARED=OFF \
		-DENABLE_APPS=OFF \
		-DENABLE_CXX=ON

	make -j"$(nproc)"
	make install
}

build_libzmq() {
	echo "[+] Building libzmq (ZeroMQ) for $ARCH..."

	cd "$BUILD_DIR/libzmq"

	rm -rf build && mkdir build && cd build

	cmake .. \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DCMAKE_BUILD_TYPE=Release \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DENABLE_CURVE=OFF \
		-DENABLE_DRAFTS=OFF \
		-DENABLE_SHARED=OFF \
		-DENABLE_STATIC=ON \
		-DBUILD_SHARED=OFF \
		-DBUILD_STATIC=ON \
		-DWITH_LIBSODIUM=OFF \
		-DBUILD_TESTS=OFF \
		-DZMQ_BUILD_TESTS=OFF

	make -j"$(nproc)"
	make install
}

build_libplacebo() {
	echo "[+] Building libplacebo (Meson) for $ARCH..."

	cd "$BUILD_DIR/libplacebo"

	git submodule update --init --recursive

	rm -rf build && mkdir build

	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_CXXFLAGS=$(echo "$CXXFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)

	meson setup build . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Ddefault_library=static \
		-Dtests=false \
		-Dshaderc=disabled \
		-Dvulkan=disabled \
		-Dglslang=disabled \
		-Dopengl=enabled \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
cpp_args = [${S_CXXFLAGS}]
c_link_args = [${S_LDFLAGS}]
cpp_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C build
	ninja -C build install
}

build_librist() {
	echo "[+] Building librist (Meson) for $ARCH..."

	cd "$BUILD_DIR/librist"

	rm -rf build && mkdir build

	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_CXXFLAGS=$(echo "$CXXFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)

	meson setup build . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Ddefault_library=static \
		-Duse_mbedtls=false \
		-Dbuiltin_cjson=true \
		-Dtest=false \
		-Dbuilt_tools=false \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
cpp_args = [${S_CXXFLAGS}]
c_link_args = [${S_LDFLAGS}]
cpp_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C build
	ninja -C build install
}

build_libvo_amrwbenc() {
	echo "[+] Building vo-amrwbenc for $ARCH..."

	cd "$BUILD_DIR/vo-amrwbenc" || exit 1
	(make clean && make distclean) || true
	autoreconf -fi || exit 1

	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS" || exit 1

	make -j"$(nproc)" || exit 1
	make install || exit 1
}

build_opencore_amr() {
	echo "[+] Building opencore-amr for $ARCH..."
	cd "$BUILD_DIR/opencore-amr" || exit 1
	(make distclean && make clean) || true
	[ -f "configure.ac.bak" ] && cp "configure.ac.bak" "configure.ac"
	cp "configure.ac" "configure.bak"
	sed -i '/AC_FUNC_MALLOC/d' configure.ac
	autoreconf -fi || exit 1
	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS" || exit 1
	make -j"$(nproc)" || exit 1
	make install || exit 1
}

build_libilbc() {
	echo "[+] Building libilbc for $ARCH..."
	cd "$BUILD_DIR/libilbc" || exit 1
	rm -rf build
	mkdir build && cd build || exit 1

	cmake .. \
		-DCMAKE_SYSTEM_NAME=Linux \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF || exit 1

	cmake --build . -j"$(nproc)" || exit 1
	cmake --install . || exit 1
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

	make -j"$(nproc)" || exit 1
}

build_libcodec2() {
	echo "[+] Building libcodec2 for $ARCH..."

	cd "$BUILD_DIR/libcodec2" || exit 1

	rm -rf build && mkdir build && cd build

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF \
		-DUNITTEST=FALSE \
		-DGENERATE_CODEBOOK="$BUILD_DIR/libcodec2-native/build/src/generate_codebook"

	make -j"$(nproc)" || exit 1
	make install || exit 1

	PC_DIR="$PREFIX/lib/pkgconfig"
	PC_FILE="$PC_DIR/libcodec2.pc"
	if [ ! -f "$PC_FILE" ]; then
		mkdir -p "$PC_DIR"
		cat >"$PC_FILE" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libcodec2
Description: Low bit rate speech codec
Version: 1.0
Libs: -L\${libdir} -lcodec2
Cflags: -I\${includedir}
EOF
	fi
}

build_aribb24() {
	echo "[+] Building aribb24 for $ARCH..."

	cd "$BUILD_DIR/aribb24" || exit 1

	make distclean >/dev/null 2>&1 || true
	autoreconf -fi || exit 1

	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared \
		CC="$CC" \
		AR="$AR" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		CFLAGS="-static -Os -ffunction-sections -fdata-sections -DNDEBUG" \
		LDFLAGS="-static -Wl,--gc-sections -Wl,--strip-all -Wl,--allow-multiple-definition" || exit 1

	make -j"$(nproc)" || exit 1
	make install || exit 1
}

build_uavs3d() {
	echo "[+] Building uavs3d..."
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
		local CMAKE_FLAGS=("${COMMON_CMAKE_FLAGS[@]}")
		CMAKE_FLAGS+=(-DCMAKE_SYSTEM_PROCESSOR="$ARCH")

		cmake .. \
			"${CMAKE_FLAGS[@]}" \
			-DCMAKE_BUILD_TYPE=Release \
			-DBUILD_SHARED_LIBS=OFF \
			-DCOMPILE_10BIT=OFF
	fi

	cmake --build . --target uavs3d -j"$(nproc)"
	cmake --install . || exit 1
}

build_xvidcore() {
	echo "[+] Building xvidcore..."

	cd "$BUILD_DIR/xvidcore/build/generic" || exit 1
	(make distclean && make clean) || true

	./configure \
		--host="${HOST}" \
		--prefix="$PREFIX" \
		CC="$CC_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		STRIP="$STRIP_ABS" \
		CFLAGS="$CFLAGS" \
		--disable-assembly \
		LDFLAGS="$LDFLAGS" || exit 1

	make -j"$(nproc)" || exit 1
	make install || exit 1

	echo "✔ xvidcore built successfully"
}

build_kvazaar() {
	echo "[+] Building kvazaar..."
	cd "$BUILD_DIR/kvazaar" || exit 1
	[ -f configure.ac.bak ] && cp "configure.ac.bak" "configure.ac"
	cp "configure.ac" "configure.ac.bak"
	sed -i 's/\-lrt//g' configure.ac
	(make clean && make distclean) || true
	autoreconf -fiv
	./configure \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared \
		--host="$HOST"
	make -j"$(nproc)" || exit 1
	make install || exit 1
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

	cd "$BUILD_DIR/rtmpdump/librtmp"
	(make clean && make distclean) || true
	make librtmp.a \
		CC="$CC_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		CFLAGS="$CFLAGS -DUSE_OPENSSL -I$PREFIX/include -I$PREFIX/include/openssl" \
		LDFLAGS="$LDFLAGS" \
		XLIBS="-L$PREFIX/lib -lssl -lcrypto -lz -ldl -lpthread" \
		-j"$(nproc)"

	mkdir -p "$PREFIX/include/librtmp"
	cp "$(pwd)"/*.h "$PREFIX/include/librtmp/"
	mkdir -p "$PREFIX/lib"
	cp "$(pwd)/librtmp.a" "$PREFIX/lib/"

	mkdir -p "$PREFIX/lib/pkgconfig"
	cat >"$PREFIX/lib/pkgconfig/librtmp.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: librtmp
Description: RTMP implementation
Version: 2.4
Requires: openssl zlib
Libs: -L\${libdir} -lrtmp
Libs.private: -lssl -lcrypto -lz -ldl -lpthread
Cflags: -I\${includedir}
EOF
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
}

build_libssh() {
	echo "[+] Building libssh for $ARCH..."
	cd "$BUILD_DIR/libssh"
	grep -q '#define GLOB_TILDE' src/config.c || sed -i '1i#ifndef GLOB_TILDE\n#define GLOB_TILDE 0\n#endif' src/config.c
	grep -q '#define GLOB_TILDE' src/bind_config.c || sed -i '1i#ifndef GLOB_TILDE\n#define GLOB_TILDE 0\n#endif' src/bind_config.c
	grep -q '#define S_IWRITE' src/misc.c || sed -i '1i#ifndef S_IWRITE\n#define S_IWRITE S_IWUSR\n#endif' src/misc.c
	rm -rf build && mkdir build && cd build
	SYSROOT_FLAGS="--sysroot=$SYSROOT"
	cmake .. \
		-DCMAKE_SYSTEM_PROCESSOR="$TARGET" \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DWITH_GSSAPI=OFF \
		-DWITH_EXAMPLES=OFF \
		-DWITH_ZLIB=ON \
		-DHAVE_GLOB_TILDE=OFF \
		-DOPENSSL_ROOT_DIR="$PREFIX" \
		-DOPENSSL_INCLUDE_DIR="$PREFIX/include" \
		-DOPENSSL_LIBRARIES="$PREFIX/lib"
	make -j"$(nproc)"
	make install
}

build_vvenc() {
	cd "$BUILD_DIR/vvenc"
	rm -rf build && mkdir build && cd build

	local simd_flags=()
	local warning_flags=()

	if [[ "$ARCH" == "armv7" ]] || [[ "$ARCH" = "riscv64" ]] || [[ "$ARCH" == "x86" ]]; then
		simd_flags+=(
			-DVVENC_ENABLE_X86_SIMD=OFF
			-DVVENC_ENABLE_ARM_SIMD=OFF
			-DVVENC_ENABLE_ARM_SIMD_SVE=OFF
			-DVVENC_ENABLE_ARM_SIMD_SVE2=OFF
		)
	fi

	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DVVENC_LIBRARY_ONLY=ON \
		-DVVENC_ENABLE_LINK_TIME_OPT=OFF \
		-DCMAKE_SYSTEM_PROCESSOR="${ARCH}" \
		"${simd_flags[@]}" \
		"${warning_flags[@]}"

	cmake --build . --target install -- -j"$(nproc)"
}

build_vapoursynth() {
	cd "$BUILD_DIR/vapoursynth"

	(make clean && make distclean) || true
	rm -rf build && mkdir build

	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_CXXFLAGS=$(echo "$CXXFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)

	ASM_ENABLED=false
	case "$ARCH" in
	x86 | x86_64) ASM_ENABLED=true ;;
	esac

	meson setup build . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Dstatic_build=true \
		-Dcore=true \
		-Dvsscript=false \
		-Dvspipe=false \
		-Dpython_module=false \
		-Dx86_asm=$ASM_ENABLED \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
cpp_args = [${S_CXXFLAGS}]
c_link_args = [${S_LDFLAGS}]
cpp_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'linux'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C build
	ninja -C build install
}

build_libffi() {
	cd "$BUILD_DIR/libffi"
	mkdir -p "build" && cd build
	../configure \
		--prefix="$PREFIX" \
		--disable-shared \
		--enable-static \
		--host="$HOST"
	CFLAGS="$CFLAGS" \
		CXXFLAGS="$CXXFLAGS" \
		LDFLAGS="$LDFLAGS" \
		CC="$CC_ABS" \
		CXX="$CXX_ABS"

	make -j"$(nproc)"
	make install
}

build_pcre2() {
	echo "[+] Building pcre2 for $ARCH....."
	cd "$BUILD_DIR/pcre2"
	rm -rf out && mkdir out && cd out

	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DPCRE2_BUILD_PCRE2_16=OFF \
		-DPCRE2_BUILD_PCRE2_32=OFF \
		-DPCRE2_BUILD_TESTS=OFF \
		-DPCRE2_BUILD_PCRE2GREP=OFF \
		-DPCRE2_BUILD_PCRE2TEST=OFF \
		-DPCRE2_SUPPORT_JIT=OFF \
		-DPCRE2_STATIC_RUNTIME=ON

	make -j"$(nproc)"
	make install
}

build_glib() {
	echo "[+] Building glib (Meson) for $ARCH..."

	cd "$BUILD_DIR/glib" || exit 1

	rm -rf build && mkdir build

	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_CXXFLAGS=$(echo "$CXXFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed "/^$/d; s/.*/'&'/" | paste -sd, -)

	meson setup build . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Ddefault_library=static \
		-Dtests=false \
		-Dintrospection=disabled \
		-Dglib_debug=disabled \
		-Dlibmount=disabled \
		-Dselinux=disabled \
		-Dman-pages=disabled \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
cpp_args = [${S_CXXFLAGS}]
c_link_args = [${S_LDFLAGS}]
cpp_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C build
	ninja -C build install
}

build_lensfun() {
	cd "$BUILD_DIR/lensfun"
	rm -rf build && mkdir build && cd build

	cmake_args=(
		-DCMAKE_INSTALL_PREFIX="$PREFIX"
		-DCMAKE_BUILD_TYPE=RELEASE
		-DBUILD_STATIC=ON
		-DCMAKE_C_COMPILER="$CC_ABS"
		-DCMAKE_CXX_COMPILER="$CXX_ABS"
		-DCMAKE_AR="$AR_ABS"
		-DCMAKE_RANLIB="$RANLIB_ABS"
		-DCMAKE_STRIP="$STRIP_ABS"
		-DCMAKE_C_FLAGS="$CFLAGS"
		-DCMAKE_CXX_FLAGS="$CXXFLAGS"
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS"
		-DLF_ENABLE_PYTHON=OFF
		-DBUILD_LENSTOOL=OFF
		-DINSTALL_PYTHON_MODULE=OFF
		-DINSTALL_HELPER_SCRIPTS=OFF
	)

	case "$ARCH" in
	x86 | x86_64 | i686) ;;
	*)
		cmake_args+=(
			-DBUILD_FOR_SSE=OFF
			-DBUILD_FOR_SSE2=OFF
		)
		;;
	esac

	cmake ../ "${cmake_args[@]}"
	make -j"$(nproc)"
	make install

	[ -f "$PREFIX/include/lensfun/lensfun.h" ] && ln -snf "$PREFIX/include/lensfun/lensfun.h" "$PREFIX/include/lensfun.h"

}

build_flite() {

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

	cat flite_lang_list.c

	cat flite_lang_list.c
	sleep 5

	autoreconf -fvi

	./configure \
		--host=$HOST \
		--prefix="$PREFIX" \
		--disable-shared \
		--with-audio=none \
		CC="$CC_ABS" \
		CFLAGS="$CFLAGS" \
		LDFLAGS="$LDFLAGS" \
		AR="$AR" \
		RANLIB="$RANLIB_ABS" \
		STRIP="$STRIP_ABS"

	make
	make install

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

	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--disable-shared \
		--enable-static \
		CC="$CC_ABS" \
		CXX="$CXX_ABS" \
		AR="$AR_ABS" \
		RANLIB="$RANLIB_ABS" \
		STRIP="$STRIP_ABS"

	sed -i '/^bin_PROGRAMS *=/d' src/Makefile.am
	sed -i '/bs2bconvert/d' src/Makefile.am
	make -j"$(nproc)"
	make install
}

build_libgme() {
	echo "[+] Building libgme for $ARCH..."

	local SRC="$BUILD_DIR/game-music-emu"
	local BUILD="$SRC/build"
	rm -rf "$BUILD"
	mkdir -p "$BUILD"
	cd "$BUILD" || exit 1

	cmake .. \
		-DCMAKE_SYSTEM_NAME=Linux \
		-DCMAKE_SYSTEM_PROCESSOR="$TARGET" \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_BUILD_TYPE=Release

	make -j"$(nproc)"
	make install
}

build_highway() {
	cd "$BUILD_DIR/highway" || exit 1

	[ -f "BUILD" ] && mv "BUILD" "BUILD.bazzle"

	rm -rf build

	cmake -B build -S . \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF \
		-DHWY_ENABLE_CONTRIB=OFF \
		-DHWY_ENABLE_TESTS=OFF

	cmake --build build -j"$(nproc)"
	cmake --install build
}

build_libjxl() {
	cd "$BUILD_DIR/libjxl"

	rm -rf build && mkdir -p build && cd build
	cmake .. \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
		-DJPEGXL_ENABLE_TOOLS=OFF \
		-DJPEGXL_ENABLE_DEVTOOLS=OFF \
		-DJPEGXL_ENABLE_FUZZERS=OFF \
		-DJPEGXL_ENABLE_BENCHMARK=OFF \
		-DJPEGXL_ENABLE_EXAMPLES=OFF \
		-DJPEGXL_ENABLE_VIEWERS=OFF \
		-DJPEGXL_ENABLE_MANPAGES=OFF \
		-DZLIB_LIBRARY="$PREFIX/lib/libz.a" \
		-DZLIB_INCLUDE_DIR="$PREFIX/include" \
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
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_C_COMPILER="$CC_ABS" \
		-DCMAKE_CXX_COMPILER="$CXX_ABS" \
		-DCMAKE_C_FLAGS="$CFLAGS -I$PREFIX/include" \
		-DCMAKE_CXX_FLAGS="$CXXFLAGS -I$PREFIX/include" \
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS -L$PREFIX/lib" \
		-DCMAKE_AR="$AR_ABS" \
		-DCMAKE_RANLIB="$RANLIB_ABS" \
		-DCMAKE_STRIP="$STRIP_ABS" \
		-DCMAKE_ASM_COMPILER="$AS" \
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
		-DJPEGXL_FORCE_SYSTEM_GTEST=OFF
	make -j"$(nproc)"
	make install
}

build_libqrencode() {
	echo "[+] Building libqrencode for $ARCH".....
	cd "$BUILD_DIR/libqrencode"
	rm -rf build && mkdir -p build && cd build
	cmake .. \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DWITH_TOOLS="NO" \
		-DBUILD_SHARED_LIBS="NO" \
		-DZLIB_LIBRARY="$PREFIX/lib/libz.a" \
		-DZLIB_INCLUDE_DIR="$PREFIX/include"

	make -j"$(nproc)"
	make install

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

	cat >"$PREFIX/lib/pkgconfig/quirc.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: quirc
Description: QR-code recognition library
Version: 1.2
Libs: -L\${libdir} -lquirc
Cflags: -I\${includedir}
EOF
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
		CXX="$CXX_ABS" \
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
		--disable-ncurses \
		--disable-vga \
		--disable-win32 \
		--disable-conio \
		--disable-utils \
		--disable-doc \
		--disable-tests \
		--disable-examples \
		--prefix="$PREFIX"

	make -j"$(nproc)"
	make install
}

build_fftw() {
	cd "$BUILD_DIR/fftw"
	echo "[+] Building fftw for $ARCH.........."

	rm -rf build && mkdir -p build && cd build

	cmake .. \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_FLOAT=OFF \
		-DENABLE_LONG_DOUBLE=OFF \
		-DENABLE_THREADS=OFF \
		"${COMMON_CMAKE_FLAGS[@]}"

	make -j"$(nproc)"
	make install
}

build_chromaprint() {
	cd "$BUILD_DIR/chromaprint"
	echo "[+] Building Chromaprint for $ARCH.........."

	rm -rf build && mkdir -p build && cd build

	cmake .. \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TOOLS=OFF \
		-DBUILD_TESTS=OFF \
		-DFFT_LIB=fftw3 \
		-DCMAKE_PREFIX_PATH="$PREFIX" \
		\
		"${COMMON_CMAKE_FLAGS[@]}"

	make -j"$(nproc)"
	make install
}

build_lcms() {
	echo "[+] [+] Building Little CMS for $ARCH..."

	cd "$BUILD_DIR/Little-CMS" || exit 1

	(make clean && make distclean) || true

	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--disable-shared \
		--enable-static \
		--without-jpeg \
		--without-tiff \
		--without-zlib

	make -j"$(nproc)"
	make install
}

build_avisynth() {
	cd "$BUILD_DIR/AviSynthPlus"
	rm -rf build
	mkdir -p build && cd build

	case "$ARCH" in
	x86 | x86_64)
		SIMD_OPTION=ON
		;;
	*)
		SIMD_OPTION=OFF
		;;
	esac

	cmake ../ \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_PROCESSOR="$ARCH" \
		-DENABLE_PLUGINS=OFF \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		-DCMAKE_CXX_COMPILER="$CXX_ABS" \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_INTEL_SIMD="$SIMD_OPTION"

	make -j$(nproc)
	make install
}

build_fribidi() {
	echo "[+] Building FriBidi for $ARCH..."

	cd "$BUILD_DIR/fribidi" || exit 1
	rm -rf build && mkdir build

	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed '/^$/d; s/.*/'"'"'&'"'"'/' | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed '/^$/d; s/.*/'"'"'&'"'"'/' | paste -sd, -)

	meson setup build . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Ddefault_library=static \
		-Dbin=false \
		-Ddocs=false \
		-Dtests=false \
		-Ddeprecated=false \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
c_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C build -j"$(nproc)"
	ninja -C build install
}

build_liblc3() {
	cd "$BUILD_DIR/liblc3"
	rm -rf build && mkdir build

	S_CFLAGS=$(echo "$CFLAGS" | xargs -n1 | sed '/^$/d; s/.*/'"'"'&'"'"'/' | paste -sd, -)
	S_LDFLAGS=$(echo "$LDFLAGS" | xargs -n1 | sed '/^$/d; s/.*/'"'"'&'"'"'/' | paste -sd, -)

	meson setup out . \
		--cross-file /dev/fd/63 \
		--prefix="$PREFIX" \
		--buildtype=release \
		-Ddefault_library=static \
		-Dtools=false \
		-Dpython=false \
		63<<EOF
[binaries]
c = '$CC_ABS'
cpp = '$CXX_ABS'
ar = '$AR_ABS'
nm = '$NM_ABS'
strip = '$STRIP_ABS'
pkg-config = 'pkg-config'

[built-in options]
c_args = [${S_CFLAGS}]
c_link_args = [${S_LDFLAGS}]

[host_machine]
system = 'android'
cpu_family = '${ARCH}'
cpu = '${ARCH}'
endian = 'little'
EOF

	ninja -C out
	ninja -C out install
}

build_lcevcdec() {
	echo "[+] Building LCEVCdec for $ARCH..."

	cd "$BUILD_DIR/LCEVCdec" || exit 1
	rm -rf out
	mkdir out && cd out || exit 1

	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		\
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DVN_SDK_EXECUTABLES=OFF \
		-DVN_SDK_UNIT_TESTS=OFF \
		-DVN_SDK_BENCHMARK=OFF \
		-DVN_SDK_DOCS=OFF

	make -j"$(nproc)" || exit 1
	make install || exit 1

	PC_FILE="$PREFIX/lib/pkgconfig/lcevc_dec.pc"
	if [ -f "$PC_FILE" ]; then
		VERSION_LINE=$(grep -E '^Version:' "$PC_FILE")
		if [ -z "$(echo "$VERSION_LINE" | cut -d' ' -f2)" ]; then
			echo "[*] lcevc_dec.pc has no version, adding 4.0.1"
			sed -i 's/^Version:.*/Version: 5.0.1/' "$PC_FILE"
		fi
	fi
}

build_xeve() {
	echo "[+] Building XEVE for $ARCH..."
	echo "v0.5.1" >"$BUILD_DIR/xeve/version.txt"
	cd "$BUILD_DIR/xeve" || exit 1
	rm -rf out
	mkdir out && cd out || exit 1

	ARM_FLAG=FALSE
	case "$ARCH" in
	aarch64) ARM_FLAG=TRUE ;;
	esac

	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		\
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DSET_PROF=MAIN \
		-DARM="$ARM_FLAG"

	make -j"$(nproc)" || exit 1
	make install || exit 1

	if [ ! -e "$PREFIX/lib/libxeve.a" ]; then
		if [ -f "$PREFIX/lib/xeve/libxeve.a" ]; then
			ln -s "$PREFIX/lib/xeve/libxeve.a" "$PREFIX/lib/libxeve.a"
		fi
	fi
}

build_xevd() {
	cd "$BUILD_DIR/xevd" || exit 1

	if [ ! -f "version.txt" ]; then
		echo "v0.5.1" >version.txt
	fi

	rm -rf out && mkdir -p out && cd out || exit 1

	ARM_FLAG=FALSE
	case "$ARCH" in
	armv7 | aarch64) ARM_FLAG=TRUE ;;
	esac

	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		\
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DSET_PROF=MAIN \
		-DARM="$ARM_FLAG"

	make -j"$(nproc)"
	make install

	if [ ! -e "$PREFIX/lib/libxevd.a" ]; then
		if [ -f "$PREFIX/lib/xevd/libxevd.a" ]; then
			ln -s "$PREFIX/lib/xevd/libxevd.a" "$PREFIX/lib/libxevd.a"
		fi
	fi
}

build_xavs2() {
	cd "$BUILD_DIR/xavs2/build/linux"

	ASMMM=""

	case "$ARCH" in
	x86_64) ;;
	x86 | armv7 | aarch64 | riscv64)
		ASMMM="--disable-asm"
		;;
	esac
	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--disable-cli \
		--enable-static \
		--enable-strip \
		--enable-pic \
		"${ASMMM}" \
		--extra-cflags="$CFLAGS" \
		--extra-ldflags="$LDFLAGS"

	make -j$(nproc)
	make install

}

build_davs2() {
	cd "$BUILD_DIR/davs2/build/linux"

	ASMMM=""

	case "$ARCH" in
	x86_64) ;;
	armv7 | x86 | aarch64 | riscv64)
		ASMMM="--disable-asm"
		;;
	esac
	./configure \
		--prefix="$PREFIX" \
		--host="$HOST" \
		--disable-cli \
		--enable-static \
		--enable-strip \
		--enable-pic \
		"${ASMMM}" \
		--extra-cflags="$CFLAGS" \
		--extra-ldflags="$LDFLAGS"

	make -j$(nproc)
	make install
}

build_libmodplug() {
	echo "[+] Building libmodplug for $ARCH..."

	cd "$BUILD_DIR/libmodplug" || exit 1
	rm -rf build && mkdir build && cd build || exit 1

	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		"${COMMON_CMAKE_FLAGS[@]}" \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" \
		\
		-DBUILD_SHARED_LIBS=OFF

	make -j"$(nproc)" || exit 1
	make install || exit 1
}

install_opencl_headers() {
	cd "$BUILD_DIR/OpenCL-Headers" || exit 1
	cmake -S . -B build -DCMAKE_INSTALL_PREFIX="$PREFIX" || exit 1
	cmake --build build --target install || exit 1
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
	cd "$BUILD_DIR/fdk-aac-free"

	(make clean || make distclean) || true

	./configure \
		--host="$HOST" \
		--prefix="$PREFIX" \
		--enable-static \
		--disable-shared

	make -j$(nproc)

	make install
}
