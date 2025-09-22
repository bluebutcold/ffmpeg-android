# Android FFmpeg Build

An automated workflow that monitors FFmpeg's master branch and creates Android builds with comprehensive codec support. The system automatically checks for new commits every 2 hours and builds fresh releases when updates are detected.

- **Dynamic builds** include hardware acceleration support through MediaCodec and OpenCL (if device supports it)
- **Static builds** create self-contained binaries without external dependencies
- **Magisk modules** (.zip) for system-wide installation
- **Termux packages** (.deb) for terminal usage


##  Installation Options

### For Android (Root Required)
**Magisk Module Installation:**
1. Download the `.zip` file for your architecture from [Releases](../../releases)
2. Flash through Magisk Manager
3. Reboot device

### For Termux (No Root)
**Package Installation:**
```bash
# Download the .deb file for your architecture
dpkg -i --force-overwrite ffmpeg-*-android-*.deb
```

### Find Your Architecture
```bash
getprop ro.product.cpu.abi
```

##  Architecture Support

### ARM64 (aarch64) - `arm64-v8a`
- Full feature set with all codecs enabled
- NEON SIMD optimizations enabled
- Hardware acceleration support

### ARMv7 (armv7) - `armeabi-v7a`  
- Legacy 32-bit ARM support
- NEON optimizations enabled
- EVC codecs (libxeve/libxevd) not available

### x86_64
- Intel/AMD 64-bit devices and emulators
- Full codec support
- Optimized performance

### x86
- Intel/AMD 32-bit devices and emulators  
- Assembly optimizations disabled in dynamic builds for compatibility
- Full codec support

### RISC-V (riscv64)
- **Experimental** support for RISC-V devices
- Limited codec availability (RAV1E, RSVG, XAVS2, EVC not supported)


##  Codec Support

### Video Codecs
#### Modern Codecs
- **AV1** (libaom, libdav1d, libsvtav1) - Next-generation royalty-free
- **H.265/HEVC** (libx265, libkvazaar) - High-efficiency video
- **H.264** (libx264) - Industry standard
- **VP8/VP9** (libvpx) - Google's open codecs
- **VVC/H.266** (libvvenc) - Latest video standard
- **JPEG XL** (libjxl) - Modern image/video format

#### Regional Standards
- **AVS2/AVS3** (libdavs2, libuavs3d) - Chinese video standards
- **XAVS/XAVS2** (libxavs, libxavs2) - Chinese AVS implementation
- **EVC** (libxeve, libxevd) - Essential Video Coding

#### Legacy Codecs
- **Xvid** (libxvid) - MPEG-4 ASP
- **Theora** (libtheora) - Open source video

### Audio Codecs
#### High-Quality Audio
- **Opus** (libopus) - Modern low-latency codec
- **MP3** (libmp3lame) - Universal compatibility
- **Vorbis** (libvorbis) - Ogg Vorbis
- **LC3** (liblc3) - Bluetooth LE Audio codec

#### Speech Codecs
- **AMR-NB/WB** (libopencore, libvo-amrwbenc) - Mobile speech
- **Speex** (libspeex) - Voice over IP
- **iLBC** (libilbc) - Internet speech
- **Codec2** (libcodec2) - Low bitrate speech

#### Broadcast & Professional
- **MP2** (libtwolame) - MPEG Layer 2
- **AAC** - Built-in advanced audio coding

### Specialized Libraries
#### Text & Subtitles
- **libass** - Advanced subtitle rendering
- **libfreetype, libfontconfig, libfribidi** - Font rendering & text processing
- **libaribb24** - Japanese broadcast text

#### Audio Processing  
- **libsoxr** - High-quality audio resampling
- **libbs2b** - Binaural audio processing
- **libmysofa** - 3D audio processing
- **FFTW3** - Fast Fourier transforms

#### Image Processing
- **libwebp** - Modern web images
- **libopenjpeg** - JPEG 2000
- **libzimg** - High-performance scaling
- **liblensfun** - Lens correction

#### Network & Streaming
- **OpenSSL** - Secure connections
- **libsrt** - Low-latency streaming
- **librist** - Reliable streaming
- **librtmp** - Flash video streaming
- **libssh** - SSH connections

## 🛠️ Build Features

### Hardware Acceleration (Dynamic builds)
- **MediaCodec** - Android native hardware encoding/decoding
- **OpenCL** - GPU compute acceleration (device dependent)  
- **NEON** - ARM SIMD optimizations (ARM architectures)

### Build Types

#### Dynamic Builds
- Shared libraries with hardware acceleration
- Smaller individual binary size
- MediaCodec and OpenCL support
- Requires system integration

#### Static Builds  
- Self-contained executables
- No external dependencies
- Larger file size
- Maximum portability
- No hardware acceleration

## 📋 Environment Variables (For Manual Builds)

| Variable | Description | Required | Default | Notes |
|----------|-------------|----------|---------|--------|
| `ANDROID_NDK_ROOT` | Path to Android NDK | Yes | - | NDK r29+ recommended |
| `ARCH` | Target architecture | Yes | - | aarch64, armv7, x86, x86_64, riscv64 |
| `API_LEVEL` | Android API level | No | 29 | Minimum: 29 |
| `FFMPEG_STATIC` | Build static FFmpeg | No | undefined | Set to any value for static |

##  Manual Build Process

If you want to build locally instead of using automated releases:

```bash
# Prerequisites: Android NDK, build tools, dependencies
export ANDROID_NDK_ROOT=/path/to/android_ndk
export ARCH=aarch64
export FFMPEG_STATIC=1  # Optional: for static build
./build.sh
```

### Build Requirements
- **Android NDK 
- **Linux** build environment  
- **Build tools**: make, cmake, ninja, autotools
- **Languages**: C/C++ toolchain, Rust (for some codecs)
- **Python tools**: meson, pipx
- **Storage**: ~10GB free space during build

##  Release Information

Each automated release includes:
- **Build artifacts** for all architectures (both static and dynamic)
- **Magisk modules** (.zip files) for system installation
- **Termux packages** (.deb files) for terminal usage
- **Build metadata** (commit hash, build date, configuration)
- **Changelog** with recent changes and features

### Update Mechanism
- JSON files automatically updated for Magisk module update checks
- Telegram notifications sent to [@ffmpegandroid](https://ffmpegandroid.t.me)
- Release notes include FFmpeg commit information

## Usage Notes

### Compatibility
- **Magisk modules**: Require root access via Magisk
- **Termux packages**: Work in Termux terminal environment
- **API compatibility**: Built for Android API 29+ (Android 10+)

### Performance
- **ARM64 recommended** for best performance on modern devices
- **Hardware acceleration** only available in dynamic builds
- **Static builds** offer maximum compatibility but larger size

### Architecture Selection
Choose based on your device:
- **Most Android phones (2015+)**: arm64-v8a (aarch64)
- **Older Android phones**: armeabi-v7a (armv7)  
- **Android-x86/Emulators**: x86_64 or x86
- **Experimental devices**: riscv64

## Troubleshooting

### Common Issues
- **Wrong architecture**: Check with `getprop ro.product.cpu.abi`
- **Magisk installation fails**: Ensure Magisk is up to date
- **Termux installation failing**: Use `--force-overwrite` with dpkg
- **Hardware acceleration not working**: Check device MediaCodec support

### Getting Help
- Check [Issues](../../issues) for known problems
- Review [Releases](../../releases) for working builds

## License

FFmpeg is licensed under **GPL v3** due to enabled GPL-licensed libraries. Some codecs may have additional patent or licensing requirements for commercial use.

## Links

- **FFmpeg Project**: https://ffmpeg.org/
- **Android NDK**: https://developer.android.com/ndk
- **Magisk**: https://github.com/topjohnwu/Magisk
- **Termux**: https://termux.dev/
- **Telegram Channel**: https://t.me/ffmpegandroid

## Contributing

The build system is automated, but contributions welcome for:
- Build script improvements
- New codec integration  
- Documentation updates
- Architecture support expansion
