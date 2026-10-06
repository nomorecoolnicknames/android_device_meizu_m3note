/* Link-time stand-in for mtk-ril.so.  Installed only in m3note-linkstub/,
 * off the linker path: libril links with DT_NEEDED mtk-ril.so through it; on
 * the device the stock blob is used.
 *
 * libril imports getIaCache, acquire_wake_lock and release_wake_lock from
 * mtk-ril.so; the two wake-lock functions are also exported by
 * libhardware_legacy, which libril links (and which comes first in its
 * DT_NEEDED order), so only getIaCache is reproduced here. */
void getIaCache(char* cache) {
    (void)cache;
}
