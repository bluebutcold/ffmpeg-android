# Build Changelog

**Commit:** f1d5114103a8164869a279326043645e7bacdc86
**Author:** Marton Balint <cus@passwd.hu>
**Date:** Thu Oct 2 00:27:29 2025 +0200

avformat/tls_openssl: do not cleanup tls after a successful dtls_start()

Regression since 8e11e2cdb82299e7f0b6d8884bf2bc65c1c3f5e8.

Signed-off-by: Marton Balint <cus@passwd.hu>
