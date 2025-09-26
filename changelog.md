# Build Changelog

**Commit:** fa72f9a2921556923fa598317db4fcdc3c85ac24
**Author:** Kacper Michajłow <kasper93@gmail.com>
**Date:** Thu Sep 25 20:35:33 2025 +0200

forgejo/workflows: include size and mtime in cache hash

In case some file has been updated. Generally fate samples shouldn't be
replaced to preserve compatibility with older revisions, but before
merge it may happen that files is replaced.

Signed-off-by: Kacper Michajłow <kasper93@gmail.com>
