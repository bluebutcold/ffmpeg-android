# Build Changelog

**Commit:** 7c78a63476da6360063d45f74cb1d9fc94047278
**Author:** Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
**Date:** Tue Sep 23 05:42:59 2025 +0200

avcodec/mpegaudiodec_float: Don't set AVCodec.sample_fmts directly

It is deprecated and doing so gives warnings from Clang.
Use CODEC_SAMPLEFMTS instead.

Signed-off-by: Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
