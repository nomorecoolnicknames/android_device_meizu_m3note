/*
 * Copyright (C) 2012 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * power.m3note - hardware/libhardware power.default (no-op init, interactive
 * and hints) plus setFeature(POWER_FEATURE_DOUBLE_TAP_TO_WAKE).
 *
 * Settings "Tap to wake" (config_supportDoubleTapWake) writes
 * Secure.DOUBLE_TAP_TO_WAKE; PowerManagerService passes it to this HAL
 * (passthrough, in system_server). The GT9XX touch driver
 * (/sys/devices/mx_tsp/gesture_control) takes one setting byte per write of
 * 4 bytes: buf[0] = value, buf[2] = byte index 1..4. Byte 1 = 1 turns gestures
 * on, bit 0 of byte 2 is the double tap; bytes 3/4 (letters, swipes) stay 0.
 * With any byte set, tpd_suspend puts the panel into doze instead of sleep,
 * and a double tap reports KEY_GESTURE (195) on mtk-tpd -> keylayout
 * mtk-tpd.kl WAKEUP.
 *
 * Boosts: init, setInteractive and powerHint go to the Power HAL engine
 * (power-fleet/, legacy profile): cpufreq floors on policy0/policy4 from
 * /vendor/etc/power/fleet_power.json - touches 70 % of the current max until
 * 1 s after the last one, an app launch the current max for at most 1.5 s.
 * The floor is clamped to scaling_max_freq, so frequency caps and the thermal
 * guard stay on top. Without the json, or before cpufreq is armed, the calls
 * do nothing.
 */
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define LOG_TAG "m3note PowerHAL"
#include <utils/Log.h>

#include <hardware/hardware.h>
#include <hardware/power.h>

#include "../power-fleet/legacy/fleet_power_legacy.h"

#define UNUSED_ARGUMENT __attribute((unused))

#define GESTURE_CONTROL "/sys/devices/mx_tsp/gesture_control"

static int gesture_byte(int fd, int index, int value)
{
    char buf[4] = { (char) value, 'x', (char) index, 'x' };

    if (write(fd, buf, sizeof(buf)) != (ssize_t) sizeof(buf)) {
        ALOGE("gesture byte %d = %d: %s", index, value, strerror(errno));
        return -1;
    }
    return 0;
}

static void set_double_tap(int on)
{
    int fd = open(GESTURE_CONTROL, O_WRONLY | O_CLOEXEC);

    if (fd < 0) {
        ALOGE("open %s: %s", GESTURE_CONTROL, strerror(errno));
        return;
    }
    /* On: master byte first, then the double-tap bit; off: the reverse. */
    if (on) {
        if (gesture_byte(fd, 1, 1) == 0)
            gesture_byte(fd, 2, 1);
    } else {
        if (gesture_byte(fd, 2, 0) == 0)
            gesture_byte(fd, 1, 0);
    }
    close(fd);
    ALOGI("double tap to wake %s", on ? "on" : "off");
}

static void power_init(struct power_module *module UNUSED_ARGUMENT)
{
    fleet_power_init();
}

static void power_set_interactive(struct power_module *module UNUSED_ARGUMENT,
                                  int on)
{
    fleet_power_set_interactive(on);
}

static void power_hint(struct power_module *module UNUSED_ARGUMENT,
                       power_hint_t hint,
                       void *data) {
    fleet_power_hint(hint, data);
}

static void power_set_feature(struct power_module *module UNUSED_ARGUMENT,
                              feature_t feature, int state)
{
    switch (feature) {
    case POWER_FEATURE_DOUBLE_TAP_TO_WAKE:
        set_double_tap(state);
        break;
    default:
        break;
    }
}

static struct hw_module_methods_t power_module_methods = {
    .open = NULL,
};

struct power_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = POWER_MODULE_API_VERSION_0_2,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = POWER_HARDWARE_MODULE_ID,
        .name = "M3 Note Power HAL",
        .author = "The Android Open Source Project",
        .methods = &power_module_methods,
    },

    .init = power_init,
    .setInteractive = power_set_interactive,
    .powerHint = power_hint,
    .setFeature = power_set_feature,
};
