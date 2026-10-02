/* libnativehelper.so under its real name, for libmeizucamera.so (and
 * libmatv_cust.so, which needs it but imports nothing from it).  With no
 * JavaVM in the camera provider the JNI helpers report failure.  Same idea as
 * android_runtime_n.cpp. */
#include <jni.h>

int jniThrowException(JNIEnv* env, const char* className, const char* msg) {
    (void) env; (void) className; (void) msg;
    return -1;
}

int jniThrowRuntimeException(JNIEnv* env, const char* fmt, ...) {
    (void) env; (void) fmt;
    return -1;
}

int jniGetFDFromFileDescriptor(JNIEnv* env, jobject fileDescriptor) {
    (void) env; (void) fileDescriptor;
    return -1;
}
