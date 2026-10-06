# rild: MediaTek Oreo RIL daemon (M681), companion of ../libril/Android.mk.
#
# rild-prop-md1 comes from ../proprietary/Android.mk.  MTK_RIL_ENV_REQUEST_ACK
# gives s_rilEnv the OnRequestAck slot of the N RIL_Env.  The M681 mtk-ril.so
# exports RIL_Init and RIL_SAP_Init but no RIL_InitSocket, so rild.c takes its
# "Old vendor ril" branch: RIL_Init(&s_rilEnv) + RIL_register().  rild.libpath
# is set in vendor.prop.

ifeq ($(TARGET_DEVICE),m3note)
ifeq ($(ENABLE_VENDOR_RIL_SERVICE),true)
LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES:= \
	rild.c

LOCAL_SHARED_LIBRARIES := \
	liblog \
	libcutils \
	libutils \
	libril \
	libdl

LOCAL_STATIC_LIBRARIES := \
	rild-prop-md1

LOCAL_C_INCLUDES += \
	$(LOCAL_PATH)/../include \
	system/core/libcutils/include

LOCAL_CFLAGS += -DANDROID_MULTI_SIM
LOCAL_CFLAGS += -DANDROID_SIM_COUNT_2

# temporary hack for broken vendor rils
LOCAL_WHOLE_STATIC_LIBRARIES := \
	librilutils

LOCAL_CFLAGS += -DRIL_SHLIB
LOCAL_CFLAGS += -DMTK_RIL_ENV_REQUEST_ACK

LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE:= rild

include $(BUILD_EXECUTABLE)
endif
endif
