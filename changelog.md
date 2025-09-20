# Build Changelog

**Commit:** 8d65da767b2b727a80672969f3120286ee478290
**Author:** Lynne <dev@lynne.ee>
**Date:** Wed Sep 17 00:11:11 2025 +0900

lavf: fix demuxing of FLAC files with id3v2 tags

Due to the recent id3v2 refactor, FLAC was left out due to
earlier code not checking for id3v2 presence on FLAC.
Without the id3v2 data parsed, detection of FLAC and therefore
demuxing fails.

Fixes 9d037c54f209958d47ac376d2a9561608f98dfae
