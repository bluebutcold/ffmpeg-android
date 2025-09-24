# Build Changelog

**Commit:** e5f82ab8686b3c6193a3f718f53dbef9436b4318
**Author:** rcombs <rcombs@rcombs.me>
**Date:** Tue Sep 23 20:21:44 2025 -0700

Revert "lavc/libsvtav1: set packet durations"

This reverts commit 5c9b2027bc48ae5d39b0d82696895f0834788242.

This doesn't actually work the way it'd appeared to in testing;
the output was based on frame *encode latency*.
