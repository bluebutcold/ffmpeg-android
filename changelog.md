# Build Changelog

**Commit:** e05f8acabff468c1382277c1f31fa8e9d90c3202
**Author:** Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
**Date:** Wed Oct 1 08:27:14 2025 +0200

avfilter/blend_modes: Don't build duplicate functions

Some of the blend mode functions only depend on the underlying type
and therefore need only one version for 9, 10, 12, 14, 16 bits.
This saved 35104B with GCC and 26880B with Clang.

Signed-off-by: Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
