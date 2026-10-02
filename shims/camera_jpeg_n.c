/* libm3note_n_camera_jpeg: libjpeg for the N camera blobs, with a size check.
 *
 * libJpgEncPipe.so imports jpeg_* but does not need libjpeg, so in the vendor
 * namespace the camera group fails to load.  This library needs the VNDK
 * libjpeg, which puts it in the group of the two roots it is shimmed into
 * (hw/camera.mt6755.so, libcam_platform.so).
 *
 * Some struct sizes the blobs pass do not match the A13 libjpeg-turbo, which
 * answers with ERREXIT(JERR_BAD_STRUCT_SIZE); the default error_exit prints
 * to stderr and calls exit(), so the provider would vanish without a logcat
 * line.  These two entry points log the mismatch first and then call the
 * real function.  The affected software encoder path is only a fallback of
 * the hardware JPEG encoder.
 *
 * Shimmed at the roots, so this library is ahead of libjpeg in the breadth-first
 * group order and its two definitions are the ones every member binds to.
 */
#include <dlfcn.h>
#include <stddef.h>
#include <stdio.h>

#include <jpeglib.h>
#include <log/log.h>

#define LOG_TAG_JPEG "m3note-camera-jpeg"

static void (*real_create_compress)(j_compress_ptr, int, size_t);
static void (*real_create_decompress)(j_decompress_ptr, int, size_t);

/* Resolved once at load (no lazy race between camera threads); a missing libjpeg
 * fails when the shim loads, not in the middle of a capture.  dlsym on the libjpeg
 * handle searches that library, not the group, so it never finds the two below. */
__attribute__((constructor)) static void m3note_camera_jpeg_init(void) {
    void* lib = dlopen("libjpeg.so", RTLD_NOW);
    LOG_ALWAYS_FATAL_IF(lib == NULL, "m3note-camera-jpeg: libjpeg.so: %s", dlerror());
    real_create_compress = (void (*)(j_compress_ptr, int, size_t)) dlsym(lib, "jpeg_CreateCompress");
    real_create_decompress =
            (void (*)(j_decompress_ptr, int, size_t)) dlsym(lib, "jpeg_CreateDecompress");
    LOG_ALWAYS_FATAL_IF(real_create_compress == NULL || real_create_decompress == NULL,
                        "m3note-camera-jpeg: libjpeg.so: %s", dlerror());
}

static void check(const char* what, size_t passed, size_t expected) {
    if (passed != expected) {
        __android_log_print(ANDROID_LOG_ERROR, LOG_TAG_JPEG,
                "%s from an N blob with struct size %zu, A13 libjpeg-turbo has %zu: "
                "libjpeg will refuse it (JERR_BAD_STRUCT_SIZE) and the default "
                "error_exit exits the process", what, passed, expected);
    }
}

void jpeg_CreateCompress(j_compress_ptr cinfo, int version, size_t structsize) {
    check("jpeg_CreateCompress", structsize, sizeof(struct jpeg_compress_struct));
    real_create_compress(cinfo, version, structsize);
}

void jpeg_CreateDecompress(j_decompress_ptr cinfo, int version, size_t structsize) {
    check("jpeg_CreateDecompress", structsize, sizeof(struct jpeg_decompress_struct));
    real_create_decompress(cinfo, version, structsize);
}
