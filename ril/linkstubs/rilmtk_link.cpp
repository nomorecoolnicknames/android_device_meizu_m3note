// Link-time stand-in for librilmtk.so.  Installed only in m3note-linkstub/,
// off the linker path: it exists only so libril links with DT_NEEDED
// librilmtk.so; on the device the stock blob is used.  The bodies are never
// executed.
//
// The imports libril takes from librilmtk.so; the declarations reproduce the
// mangled names (size_t gives 'm' on arm64 and 'j' on arm):
//   RIL_queryMyChannelId, RIL_queryMyProxyIdByThread,
//   RIL_requestProxyTimedCallback,
//   _ZN7android18RIL_startRILProxysEv,
//   _ZN7android7enqueueEPNS_11RequestInfoEPvmPNS_16UserCallbackInfoE13RIL_SOCKET_ID
#include <stddef.h>

struct timeval;
typedef enum { RIL_LINKSTUB_SOCKET_1 = 0 } RIL_SOCKET_ID;
typedef void (*RIL_TimedCallback)(void* param);

extern "C" int RIL_queryMyChannelId(void* t) {
    (void)t;
    return 0;
}

extern "C" int RIL_queryMyProxyIdByThread() {
    return 0;
}

extern "C" void RIL_requestProxyTimedCallback(RIL_TimedCallback callback, void* param,
                                              const struct timeval* relativeTime, int proxyId) {
    (void)callback;
    (void)param;
    (void)relativeTime;
    (void)proxyId;
}

namespace android {
struct RequestInfo;
struct UserCallbackInfo;

void RIL_startRILProxys() {}

void enqueue(RequestInfo* pRI, void* buffer, size_t buflen, UserCallbackInfo* pUCI,
             RIL_SOCKET_ID socket_id) {
    (void)pRI;
    (void)buffer;
    (void)buflen;
    (void)pUCI;
    (void)socket_id;
}
}  // namespace android
