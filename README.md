# Meizu M3 Note (m3note)

Device tree for the Meizu M3 Note for LineageOS 20.0.

One tree covers both board revisions, M681 and L681: a shared Linux 4.9
kernel with per-board device trees and vendor profiles. `libinit` selects
the board profile at boot.

| | |
| --- | --- |
| SoC | MediaTek MT6755 (Helio P10) |
| GPU | Mali-T860 MP2 |
| Display | 1080 x 1920 |
| Kernel | Linux 4.9, `m3note_defconfig` |
| Revisions | M681, L681 |

## Status

- M681 boots to the home screen; USB/ADB and CPU frequency scaling: working
- Display, auto-rotation and sensors: working
- Cameras: front sensor detected; main camera not working
- Wi-Fi and Bluetooth: not working
- Audio, modem and RTC: not working
- Fingerprint enrollment: untested
- SELinux: permissive
- L681: untested with this tree (it runs the LineageOS 16.0 branch)

## Building

```sh
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs
mkdir -p .repo/local_manifests
curl -L -o .repo/local_manifests/meizu_m3note.xml \
  https://raw.githubusercontent.com/nomorecoolnicknames/android_local_manifests_meizu/lineage-20.0/meizu_m3note.xml
repo sync -c
source build/envsetup.sh
breakfast m3note
brunch m3note
```

The local manifest adds:

- [android_kernel_meizu_mt6755](https://github.com/nomorecoolnicknames/android_kernel_meizu_mt6755) `lineage-20.0`, built from source with `m3note_defconfig`;
- [android_vendor_meizu_m3note](https://github.com/nomorecoolnicknames/android_vendor_meizu_m3note) `lineage-20.0` (both board profiles);
- [android_device_meizu_common](https://github.com/nomorecoolnicknames/android_device_meizu_common), whose platform patches are applied on `source build/envsetup.sh`.

A boot image built from the kernel source has not been tested on the phone yet.

## OTA package

The OTA package is the standard LineageOS one. Besides the device name
(`m3note`, `m681`, `l681`) it checks the board by the fields the bootloader
passes on the kernel command line (`releasetools/check_board.sh`). It
accepts the M681 only, because the boot image carries the M681 device tree.
Installing the package on a phone has not been tested yet.
