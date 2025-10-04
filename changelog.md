# Build Changelog

**Commit:** 8fad52bd57d5bcedce8dc4ae3166c1a50f895690
**Author:** Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
**Date:** Tue Sep 30 00:32:27 2025 +0200

avcodec/x86/h264_qpel: Use ptrdiff_t for strides

Avoids having to sign-extend the strides in the assembly
(it also is more correct given that the qpel_mc_func
already uses ptrdiff_t).

Reviewed-by: James Almer <jamrial@gmail.com>
Signed-off-by: Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
