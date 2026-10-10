// Host check of ParseHwRotation (not built by the Android build):
//   g++ -std=c++14 -Wall -Werror -I.. hwrotation_host_test.cpp -o /tmp/hwrot && /tmp/hwrot
#include <cstdio>

#include "hwrotation.h"

int main() {
    struct { const char* in; int want; } cases[] = {
        {"0", 0}, {"90", 90}, {"180", 180}, {"270", 270},
        {"", -1}, {nullptr, -1}, {"360", -1}, {"-90", -1}, {"180 ", -1}, {"1800", -1}, {"abc", -1},
    };
    int bad = 0;
    for (const auto& c : cases) {
        const int got = m3note::ParseHwRotation(c.in);
        if (got != c.want) {
            std::printf("FAIL '%s': %d, want %d\n", c.in ? c.in : "(null)", got, c.want);
            bad++;
        }
    }
    std::printf("%s: %zu cases\n", bad ? "FAIL" : "PASS", sizeof(cases) / sizeof(cases[0]));
    return bad != 0;
}
