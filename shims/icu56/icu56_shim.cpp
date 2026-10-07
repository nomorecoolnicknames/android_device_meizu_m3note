/*
 * libm3note_icu56_shim - ICU 56 -> ICU 60 forwarders for /vendor/lib{,64}/libskia.so
 * of the m681 camera set.
 *
 * The N libskia.so (pulled in via libcam.device1 -> libcam.camadapter) was
 * linked against ICU 56; Pie ships ICU 60, so 13 symbols stay unresolved:
 * ucnv_{open,close,fromUChars,toUChars}_56 and icu_56::StringPiece /
 * icu_56::UnicodeString members plus the UnicodeString vtable.
 * libmtkshim_icu (for mtk_agpsd) covers only ucnv_open/close of these.
 *
 * - ucnv_* is stable C API, same prototypes in 56 and 60: plain forwarders.
 * - StringPiece {ptr, length} and UnicodeString (64 bytes, no self-pointer)
 *   have the same layout in 56 and 60 (the UChar -> char16_t change in 59 only
 *   alters mangling). Constructors and the destructor are re-entered through
 *   placement new / explicit destructor calls, returning this as the ARM C++
 *   ABI expects.
 * - doAppend and doCaseCompare are private in ICU 60, so they are reached by
 *   their exported icu_60 names; fromUTF8 takes StringPiece by value in 60
 *   (by const reference in 56).
 * - The vtable is data: libskia's inline constructors store &vtable + 2 slots.
 *   icu_60's UnicodeString vtable has 13 slots on both arches; it is copied
 *   into the icu_56 symbol before libskia runs (this library is in libskia's
 *   load group, so its constructor runs first). The virtual set (UObject +
 *   Replaceable) and its slot order are the same in 56 and 60.
 * Wired with TARGET_LD_SHIM_LIBS for /vendor/lib{,64}/libskia.so.
 */
#include <string.h>

#include <new>

#include <unicode/stringpiece.h>
#include <unicode/ucnv.h>
#include <unicode/unistr.h>

using icu::StringPiece;
using icu::UnicodeString;

extern "C" {

UConverter* ucnv_open_56(const char* converterName, UErrorCode* err) {
    return ucnv_open(converterName, err);
}

void ucnv_close_56(UConverter* converter) {
    ucnv_close(converter);
}

int32_t ucnv_fromUChars_56(UConverter* cnv, char* dest, int32_t destCapacity,
        const UChar* src, int32_t srcLength, UErrorCode* err) {
    return ucnv_fromUChars(cnv, dest, destCapacity, src, srcLength, err);
}

int32_t ucnv_toUChars_56(UConverter* cnv, UChar* dest, int32_t destCapacity,
        const char* src, int32_t srcLength, UErrorCode* err) {
    return ucnv_toUChars(cnv, dest, destCapacity, src, srcLength, err);
}

/* icu_60 UnicodeString vtable (libicuuc) and the icu_56 copy for libskia. */
extern const void* const _ZTVN6icu_6013UnicodeStringE[13];
const void* _ZTVN6icu_5613UnicodeStringE[13];

}  // extern "C"

__attribute__((constructor)) static void m3note_icu56_vtable_init() {
    memcpy(_ZTVN6icu_5613UnicodeStringE, _ZTVN6icu_6013UnicodeStringE,
            sizeof(_ZTVN6icu_5613UnicodeStringE));
}

/* private / differently-typed icu_60 members, by their exported names */
UnicodeString& u60_doAppend(UnicodeString* self, const UnicodeString& src,
        int32_t srcStart, int32_t srcLength)
        __asm__("_ZN6icu_6013UnicodeString8doAppendERKS0_ii");
int8_t u60_doCaseCompare(const UnicodeString* self, int32_t start, int32_t length,
        const char16_t* srcChars, int32_t srcStart, int32_t srcLength,
        uint32_t options)
        __asm__("_ZNK6icu_6013UnicodeString13doCaseCompareEiiPKDsiij");

/* icu_56::StringPiece::StringPiece(const char*) */
void* u56_sp_ctor(StringPiece* self, const char* str)
        __asm__("_ZN6icu_5611StringPieceC1EPKc");
void* u56_sp_ctor(StringPiece* self, const char* str) {
    return new (self) StringPiece(str);
}

/* icu_56::UnicodeString::UnicodeString(const UChar*) */
void* u56_us_ctor_chars(UnicodeString* self, const uint16_t* text)
        __asm__("_ZN6icu_5613UnicodeStringC1EPKt");
void* u56_us_ctor_chars(UnicodeString* self, const uint16_t* text) {
    return new (self) UnicodeString(reinterpret_cast<const char16_t*>(text));
}

/* icu_56::UnicodeString::UnicodeString(const UnicodeString&) */
void* u56_us_ctor_copy(UnicodeString* self, const UnicodeString& that)
        __asm__("_ZN6icu_5613UnicodeStringC1ERKS0_");
void* u56_us_ctor_copy(UnicodeString* self, const UnicodeString& that) {
    return new (self) UnicodeString(that);
}

/* icu_56::UnicodeString::~UnicodeString() */
void* u56_us_dtor(UnicodeString* self) __asm__("_ZN6icu_5613UnicodeStringD1Ev");
void* u56_us_dtor(UnicodeString* self) {
    self->~UnicodeString();
    return self;
}

/* icu_56::UnicodeString::doAppend(const UnicodeString&, int, int) */
UnicodeString& u56_us_doAppend(UnicodeString* self, const UnicodeString& src,
        int32_t srcStart, int32_t srcLength)
        __asm__("_ZN6icu_5613UnicodeString8doAppendERKS0_ii");
UnicodeString& u56_us_doAppend(UnicodeString* self, const UnicodeString& src,
        int32_t srcStart, int32_t srcLength) {
    return u60_doAppend(self, src, srcStart, srcLength);
}

/* icu_56::UnicodeString::moveFrom(UnicodeString&) */
UnicodeString& u56_us_moveFrom(UnicodeString* self, UnicodeString& src)
        __asm__("_ZN6icu_5613UnicodeString8moveFromERS0_");
UnicodeString& u56_us_moveFrom(UnicodeString* self, UnicodeString& src) {
    return self->moveFrom(src);
}

/* static icu_56::UnicodeString::fromUTF8(const StringPiece&) */
UnicodeString u56_us_fromUTF8(const StringPiece& utf8)
        __asm__("_ZN6icu_5613UnicodeString8fromUTF8ERKNS_11StringPieceE");
UnicodeString u56_us_fromUTF8(const StringPiece& utf8) {
    return UnicodeString::fromUTF8(utf8);
}

/* icu_56::UnicodeString::doCaseCompare(int, int, const UChar*, int, int, unsigned) const */
int8_t u56_us_doCaseCompare(const UnicodeString* self, int32_t start,
        int32_t length, const uint16_t* srcChars, int32_t srcStart,
        int32_t srcLength, uint32_t options)
        __asm__("_ZNK6icu_5613UnicodeString13doCaseCompareEiiPKtiij");
int8_t u56_us_doCaseCompare(const UnicodeString* self, int32_t start,
        int32_t length, const uint16_t* srcChars, int32_t srcStart,
        int32_t srcLength, uint32_t options) {
    return u60_doCaseCompare(self, start, length,
            reinterpret_cast<const char16_t*>(srcChars), srcStart, srcLength,
            options);
}
