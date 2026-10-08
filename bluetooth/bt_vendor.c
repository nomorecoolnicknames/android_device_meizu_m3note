/*
 * libbt-vendor.so (64-bit): the BT vendor interface the HIDL Bluetooth HAL
 * dlopen()s.
 *
 * The stock firmware ships libbt-vendor.so only as a 32-bit library, while
 * the HIDL service is 64-bit; without it the HAL fails to initialize and the
 * Bluetooth stack crash-loops.  The 64-bit libbluetooth_mtk.so exports the
 * same symbols, so this file reimplements the thin forwarding layer of the
 * stock 32-bit library for 64-bit.
 *
 * mtk_bt_init(p_cb, bdaddr): set_callbacks(p_cb), return 0; bdaddr is ignored.
 * mtk_bt_cleanup():          clean_resource(); clean_callbacks().
 * mtk_bt_op():
 *      0  POWER_CTRL            log *(int*)param, return 0   (no chip call)
 *      1  FW_CFG                return mtk_fw_cfg()
 *      2  SCO_CFG               return mtk_sco_cfg()
 *      3  USERIAL_OPEN          *(int*)param = init_uart(); return 1
 *      4  USERIAL_CLOSE         close_uart(); return 0
 *      5  GET_LPM_IDLE_TIMEOUT  *(uint32_t*)param = 5000; return 0
 *      6  LPM_SET_MODE          log *(uint8_t*)param, return 0
 *      7  LPM_WAKE_SET_STATE    log, return 0
 *      8  SET_AUDIO_STATE       return -1
 *      9  EPILOG                return mtk_prepare_off()
 *      10 A2DP_OFFLOAD_START    return -1
 *      11 A2DP_OFFLOAD_STOP     return -1
 *      12 (MTK) SET_FW_ASSERT   return mtk_set_fw_assert(*(uint8_t*)param)
 *      13 (MTK) SET_PSM_CONTRL  return mtk_set_psm_control(*(uint8_t*)param)
 *      default                  log "Unknown operation %d"; return -1
 *
 * libbluetooth_mtk.so stores the callback struct pointer as-is; its layout
 * matches the 64-bit bt_vendor_callbacks_t up to epilog_cb, and newer fields
 * are only appended, so the struct is safe to pass through.
 *
 * libbluetooth_mtk.so is installed by PRODUCT_COPY_FILES, not as a build
 * module, so it is resolved with dlopen() instead of being linked.
 */
#include <dlfcn.h>
#include <stddef.h>
#include <stdint.h>

#include <android/log.h>

#define LOG_TAG "bt-vendor-m95"
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

/* bt_vendor_lib.h subset. Only the interface struct matters here: the callback
 * struct is forwarded as an opaque pointer, exactly as the stock shim does. */
typedef struct {
    size_t size;
    int (*init)(const void *p_cb, unsigned char *local_bdaddr);
    int (*op)(int opcode, void *param);
    void (*cleanup)(void);
} bt_vendor_interface_t;

/* bt_vendor_opcode_t, hardware/interfaces/bluetooth/1.0/default/bt_vendor_lib.h.
 * 12/13 are MTK-private and are not in that header. */
enum {
    BT_VND_OP_POWER_CTRL = 0,
    BT_VND_OP_FW_CFG = 1,
    BT_VND_OP_SCO_CFG = 2,
    BT_VND_OP_USERIAL_OPEN = 3,
    BT_VND_OP_USERIAL_CLOSE = 4,
    BT_VND_OP_GET_LPM_IDLE_TIMEOUT = 5,
    BT_VND_OP_LPM_SET_MODE = 6,
    BT_VND_OP_LPM_WAKE_SET_STATE = 7,
    BT_VND_OP_SET_AUDIO_STATE = 8,
    BT_VND_OP_EPILOG = 9,
    BT_VND_OP_A2DP_OFFLOAD_START = 10,
    BT_VND_OP_A2DP_OFFLOAD_STOP = 11,
    BT_VND_OP_MTK_SET_FW_ASSERT = 12,
    BT_VND_OP_MTK_SET_PSM_CONTRL = 13,
};

/* Idle timeout the stock library returns for BT_VND_OP_GET_LPM_IDLE_TIMEOUT. */
#define MTK_LPM_IDLE_TIMEOUT_MS 5000

#define MTK_BT_LIBRARY "libbluetooth_mtk.so"

/* Signatures of the 64-bit libbluetooth_mtk.so; argument widths match how
 * the stock 32-bit library loads them from `param`. */
static void *g_mtk_handle;
static void (*p_set_callbacks)(const void *p_cb);
static void (*p_clean_callbacks)(void);
static int (*p_init_uart)(void);                    /* opens /dev/stpbt */
static void (*p_close_uart)(void);
static int (*p_mtk_fw_cfg)(void);
static int (*p_mtk_sco_cfg)(void);
static int (*p_mtk_prepare_off)(void);              /* calls epilog_cb */
static int (*p_mtk_set_fw_assert)(uint32_t reason);
static int (*p_mtk_set_psm_control)(int on);
static void (*p_clean_resource)(void);

struct mtk_sym {
    const char *name;
    void **slot;
};

static const struct mtk_sym kMtkSyms[] = {
    {"set_callbacks", (void **)&p_set_callbacks},
    {"clean_callbacks", (void **)&p_clean_callbacks},
    {"init_uart", (void **)&p_init_uart},
    {"close_uart", (void **)&p_close_uart},
    {"mtk_fw_cfg", (void **)&p_mtk_fw_cfg},
    {"mtk_sco_cfg", (void **)&p_mtk_sco_cfg},
    {"mtk_prepare_off", (void **)&p_mtk_prepare_off},
    {"mtk_set_fw_assert", (void **)&p_mtk_set_fw_assert},
    {"mtk_set_psm_control", (void **)&p_mtk_set_psm_control},
    {"clean_resource", (void **)&p_clean_resource},
};

/* Resolve every symbol or none. A partially-bound shim would fail later, deep
 * inside an op(), where the log says nothing useful. */
static int mtk_bind(void) {
    size_t i;

    if (g_mtk_handle != NULL)
        return 0;

    g_mtk_handle = dlopen(MTK_BT_LIBRARY, RTLD_NOW);
    if (g_mtk_handle == NULL) {
        ALOGE("dlopen %s failed: %s", MTK_BT_LIBRARY, dlerror());
        return -1;
    }

    for (i = 0; i < sizeof(kMtkSyms) / sizeof(kMtkSyms[0]); i++) {
        void *sym = dlsym(g_mtk_handle, kMtkSyms[i].name);
        if (sym == NULL) {
            ALOGE("%s has no symbol %s: %s", MTK_BT_LIBRARY, kMtkSyms[i].name,
                  dlerror());
            dlclose(g_mtk_handle);
            g_mtk_handle = NULL;
            return -1;
        }
        *kMtkSyms[i].slot = sym;
    }
    return 0;
}

static int mtk_bt_init(const void *p_cb, unsigned char *local_bdaddr) {
    (void)local_bdaddr; /* ignored by stock too: libbluetooth_mtk reads the
                         * BD address from NVRAM. */
    ALOGI("mtk_bt_init");

    if (mtk_bind() != 0)
        return -1; /* stock cannot fail here; we can, and must say so. */

    p_set_callbacks(p_cb);
    return 0;
}

static int mtk_bt_op(int opcode, void *param) {
    if (mtk_bind() != 0)
        return -1;

    switch (opcode) {
    case BT_VND_OP_POWER_CTRL:
        /* No chip call in stock: the WMT driver powers the combo chip up when
         * /dev/stpbt is opened, so USERIAL_OPEN is the real power-on. */
        ALOGD("BT_VND_OP_POWER_CTRL %d", param ? *(int *)param : -1);
        return 0;

    case BT_VND_OP_FW_CFG:
        ALOGD("BT_VND_OP_FW_CFG");
        return p_mtk_fw_cfg();

    case BT_VND_OP_SCO_CFG:
        ALOGD("BT_VND_OP_SCO_CFG");
        return p_mtk_sco_cfg();

    case BT_VND_OP_USERIAL_OPEN:
        ALOGD("BT_VND_OP_USERIAL_OPEN");
        /* One H4 fd. VendorInterface::Open() reads fd_list[0] and takes the
         * fd_count == 1 branch (H4Protocol). */
        *(int *)param = p_init_uart();
        return 1;

    case BT_VND_OP_USERIAL_CLOSE:
        ALOGD("BT_VND_OP_USERIAL_CLOSE");
        p_close_uart();
        return 0;

    case BT_VND_OP_GET_LPM_IDLE_TIMEOUT:
        ALOGD("BT_VND_OP_GET_LPM_IDLE_TIMEOUT");
        *(uint32_t *)param = MTK_LPM_IDLE_TIMEOUT_MS;
        return 0;

    case BT_VND_OP_LPM_SET_MODE:
        ALOGD("BT_VND_OP_LPM_SET_MODE %d", *(uint8_t *)param);
        return 0;

    case BT_VND_OP_LPM_WAKE_SET_STATE:
        ALOGD("BT_VND_OP_LPM_WAKE_SET_STATE");
        return 0;

    case BT_VND_OP_EPILOG:
        ALOGD("BT_VND_OP_EPILOG");
        return p_mtk_prepare_off();

    case BT_VND_OP_MTK_SET_FW_ASSERT:
        /* the stock library passes only the low byte */
        ALOGD("BT_VND_OP_SET_FW_ASSERT 0x%02x", *(uint8_t *)param);
        return p_mtk_set_fw_assert(*(uint8_t *)param);

    case BT_VND_OP_MTK_SET_PSM_CONTRL:
        ALOGD("BT_VND_OP_SET_PSM_CONTRL, setting: %d", *(uint8_t *)param);
        return p_mtk_set_psm_control(*(uint8_t *)param);

    default:
        /* BT_VND_OP_SET_AUDIO_STATE and both A2DP_OFFLOAD opcodes land here in
         * stock too — MTK offloads neither on this chip. */
        ALOGD("Unknown operation %d", opcode);
        return -1;
    }
}

static void mtk_bt_cleanup(void) {
    ALOGI("mtk_bt_cleanup");
    if (g_mtk_handle == NULL)
        return;
    p_clean_resource();
    p_clean_callbacks();
}

__attribute__((visibility("default")))
const bt_vendor_interface_t BLUETOOTH_VENDOR_LIB_INTERFACE = {
    sizeof(bt_vendor_interface_t),
    mtk_bt_init,
    mtk_bt_op,
    mtk_bt_cleanup,
};
