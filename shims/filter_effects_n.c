/* libfilter_effects.so under its real name: libcam.camadapter.so and
 * libcam.camnode.so need it, and the vendor set has no such file (a Meizu
 * filter library of the Flyme camera app).  They import one function,
 * FilterEffect_ProcessImage(int, unsigned char*, ImgFormat, int, int); here it
 * logs and reports failure, leaving the image as it is. */
#include <android/log.h>

int m3note_filter_effect(int effect, unsigned char* image, int format, int width, int height)
        __asm__("_Z25FilterEffect_ProcessImageiPh9ImgFormatii");
int m3note_filter_effect(int effect, unsigned char* image, int format, int width, int height) {
    (void) image; (void) format;
    __android_log_print(ANDROID_LOG_WARN, "m3note-camera",
            "FilterEffect_ProcessImage(%d, %dx%d): no Meizu filter library on A13, skipped",
            effect, width, height);
    return -1;
}
