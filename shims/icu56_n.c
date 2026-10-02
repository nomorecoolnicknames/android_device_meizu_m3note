/* libicuuc.so under its real name, for the N libskia.so (ICU 56: ucnv_* and
 * icu_56::UnicodeString/StringPiece).  Every symbol below is one the N libskia
 * imports and nothing in its vendor-namespace group defines; the real
 * libicuuc.so is not reachable from the vendor namespace.  libskia is in the
 * camera group only through the HAL1 chain, which neither renders text nor
 * decodes DNG.  Functions log the name once and return 0
 * (constructors/destructors return this); the vtable objects are zeroed
 * stand-ins.  If the tag "m3note-skia-deps" shows up in logcat, that path
 * needs a real library.
 */
#include <stdatomic.h>

#include <android/log.h>

static long m3note_skia_dep(const char* name, atomic_int* once) {
    if (atomic_exchange(once, 1) == 0)
        __android_log_print(ANDROID_LOG_ERROR, "m3note-skia-deps",
                "%s called: libicuuc.so is a stub on A13, returning 0", name);
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

STUB_THIS(0, _ZN6icu_5611StringPieceC1EPKc)
STUB(1, _ZN6icu_5613UnicodeString8doAppendERKS0_ii)
STUB(2, _ZN6icu_5613UnicodeString8fromUTF8ERKNS_11StringPieceE)
STUB(3, _ZN6icu_5613UnicodeString8moveFromERS0_)
STUB_THIS(4, _ZN6icu_5613UnicodeStringC1EPKt)
STUB_THIS(5, _ZN6icu_5613UnicodeStringC1ERKS0_)
STUB_THIS(6, _ZN6icu_5613UnicodeStringD1Ev)
STUB(7, _ZNK6icu_5613UnicodeString13doCaseCompareEiiPKtiij)
OBJECT(8, _ZTVN6icu_5613UnicodeStringE)
STUB(9, ucnv_close_56)
STUB(10, ucnv_fromUChars_56)
STUB(11, ucnv_open_56)
STUB(12, ucnv_toUChars_56)
