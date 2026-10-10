# configstore 1.1: the stock hardware/interfaces service plus a runtime
# primaryDisplayOrientation from ro.sf.hwrotation (hwrotation.h). Replaces
# android.hardware.configstore@1.1-service through LOCAL_OVERRIDES_MODULES.
# SurfaceFlingerConfigs.cpp and service.cpp are copies of
# hardware/interfaces/configstore/1.1/default with the "m3note:" hunks.
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := android.hardware.configstore@1.1-service.m3note
LOCAL_OVERRIDES_MODULES := android.hardware.configstore@1.1-service
ifneq ($(NATIVE_COVERAGE),true)
LOCAL_REQUIRED_MODULES_arm64 := configstore@1.1.policy
endif
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_INIT_RC := android.hardware.configstore@1.1-service.m3note.rc
LOCAL_SRC_FILES := service.cpp

include hardware/interfaces/configstore/1.1/default/surfaceflinger.mk

LOCAL_C_INCLUDES := hardware/interfaces/configstore/1.1/default
LOCAL_SHARED_LIBRARIES := \
    libhidlbase \
    libhidltransport \
    libhwbinder \
    libbase \
    libhwminijail \
    liblog \
    libutils \
    android.hardware.configstore@1.0 \
    android.hardware.configstore@1.1

ifeq ($(TARGET_ARCH),arm)
    LOCAL_CFLAGS += -DARCH_ARM_32
endif

include $(BUILD_EXECUTABLE)
