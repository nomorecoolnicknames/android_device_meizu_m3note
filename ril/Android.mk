# SPDX-License-Identifier: Apache-2.0
# RIL: MTK Oreo HIDL libril and rild. Included from ../Android.mk: the
# finder stops descending at the first Android.mk of a branch, so libril/ and
# rild/ would not be read otherwise. librilmtk and mtk-ril link against the
# Soong stand-ins in linkstubs/Android.bp.
ifeq ($(TARGET_DEVICE),m3note)
include $(call all-makefiles-under,$(call my-dir))
endif
