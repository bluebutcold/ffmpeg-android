# Android FFmpeg Build

This script builds FFmpeg for Android. Both static and dynamic builds are supported.

- **Dynamic builds** include hardware acceleration support through MediaCodec and OpenCL (if device supports it)

## Supported Architectures

- aarch64 (ARM64)
- armv7 (armeabi-v7a)
- x86
- x86_64 
- riscv64

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `ANDROID_NDK_ROOT` | Path to Android NDK | Yes | - |
| `ARCH` | Target architecture | Yes | - |
| `API_LEVEL` | Android API level | No | 29 |
| `FFMPEG_STATIC` | Build static FFmpeg | No | undefined (dynamic) |

## Usage

```bash
./build.sh <architecture> [api_level]
```

Examples:
```bash
./build.sh aarch64
./build.sh aarch64 29
FFMPEG_STATIC=1 ./build.sh aarch64 29
```

## Output

- Build artifacts: `out/android/{architecture}/`
- Magisk module: `module/`

## FFmpeg Features

See `./scripts/ffmpeg.sh` for complete list of enabled codecs and features.
