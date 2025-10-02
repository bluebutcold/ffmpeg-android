#!/bin/bash

DOWNLOAD_DIR="${ROOT_DIR}/downloads"
LOCK_FILE="${ROOT_DIR}/git-sources.lock"

# Version definitions
FFMPEG_VERSION="ffmpeg-8.0"
ZLIB_VERSION="zlib-1.3.1"
#BROTLI_VERSION="1.1.0"
BZIP2_VERSION="bzip2-1.0.8"
OPENSSL_VERSION="openssl-3.5.3"
X264_VERSION="x264-master"
X265_VERSION="x265_4.1"
#LIBVPX_VERSION="libvpx-1.15.0"
LAME_VERSION="lame-3.100"
OPUS_VERSION="opus-1.5.2"
VORBIS_VERSION="libvorbis-1.3.7"
OGG_VERSION="libogg-1.3.6"
DAV1D_VERSION="dav1d-master"
LIBASS_VERSION="libass-0.17.4"
LIBPNG_VERSION="libpng-1.6.50"
#FONTCONFIG_VERSION="fontconfig-2.16.0"
FRIBIDI_VERSION="fribidi-1.0.16"
BLURAY_VERSION="libbluray-master"
SPEEX_VERSION="speex-1.2.1"
LIBEXPAT_VERSION="expat-2.7.1"
BUDFREAD_VERSION="libudfread-master"
OPENMPT_VERSION="libopenmpt-0.8.2"
LIBGSM_VERSION="gsm-1.0.22"
TIFF_VERSION="tiff-4.7.0"
XVID_VERSION="xvidcore-1.3.7"
LIBSSH_VERSION="libssh-0.11.0"
XZ_VERSION="xz-5.8.1"
ZSTD_VERSION="zstd-1.5.7"
LIBBS2B_VERSION="libbs2b-3.1.0"
SVTAV1_VERSION="SVT-AV1-v3.1.0"
FFTW_VERSION="fftw-3.3.10"
LIBFFI_VERSION="libffi-3.5.2"
NCURSES_VERSION="ncurses-6.5"
LZO_VERSION="lzo-2.10"
ICONV_VERSION="libiconv-1.18"

# URL definitions for direct downloads
ICONV_URL="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.18.tar.gz"
FFMPEG_URL="https://ffmpeg.org/releases/${FFMPEG_VERSION}.tar.xz"
ZLIB_URL="https://zlib.net/${ZLIB_VERSION}.tar.gz"
LZO_URL="https://www.oberhumer.com/opensource/lzo/download/${LZO_VERSION}.tar.gz"
XZ_URL="https://github.com/tukaani-project/xz/releases/download/v5.8.1/${XZ_VERSION}.tar.gz"
OPENSSL_URL="https://github.com/openssl/openssl/releases/download/${OPENSSL_VERSION}/${OPENSSL_VERSION}.tar.gz"
LAME_URL="https://sourceforge.net/projects/lame/files/lame/3.100/${LAME_VERSION}.tar.gz/download"
OPUS_URL="https://github.com/xiph/opus/releases/download/v1.5.2/${OPUS_VERSION}.tar.gz"
VORBIS_URL="https://downloads.xiph.org/releases/vorbis/${VORBIS_VERSION}.tar.xz"
OGG_URL="https://downloads.xiph.org/releases/ogg/${OGG_VERSION}.tar.gz"
LIBASS_URL="https://github.com/libass/libass/releases/download/0.17.4/${LIBASS_VERSION}.tar.gz"
LIBPNG_URL="https://download.sourceforge.net/libpng/${LIBPNG_VERSION}.tar.gz"
FRIBIDI_URL="https://github.com/fribidi/fribidi/releases/download/v1.0.16/${FRIBIDI_VERSION}.tar.xz"
SPEEX_URL="http://downloads.xiph.org/releases/speex/${SPEEX_VERSION}.tar.gz"
LIBEXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_2_7_1/${LIBEXPAT_VERSION}.tar.gz"
OPENMPT_URL="https://lib.openmpt.org/files/libopenmpt/src/${OPENMPT_VERSION}+release.autotools.tar.gz"
LIBGSM_URL="https://www.quut.com/gsm/${LIBGSM_VERSION}.tar.gz"
XVID_URL="https://downloads.xvid.com/downloads/${XVID_VERSION}.tar.gz"
LIBSSH_URL="https://www.libssh.org/files/0.11/${LIBSSH_VERSION}.tar.xz"
LIBBS2B_URL="https://sourceforge.net/projects/bs2b/files/libbs2b/3.1.0/${LIBBS2B_VERSION}.tar.gz/download"
FFTW_URL="https://www.fftw.org/${FFTW_VERSION}.tar.gz"
LIBFFI_URL="https://github.com/libffi/libffi/releases/download/v3.5.2/${LIBFFI_VERSION}.tar.gz"
NCURSES_URL="https://ftp.gnu.org/gnu/ncurses/${NCURSES_VERSION}.tar.gz"

# GitHub repos that will be cloned with --depth 1
declare -A GITHUB_REPOS=(
	["freetype"]="https://github.com/freetype/freetype.git"
	["Little-CMS"]="https://github.com/mm2/Little-CMS.git"
	["openjpeg"]="https://github.com/uclouvain/openjpeg.git"
	#["libunwind"]="https://github.com/libunwind/libunwind.git"
	["vmaf"]="https://github.com/Netflix/vmaf.git"
	["vid.stab"]="https://github.com/georgmartius/vid.stab.git"
	["rubberband"]="https://github.com/breakfastquay/rubberband.git"
	["soxr"]="https://github.com/chirlu/soxr.git"
	["libmysofa"]="https://github.com/hoene/libmysofa.git"
	["srt"]="https://github.com/Haivision/srt.git"
	["libzmq"]="https://github.com/zeromq/libzmq.git"
	["pcre2"]="https://github.com/PCRE2Project/pcre2.git"
	#["rav1e"]="https://github.com/xiph/rav1e.git"
	["vo-amrwbenc"]="https://github.com/mstorsjo/vo-amrwbenc.git"
	["opencore-amr"]="https://github.com/BelledonneCommunications/opencore-amr.git"
	["twolame"]="https://github.com/njh/twolame.git"
	["libcodec2"]="https://github.com/rhythmcache/codec2.git"
	["aribb24"]="https://github.com/nkoriyama/aribb24.git"
	["uavs3d"]="https://github.com/uavs3/uavs3d.git"
	["vvenc"]="https://github.com/fraunhoferhhi/vvenc.git"
	["vapoursynth"]="https://github.com/rhythmcache/vapoursynth.git"
	["lensfun"]="https://github.com/lensfun/lensfun.git"
	["game-music-emu"]="https://github.com/libgme/game-music-emu.git"
	["highway"]="https://github.com/google/highway.git"
	["libqrencode"]="https://github.com/fukuchi/libqrencode.git"
	["quirc"]="https://github.com/dlbeer/quirc.git"
	["chromaprint"]="https://github.com/acoustid/chromaprint.git"
	["libcaca"]="https://github.com/cacalabs/libcaca.git"
	["flite"]="https://github.com/festvox/flite.git"
	["LCEVCdec"]="https://github.com/v-novaltd/LCEVCdec.git"
	["liblc3"]="https://github.com/google/liblc3.git"
	["xeve"]="https://github.com/mpeg5/xeve.git"
	["xevd"]="https://github.com/mpeg5/xevd.git"
	["xavs2"]="https://github.com/rhythmcache/xavs2.git"
	["davs2"]="https://github.com/pkuvcl/davs2.git"
	["libmodplug"]="https://github.com/Konstanty/libmodplug.git"
	["OpenCL-Headers"]="https://github.com/KhronosGroup/OpenCL-Headers.git"
	["ocl-icd"]="https://github.com/OCL-dev/ocl-icd.git"
    ["libxml2"]="https://github.com/GNOME/libxml2.git"
	["harfbuzz"]="https://github.com/harfbuzz/harfbuzz.git"
	["theora"]="https://github.com/xiph/theora.git"
	["lz4"]="https://github.com/lz4/lz4.git"
	["zstd"]="https://github.com/facebook/zstd.git"
	["snappy"]="https://github.com/google/snappy.git"
	["shine"]="https://github.com/toots/shine.git"
	["zvbi"]="https://github.com/zapping-vbi/zvbi.git"
	["libklvanc"]="https://github.com/stoth68000/libklvanc.git"
    ["brotli"]="https://github.com/google/brotli.git"
    ["bzip2"]="https://gitlab.com/federicomenaquintero/bzip2.git"
    ["x264"]="https://code.videolan.org/videolan/x264.git"
    ["x265"]="https://bitbucket.org/multicoreware/x265_git.git"
    ["dav1d"]="https://code.videolan.org/videolan/dav1d.git"
    ["budfread"]="https://code.videolan.org/videolan/libudfread.git"
    ["bluray"]="https://code.videolan.org/videolan/libbluray.git"
    ["svtav1"]="https://gitlab.com/AOMediaCodec/SVT-AV1.git"
	["FFmpeg"]="https://github.com/FFmpeg/FFmpeg.git"
)

# GitHub repos that need recursive cloning
declare -A GITHUB_RECURSIVE_REPOS=(
	["zimg"]="https://github.com/sekrit-twc/zimg.git"
	["libplacebo"]="https://github.com/haasn/libplacebo.git"
	["libilbc"]="https://github.com/TimothyGu/libilbc.git"
	["kvazaar"]="https://github.com/ultravideo/kvazaar.git"
	["libjxl"]="https://github.com/libjxl/libjxl.git"
	["AviSynthPlus"]="https://github.com/AviSynth/AviSynthPlus.git"
	["glib"]="https://github.com/GNOME/glib.git"
)

# Other Git repos
declare -A OTHER_GIT_REPOS=(
	["libvpx"]="https://chromium.googlesource.com/webm/libvpx"
	["libwebp"]="https://chromium.googlesource.com/webm/libwebp"
	["librist"]="https://code.videolan.org/rist/librist"
	["rtmpdump"]="git://git.ffmpeg.org/rtmpdump"
	["aom"]="https://aomedia.googlesource.com/aom"
	["pixman"]="https://gitlab.freedesktop.org/pixman/pixman.git"
	["cairo"]="https://gitlab.freedesktop.org/cairo/cairo.git"
	["pango"]="https://gitlab.gnome.org/GNOME/pango.git"
	["gdk-pixbuf"]="https://gitlab.gnome.org/GNOME/gdk-pixbuf.git"
	["librsvg"]="https://gitlab.gnome.org/GNOME/librsvg.git"
	["fontconfig"]="https://gitlab.freedesktop.org/fontconfig/fontconfig.git"
)

# Extra files
declare -A EXTRA_FILES=(
	["uavs3d_cmakelists"]="https://raw.githubusercontent.com/rhythmcache/uavs3d/aeaebebed091e8ae9a08bc9f7054273c2e005d27/source/CMakeLists.txt"
	["riscv64_config_sub"]="https://cgit.git.savannah.gnu.org/cgit/config.git/plain/config.sub"
)

# SVN repo
declare -A SVN_REPOS=(
	["xavs"]="https://svn.code.sf.net/p/xavs/code/"
)

PARALLEL_DOWNLOADS=${PARALLEL_DOWNLOADS:-8}

# simple lock file functions
read_lock_file() {
	declare -gA LOCKED_COMMITS
	if [ -f "$LOCK_FILE" ]; then
		echo "Reading lock file: $LOCK_FILE"
		while IFS='=' read -r repo commit; do
			if [ -n "$repo" ] && [ -n "$commit" ] && [[ "$commit" =~ ^[a-f0-9]{40}$ ]]; then
				LOCKED_COMMITS["$repo"]="$commit"
			fi
		done <"$LOCK_FILE"
	fi
}

write_lock_entry() {
	local repo_name="$1"
	local commit="$2"
	echo "${repo_name}=${commit}" >>"$LOCK_FILE"
}

# Function to download a single file
download_file() {
	local url="$1"
	local output="$2"

	if [ ! -f "$output" ]; then
		echo "Downloading: $output"
		if ! curl -L --fail --retry 3 --retry-delay 2 "$url" -o "$output"; then
			echo "Failed to download: $output"
			return 1
		fi
	else
		echo "Already exists: $output"
	fi
	return 0
}

clone_repo_with_lock() {
	local repo_name="$1"
	local repo_url="$2"
	local recursive="$3"

	if [ -d "$repo_name" ]; then
		echo "Already exists: $repo_name"
		return 0
	fi

	local locked_commit="${LOCKED_COMMITS[$repo_name]}"

	if [ -n "$locked_commit" ]; then
		echo "Cloning $repo_name (locked to $locked_commit)"
		if [ "$recursive" = "true" ]; then
			git clone --recursive "$repo_url" "$repo_name"
		else
			git clone "$repo_url" "$repo_name"
		fi

		(cd "$repo_name" && git checkout "$locked_commit")
		if [ $? -ne 0 ]; then
			echo "Warning: Failed to checkout commit $locked_commit for $repo_name, using HEAD"
		fi
	else
		echo "Cloning $repo_name (latest)"
		if [ "$repo_name" = "AviSynthPlus" ]; then
			git clone --recursive "$repo_url" "$repo_name"
		else
			if [ "$recursive" = "true" ]; then
				git clone --depth 1 --recursive "$repo_url" "$repo_name"
			else
				git clone --depth 1 "$repo_url" "$repo_name"
			fi

			local current_commit
			current_commit=$(cd "$repo_name" && git rev-parse HEAD 2>/dev/null || echo "")
			if [ -n "$current_commit" ]; then
				write_lock_entry "$repo_name" "$current_commit"
				echo "Locked $repo_name to commit: $current_commit"
			fi
		fi
	fi
}

download_sources() {
	mkdir -p "$DOWNLOAD_DIR"
	read_lock_file

	cd "$DOWNLOAD_DIR" || exit 1
	echo "Downloading source archives..."
	{
		download_file "$ZLIB_URL" "zlib.tar.gz" &
		download_file "$XZ_URL" "xz.tar.gz" &
		download_file "$OPENSSL_URL" "openssl.tar.gz" &
		download_file "$LIBGSM_URL" "libgsm.tar.gz" &
		download_file "$LAME_URL" "lame.tar.gz" &
		download_file "$OPUS_URL" "opus.tar.gz" &
		download_file "$VORBIS_URL" "vorbis.tar.xz" &
		download_file "$OGG_URL" "ogg.tar.gz" &
		wait

        download_file "$LIBASS_URL" "libass.tar.gz" &
		download_file "$LIBPNG_URL" "libpng.tar.gz" &
		download_file "$FRIBIDI_URL" "fribidi.tar.xz" &
		download_file "$SPEEX_URL" "speex.tar.gz" &
		download_file "$LIBEXPAT_URL" "libexpat.tar.gz" &
		download_file "$OPENMPT_URL" "openmpt.tar.gz" &
		download_file "$XVID_URL" "xvid.tar.gz" &
		download_file "$LIBSSH_URL" "libssh.tar.xz" &

        wait
		download_file "$LIBBS2B_URL" "libbs2b.tar.gz" &
		download_file "$FFTW_URL" "fftw.tar.gz" &
		download_file "$LIBFFI_URL" "libffi.tar.gz" &
		if [ -z "$LATEST_GIT" ]; then
        download_file "$FFMPEG_URL" "ffmpeg.tar.xz" &
        fi
		download_file "$NCURSES_URL" "ncurses.tar.gz" &
		download_file "$LZO_URL" "lzo.tar.gz" &
		download_file "$ICONV_URL" iconv.tar.gz &
		wait

		download_file "${EXTRA_FILES[uavs3d_cmakelists]}" "uavs3d_cmakelists.txt" &
		download_file "${EXTRA_FILES[riscv64_config_sub]}" "riscv64_config_sub" &
		wait
	}

	echo "Cloning GitHub repositories..."
	for repo_name in "${!GITHUB_REPOS[@]}"; do
		local repo_url="${GITHUB_REPOS[$repo_name]}"
		clone_repo_with_lock "$repo_name" "$repo_url" "false"
	done

	echo "Cloning GitHub repositories (recursive)..."
	for repo_name in "${!GITHUB_RECURSIVE_REPOS[@]}"; do
		local repo_url="${GITHUB_RECURSIVE_REPOS[$repo_name]}"
		clone_repo_with_lock "$repo_name" "$repo_url" "true"
	done

	echo "Cloning other Git repositories..."
	for repo_name in "${!OTHER_GIT_REPOS[@]}"; do
		local repo_url="${OTHER_GIT_REPOS[$repo_name]}"
		clone_repo_with_lock "$repo_name" "$repo_url" "false"
	done

	echo "Checking out SVN repositories..."
	for repo_name in "${!SVN_REPOS[@]}"; do
		local repo_url="${SVN_REPOS[$repo_name]}"
		if [ ! -d "$repo_name" ]; then
			echo "SVN checkout: $repo_name"
			svn checkout "$repo_url" "$repo_name"
		fi
	done

	rm -f "${LOCK_FILE}.lock"

	echo "All downloads completed to: $DOWNLOAD_DIR"
	if [ -f "$LOCK_FILE" ]; then
		echo "Lock file created/used: $LOCK_FILE"
	fi
}

prepare_sources() {
	local arch_build_dir="${BUILD_DIR}"
	mkdir -p "$arch_build_dir"
	cd "$arch_build_dir" || exit 1
	[ ! -d zlib ] && tar -xf "${DOWNLOAD_DIR}/zlib.tar.gz" && mv "$ZLIB_VERSION" zlib
	[ ! -d xz ] && tar -xf "${DOWNLOAD_DIR}/xz.tar.gz" && mv "$XZ_VERSION" xz
	[ ! -d openssl ] && tar -xf "${DOWNLOAD_DIR}/openssl.tar.gz" && mv "$OPENSSL_VERSION" openssl
	[ ! -d lame ] && tar -xf "${DOWNLOAD_DIR}/lame.tar.gz" && mv "$LAME_VERSION" lame
	[ ! -d libpng ] && tar -xf "${DOWNLOAD_DIR}/libpng.tar.gz" && mv "$LIBPNG_VERSION" libpng
	[ ! -d opus ] && tar -xf "${DOWNLOAD_DIR}/opus.tar.gz" && mv "$OPUS_VERSION" opus
	[ ! -d vorbis ] && tar -xf "${DOWNLOAD_DIR}/vorbis.tar.xz" && mv "$VORBIS_VERSION" vorbis
	[ ! -d ogg ] && tar -xf "${DOWNLOAD_DIR}/ogg.tar.gz" && mv "$OGG_VERSION" ogg
	[ ! -d libass ] && tar -xf "${DOWNLOAD_DIR}/libass.tar.gz" && mv "$LIBASS_VERSION" libass
	[ ! -d fribidi ] && tar -xf "${DOWNLOAD_DIR}/fribidi.tar.xz" && mv "$FRIBIDI_VERSION" fribidi
	[ ! -d speex ] && tar -xf "${DOWNLOAD_DIR}/speex.tar.gz" && mv "$SPEEX_VERSION" speex
	[ ! -d libexpat ] && tar -xf "${DOWNLOAD_DIR}/libexpat.tar.gz" && mv "$LIBEXPAT_VERSION" libexpat
	[ ! -d openmpt ] && tar -xf "${DOWNLOAD_DIR}/openmpt.tar.gz" && mv "$OPENMPT_VERSION"* openmpt
	[ ! -d libgsm ] && tar -xf "${DOWNLOAD_DIR}/libgsm.tar.gz" && mv gsm* libgsm
	[ ! -d libssh ] && tar -xf "${DOWNLOAD_DIR}/libssh.tar.xz" && mv "$LIBSSH_VERSION" libssh
	[ ! -d xvidcore ] && tar -xf "${DOWNLOAD_DIR}/xvid.tar.gz"
	[ ! -d libbs2b ] && tar -xf "${DOWNLOAD_DIR}/libbs2b.tar.gz" && mv "$LIBBS2B_VERSION" libbs2b
	[ ! -d fftw ] && tar -xf "${DOWNLOAD_DIR}/fftw.tar.gz" && mv "$FFTW_VERSION" fftw
	[ ! -d libffi ] && tar -xf "${DOWNLOAD_DIR}/libffi.tar.gz" && mv "$LIBFFI_VERSION" libffi
	[ ! -d ncurses ] && tar -xf "${DOWNLOAD_DIR}/ncurses.tar.gz" && mv "$NCURSES_VERSION" ncurses
	[ ! -d lzo ] && tar -xf "${DOWNLOAD_DIR}/lzo.tar.gz" && mv "$LZO_VERSION" lzo
	[ ! -d iconv ] && tar -xf "${DOWNLOAD_DIR}/iconv.tar.gz" && mv "$ICONV_VERSION" iconv
	
    if [ -z "$LATEST_GIT" ]; then
    [ ! -d FFmpeg ] && tar -xf "${DOWNLOAD_DIR}/ffmpeg.tar.xz" && mv "$FFMPEG_VERSION" FFmpeg
    else     
    [ ! -d FFmpeg ] && [ -d "${DOWNLOAD_DIR}/FFmpeg" ] && cp -r "${DOWNLOAD_DIR}/FFmpeg" . 
    fi

	
	for repo_name in "${!GITHUB_REPOS[@]}"; do
		[ ! -d "$repo_name" ] && [ -d "${DOWNLOAD_DIR}/$repo_name" ] && cp -r "${DOWNLOAD_DIR}/$repo_name" .
	done

	for repo_name in "${!GITHUB_RECURSIVE_REPOS[@]}"; do
		[ ! -d "$repo_name" ] && [ -d "${DOWNLOAD_DIR}/$repo_name" ] && cp -r "${DOWNLOAD_DIR}/$repo_name" .
	done

	for repo_name in "${!OTHER_GIT_REPOS[@]}"; do
		[ ! -d "$repo_name" ] && [ -d "${DOWNLOAD_DIR}/$repo_name" ] && cp -r "${DOWNLOAD_DIR}/$repo_name" .
	done

	for repo_name in "${!SVN_REPOS[@]}"; do
		[ ! -d "$repo_name" ] && [ -d "${DOWNLOAD_DIR}/$repo_name" ] && cp -r "${DOWNLOAD_DIR}/$repo_name" .
	done

	echo "Sources prepared for architecture: $arch in $arch_build_dir"
}

apply_extra_setup() {
	local arch_build_dir="${BUILD_DIR}"

	if [ -d "$arch_build_dir/uavs3d" ] && [ -f "${DOWNLOAD_DIR}/uavs3d_cmakelists.txt" ]; then
		cp "${DOWNLOAD_DIR}/uavs3d_cmakelists.txt" "$arch_build_dir/uavs3d/source/CMakeLists.txt"
	fi

	if [ "$ARCH" = "riscv64" ] && [ -d "$arch_build_dir/xvidcore" ] && [ -f "${DOWNLOAD_DIR}/riscv64_config_sub" ]; then
		cp "${DOWNLOAD_DIR}/riscv64_config_sub" "$arch_build_dir/xvidcore/build/generic/config.sub"
	fi

	if [ "$ARCH" = "riscv64" ] && [ -d "$arch_build_dir/xavs" ] && [ -f "${DOWNLOAD_DIR}/riscv64_config_sub" ]; then
		cp "${DOWNLOAD_DIR}/riscv64_config_sub" "$arch_build_dir/xavs/trunk/config.sub"
	fi

	if [ "$ARCH" = "riscv64" ] && [ -d "$arch_build_dir/xavs2" ] && [ -f "${DOWNLOAD_DIR}/riscv64_config_sub" ]; then
		cp "${DOWNLOAD_DIR}/riscv64_config_sub" "$arch_build_dir/xavs2/build/linux/config.sub"
	fi

	if [ "$ARCH" = "riscv64" ] && [ -d "$arch_build_dir/davs2" ] && [ -f "${DOWNLOAD_DIR}/riscv64_config_sub" ]; then
		cp "${DOWNLOAD_DIR}/riscv64_config_sub" "$arch_build_dir/davs2/build/linux/config.sub"
	fi

}
