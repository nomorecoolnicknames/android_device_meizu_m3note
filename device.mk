LOCAL_PATH := device/meizu/m3note
# The m681 vendor set serves both revisions.
TARGET_MEIZU_MT675X_DEVICE := m681

$(call inherit-product, device/meizu/mt6755-common/device-common.mk)
# Optional: this tree may not ship the dalvik-heap presets.
$(call inherit-product-if-exists, frameworks/native/build/phone-xxhdpi-3072-dalvik-heap.mk)

# Vendor
# m681 blobs for both revisions plus the m681/l681 revision profiles (modem, WMT,
# sensors, TEE keystore), selected at runtime by ro.vendor.meizu.profile.
$(call inherit-product, vendor/meizu/m3note/m3note-vendor.mk)

# Sensors, cpufreq and camera init scripts (cpufreq arming can be disabled with
# persist.vendor.m3note.cpufreq_arm=0).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/m3note-sensors.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/m3note-sensors.rc \
    $(LOCAL_PATH)/rootdir/m3note-cpufreq.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/m3note-cpufreq.rc \
    $(LOCAL_PATH)/rootdir/bin/m3note-cpufreq-arm.sh:$(TARGET_COPY_OUT_VENDOR)/bin/m3note-cpufreq-arm.sh \
    $(LOCAL_PATH)/rootdir/m3note-camera.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/m3note-camera.rc

# Panel -> revision table, shared by libinit_m3note (/vendor/etc) and the OTA
# revision check (install/, see releasetools.py).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/install/m3note-panels.tsv:$(TARGET_COPY_OUT_VENDOR)/etc/m3note-panels.tsv \
    $(LOCAL_PATH)/install/m3note-panels.tsv:install/m3note-panels.tsv \
    $(LOCAL_PATH)/install/bin/m3note-revision.sh:install/bin/m3note-revision.sh \
    $(LOCAL_PATH)/install/bin/m3note-boot-verify.sh:install/bin/m3note-boot-verify.sh

PRODUCT_DEVICE := m3note

# Keep the platform camera/audio framework libraries: the Flyme copies shadow
# the Lineage ones and break app_process. filter-out supports a single '%'.
PRODUCT_COPY_FILES := $(filter-out \
    %:system/lib/libcamera_metadata.so \
    %:system/lib64/libcamera_metadata.so \
    %:system/lib/libcamera_client.so \
    %:system/lib64/libcamera_client.so \
    %:system/lib/libcamera2ndk.so \
    %:system/lib64/libcamera2ndk.so \
    %:system/lib/libcameraservice.so \
    %:system/lib64/libcameraservice.so \
    %:system/lib/libaudioflinger.so \
    %:system/lib/libaudiopolicymanager.so \
    %:system/lib64/libaudiopolicymanager.so \
    %:system/lib/libaudiopolicymanagerdefault.so \
    %:system/lib64/libaudiopolicymanagerdefault.so \
    %:system/lib/libaudiopolicyservice.so \
    %:system/lib64/libaudiopolicyservice.so \
    %:system/lib/libaudiopolicyenginedefault.so \
    %:system/lib64/libaudiopolicyenginedefault.so \
    %:system/lib/libaudioeffect_jni.so \
    %:system/lib64/libaudioeffect_jni.so \
    %:system/etc/audio_policy_configuration.xml \
    %:system/etc/audio_policy_volumes.xml \
    %:system/etc/default_volume_tables.xml \
    %:system/etc/a2dp_audio_policy_configuration.xml \
    %:system/etc/usb_audio_policy_configuration.xml \
    %:system/etc/r_submix_audio_policy_configuration.xml \
    vendor/meizu/m681/proprietary/vendor/app/AtciService/% \
    vendor/meizu/m681/proprietary/vendor/app/AutoDialer/% \
    vendor/meizu/m681/proprietary/vendor/app/BatteryWarning/% \
    vendor/meizu/m681/proprietary/vendor/app/BtTool/% \
    vendor/meizu/m681/proprietary/vendor/app/CalendarImporter/% \
    vendor/meizu/m681/proprietary/vendor/app/DrmProvider/% \
    vendor/meizu/m681/proprietary/vendor/app/EngineerMode/% \
    vendor/meizu/m681/proprietary/vendor/app/Gba/% \
    vendor/meizu/m681/proprietary/vendor/app/LocationEM2/% \
    vendor/meizu/m681/proprietary/vendor/app/MDMLSample/% \
    vendor/meizu/m681/proprietary/vendor/app/MTKLogger/% \
    vendor/meizu/m681/proprietary/vendor/app/MTKThermalManager/% \
    vendor/meizu/m681/proprietary/vendor/app/MiraVision/% \
    vendor/meizu/m681/proprietary/vendor/app/MtkFloatMenu/% \
    vendor/meizu/m681/proprietary/vendor/app/RootPA/% \
    vendor/meizu/m681/proprietary/vendor/app/SelfRegister/% \
    vendor/meizu/m681/proprietary/vendor/app/SensorHub/% \
    vendor/meizu/m681/proprietary/vendor/app/SimRecoveryTestTool/% \
    vendor/meizu/m681/proprietary/vendor/app/YGPS/%,\
    $(PRODUCT_COPY_FILES))

# Kernel
# Wire the prebuilt kernel explicitly so target_files has no empty ":kernel"
# rule. M681_PREBUILT_KERNEL would bypass the prebuilt-kernel check: product
# config is read before BoardConfig and the first ":kernel" rule wins.
ifneq ($(strip $(M681_PREBUILT_KERNEL)),)
$(error m3note: M681_PREBUILT_KERNEL is set ($(M681_PREBUILT_KERNEL)); unset it, the kernel comes from prebuilt-kernel/)
endif
M681_EFFECTIVE_KERNEL_PREBUILT := $(strip $(TARGET_PREBUILT_KERNEL))
ifneq ($(M681_EFFECTIVE_KERNEL_PREBUILT),)
PRODUCT_COPY_FILES += \
    $(M681_EFFECTIVE_KERNEL_PREBUILT):kernel
endif

# Vendor runtime fixes:
# - mnld is a 32-bit vendor binary and aborts without libcurl.
# - The Goodix fingerprint HAL links libgf_* from the system linker namespace.
# - camera libcam_platform dlopens libvmp_render from the vendor namespace.
# - camera libcam.camadapter needs the stock FilterEffect_ProcessImage symbol.
# - camera.mt6755.so needs its camera_client/metadata ABI in the vendor path.
# - The stock ProjectConfig keeps the camera feature matrix visible.
# - The stock static fuelgauged avoids a libfgauge/libc++ bad_alloc abort.
# - fp-keys/mtk-kpd/ACCDET must not fall back to Generic.kl.
PRODUCT_COPY_FILES += \
    vendor/meizu/m681/proprietary/vendor/lib/libcurl.so:$(TARGET_COPY_OUT_VENDOR)/lib/libcurl.so \
    vendor/meizu/m681/proprietary/vendor/lib/libvmp_render.so:$(TARGET_COPY_OUT_VENDOR)/lib/libvmp_render.so \
    vendor/meizu/m681/proprietary/lib/libcamera_client.so:$(TARGET_COPY_OUT_VENDOR)/lib/libcamera_client.so \
    vendor/meizu/m681/proprietary/lib/libcamera_metadata.so:$(TARGET_COPY_OUT_VENDOR)/lib/libcamera_metadata.so \
    vendor/meizu/m681/proprietary/vendor/data/misc/ProjectConfig.mk:$(TARGET_COPY_OUT_VENDOR)/data/misc/ProjectConfig.mk \
    vendor/meizu/m681/proprietary/lib/libfilter_effects.so:system/lib/libfilter_effects.so \
    vendor/meizu/m681/proprietary/lib64/libfilter_effects.so:system/lib64/libfilter_effects.so \
    vendor/meizu/m681/proprietary/bin/goodixfingerprintd:system/bin/goodixfingerprintd \
    vendor/meizu/m681/proprietary/lib/libcamera_client_mtk.so:system/lib/libcamera_client_mtk.so \
    vendor/meizu/m681/proprietary/lib64/libcamera_client_mtk.so:system/lib64/libcamera_client_mtk.so \
    vendor/meizu/m681/proprietary/vendor/lib/libMcClient.so:system/lib/libMcClient.so \
    vendor/meizu/m681/proprietary/lib/libgf_ca.so:system/lib/libgf_ca.so \
    vendor/meizu/m681/proprietary/vendor/lib64/libvmp_render.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libvmp_render.so \
    vendor/meizu/m681/proprietary/lib64/libcamera_client.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libcamera_client.so \
    vendor/meizu/m681/proprietary/lib64/libcamera_metadata.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libcamera_metadata.so \
    vendor/meizu/m681/proprietary/vendor/lib64/libMcClient.so:system/lib64/libMcClient.so \
    vendor/meizu/m681/proprietary/lib64/libgf_hal.so:system/lib64/libgf_hal.so \
    vendor/meizu/m681/proprietary/lib64/libgf_ca.so:system/lib64/libgf_ca.so \
    vendor/meizu/m681/proprietary/lib64/libgf_algo.so:system/lib64/libgf_algo.so \
    vendor/meizu/m681/proprietary/vendor/bin/fuelgauged_static:system/bin/fuelgauged_static \
    $(LOCAL_PATH)/keylayout/fp-keys.kl:system/usr/keylayout/fp-keys.kl \
    $(LOCAL_PATH)/keylayout/mtk-kpd.kl:system/usr/keylayout/mtk-kpd.kl \
    $(LOCAL_PATH)/keylayout/ACCDET.kl:system/usr/keylayout/ACCDET.kl \
    $(LOCAL_PATH)/keylayout/mtk-tpd.kl:system/usr/keylayout/mtk-tpd.kl

# Modem
# Per-revision firmware comes from vendor/meizu/m3note (profile-m681.mk,
# profile-l681.mk) under the same file names. IMEI lives in NVRAM.

PRODUCT_PROPERTY_OVERRIDES += \
    rild.libpath=mtk-ril.so \
    ril.first.md=1 \
    ril.active.md=12 \
    ril.current.share_modem=2 \
    ril.external.md=0 \
    ril.flightmode.poweroffMD=0 \
    ril.radiooff.poweroffMD=0 \
    ril.specific.sm_cause=0 \
    ril.telephony.mode=0 \
    ro.telephony.sim.count=2 \
    ro.telephony.default_network=9,9 \
    persist.m681.ril.no_ia=1 \
    persist.radio.default.sim=0 \
    persist.radio.mobile.data=1,1 \
    persist.radio.mobile.enable=1,1 \
    persist.radio.multisim.config=dsds \
    persist.radio.flashless.fsm=0 \
    persist.radio.flashless.fsm_cst=0 \
    persist.radio.flashless.fsm_rw=0 \
    persist.radio.fd.counter=15 \
    persist.radio.fd.off.counter=5 \
    persist.radio.fd.r8.counter=15 \
    persist.radio.fd.off.r8.counter=5 \
    persist.radio.mtk_dsbp_support=1 \
    persist.radio.mtk_ps2_rat=W/G \
    wifi.interface=wlan0 \
    wifi.direct.interface=wlan0 \
    wifi.tethering.interface=ap0 \
    ro.mtk.no_conn_autostart=true \
    qemu.hw.mainkeys=0 \
    ro.mediatek.wlan.wsc=1 \
    ro.mediatek.wlan.p2p=0 \
    ro.mediatek.gemini_support=true \
    ro.mediatek.chip_ver=S01 \
    ro.mediatek.version.sdk=4 \
    ro.mtk_agps_app=1 \
    ro.mtk_bt_support=1 \
    ro.mtk_c2k_support=0 \
    ro.mtk.c2k.om.mode=none \
    ro.mtk.c2k.slot2.support=0 \
    ro.mtk_dhcpv6c_wifi=1 \
    ro.mtk_eap_sim_aka=1 \
    ro.mtk_enable_md1=1 \
    ro.mtk_enable_md3=0 \
    ro.mtk_external_sim_support=0 \
    ro.mtk_gemini_support=1 \
    ro.mtk_gemini_enhancement=1 \
    ro.mtk_gps_support=1 \
    ro.mtk_lte_support=1 \
    ro.mtk_md_world_mode_support=1 \
    ro.mtk_modem_monitor_support=1 \
    ro.mtk_srlte_support=1 \
    ro.mtk_sim_hot_swap=1 \
    ro.mtk_sim_hot_swap_common_slot=1 \
    ro.mtk_trustonic_tee_support=1 \
    ro.mtk_wapi_support=1 \
    ro.mtk_wlan_support=1 \
    ro.mtk_world_phone=1 \
    ro.mtk_world_phone_policy=0 \
    ro.mtk_audio_ape_support=1 \
    ro.mtk_deinterlace_support=1 \
    ro.mtk_flv_playback_support=1 \
    ro.mtk_widevine_drm_l3_support=1 \
    ro.mtk_wmv_playback_support=1 \
    ro.mtk_wfd_support=1 \
    ro.mtk_wfd_sink_support=1 \
    ro.mtk_wfd_sink_uibc_support=1 \
    persist.mtk.datashaping.support=1 \
    persist.mtk.wcn.combo.chipid=-1 \
    persist.mtk.wcn.dynamic.dump=0 \
    persist.mtk.wcn.fwlog.status=no

# Dexopt: PackageManager aborts if any compiler-filter property is empty.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    pm.dexopt.first-boot=verify-at-runtime \
    pm.dexopt.boot=verify-at-runtime \
    pm.dexopt.install=interpret-only \
    pm.dexopt.bg-dexopt=speed-profile \
    pm.dexopt.ab-ota=speed-profile \
    pm.dexopt.nsys-library=speed \
    pm.dexopt.shared-apk=speed \
    pm.dexopt.forced-dexopt=speed \
    pm.dexopt.core-app=speed

PRODUCT_PROPERTY_OVERRIDES += \
    persist.m681.cam.no_torch=0 \
    persist.m681.cam.force640=0 \
    persist.m681.cam.no_fullraw=1 \
    persist.m681.cam.p1path=2 \
    persist.m681.cam.pre_p1magic=1 \
    persist.m681.cam.sync_tuning=1 \
    persist.m681.cam.deq_retry=0 \
    persist.m681.cam.deq_us=50000 \
    persist.m681.cam.deq_to=100 \
    camera.disable_zsl_mode=1 \
    camera.zsdmode=0 \
    debug.featurepipe.enable=0 \
    debug.tworunpass2.enable=0 \
    debug.lowPowerVR.enable=0 \
    debug.forceFPS.enable=0 \
    debug.pass1.pdafon=0 \
    debug.pass1.rawtype=0 \
    debug.mtk_cam_zsdmfb_support=0 \
    debug.mtk_cam_zsdhdr_support=0 \
    debug.camera.vfb.disable=1 \
    debug.camera.eis.disable=1 \
    debug.eis.EMEnabled=0 \
    debug.eis.dump=0 \
    debug.eisDrv.dump=0 \
    debug.eis.disable=1 \
    persist.camera.eis.enable=0 \
    persist.camera.eis.disable=1 \
    persist.camera.vfb.enable=0 \
    persist.camera.vfb.disable=1 \
    cam.dumpnpipelog.enable=0 \
    camera.featurepipe.dumpvfb=0

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:system/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.telephony.cdma.xml:system/etc/permissions/android.hardware.telephony.cdma.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.autofocus.xml:system/etc/permissions/android.hardware.camera.autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:system/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:system/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:system/etc/permissions/android.hardware.fingerprint.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:system/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:system/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.print.xml:system/etc/permissions/android.software.print.xml \
    frameworks/native/data/etc/android.software.sip.xml:system/etc/permissions/android.software.sip.xml \
    packages/wallpapers/LivePicker/android.software.live_wallpaper.xml:system/etc/permissions/android.software.live_wallpaper.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_configuration.xml:system/etc/audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:system/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:system/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/a2dp_audio_policy_configuration.xml:system/etc/a2dp_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:system/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:system/etc/r_submix_audio_policy_configuration.xml \
    hardware/broadcom/wlan/bcmdhd/config/p2p_supplicant_overlay.conf:system/etc/wifi/p2p_supplicant_overlay.conf \
    hardware/broadcom/wlan/bcmdhd/config/wpa_supplicant_overlay.conf:system/etc/wifi/wpa_supplicant_overlay.conf \
    $(LOCAL_PATH)/wifi/wifi_concurrency_cfg.txt:system/etc/wifi/wifi_concurrency_cfg.txt \
    vendor/meizu/m681/proprietary/vendor/firmware/WMT_SOC.cfg:system/etc/firmware/WMT_SOC.cfg \
    $(LOCAL_PATH)/gps/gps.conf:system/etc/gps.conf \
    $(LOCAL_PATH)/media/media_codecs.xml:system/etc/media_codecs.xml \
    $(LOCAL_PATH)/media/media_codecs_performance.xml:system/etc/media_codecs_performance.xml \
    $(LOCAL_PATH)/media/media_codecs_mediatek_audio.xml:system/etc/media_codecs_mediatek_audio.xml \
    $(LOCAL_PATH)/media/media_codecs_mediatek_video.xml:system/etc/media_codecs_mediatek_video.xml \
    $(LOCAL_PATH)/media/media_codecs_google_audio.xml:system/etc/media_codecs_google_audio.xml \
    $(LOCAL_PATH)/media/media_codecs_google_video_le.xml:system/etc/media_codecs_google_video_le.xml \
    $(LOCAL_PATH)/media/media_profiles.xml:system/etc/media_profiles.xml \
    $(LOCAL_PATH)/rootdir/default.prop:root/default.prop \
    $(LOCAL_PATH)/rootdir/FWUpgradeInit.rc:root/FWUpgradeInit.rc \
    $(LOCAL_PATH)/sepolicy/file_contexts:root/file_contexts \
    $(LOCAL_PATH)/rootdir/fstab.mt6755:root/fstab.mt6755 \
    $(LOCAL_PATH)/rootdir/init.aee.rc:root/init.aee.rc \
    $(LOCAL_PATH)/rootdir/init.c2k.rc:root/init.c2k.rc \
    $(LOCAL_PATH)/rootdir/init.common_svc.rc:root/init.common_svc.rc \
    $(LOCAL_PATH)/rootdir/init.connectivity.rc:root/init.connectivity.rc \
    $(LOCAL_PATH)/rootdir/init.epdg.rc:root/init.epdg.rc \
    $(LOCAL_PATH)/rootdir/init.fon.rc:root/init.fon.rc \
    $(LOCAL_PATH)/rootdir/init.microtrust.rc:root/init.microtrust.rc \
    $(LOCAL_PATH)/rootdir/init.modem.rc:root/init.modem.rc \
    $(LOCAL_PATH)/rootdir/init.mt6755.rc:root/init.mt6755.rc \
    $(LOCAL_PATH)/rootdir/init.mt6755.usb.rc:root/init.mt6755.usb.rc \
    $(LOCAL_PATH)/rootdir/init.no_ssd.rc:root/init.no_ssd.rc \
    $(LOCAL_PATH)/rootdir/init.nvdata.rc:root/init.nvdata.rc \
    $(LOCAL_PATH)/rootdir/init.preload.rc:root/init.preload.rc \
    $(LOCAL_PATH)/rootdir/init.project.rc:root/init.project.rc \
    $(LOCAL_PATH)/rootdir/init.recovery.mt6755.rc:root/init.recovery.mt6755.rc \
    $(LOCAL_PATH)/rootdir/init.rilproxy.rc:root/init.rilproxy.rc \
    $(LOCAL_PATH)/rootdir/init.ssd.rc:root/init.ssd.rc \
    $(LOCAL_PATH)/rootdir/init.ssd_nomuser.rc:root/init.ssd_nomuser.rc \
    $(LOCAL_PATH)/rootdir/init.trace.rc:root/init.trace.rc \
    $(LOCAL_PATH)/rootdir/init.trustonic.rc:root/init.trustonic.rc \
    $(LOCAL_PATH)/rootdir/init.usb.configfs.rc:root/init.usb.configfs.rc \
    $(LOCAL_PATH)/rootdir/init.volte.rc:root/init.volte.rc \
    $(LOCAL_PATH)/rootdir/init.xlog.rc:root/init.xlog.rc \
    $(LOCAL_PATH)/rootdir/init.zygote32.rc:root/init.zygote32.rc \
    $(LOCAL_PATH)/rootdir/init.zygote64_32.rc:root/init.zygote64_32.rc \
    $(LOCAL_PATH)/rootdir/property_contexts:root/property_contexts \
    $(LOCAL_PATH)/rootdir/seapp_contexts:root/seapp_contexts \
    $(LOCAL_PATH)/rootdir/service_contexts:root/service_contexts \
    $(LOCAL_PATH)/rootdir/ueventd.mt6755.rc:root/ueventd.mt6755.rc \
    $(LOCAL_PATH)/rootdir/ueventd.rc:root/ueventd.rc \
    $(LOCAL_PATH)/rootdir/bin/pstore-preserve.sh:root/sbin/pstore-preserve.sh \
    $(LOCAL_PATH)/rootdir/bin/forge-nvram-fstab.sh:root/sbin/forge-nvram-fstab.sh \
    $(LOCAL_PATH)/rootdir/bin/forge-wifi-conf.sh:root/sbin/forge-wifi-conf.sh \
    $(LOCAL_PATH)/wifi/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
    $(LOCAL_PATH)/rootdir/bin/bootdiag-mark.sh:root/sbin/bootdiag-mark.sh \
    $(LOCAL_PATH)/rootdir/bin/mcregistry-setup.sh:root/sbin/mcregistry-setup.sh \
    $(LOCAL_PATH)/rootdir/bin/repair-userde.sh:root/sbin/repair-userde.sh \
    $(LOCAL_PATH)/rootdir/bin/m681_connectivity_autostart.sh:root/sbin/m681_connectivity_autostart.sh \
    $(LOCAL_PATH)/rootdir/bin/m681_wifi_kick.sh:system/bin/m681_wifi_kick.sh \
    $(LOCAL_PATH)/rootdir/bin/forge-ril-kick.sh:system/bin/forge-ril-kick.sh \
    $(LOCAL_PATH)/rootdir/forge-ril-kick.rc:system/etc/init/forge-ril-kick.rc \
    $(LOCAL_PATH)/rootdir/forge-diag.rc:system/etc/init/forge-diag.rc \
    $(LOCAL_PATH)/rootdir/bin/m681_mdtype_fix.sh:system/bin/m681_mdtype_fix.sh \
    $(LOCAL_PATH)/rootdir/bin/m681_postboot_recover.sh:system/bin/m681_postboot_recover.sh
# libinvensense_hal/libmllite/libmplmpu are installed to /vendor/lib64 by the
# vendor makefile, where sensors.mt6755.so finds them.

PRODUCT_PACKAGES += \
    libfs_mgr \
    libion \
    libwifi-hal-mt66xx \
    libtinycompress \
    libtinyxml \
    libtinyxml_32 \
    libxml2 \
    m681_nvram_wifi_repair \
    org.apache.http.legacy \
    sgdisk \
    m681_vendor_hal_symlinks \
    m3note_keystore_profile \
    wpa_supplicant \
    wpa_supplicant.conf

# MTK framework resources, IMS/VoWiFi and diagnostics (prebuilts from
# vendor/meizu/m681). Flyme DataProtection is excluded.
PRODUCT_PACKAGES += \
    mediatek-res \
    CustomPropInterface \
    ImsService \
    WfoService \
    CDS_INFO

# HIDL HALs
# The Nougat vendor set ships no android.hardware.*-service binaries; the
# .mtk-service variants come from vendor/mediatek/hidl, the generic ones from
# hardware/interfaces.
PRODUCT_PACKAGES += \
    hwservicemanager \
    vndservicemanager \
    servicemanager \
    mediaserver

# Graphics
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator@2.0-impl \
    android.hardware.graphics.allocator@2.0-service \
    android.hardware.graphics.composer@2.1-impl \
    android.hardware.graphics.mapper@2.0-impl \
    android.hardware.memtrack@1.0-impl \
    android.hardware.renderscript@1.0-impl \
    libmtkshim_gui \
    libmtkshim_ui \
    libmtkshim_sensor \
    libmtkshim_icu

# Lights: the generic service is a passthrough wrapper and needs the -impl
# library to load the legacy lights.mt6755.so.
PRODUCT_PACKAGES += \
    android.hardware.light@2.0-service \
    android.hardware.light@2.0-impl

# Vibrator: MTK HIDL wrapper around the legacy vibrator.default.so.
PRODUCT_PACKAGES += \
    android.hardware.vibrator@1.0-service.mtk

# Sensors: wrappers around the blob HAL. m681 uses sensors.mt6755.so
# (InvenSense MPL), l681 uses sensors.l681.so (hwmsen) via ro.hardware.sensors.
PRODUCT_PACKAGES += \
    android.hardware.sensors@1.0-impl.mtk \
    android.hardware.sensors@1.0-service.mtk

# Camera / GNSS / media
# The camera provider service is passthrough and needs the -impl library.
PRODUCT_PACKAGES += \
    android.hardware.gnss@1.0-impl \
    android.hardware.gnss@1.0-service \
    android.hardware.camera.provider@2.4-impl \
    android.hardware.camera.provider@2.4-service \
    libstagefright_soft_avcenc \
    libstagefright_soft_aacdec \
    libstagefright_soft_aacenc \
    libstagefright_soft_amrdec \
    libstagefright_soft_amrnbenc \
    libstagefright_soft_amrwbenc \
    libstagefright_soft_avcdec \
    libstagefright_soft_flacdec \
    libstagefright_soft_flacenc \
    libstagefright_soft_g711dec \
    libstagefright_soft_gsmdec \
    libstagefright_soft_hevcdec \
    libstagefright_soft_mp3dec \
    libstagefright_soft_mpeg2dec \
    libstagefright_soft_mpeg4dec \
    libstagefright_soft_mpeg4enc \
    libstagefright_soft_opusdec \
    libstagefright_soft_rawdec \
    libstagefright_soft_vorbisdec \
    libstagefright_soft_vpxdec \
    libstagefright_soft_vpxenc \
    libcurl \
    libandroid_net

# Wi-Fi / Bluetooth
PRODUCT_PACKAGES += \
    android.hardware.wifi@1.0 \
    android.hardware.wifi@1.0-service \
    lib_driver_cmd_mt66xx \
    hostapd \
    wificond \
    wmt_loader \
    android.hardware.bluetooth@1.0-service.mtk

# VINTF
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sepolicy/manifest.xml:system/manifest.xml \
    $(LOCAL_PATH)/sepolicy/compatibility_matrix.xml:system/compatibility_matrix.xml

# hwservicemanager reads the device manifest from /vendor/manifest.xml.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/sepolicy/manifest.xml:$(TARGET_COPY_OUT_VENDOR)/manifest.xml

# Legacy codecs still probe the media_profiles_V1_0.xml name.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_profiles.xml:system/etc/media_profiles_V1_0.xml

# Device identity
PRODUCT_NAME := lineage_m3note
PRODUCT_DEVICE := m3note
PRODUCT_BRAND := meizu
PRODUCT_MANUFACTURER := Meizu
PRODUCT_MODEL := M3 Note
PRODUCT_RELEASE_NAME := m3note
TARGET_OTA_ASSERT_DEVICE := m3note,m681,l681,l681h,l91
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=lineage_m3note \
    PRODUCT_DEVICE=m3note \
    TARGET_DEVICE=m3note

# ADB
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.secure=0 \
    ro.debuggable=1 \
    ro.adb.secure=0 \
    persist.sys.usb.config=adb \
    persist.service.adb.enable=1 \
    persist.sys.adb.shell=/system/bin/sh
# sys.usb.ffs.aio_compat=1 lives in rootdir/default.prop: /vendor/default.prop
# is loaded before /vendor is mounted on this device.

# libalsautils is missing from the m681 set (the MT675x Nougat copy is used);
# the MTK audio HAL loads it from /vendor/lib[64].
PRODUCT_COPY_FILES += \
    vendor/meizu/m681/proprietary/vendor/lib/libalsautils.so:$(TARGET_COPY_OUT_VENDOR)/lib/libalsautils.so \
    vendor/meizu/m681/proprietary/vendor/lib64/libalsautils.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libalsautils.so

# Zygote: GL preload opens /proc/ged, which fails the post-fork fd sanitizer.
# Set in build.prop and rootdir/default.prop (prop.default is not loaded here).
PRODUCT_PROPERTY_OVERRIDES += ro.zygote.disable_gl_preload=true

# PackageManagerService throws if any pm.dexopt.* compiler filter is empty.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    pm.dexopt.first-boot=quicken \
    pm.dexopt.boot=verify \
    pm.dexopt.install=quicken \
    pm.dexopt.bg-dexopt=speed-profile \
    pm.dexopt.ab-ota=speed-profile \
    pm.dexopt.inactive=verify \
    pm.dexopt.shared=speed

# Silence log spam: keystore retries the Trustonic MobiCore daemon, which never
# runs here (the secure OS is MicroTrust TEEI), and vndksupport logs every
# vendor HAL load (there is no sphal namespace on this device).
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    log.tag.McClient=S \
    log.tag.McDriverClient=S \
    log.tag.TeeSyCommonClient=S \
    log.tag.TeeSyMcClient=S \
    log.tag.vndksupport=S

# Seccomp: the MTK OMX components need the additional vendor policy, otherwise
# media.omx hits SIGSYS on pselect6.
PRODUCT_COPY_FILES += \
    device/meizu/m3note/seccomp/mediacodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy

# RIL
# Build the MTK HIDL rild/libril (vendor/mediatek/ril) instead of the AOSP ones;
# ENABLE_VENDOR_RIL_SERVICE swaps rild, BOARD_PROVIDES_LIBRIL swaps libril.
ENABLE_VENDOR_RIL_SERVICE := true

PRODUCT_PACKAGES += \
    rild

# Install the RIL blobs explicitly: they are optional prebuilt modules and
# rild.libpath is only a runtime dlopen, not a build dependency.
PRODUCT_PACKAGES += \
    librilmtk \
    mtk-ril

# The MTK rild installs no init script; drop any inherited rild.rc and use ours.
PRODUCT_COPY_FILES := $(filter-out %:$(TARGET_COPY_OUT_VENDOR)/etc/init/rild.rc, \
    $(PRODUCT_COPY_FILES))
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rild-mtk-hidl.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/rild.rc

# HWC1 wrapper: the m681 HWC blob never powers the panel down
# (DispDevice::setPowerMode is a stub); the wrapper adds FBIOBLANK around it.
# Selected by ro.hardware.hwcomposer=m3note (system.prop).
PRODUCT_PACKAGES += \
    hwcomposer.m3note

# Camera ABI shims (see TARGET_LD_SHIM_LIBS in BoardConfig.mk).
PRODUCT_PACKAGES += \
    libm3note_jpgenc_shim \
    libm3note_icu56_shim \
    libm3note_dpfrag_shim \
    libm3note_gbuf_shim
