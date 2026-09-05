/// Stub "correct" SMS code used until a real verification backend is wired
/// up, matching the TZ spec (docs/TZ_Put_Flutter_PocketBase.md §8.4): SMS is
/// not actually sent, and `111111` is always accepted as valid.
const previewValidSmsCode = '111111';
