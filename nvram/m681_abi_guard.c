/*
 * Compile-time guards for the local include/hardware/audio.h layout fix in
 * hardware/libhardware, which a sync would revert silently: a wrong struct
 * layout exports the same symbols, so only the audioserver crash shows it.
 *
 * The guards live outside audio.h on purpose (a revert would remove them
 * together with the fix) and are built as part of m681_nvram_wifi_repair, an
 * existing module, so they are always compiled.
 */

#include <stddef.h>
#include <hardware/audio.h>

/*
 * Portable static assertion: this module is built as gnu99, where
 * _Static_assert is only an extension. The typedef name is the error message.
 */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define M681_ABI_ASSERT(cond, name, msg) _Static_assert(cond, msg)
#else
#define M681_ABI_ASSERT(cond, name, msg) typedef char name[(cond) ? 1 : -1]
#endif

/*
 * GUARD 1 - nothing may be inserted between close_input_stream and dump.
 *
 * Android P inserted get_microphones there, shifting every later function
 * pointer by one slot, so the framework called the pre-P blob's
 * create_audio_patch through the get_master_mute slot. The fix moves
 * get_microphones to the struct tail. Offsets (arm64 / arm32):
 *   close_input_stream  232 / 120
 *   dump                240 / 124
 *   create_audio_patch  264 / 136
 *   get_microphones     296 / 152   (last member)
 *
 * Asserted as a relation, so it holds on both arches without #ifdef.
 */
M681_ABI_ASSERT(
    offsetof(struct audio_hw_device, dump) ==
        offsetof(struct audio_hw_device, close_input_stream) + sizeof(void *),
    M681_ABI_BROKEN_something_inserted_between_close_input_stream_and_dump,
    "audio_hw_device: a member was inserted between close_input_stream and "
    "dump. The pre-P vendor blob ABI is broken and audioserver will SIGSEGV. "
    "The local fix to hardware/libhardware/include/hardware/audio.h has "
    "probably been reverted by a repo sync. "
    "See docs/M681_REQUIRED_LOCAL_PATCHES.md entry C.");

/*
 * GUARD 2 - get_microphones must stay past the last legacy member (at the
 * struct tail).
 */
M681_ABI_ASSERT(
    offsetof(struct audio_hw_device, get_microphones) >
        offsetof(struct audio_hw_device, set_audio_port_config),
    M681_ABI_BROKEN_get_microphones_moved_out_of_the_struct_tail,
    "audio_hw_device: get_microphones is no longer at the struct tail. "
    "The pre-P vendor blob ABI is broken. "
    "See docs/M681_REQUIRED_LOCAL_PATCHES.md entry C.");
