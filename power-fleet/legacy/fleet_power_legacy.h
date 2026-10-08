/*
 * C entry points of the Power HAL for a legacy power_module (power/power.c):
 * the module keeps its own setFeature and forwards init, setInteractive and
 * powerHint here. Config: /vendor/etc/power/fleet_power.json; a missing or
 * broken file leaves the calls as no-ops.
 */
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void fleet_power_init(void);
void fleet_power_set_interactive(int on);
/* hint and data as in power_module.powerHint (hardware/power.h) */
void fleet_power_hint(int hint, void* data);

#ifdef __cplusplus
}
#endif
