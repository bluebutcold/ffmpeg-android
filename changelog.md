# Build Changelog

**Commit:** 843920d5d6bdcecbfd4eeac66cd175348bf99496
**Author:** Niklas Haas <git@haasn.dev>
**Date:** Mon Sep 15 17:47:39 2025 +0200

avfilter/x86/vf_idetdsp: add AVX2 and AVX512 implementations

The only thing that changes slightly is the horizontal sum at the end.
