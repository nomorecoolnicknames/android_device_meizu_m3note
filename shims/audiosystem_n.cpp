// android::AudioSystem::getDeviceConnectionState(audio_devices_t, const char*)
// for audio.primary.mt6755.so (Nougat MTK HAL, both ABIs).
//
// This is the HAL's only unresolved import; it came from the Nougat MTK
// libmedia, and Android 13 moved AudioSystem to libaudioclient with a
// different signature.  Return AUDIO_POLICY_DEVICE_STATE_UNAVAILABLE (0): the
// HAL then only trusts the devices the policy announces through
// set_parameters.  The declaration reproduces the import exactly
// (_ZN7android11AudioSystem24getDeviceConnectionStateEjPKc).
#include <stdint.h>

namespace android {

class AudioSystem {
  public:
    static int getDeviceConnectionState(uint32_t device, const char* address);
};

int AudioSystem::getDeviceConnectionState(uint32_t, const char*) { return 0; }

}  // namespace android
