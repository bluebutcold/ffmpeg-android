# Build Changelog

**Commit:** b80f28fcbcedbf48b760921e85c5f2ae4f2f802a
**Author:** Niklas Haas <git@haasn.dev>
**Date:** Tue Sep 23 20:49:07 2025 +0200

avfilter/vf_libplacebo: introduce `fit_sense` option

This allows choosing whether the `fit_mode` merely controls the placement
of the image within the output resolution, or whether the output resolution
is also adjusted according to the given `fit_mode`.
