# Build Changelog

**Commit:** 5cb6d2221a6d4c07453b6c301ecfcaed48402680
**Author:** Marvin Scholz <epirat07@gmail.com>
**Date:** Thu May 22 20:14:49 2025 +0200

avformat/http: Handle IPv6 Zone ID in hostname

When using a literal IPv6 address as hostname, it can contain a Zone ID
especially in the case of link-local addresses. Sending this to the
server in the Host header is not useful to the server and in some cases
servers refuse such requests.

To prevent any such issues, strip the Zone ID from the address if it's
an IPv6 address. This also removes it for the Cookies lookup.

Based on a patch by: Daniel N Pettersson <danielnp@axis.com>
