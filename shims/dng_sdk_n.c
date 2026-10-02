/* libdng_sdk.so under its real name, for the N libskia.so (Adobe DNG SDK and
 * piex).  Every symbol below is one the N libskia imports and nothing in its
 * vendor-namespace group defines; the real libdng_sdk.so is not reachable from
 * the vendor namespace.  libskia is in the camera group only through the HAL1
 * chain, which neither renders text nor decodes DNG.  Functions log the name
 * once and return 0 (constructors/destructors return this); the vtable objects
 * are zeroed stand-ins.  If the tag "m3note-skia-deps" shows up in logcat,
 * that path needs a real library.
 */
#include <stdatomic.h>

#include <android/log.h>

static long m3note_skia_dep(const char* name, atomic_int* once) {
    if (atomic_exchange(once, 1) == 0)
        __android_log_print(ANDROID_LOG_ERROR, "m3note-skia-deps",
                "%s called: libdng_sdk.so is a stub on A13, returning 0", name);
    return 0;
}

#define STUB(n, sym) \
    long m3note_stub_##n(void) __asm__(#sym); \
    long m3note_stub_##n(void) { \
        static atomic_int once; \
        return m3note_skia_dep(#sym, &once); \
    }
/* Constructors and destructors: on ARM EABI they return `this` in r0 and callers may
 * use it, so these hand back their first argument. */
#define STUB_THIS(n, sym) \
    void* m3note_stub_##n(void* self) __asm__(#sym); \
    void* m3note_stub_##n(void* self) { \
        static atomic_int once; \
        m3note_skia_dep(#sym, &once); \
        return self; \
    }
#define OBJECT(n, sym) void* m3note_obj_##n[16] __asm__(#sym);

STUB(0, _Z12SafeInt32SubiiPi)
STUB(1, _Z15Throw_dng_erroriPKcS0_b)
STUB(2, _ZN10dng_render6RenderEv)
STUB_THIS(3, _ZN10dng_renderC1ER8dng_hostRK12dng_negative)
STUB_THIS(4, _ZN10dng_streamD2Ev)
STUB(5, _ZN12dng_metadata19SynchronizeMetadataEv)
STUB(6, _ZN12dng_negative16BuildStage2ImageER8dng_host)
STUB(7, _ZN12dng_negative16BuildStage3ImageER8dng_hosti)
STUB(8, _ZN12dng_negative20ReadTransparencyMaskER8dng_hostR10dng_streamR8dng_info)
STUB(9, _ZN12dng_negative22ValidateRawImageDigestER8dng_host)
STUB(10, _ZN13dng_area_task15ProcessOnThreadEjRK8dng_rectRK9dng_pointP17dng_abort_sniffer)
STUB(11, _ZN14dng_space_sRGB3GetEv)
STUB_THIS(12, _ZN16dng_pixel_bufferC1Ev)
STUB_THIS(13, _ZN16dng_pixel_bufferD1Ev)
STUB(14, _ZN20dng_memory_allocator8AllocateEj)
STUB(15, _ZN4piex19GetPreviewImageDataEPNS_15StreamInterfaceEPNS_16PreviewImageDataE)
STUB(16, _ZN8dng_host12Make_dng_ifdEv)
STUB(17, _ZN8dng_host13Make_dng_exifEv)
STUB(18, _ZN8dng_host13ResampleImageERK9dng_imageRS0_)
STUB(19, _ZN8dng_host13SniffForAbortEv)
STUB(20, _ZN8dng_host13ValidateSizesEv)
STUB(21, _ZN8dng_host14Make_dng_imageERK8dng_rectjj)
STUB(22, _ZN8dng_host15ApplyOpcodeListER15dng_opcode_listR12dng_negativeR7AutoPtrI9dng_imageE)
STUB(23, _ZN8dng_host15Make_dng_opcodeEjR10dng_stream)
STUB(24, _ZN8dng_host15Make_dng_sharedEv)
STUB(25, _ZN8dng_host16IsTransientErrorEi)
STUB(26, _ZN8dng_host17Make_dng_negativeEv)
STUB(27, _ZN8dng_host8AllocateEj)
STUB(28, _ZN8dng_host9AllocatorEv)
STUB_THIS(29, _ZN8dng_hostC2EP20dng_memory_allocatorP17dng_abort_sniffer)
STUB_THIS(30, _ZN8dng_hostD2Ev)
STUB_THIS(31, _ZN8dng_infoC1Ev)
STUB(32, _ZNK13dng_area_task12FindTileSizeERK8dng_rect)
STUB(33, _ZNK13dng_urational9As_real64Ev)
STUB(34, _ZNK8dng_host13SaveLinearDNGERK12dng_negative)
STUB(35, _ZNK8dng_host14SaveDNGVersionEv)
STUB(36, _ZNK9dng_image3GetER16dng_pixel_bufferNS_11edge_optionEjj)
OBJECT(37, _ZTV10dng_render)
#if defined(__LP64__)
STUB(38, _ZN10dng_stream11DoSetLengthEm)
STUB(39, _ZN10dng_stream12CopyToStreamERS_m)
STUB(40, _ZN10dng_stream7DoWriteEPKvjm)
STUB_THIS(41, _ZN10dng_streamC2EP17dng_abort_snifferjm)
#else
STUB(42, _ZN10dng_stream11DoSetLengthEy)
STUB(43, _ZN10dng_stream12CopyToStreamERS_y)
STUB(44, _ZN10dng_stream7DoWriteEPKvjy)
STUB_THIS(45, _ZN10dng_streamC2EP17dng_abort_snifferjy)
#endif
