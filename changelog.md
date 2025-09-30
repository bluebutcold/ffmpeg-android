# Build Changelog

**Commit:** bc561013c9a809a90c0d1b84413814ba612f7c44
**Author:** Jack Lau <jacklau1222@qq.com>
**Date:** Thu Sep 18 09:23:31 2025 +0800

avformat/whip: add RTX initial support

Refer to RFC 4588.

Add and set the basic param of RTX like
ssrc, payload_type, srtp.

Modify the SDP to add RTX info so that
the peer be able to parse the RTX packet.

There are more pateches to make RTX really
work.

Signed-off-by: Jack Lau <jacklau1222@qq.com>
