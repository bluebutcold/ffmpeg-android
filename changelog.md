# Build Changelog

**Commit:** 82b5a0faba9ce558682de728586929bc19d106e2
**Author:** Henrik Gramner <gramner@twoorioles.com>
**Date:** Mon Sep 15 14:11:58 2025 +0200

vp9: Remove 8bpc AVX asm for inverse transforms

There's very little performance difference vs SSE2/SSSE3 and most
systems will use the AVX2 implementations anyway.

This reduces code size and compilation time by a significant amount.
