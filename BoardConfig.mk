# SPDX-License-Identifier: Apache-2.0

DEVICE_PATH := device/meizu/m3note

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53
TARGET_USES_64_BIT_BINDER := true

# Platform
TARGET_BOARD_PLATFORM := mt6755
TARGET_BOOTLOADER_BOARD_NAME := mt6755
TARGET_BOARD_PLATFORM_GPU := mali-t860mp2
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
BOARD_NAME := m3note
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681

# Display
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 1920
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2684354560
BOARD_CACHEIMAGE_PARTITION_SIZE := 452984832
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
AB_OTA_UPDATER := false
BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
TARGET_COPY_OUT_VENDOR := system/vendor

# VNDK
# Vendor processes get their own libbinder/libhidl instances; without it
# android.hardware.audio.service aborts with "Binder threadpool cannot be
# shrunk after starting".
BOARD_VNDK_VERSION := current
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# Kernel
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_TAGS_OFFSET := 0x03f88000
BOARD_MKBOOTIMG_ARGS := --board 1480869018 --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --second_offset $(BOARD_SECOND_OFFSET) --tags_offset $(BOARD_TAGS_OFFSET)
BOARD_BOOT_HEADER_VERSION := 0
BOARD_INCLUDE_DTB_IN_BOOTIMG :=
BOARD_INCLUDE_RECOVERY_DTBO :=
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 androidboot.hardware=mt6755 androidboot.selinux=permissive androidboot.usb.config=adb buildvariant=userdebug clk_ignore_unused
TARGET_NO_KERNEL := false
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
# Kernel source is used only for generated kernel headers; the boot kernel
# is prebuilt.
TARGET_KERNEL_SOURCE := kernel/meizu/m681
TARGET_KERNEL_CONFIG := m3note_defconfig
TARGET_KERNEL_VERSION := 4.9
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/Image-m681.gz-dtb
TARGET_FORCE_PREBUILT_KERNEL := true
BOARD_KERNEL_IMAGE_NAME := kernel

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.mt6755

# Mount points for the MTK data partitions in fstab.mt6755.
BOARD_ROOT_EXTRA_FOLDERS := nvdata protect_f protect_s
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_CHARGER_SHOW_PERCENTAGE := true

# SELinux
SELINUX_IGNORE_NEVERALLOWS := true
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor

# Hardware
BOARD_USES_QCOM_HARDWARE := false
TARGET_USES_QCOM_BSP := false

# Properties
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# VINTF
# Per-SKU manifests, selected by ro.boot.product.vendor.sku: keymaster differs.
DEVICE_MANIFEST_SKUS := m681 l681
DEVICE_MANIFEST_M681_FILES := $(DEVICE_PATH)/vintf/manifest_m681.xml
DEVICE_MANIFEST_L681_FILES := $(DEVICE_PATH)/vintf/manifest_l681.xml

# Shims
# N-ABI shims for the legacy blobs, plus liblog for the MTK loaders.  /vendor
# is /system/vendor here, so each pair is listed with both prefixes.
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/egl/libGLES_mali.so|/vendor/lib/libm681shim_base.so \
    /vendor/lib64/egl/libGLES_mali.so|/vendor/lib64/libm681shim_base.so \
    /vendor/lib/hw/gralloc.mt6755.so|/vendor/lib/libm681shim_base.so \
    /vendor/lib64/hw/gralloc.mt6755.so|/vendor/lib64/libm681shim_base.so \
    /vendor/lib/libgui_ext.so|/vendor/lib/libmtkshim_ui.so \
    /vendor/lib64/libgui_ext.so|/vendor/lib64/libmtkshim_ui.so \
    /vendor/bin/spm_loader|liblog.so \
    /vendor/bin/wmt_loader|liblog.so \
    /vendor/bin/wmt_launcher|liblog.so \
    /vendor/lib/hw/audio.primary.mt6755.so|/vendor/lib/libm3note_n_audio.so \
    /vendor/lib64/hw/audio.primary.mt6755.so|/vendor/lib64/libm3note_n_audio.so \
    /system/vendor/lib/egl/libGLES_mali.so|/system/vendor/lib/libm681shim_base.so \
    /system/vendor/lib64/egl/libGLES_mali.so|/system/vendor/lib64/libm681shim_base.so \
    /system/vendor/lib/hw/gralloc.mt6755.so|/system/vendor/lib/libm681shim_base.so \
    /system/vendor/lib64/hw/gralloc.mt6755.so|/system/vendor/lib64/libm681shim_base.so \
    /system/vendor/lib/libgui_ext.so|/system/vendor/lib/libmtkshim_ui.so \
    /system/vendor/lib64/libgui_ext.so|/system/vendor/lib64/libmtkshim_ui.so \
    /system/vendor/bin/spm_loader|liblog.so \
    /system/vendor/bin/wmt_loader|liblog.so \
    /system/vendor/bin/wmt_launcher|liblog.so \
    /system/vendor/lib/hw/audio.primary.mt6755.so|/system/vendor/lib/libm3note_n_audio.so \
    /system/vendor/lib64/hw/audio.primary.mt6755.so|/system/vendor/lib64/libm3note_n_audio.so

# liblog for N daemons that call __android_log_* with only libcutils in
# DT_NEEDED: with full Treble libcutils comes from the VNDK namespace and
# liblog is not in the daemon's local group.  gsm0710muxd is the MD1 mux of
# the RIL chain.
TARGET_LD_SHIM_LIBS += \
    /vendor/bin/gsm0710muxd|liblog.so \
    /vendor/bin/muxreport|liblog.so \
    /vendor/bin/msensord|liblog.so \
    /system/vendor/bin/gsm0710muxd|liblog.so \
    /system/vendor/bin/muxreport|liblog.so \
    /system/vendor/bin/msensord|liblog.so

# thermalloadalgod (init.m681.thermal.rc) needs liblog for the same reason.
TARGET_LD_SHIM_LIBS += \
    /vendor/bin/thermalloadalgod|liblog.so \
    /system/vendor/bin/thermalloadalgod|liblog.so

# Malloc
# N camera blobs allocate GraphicBuffer with the N size (136 bytes on arm)
# while the A13 object is 160; jemalloc rounds 136 up to 160, Scudo does not.
# The camera provider is 32-bit only, so only libc32 uses jemalloc.
MALLOC_SVELTE_FOR_LIBC32 := true

# Build scope
ifneq ($(M3NOTE_BUILD_SCOPE),two-unit-diagnostic)
$(error M3 Note requires the explicit two-unit-diagnostic build scope)
endif
ifeq ($(wildcard $(DEVICE_PATH)/prebuilt/common-kernel-proof.json),)
$(error Source-built common Image and both own DTBs must be admitted first)
endif
ifeq ($(wildcard vendor/meizu/m3note/profile-proof.json),)
$(error Both isolated vendor profiles are required; single-board fallback is forbidden)
endif
include $(DEVICE_PATH)/BoardConfigProfiles.mk
TARGET_RECOVERY_DEVICE_MODULES += m3note_probe
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
# AOSP builds fingerprint.default.so at the same path as the vendor placeholder
# (the Goodix HAL is bind-mounted over it at boot).
BUILD_BROKEN_DUP_RULES := true
TARGET_FS_CONFIG_GEN := $(DEVICE_PATH)/config.fs
