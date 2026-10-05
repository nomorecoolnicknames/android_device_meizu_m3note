LOCAL_PATH := $(call my-dir)

# Linked into init through TARGET_INIT_VENDOR_LIB (BoardConfig.mk).
include $(CLEAR_VARS)
LOCAL_MODULE := libinit_m3note
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := init_m3note.cpp
LOCAL_C_INCLUDES := system/core/init
LOCAL_STATIC_LIBRARIES := libbase
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_STATIC_LIBRARY)
