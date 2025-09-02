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
export ARCH=<architecture>
export API_LEVEL=<API_LEVEL> # Default is 29
./build.sh
```

Using an API level below 29 may cause problems when building some libraries, so it is recommended not to set API < 29.


Examples:
```bash
export ARCH=aarch64
export FFMPEG_STATIC=1 # for static build
./build.sh
```
## FFmpeg Features

See [ffmpeg.sh](./scripts/ffmpeg.sh) for complete list of enabled codecs and features.
