/* Empty body of a DT_NEEDED forwarder (see Android.bp of this tree).
 * The library exists only for its soname and its own DT_NEEDED; bionic binds
 * every consumer against the whole breadth-first load group, so the
 * consumers' symbols land in the library this one needs. */
void __mt6755_fwd_marker(void) {}
