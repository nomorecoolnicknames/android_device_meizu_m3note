#include "LegacyHints.h"

#include <algorithm>
#include <sstream>

namespace aidl {
namespace android {
namespace hardware {
namespace power {
namespace impl {
namespace meizu {

namespace {

ValueMap Without(const ValueMap& set, const std::set<std::string>& off) {
    ValueMap out;
    for (const auto& [node, value] : set) {
        if (!off.count(node)) out[node] = value;
    }
    return out;
}

}  // namespace

LegacyHints::LegacyHints(Config config, std::shared_ptr<Engine> engine, OffSource off)
    : mConfig(std::move(config)), mEngine(std::move(engine)), mOff(std::move(off)) {}

// Comma-separated sources (interaction, fling, launch) and node names that stay
// off; "none" clears the ro.vendor default for a run (as Power.cpp OffList).
std::set<std::string> LegacyHints::offList() const {
    std::set<std::string> off;
    const std::string v = mOff ? mOff() : std::string();
    if (v == "none") return off;
    std::string item;
    std::istringstream in(v);
    while (std::getline(in, item, ',')) {
        item.erase(0, item.find_first_not_of(" \t"));
        item.erase(item.find_last_not_of(" \t") + 1);
        if (!item.empty()) off.insert(item);
    }
    return off;
}

void LegacyHints::interaction(int32_t durationMs, Clock::time_point now) {
    std::lock_guard<std::mutex> lock(mLock);
    if (mScreenOff || mLowPower) return;
    const bool fling = durationMs > 0 && mConfig.requests.count("fling");
    const std::string source = fling ? "fling" : "interaction";
    auto it = mConfig.requests.find(source);
    std::set<std::string> off = offList();
    if (it == mConfig.requests.end() || off.count(source)) return;
    const RequestConfig& rc = it->second;
    if (durationMs <= 0 && rc.ignoreZeroDuration) return;
    if (!rc.pulse.empty()) {
        int32_t pulseMs = std::clamp(durationMs > 0 ? durationMs : rc.pulseMs, 1, rc.pulseMaxMs);
        for (const auto& p : rc.pulse) {
            if (!off.count(p)) mEngine->pulse(p, pulseMs);
        }
    }
    ValueMap set = Without(rc.set, off);
    if (set.empty()) return;
    int32_t holdMs = fling ? std::max(durationMs, rc.flingMinMs) : std::max(rc.holdMs, durationMs);
    // extend: the hints of a running gesture keep pushing the end out.
    mEngine->setRequest(source, set, now + std::chrono::milliseconds(holdMs), true, now);
}

void LegacyHints::launch(bool start, Clock::time_point now) {
    std::lock_guard<std::mutex> lock(mLock);
    auto it = mConfig.requests.find("launch");
    if (it == mConfig.requests.end()) return;
    std::set<std::string> off = offList();
    if (!start || mScreenOff || off.count("launch")) {
        mEngine->clearRequest("launch", now);
        return;
    }
    const RequestConfig& rc = it->second;
    for (const auto& p : rc.pulse) {
        if (!off.count(p)) mEngine->pulse(p, std::min(rc.pulseMs, rc.pulseMaxMs));
    }
    // MaxMs: a lost LAUNCH 0 must not hold the floor.
    mEngine->setRequest("launch", Without(rc.set, off), now + std::chrono::milliseconds(rc.maxMs),
                        false, now);
}

void LegacyHints::lowPower(bool on, Clock::time_point now) {
    std::lock_guard<std::mutex> lock(mLock);
    mLowPower = on;
    if (on) {
        mEngine->clearRequest("interaction", now);
        mEngine->clearRequest("fling", now);
    }
}

void LegacyHints::setInteractive(bool on, Clock::time_point now) {
    std::lock_guard<std::mutex> lock(mLock);
    mScreenOff = !on;
    if (mScreenOff) mEngine->clearAll(now);
}

std::string LegacyHints::dump(Clock::time_point now) const {
    std::ostringstream out;
    {
        std::lock_guard<std::mutex> lock(mLock);
        std::string off;
        for (const auto& s : offList()) off += (off.empty() ? "" : ",") + s;
        out << "fleet Power HAL (legacy): screen " << (mScreenOff ? "off" : "on")
            << ", low power " << mLowPower << ", off list '" << off << "'\n";
    }
    out << mEngine->dump(now);
    return out.str();
}

}  // namespace meizu
}  // namespace impl
}  // namespace power
}  // namespace hardware
}  // namespace android
}  // namespace aidl
