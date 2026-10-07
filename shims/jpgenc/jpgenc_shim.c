/*
 * libm3note_jpgenc_shim - JpgEncHal::setEncSize(u32, u32, EncFormat, bool)
 * for libfeatureio.so of the m681 camera set.
 *
 * libfeatureio.so needs _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatEb, but the
 * libJpgEncPipe.so of the same set exports only the 3-argument
 * _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatE, so libcam_platform.so fails to
 * load and no camera opens. The newer JpgEncHal adds a trailing bool
 * (isSrcBufNeedFlush, default true); the older encoder handles the source
 * buffer itself, so the flag is dropped.
 * Wired with TARGET_LD_SHIM_LIBS for /vendor/lib{,64}/libfeatureio.so.
 */
#include <stdbool.h>

struct JpgEncHal;

/* JpgEncHal::setEncSize(unsigned, unsigned, EncFormat) -- libJpgEncPipe.so */
extern bool _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatE(struct JpgEncHal *self,
        unsigned int width, unsigned int height, int fmt);

/* JpgEncHal::setEncSize(unsigned, unsigned, EncFormat, bool) */
bool _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatEb(struct JpgEncHal *self,
        unsigned int width, unsigned int height, int fmt, bool flag)
{
    (void) flag;
    return _ZN9JpgEncHal10setEncSizeEjjNS_9EncFormatE(self, width, height, fmt);
}
