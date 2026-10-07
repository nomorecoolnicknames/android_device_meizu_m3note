DEVICE_PATH := device/meizu/m3note
TARGET_MEIZU_MT675X_DEVICE := m681
BOARD_SECCOMP_POLICY := $(DEVICE_PATH)/seccomp

include device/meizu/mt6755-common/BoardConfigCommon.mk
include vendor/meizu/m681/BoardConfigVendor.mk

# Shims
# Legacy libgui/libui symbols for the MTK display and camera blobs
# (createBufferQueue with IGraphicBufferAlloc, IDumpTunnel::asInterface,
# GraphicBufferMapper::lock(int)).
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libcam_utils.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libcam.client.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libcam.camnode.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libeffecthal.base.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libjni_lomoeffect.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libvfb_render.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libMtkOmxVenc.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libmtk_mmutils.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libshowlogo.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libgui_ext.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib/libui_ext.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib64/libcam_utils.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libcam.client.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libcam.camnode.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libeffecthal.base.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libjni_lomoeffect.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libvfb_render.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libmtk_mmutils.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libgui_ext.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib64/libui_ext.so|/vendor/lib64/libmtkshim_gui.so

# GPS/sensor daemons: libmpe.sensorlistener needs the N libgui SensorManager
# (moved to libsensor in O), mtk_agpsd needs ICU 56 ucnv_* symbols.
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libmpe.sensorlistener.so|/vendor/lib/libmtkshim_sensor.so \
    /vendor/bin/mtk_agpsd|/vendor/lib/libmtkshim_icu.so

# Camera: libfeatureio.so of the m681 set needs JpgEncHal::setEncSize(..., bool),
# its libJpgEncPipe.so has only the 3-argument one (shims/jpgenc/jpgenc_shim.c).
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libfeatureio.so|/vendor/lib/libm3note_jpgenc_shim.so \
    /vendor/lib64/libfeatureio.so|/vendor/lib64/libm3note_jpgenc_shim.so

# Camera: libskia (N) needs ICU 56, libJpgDecPipe needs the newer DpFragStream
# API, libeffecthal.base needs GraphicBuffer(ANativeWindowBuffer*, bool).
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libskia.so|/vendor/lib/libm3note_icu56_shim.so \
    /vendor/lib64/libskia.so|/vendor/lib64/libm3note_icu56_shim.so \
    /vendor/lib/libJpgDecPipe.so|/vendor/lib/libm3note_dpfrag_shim.so \
    /vendor/lib64/libJpgDecPipe.so|/vendor/lib64/libm3note_dpfrag_shim.so \
    /vendor/lib/libeffecthal.base.so|/vendor/lib/libm3note_gbuf_shim.so \
    /vendor/lib64/libeffecthal.base.so|/vendor/lib64/libm3note_gbuf_shim.so

# Other vendor libraries with unresolved symbols. libJpgEncPipe and
# libcam.utils.sensorlistener have no DT_NEEDED on libjpeg/libsensor; link them
# explicitly so every camera load group is self-contained.
TARGET_LD_SHIM_LIBS += \
    /vendor/lib/libdrmmtkutil.so|/vendor/lib/libmtkshim_icu.so \
    /vendor/lib64/libdrmmtkutil.so|/vendor/lib64/libmtkshim_icu.so \
    /vendor/lib/libcommonpawrapper.so|/vendor/lib/libmtkshim_icu.so \
    /vendor/lib/libvmp_render.so|/vendor/lib/libmtkshim_gui.so \
    /vendor/lib64/libvmp_render.so|/vendor/lib64/libmtkshim_gui.so \
    /vendor/lib/libjni_lomoeffect.so|/vendor/lib/libm3note_gbuf_shim.so \
    /vendor/lib64/libjni_lomoeffect.so|/vendor/lib64/libm3note_gbuf_shim.so \
    /vendor/lib/libJpgEncPipe.so|/system/lib/libjpeg.so \
    /vendor/lib64/libJpgEncPipe.so|/system/lib64/libjpeg.so \
    /vendor/lib/libcam.utils.sensorlistener.so|/vendor/lib/libmtkshim_sensor.so \
    /vendor/lib64/libcam.utils.sensorlistener.so|/vendor/lib64/libmtkshim_sensor.so

TARGET_DEVICE := m3note

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

# Display
# The MTK display blobs are more stable with a 32-bit SurfaceFlinger.
TARGET_32_BIT_SURFACEFLINGER := true
# MTK GuiExt/HWC configures the primary display with three buffers.
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3
# The legacy MTK HWC does not signal present/retire fences reliably.
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := true

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
