# Meizu M3 Note (m3note)

Device tree for the Meizu M3 Note for LineageOS 16.0.

One tree for both board revisions, M681 and L681: a shared Linux 4.4 kernel with each revision's own
appended DTB and vendor profile. The board is identified from device-tree compatible strings, the bootloader
panel identity and an optional board property; missing or conflicting identity selects `unknown` rather than
the other board's profile.

## Specifications

| | |
| --- | --- |
| SoC | MediaTek MT6755 |
| Display | 1080 x 1920 |
| Kernel | Linux 4.4, `m3note_defconfig` (prebuilt, one image per revision) |
| Revisions | M681, L681 |

## Status

- L681 display: working, including lock/unlock with correct rotation and navigation bar
- Mobile network: SIM 1 on LTE; SIM 2 not working; ending an outgoing call crashes the MediaTek rild (fix in the platform patches, untested)
- Wi-Fi: scanning works
- Cameras: the HAL sees and powers both sensors; camera app preview not working
- Sensors: nine reporting; audio: sound card present, playback and recording untested
- Battery percentage: not reliable; thermal protection: armed
- Fingerprint enrollment: untested; SELinux: permissive
- M681: untested with this tree

## Building

```sh
repo init -u https://github.com/LineageOS/android.git -b lineage-16.0
repo sync -c
git clone -b lineage-16.0 https://github.com/nomorecoolnicknames/android_device_meizu_m3note device/meizu/m3note
source build/envsetup.sh
breakfast m3note
brunch m3note
```

There is no local manifest for this branch. Also required:

- `device/meizu/mt6755-common` and the MediaTek platform compatibility patches (not public yet).
- Vendor blobs: `vendor/meizu/m681` and the matching `vendor/meizu/m3note` board profiles and firmware.
- Kernel images `prebuilt-kernel/Image.gz-dtb-m681` and `Image.gz-dtb-l681`, built from
  [android_kernel_meizu_mt6755](https://github.com/nomorecoolnicknames/android_kernel_meizu_mt6755) `lineage-16.0`
  with `m3note_defconfig`. The build checks them against `prebuilt-kernel/EXPECTED-*.txt`; update those together with the images.

Keep boot verification enabled and check the target revision before installing.
Original copyright and license notices are retained; vendor libraries and firmware have separate terms.
