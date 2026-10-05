DEVICE_PATH := device/meizu/m3note
TARGET_MEIZU_MT675X_DEVICE := m681
BOARD_SECCOMP_POLICY := $(DEVICE_PATH)/seccomp

include device/meizu/mt6755-common/BoardConfigCommon.mk
include vendor/meizu/m681/BoardConfigVendor.mk

# RIL: mtk-ril.so calls pthread_kill() on an exited thread during a SIM switch.
# Pie bionic aborts on that only for target SDK >= 26.
TARGET_PROCESS_SDK_VERSION_OVERRIDE := /vendor/bin/hw/rild=25
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681,l681h,l91
TARGET_VENDOR := meizu
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/fstab.mt6755

# Init
# Sets the revision profile (m681 | l681) from the device-tree compatible.
TARGET_INIT_VENDOR_LIB := libinit_m3note
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 1920

# Kernel
# LK keeps only the first 99 bytes of the header cmdline and appends lcm=,
# fps=, vram= and androidboot.hardware itself. L681_KERNEL_CMDLINE_EXTRA goes
# first so it is not cut off.
BOARD_KERNEL_CMDLINE := $(strip $(L681_KERNEL_CMDLINE_EXTRA) bootopt=64S3,32N2,64N2 androidboot.selinux=permissive enforcing=0)

# VNDK
# Not enabled: libgui is vendor_available but depends on libsensor, which is not.

# Partitions
# /vendor lives on the 512 MiB custom partition (p3). VNDK stays unenforced
# (PRODUCT_FULL_TREBLE_OVERRIDE false, shipping API level 25).
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_PARTITION_SIZE := 536870912

# The recovery partition is 16 MiB (mt6755-common assumes 32 MiB).
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
# userdata: eMMC size minus flashinfo (16 MiB) and the backup GPT, rounded down
# to the 128 KiB flash block.
BOARD_USERDATAIMAGE_PARTITION_SIZE := 27308982272

# A-only, no dynamic partitions.
AB_OTA_UPDATER := false

# Split system/vendor build properties (Oreo requirement).
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# SELinux
# The kernel supports policy version 30. If the policy fails to load, set
# POLICYVERS := 29 and drop the allowxperm rules.
# POLICYVERS := 29

# Platform and vendor policy both live in the device tree.
BOARD_PLAT_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/plat
BOARD_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy \
    $(DEVICE_PATH)/sepolicy/vendor

# Boot image
# kernel 0x40080000, ramdisk 0x45000000, second 0x40f00000, tags 0x44000000;
# the stock boot image has an empty board name, so no --board is passed.
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x04f88000 --second_offset 0x00e88000 --tags_offset 0x03f88000
BOARD_RAMDISK_OFFSET := 0x04f88000
BOARD_SECOND_OFFSET := 0x00e88000
BOARD_TAGS_OFFSET := 0x03f88000

# Device
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681,l681h,l91
BOARD_NAME := m3note
TARGET_SYSTEM_PROP := device/meizu/m3note/system.prop

# Prebuilt kernel (4.4). The m681 HWC needs the 3.18/4.4 disp_session ABI.
# TARGET_KERNEL_SOURCE only provides kernel headers; nothing is compiled.
TARGET_NO_KERNEL := false
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_SOURCE := kernel/meizu/meizu_m6/kernel-3.18
TARGET_KERNEL_CONFIG :=
# Image.gz-dtb-m681 and Image.gz-dtb-l681 differ only in the appended board
# DTB. boot.img carries the m681 one; build/tasks/m3note-boot-l681.mk builds
# install/boot-l681.img with the l681 one, which the OTA flashes on l681.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt-kernel/Image.gz-dtb-m681
M3NOTE_L681_KERNEL := $(DEVICE_PATH)/prebuilt-kernel/Image.gz-dtb-l681
BOARD_KERNEL_IMAGE_NAME := kernel
PRODUCT_COPY_FILES += \
    $(TARGET_PREBUILT_KERNEL):kernel

# Fail the build if a prebuilt kernel does not match its
# prebuilt-kernel/EXPECTED-<rev>.txt.
m3note_kernel_check := $(strip \
    $(shell $(DEVICE_PATH)/tools/check_prebuilt_kernel.sh \
        $(TARGET_PREBUILT_KERNEL) $(DEVICE_PATH)/prebuilt-kernel/EXPECTED-m681.txt) \
    $(shell $(DEVICE_PATH)/tools/check_prebuilt_kernel.sh \
        $(M3NOTE_L681_KERNEL) $(DEVICE_PATH)/prebuilt-kernel/EXPECTED-l681.txt))
ifneq ($(m3note_kernel_check),)
$(error $(m3note_kernel_check))
endif

# OTA: device extension (revision check before any write, boot-l681.img on l681).
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)

# RIL
# MTK HIDL RIL wrapper (vendor/mediatek/ril): the stock MTK rild has no IRadio.
# mtk-ril.so needs MTK's telephony/ril.h, whose RIL_Env is larger than AOSP's;
# vendor/mediatek/include contains only telephony headers.
TARGET_SPECIFIC_HEADER_PATH := vendor/mediatek/include
BOARD_PROVIDES_RILD := true
BOARD_PROVIDES_LIBRIL := true
