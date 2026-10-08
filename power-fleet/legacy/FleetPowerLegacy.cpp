/*
 * fleet_power_legacy.h on Android: one Engine per process (the passthrough
 * power HAL of Pie lives in system_server), its worker thread releases the
 * floors when their deadline passes.
 */
#include "fleet_power_legacy.h"

#include <memory>
#include <mutex>
#include <sstream>
#include <string>

#include <android-base/logging.h>
#include <android-base/properties.h>
#include <hardware/power.h>

#include "LegacyHints.h"

using aidl::android::hardware::power::impl::meizu::Config;
using aidl::android::hardware::power::impl::meizu::Engine;
using aidl::android::hardware::power::impl::meizu::LegacyHints;
using aidl::android::hardware::power::impl::meizu::LoadConfig;

namespace {

constexpr char kConfigPath[] = "/vendor/etc/power/fleet_power.json";

std::once_flag gInitOnce;
LegacyHints* gHints = nullptr;  // never freed: lives as long as the process

std::string OffProperty() {
    std::string v = ::android::base::GetProperty("debug.vendor.power.fleet.off", "");
    if (v.empty()) v = ::android::base::GetProperty("ro.vendor.power.fleet.off", "");
    return v;
}

int IntData(void* data) { return data ? *static_cast<int*>(data) : 0; }

// No dumpsys for a passthrough module: with debug.vendor.power.fleet.dump=1 the
// state goes to logcat on every screen on/off.
void MaybeDump() {
    if (!gHints || !::android::base::GetBoolProperty("debug.vendor.power.fleet.dump", false)) return;
    std::istringstream in(gHints->dump());
    std::string line;
    while (std::getline(in, line)) LOG(INFO) << "fleet power: " << line;
}

}  // namespace

extern "C" void fleet_power_init(void) {
    std::call_once(gInitOnce, [] {
        Config config;
        std::string error;
        if (!LoadConfig(kConfigPath, &config, &error)) {
            LOG(ERROR) << "fleet power: " << kConfigPath << ": " << error << " - no boosts";
            return;
        }
        auto engine = std::make_shared<Engine>(config.nodes);
        engine->reset();
        engine->start();
        gHints = new LegacyHints(std::move(config), std::move(engine), OffProperty);
        LOG(INFO) << "fleet power: " << kConfigPath << " loaded";
    });
}

extern "C" void fleet_power_set_interactive(int on) {
    if (!gHints) return;
    gHints->setInteractive(on != 0);
    MaybeDump();
}

extern "C" void fleet_power_hint(int hint, void* data) {
    if (!gHints) return;
    switch (hint) {
        case POWER_HINT_INTERACTION:
            gHints->interaction(IntData(data));
            break;
        case POWER_HINT_LAUNCH:
            gHints->launch(IntData(data) != 0);
            break;
        case POWER_HINT_LOW_POWER:
            gHints->lowPower(IntData(data) != 0);
            break;
        default:
            break;
    }
}
