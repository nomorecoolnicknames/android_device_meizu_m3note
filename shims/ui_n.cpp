// libmtkshim_ui: the library hwcomposer.mt6755.so and libui_ext.so need by this
// name (both ABIs).  Vendor namespace only: it links libui, which sphal cannot
// see.  Everything they need from libcutils/libutils/libbinder/xlog comes from
// libm681shim_base, needed below, so it is in hwcomposer's local group as well.
#include <string.h>

#include <log/log.h>
#include <ui/GraphicBufferMapper.h>
#include <ui/Rect.h>
#include <utils/String8.h>

namespace android {

// ---- GraphicBufferMapper singleton ------------------------------------------
// The N-inline GraphicBufferMapper::get() in the blobs allocates 8 bytes and runs
// the A13 constructor, which needs 16 on arm64 (8 on arm): a heap overrun.
// Creating the singleton here, from libui's own getInstance(), before any blob
// code runs avoids it: sInstance/sLock are libui's exported statics, so the
// blobs' inline get() finds the A13-sized object.  This library is the first
// DT_NEEDED of hwcomposer.mt6755 and libui_ext, and bionic runs the
// constructors of a library's children in DT_NEEDED order before its own.
// Side effect: the mapper HAL is opened when hwcomposer is loaded.
__attribute__((constructor)) static void m681_create_mapper_singleton() {
    (void)GraphicBufferMapper::get();
}

// status_t GraphicBufferMapper::lock(buffer_handle_t, int usage, const Rect&,
// void**): pre-N int usage, not in stock N libui either.  Importers:
// hwcomposer.mt6755, libui_ext (both ABIs).  A13 lock() takes uint32_t usage
// and two optional out-params; `this` is the singleton above.
status_t m681_GraphicBufferMapper_lock_int(GraphicBufferMapper* self, buffer_handle_t handle,
                                           int usage, const Rect& bounds, void** vaddr)
        __asm__("_ZN7android19GraphicBufferMapper4lockEPK13native_handleiRKNS_4RectEPPv");
status_t m681_GraphicBufferMapper_lock_int(GraphicBufferMapper* self, buffer_handle_t handle,
                                           int usage, const Rect& bounds, void** vaddr) {
    return self->lock(handle, static_cast<uint32_t>(usage), bounds, vaddr);
}

// void String8::setPathName(const char*), gone from A13 libutils.  Importers:
// libui_ext (both ABIs), libcam.client.  N body: copy, drop one trailing '/'.
void m681_String8_setPathName(String8* self, const char* name)
        __asm__("_ZN7android7String811setPathNameEPKc");
void m681_String8_setPathName(String8* self, const char* name) {
    size_t len = strlen(name);
    if (len > 0 && name[len - 1] == '/') len--;
    self->setTo(name, len);
}

}  // namespace android

// ---- Fence::~Fence() ----------------------------------------------------------
// Imported by libgui_ext.so (on the hwcomposer path), libshowlogo,
// libMtkOmxVdecEx; A13 libui does not export it.
// A13 Fence is polymorphic (vptr at 0, LightRefBase::mCount after it); N Fence
// had no vtable (mCount at 0, fd at 4).  libgui_ext imports no Fence
// constructor, so every Fence it sees is an A13 object, and its inline
// refcount at offset 0 is the low half of the vptr: the balanced inc/dec leaves
// it unchanged and the "== 1" branch cannot be taken for an aligned vtable
// address.  This destructor is expected never to run; if it does, the object
// is not what the blob thinks it is: log and leave it (the blob frees the
// memory).
extern "C" void _ZN7android5FenceD1Ev(void* self) {
    ALOGE("m681: N-ABI Fence::~Fence() reached for %p — unexpected with A13 Fence objects "
          "(see vendor/meizu/m681/shims/ui_n.cpp)", self);
}
