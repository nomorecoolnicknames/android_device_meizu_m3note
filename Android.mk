LOCAL_PATH:= $(call my-dir)

ifneq ($(filter m3note, $(TARGET_DEVICE)),)

# Several makefile sets outside this tree are gated on device names that do
# not include m3note; the includes below pull in exactly what the m681 product
# gets. Drop an include once its repo admits m3note itself.

# 1. Subdirectory makefiles of this tree. Keep first, while LOCAL_PATH is
#    still ours.
include $(call first-makefiles-under,$(LOCAL_PATH))

# 2. vendor/mediatek: the GUI-only symbol shims (libmtkshim_gui/ui/sensor/icu),
#    wmt_loader, libwifi-hal-mt66xx and the MTK HIDL RIL (libril, rild).
MTK_SYMBOLS_GUI_ONLY := true
include vendor/mediatek/symbols/Android.mk
MTK_SYMBOLS_GUI_ONLY :=
include vendor/mediatek/combo_loader/Android.mk
include vendor/mediatek/wlan/wifi_hal/Android.mk
include vendor/mediatek/ril/Android.mk

# 3. device/meizu/m3_meizu_m6-common: flyme-res, libbt-vendor and libxlog.
#    lib_driver_cmd_mt66xx is built by wpa_supplicant_8_lib/ in this tree.
#    The mkdir provides the kernel header path.
include device/meizu/m3_meizu_m6-common/flyme/res/Android.mk
include device/meizu/m3_meizu_m6-common/libbt-vendor-mtk/Android.mk
include device/meizu/m3_meizu_m6-common/libxlog/Android.mk
$(shell mkdir -p $(PRODUCT_OUT)/obj/KERNEL_OBJ/usr)

# 4. vendor/meizu/m681: every module is wrapped in ifeq ($(TARGET_DEVICE),m681),
#    so TARGET_DEVICE is set to m681 for the duration of the include only.
#    Install paths are not affected: PRODUCT_OUT and TARGET_OUT_VENDOR* are
#    already fixed by then.
m3note_saved_target_device := $(TARGET_DEVICE)
TARGET_DEVICE := m681
include vendor/meizu/m681/Android.mk
TARGET_DEVICE := $(m3note_saved_target_device)
m3note_saved_target_device :=
ifeq ($(ALL_MODULES.mtk-ril.PATH),)
$(error m3note: vendor/meizu/m681/Android.mk defined no mtk-ril module -- its TARGET_DEVICE guard changed; see device/meizu/m3note/Android.mk step 4)
endif

# 5. m3note_keystore_profile: the Trustonic keystore HAL per revision. The
#    keystore.mt6755.so/keystore.mz6755_66_n.so links are replaced by
#    keystore.m681tee.so, selected only by ro.hardware.keystore=m681tee (set by
#    libinit on m681); l681 uses the software keymaster.
#    LOCAL_REQUIRED_MODULES orders the rm/ln after the m681 symlinks module.
#    LOCAL_PATH is set explicitly: the includes above changed it.
include $(CLEAR_VARS)
LOCAL_PATH := device/meizu/m3note
LOCAL_MODULE := m3note_keystore_profile
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_ETC)
LOCAL_SRC_FILES := keystore/m3note_keystore_profile.txt
LOCAL_REQUIRED_MODULES := m681_vendor_hal_symlinks
LOCAL_POST_INSTALL_CMD := \
    rm -f $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mt6755.so \
          $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mz6755_66_n.so \
          $(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mt6755.so \
          $(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.mz6755_66_n.so && \
    ln -sf libMcTeeKeymaster.so $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.m681tee.so && \
    ln -sf libMcTeeKeymaster.so $(2ND_TARGET_OUT_VENDOR_SHARED_LIBRARIES)/hw/keystore.m681tee.so
include $(BUILD_PREBUILT)

endif
