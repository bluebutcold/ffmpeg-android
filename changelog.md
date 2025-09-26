# Build Changelog

**Commit:** 6d8732f397bfb07f2292e15a61904665abe13ce3
**Author:** James Almer <jamrial@gmail.com>
**Date:** Tue Sep 16 21:45:00 2025 -0300

avformat/movenc: clear subsample information on fragment flush

Don't keep around information from a previous traf atom.

Fixes issue #20492.

Signed-off-by: James Almer <jamrial@gmail.com>
