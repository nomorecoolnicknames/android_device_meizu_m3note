// libm3note_n_ril: symbols the MTK RIL blobs import from Nougat platform
// libraries that Android 13 no longer exports.  Preloaded into mtk-ril.so and
// librilmtk.so by TARGET_LD_SHIM_LIBS (BoardConfig.mk):
//   mtk-ril.so:   ifc_ccmni_md_cfg, ifc_set_txq_state (MTK additions to the
//                 N libnetutils); protectFromVpn is in netd_client_n.c, since
//                 it needs a library of that name;
//   librilmtk.so: strdup8to16, strndup16to8, strnlen16to8, strncpy16to8
//                 (libcutils <cutils/jstring.h>, gone in A13).
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

extern "C" {

// The ccmni/txq calls only tune the data path, success is safe.
int ifc_set_txq_state(const char* ifname, int state) {
    (void)ifname;
    (void)state;
    return 0;
}

int ifc_ccmni_md_cfg(const char* ifname, int md_id, int ccmni_idx, int op) {
    (void)ifname;
    (void)md_id;
    (void)ccmni_idx;
    (void)op;
    return 0;
}

// libcutils' jstring helpers (cutils/jstring.h): librilmtk.so and
// librilmtkmd2.so (both ABIs) import strnlen16to8, strncpy16to8, strndup16to8
// and strdup8to16, which A13 libcutils no longer exports.  The bodies follow
// AOSP (system/core/libcutils/strdup16to8.cpp and strdup8to16.cpp) so callers
// get the real contract: UTF-8/modified-UTF-8 conversion, strnlen16to8
// counting all n units, strncpy16to8 always NUL-terminating.
size_t strnlen16to8(const char16_t* utf16Str, size_t len) {
    size_t utf8Len = 0;
    while (len != 0) {
        len--;
        unsigned int uic = *utf16Str++;
        size_t utf8Cur = utf8Len;
        if (uic > 0x07ff)
            utf8Len += 3;
        else if (uic > 0x7f || uic == 0)
            utf8Len += 2;
        else
            utf8Len++;
        if (utf8Len < utf8Cur) return SIZE_MAX - 1;  // overflow
    }
    if (utf8Len == SIZE_MAX) utf8Len = SIZE_MAX - 1;
    return utf8Len;
}

char* strncpy16to8(char* utf8Str, const char16_t* utf16Str, size_t len) {
    char* utf8cur = utf8Str;
    while (len != 0) {
        len--;
        unsigned int uic = *utf16Str++;
        if (uic > 0x07ff) {
            *utf8cur++ = static_cast<char>((uic >> 12) | 0xe0);
            *utf8cur++ = static_cast<char>(((uic >> 6) & 0x3f) | 0x80);
            *utf8cur++ = static_cast<char>((uic & 0x3f) | 0x80);
        } else if (uic > 0x7f || uic == 0) {
            *utf8cur++ = static_cast<char>((uic >> 6) | 0xc0);
            *utf8cur++ = static_cast<char>((uic & 0x3f) | 0x80);
        } else {
            *utf8cur++ = static_cast<char>(uic);
            if (uic == 0) break;
        }
    }
    *utf8cur = '\0';
    return utf8Str;
}

char* strndup16to8(const char16_t* s, size_t n) {
    if (s == nullptr) return nullptr;
    size_t len = strnlen16to8(s, n);
    if (len >= SIZE_MAX - 1) return nullptr;
    char* ret = static_cast<char*>(malloc(len + 1));
    if (ret == nullptr) return nullptr;
    strncpy16to8(ret, s, n);
    return ret;
}

#define M3N_UTF16_REPLACEMENT_CHAR 0xfffd
#define M3N_UTF8_SEQ_LENGTH(ch) (((0xe5000000 >> (((ch) >> 3) & 0x1e)) & 3) + 1)
#define M3N_UNICODE_UPPER_LIMIT 0x10fffd

static size_t strlen8to16(const char* utf8Str) {
    size_t len = 0;
    int ic;
    int expected = 0;
    while ((ic = *utf8Str++) != '\0') {
        if ((ic & 0xc0) == 0x80) {
            expected--;
            if (expected < 0) len++;
        } else {
            len++;
            expected = M3N_UTF8_SEQ_LENGTH(ic) - 1;
            if (expected == 3) len++;  // surrogate pair
        }
    }
    return len;
}

static uint32_t getUtf32FromUtf8(const char** pUtf8Ptr) {
    static const unsigned char leaderMask[4] = {0xff, 0x1f, 0x0f, 0x07};
    if (((**pUtf8Ptr) & 0xc0) == 0x80) {
        (*pUtf8Ptr)++;
        return M3N_UTF16_REPLACEMENT_CHAR;
    }
    int seq_len = M3N_UTF8_SEQ_LENGTH(**pUtf8Ptr);
    uint32_t ret = (**pUtf8Ptr) & leaderMask[seq_len - 1];
    if (**pUtf8Ptr == '\0') return ret;
    (*pUtf8Ptr)++;
    for (int i = 1; i < seq_len; i++, (*pUtf8Ptr)++) {
        if ((**pUtf8Ptr) == '\0') return M3N_UTF16_REPLACEMENT_CHAR;
        if (((**pUtf8Ptr) & 0xc0) != 0x80) return M3N_UTF16_REPLACEMENT_CHAR;
        ret = (ret << 6) | (0x3f & (**pUtf8Ptr));
    }
    return ret;
}

// AOSP returns an unterminated UTF-16 string of *out_len units; one extra unit
// is allocated and set to 0 here, which callers that follow the contract never
// read.
char16_t* strdup8to16(const char* s, size_t* out_len) {
    if (s == nullptr) return nullptr;
    size_t len = strlen8to16(s);
    if (len >= SIZE_MAX / sizeof(char16_t)) return nullptr;
    char16_t* ret = static_cast<char16_t*>(malloc(sizeof(char16_t) * (len + 1)));
    if (ret == nullptr) return nullptr;
    char16_t* dest = ret;
    while (*s != '\0') {
        uint32_t c = getUtf32FromUtf8(&s);
        if (c <= 0xffff) {
            *dest++ = static_cast<char16_t>(c);
        } else if (c <= M3N_UNICODE_UPPER_LIMIT) {
            *dest++ = static_cast<char16_t>(0xd800 | ((c - 0x10000) >> 10));
            *dest++ = static_cast<char16_t>(0xdc00 | ((c - 0x10000) & 0x3ff));
        } else {
            *dest++ = M3N_UTF16_REPLACEMENT_CHAR;
        }
    }
    *dest = 0;
    if (out_len != nullptr) *out_len = dest - ret;
    return ret;
}

}  // extern "C"
