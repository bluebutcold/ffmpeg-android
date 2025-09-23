# Build Changelog

**Commit:** 899e497122f793c3d97f5aac7bee62567f23fe29
**Author:** Niklas Haas <git@haasn.dev>
**Date:** Thu Sep 11 01:48:32 2025 +0200

avfilter/vf_libplacebo: force premultiplied blending for linear texture

Blending onto independent alpha framebuffers is not possible under the
constraints of the supported blend operators. While we could handle
blending premul-onto-premul, this would break if the base layer is YUV,
since premultiplied alpha does not survive the (nonlinear) YUV conversion.

Fortunately, blending independent-onto-premul is just as easy, and works in
all cases. So just force this mode when using a linear intermediate blend
texture, which is always RGBA.
