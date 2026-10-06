# libril: MediaTek Oreo HIDL RIL library (IRadio 1.0), based on daniel_hk's
# Oreo port of the AOSP libril for MTK.  It drives the stock mtk-ril.so.
#
#  - The symbols the stock blobs miss on Android 13 come from libm3note_n_ril,
#    preloaded into mtk-ril.so / librilmtk.so by TARGET_LD_SHIM_LIBS.
#  - librilmtk / mtk-ril are linked through the uninstallable Soong stand-ins
#    of ../linkstubs: libril imports RIL_queryMyChannelId,
#    RIL_queryMyProxyIdByThread, RIL_requestProxyTimedCallback,
#    android::RIL_startRILProxys, android::enqueue from librilmtk and
#    getIaCache, acquire/release_wake_lock from mtk-ril.
#  - mtk_ril_unsol_commands.h comes from ../proprietary/libril.
#  - The M681 mtk-ril has roamingProtocol in RIL_InitialAttachApn, so
#    MTK_RIL_IAA_NO_ROAMING_PROTOCOL is not set.
#  - MTK_RIL_ENV_REQUEST_ACK: the 7-slot N RIL_Env of the M681 mtk-ril.
#  - ../include is this port's own copy of the RIL headers and comes before
#    the ril_headers exported by librilutils.
#
# Guarded by TARGET_DEVICE: Make parses this file for every product.

ifeq ($(TARGET_DEVICE),m3note)
ifeq ($(BOARD_PROVIDES_LIBRIL),true)
LOCAL_PATH:= $(call my-dir)

ril_src_files := \
    ril.cpp \
    ril_event.cpp\
    RilSapSocket.cpp \
    ril_service.cpp \
    sap_service.cpp

ril_shared_libs := \
    liblog \
    libutils \
    libcutils \
    libhardware_legacy \
    libbinder \
    libm3note_ril_link_rilmtk \
    librilutils \
    libm3note_ril_link_mtkril \
    android.hardware.radio@1.0 \
    android.hardware.radio.deprecated@1.0 \
    libhidlbase

# ../proprietary/libril: mtk_ril_unsol_commands.h, included by ril.cpp.
ril_inc := $(LOCAL_PATH)/../include \
    external/nanopb-c \
    $(LOCAL_PATH)/../proprietary/libril

# M681: RIL_InitialAttachApn WITH roamingProtocol, 7-slot RIL_Env (header).
ril_cflags := -Wno-unused-parameter -DANDROID_SIM_COUNT_2 -DANDROID_MULTI_SIM -DMTK_HARDWARE \
    -DMTK_RIL_ENV_REQUEST_ACK

include $(CLEAR_VARS)
LOCAL_VENDOR_MODULE := true
LOCAL_SRC_FILES := $(ril_src_files)
LOCAL_SHARED_LIBRARIES := $(ril_shared_libs)
LOCAL_STATIC_LIBRARIES := \
    libprotobuf-c-nano-enable_malloc
LOCAL_CFLAGS := $(ril_cflags)
LOCAL_C_INCLUDES += $(ril_inc)
LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_PATH)/../include
LOCAL_MODULE:= libril
LOCAL_SANITIZE := integer
include $(BUILD_SHARED_LIBRARY)

endif
endif
