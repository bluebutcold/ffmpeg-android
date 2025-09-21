# Build Changelog

**Commit:** 0bd5a7d3719456f049f4d29abb313968ccacb28c
**Author:** Niklas Haas <git@haasn.dev>
**Date:** Sun Sep 21 13:28:58 2025 +0200

avfilter/vf_colordetect: only report detected properties on EOF

Instead of reporting them also when the filtergraph is suddenly destroyed
mid-stream, e.g. during the `ffmpeg` tool's early init.
