/*
 * libm3note_gbuf_shim - GraphicBuffer(ANativeWindowBuffer*, bool) for
 * libeffecthal.base.so of the m681 camera set.
 *
 * libeffecthal.base.so (pulled in via libcam.device1 -> libcam.camadapter)
 * needs _ZN7android13GraphicBufferC1EP19ANativeWindowBufferb, which Pie libui
 * no longer has. libmtkshim_ui exports the same name but treats its first
 * argument (this) as the buffer and constructs nothing, so it is not used.
 *
 * The only caller (EffectHalClient::getOutputBuffer) does operator new(136 /
 * 232 on arm / arm64), then this constructor with a buffer from
 * ANativeWindow::dequeueBuffer_DEPRECATED and keepOwnership = false. Pie's
 * GraphicBuffer is 144 / 240 bytes, 8 bytes more than the blob allocates.
 * jemalloc rounds 136 -> 160 and 232 -> 256, so the object fits; the shim
 * checks malloc_usable_size() and aborts rather than overrun the heap.
 *
 * N kept a strong reference to the wrapped ANativeWindowBuffer; Pie's
 * GraphicBuffer has no such member. The Surface keeps its slot buffers alive
 * while connected, so WRAP_HANDLE is used for keepOwnership = false and
 * TAKE_HANDLE for true, as N's ownNone / ownHandle.
 * Wired with TARGET_LD_SHIM_LIBS for /vendor/lib{,64}/libeffecthal.base.so.
 */
#include <malloc.h>

#include <new>

#include <log/log.h>
#include <ui/GraphicBuffer.h>

using android::GraphicBuffer;

void* m3note_gbuf_from_anwb(GraphicBuffer* self, ANativeWindowBuffer* buffer,
        bool keepOwnership)
        __asm__("_ZN7android13GraphicBufferC1EP19ANativeWindowBufferb");

void* m3note_gbuf_from_anwb(GraphicBuffer* self, ANativeWindowBuffer* buffer,
        bool keepOwnership) {
    size_t room = malloc_usable_size(self);
    LOG_ALWAYS_FATAL_IF(room < sizeof(GraphicBuffer),
            "m3note-gbuf: GraphicBuffer needs %zu bytes, allocation has %zu",
            sizeof(GraphicBuffer), room);
    uint32_t layerCount = buffer->layerCount ? buffer->layerCount : 1;
    new (self) GraphicBuffer(buffer->handle,
            keepOwnership ? GraphicBuffer::TAKE_HANDLE : GraphicBuffer::WRAP_HANDLE,
            buffer->width, buffer->height, buffer->format, layerCount,
            buffer->usage, buffer->stride);
    return self;
}
