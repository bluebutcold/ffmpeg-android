# Build Changelog

**Commit:** f40766da45642cfe2783c188dacac3f81898ec23
**Author:** Kacper Michajłow <kasper93@gmail.com>
**Date:** Thu Sep 25 18:19:29 2025 +0200

configure: suppress C4267 warnings from MSVC

Suppresses implicit integer conversion narrowing warnings:
warning C4267: 'initializing': conversion from 'size_t' to 'int', possible loss of data

Those implicit conversions are abundant in ffmpeg's code base.
Additionally equivalent warnings are not enabled for GCC/Clang by
default, so they are mostly left unfixed.

Suppress reports about them to reduce noise in MSVC build log.

Signed-off-by: Kacper Michajłow <kasper93@gmail.com>
