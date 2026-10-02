// N-era libcutils and MTK xlog symbols for the MT6755 blobs on Android 13: the
// C half of libm681shim_base (Android.bp).
//
// libm681shim_base is loaded into both the vendor default namespace (composer,
// allocator) and sphal (Mali EGL and gralloc inside SurfaceFlinger, zygote and
// every app), so it may depend only on what sphal reaches: LLNDK (libc, liblog)
// and VNDK-SP (plus libbinder/libnetutils with the patched linkerconfig).  This
// file needs libc and liblog only.  Consumers on the graphics path, both ABIs:
// hwcomposer.mt6755, gralloc.mt6755, libGLES_mali, libged, libgpu_aux,
// libgralloc_extra, libgui_ext, libui_ext, libbwc, libpq_prot, libpqservice.
#include <errno.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#include <log/log.h>

// ---- android_atomic_* -------------------------------------------------------
// N libcutils exported the whole <cutils/atomic.h> family: its atomic.c was
// `#define ANDROID_ATOMIC_INLINE` + `#include <cutils/atomic.h>`.  The A13 header
// still carries the bodies (C11 stdatomic, same memory orders as N) but makes
// them static inline and libcutils exports none of them.  Same trick: empty
// macro -> external definitions.  Imported by the blobs: acquire_load,
// release_load, release_store, inc, dec, and, or.  The helper
// to_atomic_int_least32_t is exported as a side effect; no blob imports it.
#define ANDROID_ATOMIC_INLINE
#include <cutils/atomic.h>

// ---- android_memset16 -------------------------------------------------------
// Gone from libcutils since P.  gralloc.mt6755.so (lib and lib64) imports it.
// Old header semantics: count is in bytes, dst is 2-byte aligned.
void android_memset16(uint16_t* dst, uint16_t value, size_t count) {
    count /= sizeof(uint16_t);
    while (count-- > 0) *dst++ = value;
}

// ---- __xlog_buf_printf ------------------------------------------------------
// MediaTek xlog, exported by the MTK liblog of the original ROMs; no AOSP
// library has it.  Importers include hwcomposer, libgui_ext, libui_ext, libbwc,
// libpqservice.  The record is 24 bytes: tag and fmt pointers and an int
// priority (e.g. 5 = ANDROID_LOG_WARN).  bufid is a log_id_t (0 = main); it is
// honoured, so RIL lines keep going to the radio buffer.
struct xlog_record {
    const char* tag_str;
    const char* fmt_str;
    int prio;
};

int __xlog_buf_printf(int bufid, const struct xlog_record* rec, ...) {
    if (rec == NULL || rec->fmt_str == NULL) return -EINVAL;
    char buf[1024];  // LOG_BUF_SIZE of __android_log_vprint
    va_list ap;
    va_start(ap, rec);
    vsnprintf(buf, sizeof(buf), rec->fmt_str, ap);
    va_end(ap);
    if (bufid < LOG_ID_MIN || bufid >= LOG_ID_MAX) bufid = LOG_ID_MAIN;
    return __android_log_buf_write(bufid, rec->prio, rec->tag_str, buf);
}
