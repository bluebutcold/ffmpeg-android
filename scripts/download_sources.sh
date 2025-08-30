#!/bin/bash

DOWNLOAD_DIR="${ROOT_DIR}/downloads"
# Version definitions
FFMPEG_VERSION="ffmpeg-8.0"
ZLIB_VERSION="zlib-1.3.1"
BROTLI_VERSION="1.1.0"
BZIP2_VERSION="bzip2-1.0.8"
OPENSSL_VERSION="openssl-3.5.1"
X264_VERSION="x264-master"
X265_VERSION="x265_4.1"
LIBVPX_VERSION="libvpx-1.15.0"
AAC_VERSION="fdk-aac-2.0.3"
LAME_VERSION="lame-3.100"
OPUS_VERSION="opus-1.5.2"
VORBIS_VERSION="libvorbis-1.3.7"
OGG_VERSION="libogg-1.3.6"
DAV1D_VERSION="dav1d-master"
LIBASS_VERSION="libass-0.17.4"
LIBPNG_VERSION="libpng-1.6.50"
FONTCONFIG_VERSION="fontconfig-2.16.0"
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

# URL definitions for direct downloads
FFMPEG_URL="https://ffmpeg.org/releases/${FFMPEG_VERSION}.tar.xz"
ZLIB_URL="https://zlib.net/${ZLIB_VERSION}.tar.gz"
BROTLI_URL="https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz"
XZ_URL="https://github.com/tukaani-project/xz/releases/download/v5.8.1/${XZ_VERSION}.tar.gz"
ZSTD_URL="https://github.com/facebook/zstd/releases/download/v1.5.7/${ZSTD_VERSION}.tar.gz"
BZIP2_URL="https://github.com/libarchive/bzip2/archive/refs/tags/${BZIP2_VERSION}.tar.gz"
OPENSSL_URL="https://github.com/openssl/openssl/releases/download/${OPENSSL_VERSION}/${OPENSSL_VERSION}.tar.gz"
X264_URL="https://code.videolan.org/videolan/x264/-/archive/master/${X264_VERSION}.tar.gz"
X265_URL="http://ftp.videolan.org/pub/videolan/x265/${X265_VERSION}.tar.gz"
AAC_URL="https://downloads.sourceforge.net/opencore-amr/${AAC_VERSION}.tar.gz"
LAME_URL="https://sourceforge.net/projects/lame/files/lame/3.100/${LAME_VERSION}.tar.gz/download"
OPUS_URL="https://github.com/xiph/opus/releases/download/v1.5.2/${OPUS_VERSION}.tar.gz"
VORBIS_URL="https://downloads.xiph.org/releases/vorbis/${VORBIS_VERSION}.tar.xz"
OGG_URL="https://downloads.xiph.org/releases/ogg/${OGG_VERSION}.tar.gz"
DAV1D_URL="https://code.videolan.org/videolan/dav1d/-/archive/master/${DAV1D_VERSION}.tar.gz"
LIBASS_URL="https://github.com/libass/libass/releases/download/0.17.4/${LIBASS_VERSION}.tar.gz"
LIBPNG_URL="https://download.sourceforge.net/libpng/${LIBPNG_VERSION}.tar.gz"
FONTCONFIG_URL="https://www.freedesktop.org/software/fontconfig/release/${FONTCONFIG_VERSION}.tar.xz"
FRIBIDI_URL="https://github.com/fribidi/fribidi/releases/download/v1.0.16/${FRIBIDI_VERSION}.tar.xz"
BLURAY_URL="https://code.videolan.org/videolan/libbluray/-/archive/master/${BLURAY_VERSION}.tar.gz"
SPEEX_URL="http://downloads.xiph.org/releases/speex/${SPEEX_VERSION}.tar.gz"
LIBEXPAT_URL="https://github.com/libexpat/libexpat/releases/download/R_2_7_1/${LIBEXPAT_VERSION}.tar.gz"
BUDFREAD_URL="https://code.videolan.org/videolan/libudfread/-/archive/master/${BUDFREAD_VERSION}.tar.gz"
OPENMPT_URL="https://lib.openmpt.org/files/libopenmpt/src/${OPENMPT_VERSION}+release.autotools.tar.gz"
LIBGSM_URL="https://www.quut.com/gsm/${LIBGSM_VERSION}.tar.gz"
XVID_URL="https://downloads.xvid.com/downloads/${XVID_VERSION}.tar.gz"
LIBSSH_URL="https://www.libssh.org/files/0.11/${LIBSSH_VERSION}.tar.xz"
LIBBS2B_URL="https://sourceforge.net/projects/bs2b/files/libbs2b/3.1.0/${LIBBS2B_VERSION}.tar.gz/download"
FFTW_URL="https://www.fftw.org/${FFTW_VERSION}.tar.gz"
LIBFFI_URL="https://github.com/libffi/libffi/releases/download/v3.5.2/${LIBFFI_VERSION}.tar.gz"
SVTAV1_URL="https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v3.1.0/${SVTAV1_VERSION}.tar.gz"

# GitHub repos that can be downloaded as zip
declare -A GITHUB_REPOS=(
    ["freetype"]="freetype/freetype"
    ["Little-CMS"]="mm2/Little-CMS"
    ["openjpeg"]="uclouvain/openjpeg"
    ["libunwind"]="libunwind/libunwind"
    ["vmaf"]="Netflix/vmaf"
    ["vid.stab"]="georgmartius/vid.stab"
    ["rubberband"]="breakfastquay/rubberband"
    ["soxr"]="chirlu/soxr"
    ["libmysofa"]="hoene/libmysofa"
    ["srt"]="Haivision/srt"
    ["libzmq"]="zeromq/libzmq"
    ["pcre2"]="PCRE2Project/pcre2"
    ["rav1e"]="xiph/rav1e"
    ["vo-amrwbenc"]="mstorsjo/vo-amrwbenc"
    ["opencore-amr"]="BelledonneCommunications/opencore-amr"
    ["twolame"]="njh/twolame"
    ["libcodec2"]="rhythmcache/codec2"
    ["aribb24"]="nkoriyama/aribb24"
    ["uavs3d"]="uavs3/uavs3d"
    ["vvenc"]="fraunhoferhhi/vvenc"
    ["vapoursynth"]="rhythmcache/vapoursynth"
    ["lensfun"]="lensfun/lensfun"
    ["game-music-emu"]="libgme/game-music-emu"
    ["highway"]="google/highway"
    ["libqrencode"]="fukuchi/libqrencode"
    ["quirc"]="dlbeer/quirc"
    ["chromaprint"]="acoustid/chromaprint"
    ["libcaca"]="cacalabs/libcaca"
    ["flite"]="festvox/flite"
    ["LCEVCdec"]="v-novaltd/LCEVCdec"
    ["liblc3"]="google/liblc3"
    ["xeve"]="mpeg5/xeve"
    ["xevd"]="mpeg5/xevd"
    ["xavs2"]="rhythmcache/xavs2"
    ["davs2"]="pkuvcl/davs2"
    ["libmodplug"]="Konstanty/libmodplug"
    ["OpenCL-Headers"]="KhronosGroup/OpenCL-Headers"
    ["ocl-icd"]="OCL-dev/ocl-icd"
)

# github repos that need recursive cloning 
declare -A GITHUB_RECURSIVE_REPOS=(
    ["zimg"]="sekrit-twc/zimg"
    ["libplacebo"]="haasn/libplacebo"
    ["libilbc"]="TimothyGu/libilbc"
    ["kvazaar"]="ultravideo/kvazaar"
    ["libjxl"]="libjxl/libjxl"
    ["AviSynthPlus"]="AviSynth/AviSynthPlus"
    ["glib"]="GNOME/glib"
)

# Other Git repos
declare -A OTHER_GIT_REPOS=(
    ["libvpx"]="https://chromium.googlesource.com/webm/libvpx"
    ["libxml2"]="https://github.com/GNOME/libxml2.git"
    ["harfbuzz"]="https://github.com/harfbuzz/harfbuzz.git"
    ["theora"]="https://gitlab.xiph.org/xiph/theora.git"
    ["libwebp"]="https://chromium.googlesource.com/webm/libwebp"
    ["librist"]="https://code.videolan.org/rist/librist"
    ["rtmpdump"]="git://git.ffmpeg.org/rtmpdump"
    ["aom"]="https://aomedia.googlesource.com/aom"
)

# Extra files
declare -A EXTRA_FILES=(
    ["uavs3d_cmakelists"]="https://raw.githubusercontent.com/rhythmcache/uavs3d/aeaebebed091e8ae9a08bc9f7054273c2e005d27/source/CMakeLists.txt"
    ["riscv64_config_sub"]="https://cgit.git.savannah.gnu.org/cgit/config.git/plain/config.sub"
)

# SVN repos
declare -A SVN_REPOS=(
    ["xavs"]="https://svn.code.sf.net/p/xavs/code/"
)

PARALLEL_DOWNLOADS=${PARALLEL_DOWNLOADS:-8}

# Get default branch for GitHub repo
get_github_default_branch() {
    local repo="$1"
    local api_url="https://api.github.com/repos/$repo"
    
    # Try to get default branch, fallback to 'main' or 'master'
    local branch
    branch=$(curl -s "$api_url" 2>/dev/null | grep '"default_branch"' | head -1 | sed 's/.*"default_branch": *"\([^"]*\)".*/\1/')
    
    if [ -z "$branch" ] || [ "$branch" = "$api_url" ]; then
        # Fallback logic - test which branch exists
        if curl -s -f -I "https://github.com/$repo/archive/refs/heads/main.zip" >/dev/null 2>&1; then
            branch="main"
        elif curl -s -f -I "https://github.com/$repo/archive/refs/heads/master.zip" >/dev/null 2>&1; then
            branch="master"
        else
            # Default fallback
            branch="main"
        fi
    fi
    
    echo "$branch"
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

download_sources() {
    mkdir -p "$DOWNLOAD_DIR"
    
    cd "$DOWNLOAD_DIR" || exit 1

    # Download tarballs in parallel using background processes
    {
        download_file "$ZLIB_URL" "zlib.tar.gz" &
        download_file "$BROTLI_URL" "brotli.tar.gz" &
        download_file "$XZ_URL" "xz.tar.gz" &
        download_file "$ZSTD_URL" "zstd.tar.gz" &
        download_file "$BZIP2_URL" "bzip2.tar.gz" &
        download_file "$OPENSSL_URL" "openssl.tar.gz" &
        download_file "$X264_URL" "x264.tar.gz" &
        download_file "$X265_URL" "x265.tar.gz" &
        wait
        
        download_file "$AAC_URL" "aac.tar.gz" &
        download_file "$LIBGSM_URL" "libgsm.tar.gz" &
        download_file "$LAME_URL" "lame.tar.gz" &
        download_file "$OPUS_URL" "opus.tar.gz" &
        download_file "$VORBIS_URL" "vorbis.tar.xz" &
        download_file "$OGG_URL" "ogg.tar.gz" &
        download_file "$DAV1D_URL" "dav1d.tar.gz" &
        download_file "$LIBASS_URL" "libass.tar.gz" &
        wait
        
        download_file "$LIBPNG_URL" "libpng.tar.gz" &
        download_file "$FONTCONFIG_URL" "fontconfig.tar.xz" &
        download_file "$FRIBIDI_URL" "fribidi.tar.xz" &
        download_file "$BLURAY_URL" "bluray.tar.gz" &
        download_file "$SPEEX_URL" "speex.tar.gz" &
        download_file "$LIBEXPAT_URL" "libexpat.tar.gz" &
        download_file "$BUDFREAD_URL" "budfread.tar.gz" &
        download_file "$OPENMPT_URL" "openmpt.tar.gz" &
        wait
        
        download_file "$XVID_URL" "xvid.tar.gz" &
        download_file "$LIBSSH_URL" "libssh.tar.xz" &
        download_file "$LIBBS2B_URL" "libbs2b.tar.gz" &
        download_file "$SVTAV1_URL" "svtav1.tar.gz" &
        download_file "$FFTW_URL" "fftw.tar.gz" &
        download_file "$LIBFFI_URL" "libffi.tar.gz" &
        download_file "$FFMPEG_URL" "ffmpeg.tar.xz" &
        wait
        
        # Download extra files
        download_file "${EXTRA_FILES[uavs3d_cmakelists]}" "uavs3d_cmakelists.txt" &
        download_file "${EXTRA_FILES[riscv64_config_sub]}" "riscv64_config_sub" &
        wait
    }

    # Download GitHub repos as ZIP archives 
    
    {
        for repo_name in "${!GITHUB_REPOS[@]}"; do
            {
                local repo_path="${GITHUB_REPOS[$repo_name]}"
                if [ ! -f "${repo_name}.zip" ]; then
                    local branch
                    branch=$(get_github_default_branch "$repo_path")
                    download_file "https://github.com/$repo_path/archive/refs/heads/$branch.zip" "${repo_name}.zip"
                fi
            } &
            
            # Limit concurrent processes
            (($(jobs -r | wc -l) >= PARALLEL_DOWNLOADS)) && wait
        done
        wait
    }

    # Clone repositories that need special handling
    echo "Cloning repositories that require special handling..."
    {
        for repo_name in "${!GITHUB_RECURSIVE_REPOS[@]}"; do
            {
                local repo_path="${GITHUB_RECURSIVE_REPOS[$repo_name]}"
                if [ ! -d "$repo_name" ]; then
                    echo "Cloning (recursive): $repo_name"
                    git clone --recursive "https://github.com/$repo_path" "$repo_name"
                fi
            } &
            
            # Limit concurrent processes
            (($(jobs -r | wc -l) >= PARALLEL_DOWNLOADS)) && wait
        done
        wait
    }

    # Clone other git repositories
    {
        for repo_name in "${!OTHER_GIT_REPOS[@]}"; do
            {
                local repo_url="${OTHER_GIT_REPOS[$repo_name]}"
                if [ ! -d "$repo_name" ]; then
                    echo "Cloning: $repo_name"
                    git clone --depth 1 "$repo_url" "$repo_name"
                fi
            } &
            
            # Limit concurrent processes  
            (($(jobs -r | wc -l) >= PARALLEL_DOWNLOADS)) && wait
        done
        wait
    }

    # SVN repositories
    for repo_name in "${!SVN_REPOS[@]}"; do
        local repo_url="${SVN_REPOS[$repo_name]}"
        if [ ! -d "$repo_name" ]; then
            echo "SVN checkout: $repo_name"
            svn checkout "$repo_url" "$repo_name"
        fi
    done

    echo "All downloads completed to: $DOWNLOAD_DIR"
}

# Function to prepare sources
prepare_sources() {
    local arch_build_dir="${BUILD_DIR}"
    mkdir -p "$arch_build_dir"
    cd "$arch_build_dir" || exit 1

    [ ! -d zlib ] && tar -xf "${DOWNLOAD_DIR}/zlib.tar.gz" && mv "$ZLIB_VERSION" zlib
    [ ! -d brotli ] && tar -xf "${DOWNLOAD_DIR}/brotli.tar.gz" && mv "brotli-${BROTLI_VERSION}" brotli
    [ ! -d xz ] && tar -xf "${DOWNLOAD_DIR}/xz.tar.gz" && mv "$XZ_VERSION" xz
    [ ! -d zstd ] && tar -xf "${DOWNLOAD_DIR}/zstd.tar.gz" && mv "$ZSTD_VERSION" zstd
    [ ! -d bzip2 ] && tar -xf "${DOWNLOAD_DIR}/bzip2.tar.gz" && mv "bzip2-${BZIP2_VERSION}" bzip2
    [ ! -d openssl ] && tar -xf "${DOWNLOAD_DIR}/openssl.tar.gz" && mv "$OPENSSL_VERSION" openssl
    [ ! -d x264 ] && tar -xf "${DOWNLOAD_DIR}/x264.tar.gz" && mv "$X264_VERSION" x264
    [ ! -d x265 ] && tar -xf "${DOWNLOAD_DIR}/x265.tar.gz" && mv "$X265_VERSION" x265
    [ ! -d aac ] && tar -xf "${DOWNLOAD_DIR}/aac.tar.gz" && mv "$AAC_VERSION" aac
    [ ! -d lame ] && tar -xf "${DOWNLOAD_DIR}/lame.tar.gz" && mv "$LAME_VERSION" lame
    [ ! -d libpng ] && tar -xf "${DOWNLOAD_DIR}/libpng.tar.gz" && mv "$LIBPNG_VERSION" libpng
    [ ! -d opus ] && tar -xf "${DOWNLOAD_DIR}/opus.tar.gz" && mv "$OPUS_VERSION" opus
    [ ! -d vorbis ] && tar -xf "${DOWNLOAD_DIR}/vorbis.tar.xz" && mv "$VORBIS_VERSION" vorbis
    [ ! -d ogg ] && tar -xf "${DOWNLOAD_DIR}/ogg.tar.gz" && mv "$OGG_VERSION" ogg
    [ ! -d dav1d ] && tar -xf "${DOWNLOAD_DIR}/dav1d.tar.gz" && mv "$DAV1D_VERSION"* dav1d
    [ ! -d libass ] && tar -xf "${DOWNLOAD_DIR}/libass.tar.gz" && mv "$LIBASS_VERSION" libass
    [ ! -d fontconfig ] && tar -xf "${DOWNLOAD_DIR}/fontconfig.tar.xz" && mv "$FONTCONFIG_VERSION" fontconfig
    [ ! -d fribidi ] && tar -xf "${DOWNLOAD_DIR}/fribidi.tar.xz" && mv "$FRIBIDI_VERSION" fribidi
    [ ! -d bluray ] && tar -xf "${DOWNLOAD_DIR}/bluray.tar.gz" && mv "$BLURAY_VERSION"* bluray
    [ ! -d speex ] && tar -xf "${DOWNLOAD_DIR}/speex.tar.gz" && mv "$SPEEX_VERSION" speex
    [ ! -d libexpat ] && tar -xf "${DOWNLOAD_DIR}/libexpat.tar.gz" && mv "$LIBEXPAT_VERSION" libexpat
    [ ! -d budfread ] && tar -xf "${DOWNLOAD_DIR}/budfread.tar.gz" && mv "$BUDFREAD_VERSION" budfread
    [ ! -d openmpt ] && tar -xf "${DOWNLOAD_DIR}/openmpt.tar.gz" && mv "$OPENMPT_VERSION"* openmpt
    [ ! -d libgsm ] && tar -xf "${DOWNLOAD_DIR}/libgsm.tar.gz" && mv gsm* libgsm
    [ ! -d libssh ] && tar -xf "${DOWNLOAD_DIR}/libssh.tar.xz" && mv "$LIBSSH_VERSION" libssh
    [ ! -d svtav1 ] && tar -xf "${DOWNLOAD_DIR}/svtav1.tar.gz" && mv "$SVTAV1_VERSION" svtav1
    [ ! -d xvidcore ] && tar -xf "${DOWNLOAD_DIR}/xvid.tar.gz"
    [ ! -d libbs2b ] && tar -xf "${DOWNLOAD_DIR}/libbs2b.tar.gz" && mv "$LIBBS2B_VERSION" libbs2b
    [ ! -d fftw ] && tar -xf "${DOWNLOAD_DIR}/fftw.tar.gz" && mv "$FFTW_VERSION" fftw
    [ ! -d libffi ] && tar -xf "${DOWNLOAD_DIR}/libffi.tar.gz" && mv "$LIBFFI_VERSION" libffi
    [ ! -d FFmpeg ] && tar -xf "${DOWNLOAD_DIR}/ffmpeg.tar.xz" && mv "$FFMPEG_VERSION" FFmpeg

    # extract gitHub ZIP files
    for repo_name in "${!GITHUB_REPOS[@]}"; do
        if [ ! -d "$repo_name" ] && [ -f "${DOWNLOAD_DIR}/${repo_name}.zip" ]; then
            unzip -qo "${DOWNLOAD_DIR}/${repo_name}.zip"
            # find the extracted directory - GitHub zips are named as "reponame-branch"
            # so we need to extract the actual repo name from the GitHub path
            local repo_path="${GITHUB_REPOS[$repo_name]}"
            local actual_repo_name="${repo_path##*/}"  # get everything after the last /
            local extracted_dir
            extracted_dir=$(find . -maxdepth 1 -type d -name "${actual_repo_name}-*" | head -1)
            if [ -n "$extracted_dir" ]; then
                mv "$extracted_dir" "$repo_name"
            else
                echo "Warning: Could not find extracted directory for $repo_name (expected ${actual_repo_name}-*)"
              
                echo "Available directories:"
                find . -maxdepth 1 -type d -name "*-*" | head -5
            fi
        fi
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

}
