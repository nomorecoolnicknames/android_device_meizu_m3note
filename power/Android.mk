LOCAL_PATH := $(call my-dir)

# power.default + setFeature(DOUBLE_TAP_TO_WAKE) -> /sys/devices/mx_tsp/gesture_control
# (power.c); selected by ro.hardware.power=m3note (system.prop).
# Boost hints go to the Power HAL engine in ../power-fleet (legacy profile),
# configured by configs/power/fleet_power.json. The engine needs gnu++17.
include $(CLEAR_VARS)
LOCAL_MODULE := power.m3note
LOCAL_MODULE_RELATIVE_PATH := hw
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MULTILIB := both
LOCAL_SRC_FILES := \
    power.c \
    ../power-fleet/Config.cpp \
    ../power-fleet/Engine.cpp \
    ../power-fleet/legacy/LegacyHints.cpp \
    ../power-fleet/legacy/FleetPowerLegacy.cpp
LOCAL_CPP_STD := gnu++17
LOCAL_HEADER_LIBRARIES := libhardware_headers libutils_headers
LOCAL_SHARED_LIBRARIES := liblog libbase
LOCAL_STATIC_LIBRARIES := libjsoncpp
LOCAL_CFLAGS := -Wall -Werror
include $(BUILD_SHARED_LIBRARY)
