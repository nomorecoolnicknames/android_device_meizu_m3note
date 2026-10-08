/*
 * Hint front end of the Power HAL for the legacy power_module: hardware/power.h
 * hints instead of the AIDL boosts and modes of Power.cpp, with the same Engine
 * and fleet_power.json. Pie sends POWER_HINT_INTERACTION with 0 on every user
 * activity (at most every 100 ms), POWER_HINT_LAUNCH 1/0 around an activity
 * start, POWER_HINT_LOW_POWER and setInteractive; there are no hint sessions.
 */
#pragma once

#include <functional>
#include <memory>
#include <mutex>
#include <set>
#include <string>

#include "../Config.h"
#include "../Engine.h"

namespace aidl {
namespace android {
namespace hardware {
namespace power {
namespace impl {
namespace meizu {

class LegacyHints {
  public:
    using Clock = Engine::Clock;
    // Runtime off switch (debug.vendor.power.fleet.off, else
    // ro.vendor.power.fleet.off), read on every hint; injected for the host test.
    using OffSource = std::function<std::string()>;

    LegacyHints(Config config, std::shared_ptr<Engine> engine, OffSource off);

    // POWER_HINT_INTERACTION: durationMs > 0 is a fling when the config has a
    // "fling" request, otherwise an interaction held max(HoldMs, durationMs).
    void interaction(int32_t durationMs, Clock::time_point now = Clock::now());
    void launch(bool start, Clock::time_point now = Clock::now());
    void lowPower(bool on, Clock::time_point now = Clock::now());
    void setInteractive(bool on, Clock::time_point now = Clock::now());

    std::string dump(Clock::time_point now = Clock::now()) const;

  private:
    std::set<std::string> offList() const;

    const Config mConfig;
    const std::shared_ptr<Engine> mEngine;
    const OffSource mOff;
    mutable std::mutex mLock;
    bool mScreenOff = false;
    bool mLowPower = false;
};

}  // namespace meizu
}  // namespace impl
}  // namespace power
}  // namespace hardware
}  // namespace android
}  // namespace aidl
