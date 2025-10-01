# Build Changelog

**Commit:** 1a02412170144f07711428ddc2d1051c4284ee0a
**Author:** Zhao Zhili <zhilizhao@tencent.com>
**Date:** Tue Sep 23 22:08:02 2025 +0800

avformat/movenc_ttml: fix memleaks

Memory leaks can happen on normal case when break from while loop
early, and it can happen on error path with goto cleanup.

Signed-off-by: Zhao Zhili <zhilizhao@tencent.com>
