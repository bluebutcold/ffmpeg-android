# Build Changelog

**Commit:** 0fdb5829e38dabea9cbe4073a35b6c6315e7508e
**Author:** Kaarle Ritvanen <kaarle.ritvanen@datakunkku.fi>
**Date:** Tue Apr 29 14:35:00 2025 +0300

avformat/rtsp: set AVFMTCTX_UNSEEKABLE flag

for live RTP streams. Some external applications, such as Qt Multimedia,
depend on this flag being set correctly.

Signed-off-by: Kaarle Ritvanen <kaarle.ritvanen@datakunkku.fi>
