// libm3note_n_camera: N libui/libutils ABI imported by the N camera blobs and no
// longer exported by Android 13.  Added by TARGET_LD_SHIM_LIBS to
// hw/camera.mt6755.so and libcam_platform.so, the two dlopen() roots of the
// camera provider; a shim at the root is in the local group of every member
// (libcam_utils, libmtk_mmutils, libcam.client, libeffecthal.base, ...).
//
// Needs libmtkshim_ui (libm3note_n_ui): it creates the GraphicBufferMapper
// singleton from A13 libui before any blob runs the N-inline get(), which
// allocates a smaller object than A13 needs.
#include <malloc.h>
#include <stdint.h>
#include <stdlib.h>

#include <new>

#include <log/log.h>
#include <ui/GraphicBuffer.h>
#include <ui/GraphicBufferMapper.h>
#include <ui/Rect.h>
#include <utils/KeyedVector.h>
#include <utils/String8.h>

using android::GraphicBuffer;
using android::GraphicBufferMapper;
using android::Rect;
using android::status_t;

namespace {

// ---- GraphicBuffer constructors -------------------------------------------------
// Every caller does operator new(136) and then the N constructor.  N GraphicBuffer
// was 136 / 232 bytes (arm / arm64); A13's is 160 / 256.  The A13 object is built
// in the blob's allocation, so it has to be big enough: jemalloc rounds 136 -> 160
// and 232 -> 256, Scudo does not (hence MALLOC_SVELTE_FOR_LIBC32 in BoardConfig.mk;
// the provider is 32-bit only).  The check below turns an allocator change into an
// explicit abort instead of a heap overrun.  ANativeWindowBuffer keeps its fields at
// the N offsets, so the blobs' inline field reads stay valid.  GWP-ASan is disabled
// for the provider (system.prop), and the lib64 copies abort on every constructor.
//
// The shims are complete-object constructors (C1); on ARM EABI a constructor
// returns `this` in r0 and the callers use it, so each one returns self.  AArch64
// constructors return void and callers ignore x0.
void check_room(void* self) {
    size_t room = malloc_usable_size(self);
    LOG_ALWAYS_FATAL_IF(room < sizeof(GraphicBuffer),
            "m3note-camera: GraphicBuffer needs %zu bytes, the N blob allocated %zu "
            "(is libc still jemalloc? BoardConfig MALLOC_SVELTE_FOR_LIBC32)",
            sizeof(GraphicBuffer), room);
}

// N keepOwnership=true owned the handle (ownHandle), false wrapped it (ownNone).
GraphicBuffer::HandleWrapMethod wrap_method(bool keepOwnership) {
    return keepOwnership ? GraphicBuffer::TAKE_HANDLE : GraphicBuffer::WRAP_HANDLE;
}

}  // namespace

// GraphicBuffer(uint32_t w, uint32_t h, PixelFormat, uint32_t usage)
GraphicBuffer* m3note_gb_alloc(GraphicBuffer* self, uint32_t w, uint32_t h,
                               android::PixelFormat format, uint32_t usage)
        __asm__("_ZN7android13GraphicBufferC1Ejjij");
GraphicBuffer* m3note_gb_alloc(GraphicBuffer* self, uint32_t w, uint32_t h,
                               android::PixelFormat format, uint32_t usage) {
    check_room(self);
    new (self) GraphicBuffer(w, h, format, 1, usage, "m3note-n-camera");
    return self;
}

// GraphicBuffer(uint32_t w, uint32_t h, PixelFormat, uint32_t usage, uint32_t stride,
//               native_handle_t*, bool keepOwnership)
GraphicBuffer* m3note_gb_handle(GraphicBuffer* self, uint32_t w, uint32_t h,
                                android::PixelFormat format, uint32_t usage, uint32_t stride,
                                native_handle_t* handle, bool keepOwnership)
        __asm__("_ZN7android13GraphicBufferC1EjjijjP13native_handleb");
GraphicBuffer* m3note_gb_handle(GraphicBuffer* self, uint32_t w, uint32_t h,
                                android::PixelFormat format, uint32_t usage, uint32_t stride,
                                native_handle_t* handle, bool keepOwnership) {
    check_room(self);
    new (self) GraphicBuffer(handle, wrap_method(keepOwnership), w, h, format, 1, usage, stride);
    return self;
}

// GraphicBuffer(ANativeWindowBuffer*, bool keepOwnership): libeffecthal.base, with a
// buffer from ANativeWindow::dequeueBuffer.  The 64-bit usage is A13-only; an
// N-built window leaves it 0, so the 32-bit usage_deprecated is the fallback.
GraphicBuffer* m3note_gb_anwb(GraphicBuffer* self, ANativeWindowBuffer* buffer,
                              bool keepOwnership)
        __asm__("_ZN7android13GraphicBufferC1EP19ANativeWindowBufferb");
GraphicBuffer* m3note_gb_anwb(GraphicBuffer* self, ANativeWindowBuffer* buffer,
                              bool keepOwnership) {
    check_room(self);
    uint32_t layerCount = buffer->layerCount ? buffer->layerCount : 1;
    uint64_t usage = buffer->usage ? buffer->usage
                                   : static_cast<uint32_t>(buffer->usage_deprecated);
    new (self) GraphicBuffer(buffer->handle, wrap_method(keepOwnership), buffer->width,
                             buffer->height, buffer->format, layerCount, usage, buffer->stride);
    return self;
}

// ---- lock() with the N argument lists ---------------------------------------------
// A13 added two optional out-params (bytes per pixel / stride); same calls otherwise.
status_t m3note_gb_lock(GraphicBuffer* self, uint32_t usage, void** vaddr)
        __asm__("_ZN7android13GraphicBuffer4lockEjPPv");
status_t m3note_gb_lock(GraphicBuffer* self, uint32_t usage, void** vaddr) {
    return self->lock(usage, vaddr);
}

status_t m3note_gbm_lock(GraphicBufferMapper* self, buffer_handle_t handle, uint32_t usage,
                         const Rect& bounds, void** vaddr)
        __asm__("_ZN7android19GraphicBufferMapper4lockEPK13native_handlejRKNS_4RectEPPv");
status_t m3note_gbm_lock(GraphicBufferMapper* self, buffer_handle_t handle, uint32_t usage,
                         const Rect& bounds, void** vaddr) {
    return self->lock(handle, usage, bounds, vaddr);
}

// ---- android::PropertyMap ------------------------------------------------------------
// libcam_utils imports the N libutils class (ctor, dtor, clear, addProperty,
// hasProperty, tryGetProperty x4); A13 moved it to libinput, which a vendor process
// cannot load.  Based on N system/core/libutils/PropertyMap.cpp.  The blob allocates
// the object, so the only member stays N's KeyedVector<String8, String8>.
namespace android {

class PropertyMap {
  public:
    PropertyMap();
    ~PropertyMap();
    void clear();
    void addProperty(const String8& key, const String8& value);
    bool hasProperty(const String8& key) const;
    bool tryGetProperty(const String8& key, String8& outValue) const;
    bool tryGetProperty(const String8& key, bool& outValue) const;
    bool tryGetProperty(const String8& key, int32_t& outValue) const;
    bool tryGetProperty(const String8& key, float& outValue) const;

  private:
    KeyedVector<String8, String8> mProperties;
};

PropertyMap::PropertyMap() {}

PropertyMap::~PropertyMap() {}

void PropertyMap::clear() {
    mProperties.clear();
}

void PropertyMap::addProperty(const String8& key, const String8& value) {
    mProperties.add(key, value);
}

bool PropertyMap::hasProperty(const String8& key) const {
    return mProperties.indexOfKey(key) >= 0;
}

bool PropertyMap::tryGetProperty(const String8& key, String8& outValue) const {
    ssize_t index = mProperties.indexOfKey(key);
    if (index < 0) {
        return false;
    }
    outValue = mProperties.valueAt(index);
    return true;
}

bool PropertyMap::tryGetProperty(const String8& key, bool& outValue) const {
    int32_t intValue;
    if (!tryGetProperty(key, intValue)) {
        return false;
    }
    outValue = intValue;
    return true;
}

bool PropertyMap::tryGetProperty(const String8& key, int32_t& outValue) const {
    String8 stringValue;
    if (!tryGetProperty(key, stringValue) || stringValue.length() == 0) {
        return false;
    }
    char* end;
    int value = strtol(stringValue.c_str(), &end, 10);
    if (*end != '\0') {
        return false;
    }
    outValue = value;
    return true;
}

bool PropertyMap::tryGetProperty(const String8& key, float& outValue) const {
    String8 stringValue;
    if (!tryGetProperty(key, stringValue) || stringValue.length() == 0) {
        return false;
    }
    char* end;
    float value = strtof(stringValue.c_str(), &end);
    if (*end != '\0') {
        return false;
    }
    outValue = value;
    return true;
}

}  // namespace android
