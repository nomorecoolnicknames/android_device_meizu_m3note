// libandroid_runtime.so under its real name, for libmeizucamera.so, which
// camera.mt6755.so needs directly (as does libcam.common.meizu).  A Meizu
// camera-app JNI library; the native provider process has no JavaVM, so the two
// helpers it imports report failure.  libcam.common.meizu needs the name but
// imports nothing from it.
struct _JNIEnv;
struct JNINativeMethod;

namespace android {
class AndroidRuntime {
  public:
    static int registerNativeMethods(_JNIEnv* env, const char* className,
                                     const JNINativeMethod* methods, int numMethods);
    static _JNIEnv* getJNIEnv();
};

int AndroidRuntime::registerNativeMethods(_JNIEnv*, const char*, const JNINativeMethod*, int) {
    return -1;
}

_JNIEnv* AndroidRuntime::getJNIEnv() {
    return nullptr;
}
}  // namespace android
