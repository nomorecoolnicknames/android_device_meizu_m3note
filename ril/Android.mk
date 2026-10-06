# SPDX-License-Identifier: Apache-2.0
# MTK Oreo HIDL libril and rild (M681).  Included from ../Android.mk: the
# Soong finder stops descending at the first Android.mk of a branch, so
# libril/, rild/ and proprietary/ would not be read otherwise.
# librilmtk / mtk-ril for linking: Soong stand-ins in linkstubs/Android.bp.
ifeq ($(TARGET_DEVICE),m3note)
include $(call all-makefiles-under,$(call my-dir))
endif
