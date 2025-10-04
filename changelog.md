# Build Changelog

**Commit:** ab7d1c64c9aa9186acb1d988d020e59f2d3defce
**Author:** Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
**Date:** Wed Oct 1 10:46:39 2025 +0200

avcodec/x86/h263_loopfilter: Port loop filter to SSE2

Old benchmarks:
h263dsp.h_loop_filter_c:                                41.2 ( 1.00x)
h263dsp.h_loop_filter_mmx:                              39.5 ( 1.04x)
h263dsp.v_loop_filter_c:                                43.5 ( 1.00x)
h263dsp.v_loop_filter_mmx:                              16.9 ( 2.57x)

New benchmarks:
h263dsp.h_loop_filter_c:                                41.6 ( 1.00x)
h263dsp.h_loop_filter_sse2:                             28.2 ( 1.48x)
h263dsp.v_loop_filter_c:                                42.4 ( 1.00x)
h263dsp.v_loop_filter_sse2:                             15.1 ( 2.81x)

Signed-off-by: Andreas Rheinhardt <andreas.rheinhardt@outlook.com>
