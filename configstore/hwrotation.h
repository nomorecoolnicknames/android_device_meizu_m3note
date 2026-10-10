/*
 * Runtime primary display orientation for the M3 Note.
 *
 * One system/vendor image runs on m681 and l681, whose panels are mounted
 * differently. Pie SurfaceFlinger takes the orientation only from configstore
 * 1.1 primaryDisplayOrientation, which the stock service fixes at build time.
 * libinit_m3note sets ro.sf.hwrotation per board at post-fs, before class hal
 * starts; this service turns it into primaryDisplayOrientation. If the property
 * is unset or not 0/90/180/270, the build value stays.
 */
#pragma once

#include <cstring>

namespace m3note {

// "0" | "90" | "180" | "270" -> degrees; anything else -> -1 (keep the build value).
inline int ParseHwRotation(const char* value) {
    if (value == nullptr) return -1;
    static const int kDegrees[] = {0, 90, 180, 270};
    static const char* const kNames[] = {"0", "90", "180", "270"};
    for (int i = 0; i < 4; i++) {
        if (std::strcmp(value, kNames[i]) == 0) return kDegrees[i];
    }
    return -1;
}

// Reads ro.sf.hwrotation once.  Called from main() before SetupMinijail, so the
// property area is mapped while the process may still open files freely.
void LoadHwRotation();

// Degrees from LoadHwRotation(), or -1.
int HwRotation();

}  // namespace m3note
