/* libperfservicenative.so replacement: MTK PerfService client stubs.
 * Module libm681shim_perfservice (Android.bp), installed under the stock name.
 *
 * The stock library needs libnativehelper.so, which the vendor namespace
 * cannot load, and hwcomposer.mt6755.so needs it in turn.  It also talks to
 * the MTK "perfservice" binder service, which does not exist here; camera
 * code (CpuCtrlImp) then deadlocks on disable() after a failed enable().
 * A client that always succeeds locally (valid handles, no-op boosts) keeps
 * every consumer on its normal code path; CPU boosts are not applied.
 *
 * All entry points take ints in the N-era perfservice_native.h; a uniform
 * 6-int prototype is ABI-safe for callers passing fewer arguments
 * (AAPCS/AAPCS64: extra registers ignored, callers that expect void ignore
 * r0/w0). */

#define STUB0(name) int name(int a, int b, int c, int d, int e, int f) { (void)a;(void)b;(void)c;(void)d;(void)e;(void)f; return 0; }
#define STUB1(name) int name(int a, int b, int c, int d, int e, int f) { (void)a;(void)b;(void)c;(void)d;(void)e;(void)f; return 1; }

/* registration: return a valid (non-zero, non-negative) handle */
STUB1(PerfServiceNative_userReg)
STUB1(PerfServiceNative_userRegBigLittle)
STUB1(PerfServiceNative_userRegScn)
/* everything else: success / nothing */
STUB0(PerfServiceNative_userRegScnConfig)
STUB0(PerfServiceNative_userUnreg)
STUB0(PerfServiceNative_userUnregScn)
STUB0(PerfServiceNative_userGetCapability)
STUB0(PerfServiceNative_userEnable)
STUB0(PerfServiceNative_userEnableAsync)
STUB0(PerfServiceNative_userEnableTimeout)
STUB0(PerfServiceNative_userEnableTimeoutAsync)
STUB0(PerfServiceNative_userEnableTimeoutMs)
STUB0(PerfServiceNative_userEnableTimeoutMsAsync)
STUB0(PerfServiceNative_userDisable)
STUB0(PerfServiceNative_userDisableAll)
STUB0(PerfServiceNative_userResetAll)
STUB0(PerfServiceNative_boostEnable)
STUB0(PerfServiceNative_boostEnableAsync)
STUB0(PerfServiceNative_boostEnableTimeout)
STUB0(PerfServiceNative_boostEnableTimeoutAsync)
STUB0(PerfServiceNative_boostEnableTimeoutMs)
STUB0(PerfServiceNative_boostEnableTimeoutMsAsync)
STUB0(PerfServiceNative_boostDisable)
STUB0(PerfServiceNative_boostDisableAsync)
STUB0(PerfServiceNative_dumpAll)
STUB0(PerfServiceNative_getClusterInfo)
STUB0(PerfServiceNative_getLastBoostPid)
STUB0(PerfServiceNative_getPackAttr)
STUB0(PerfServiceNative_getPackName)
STUB0(PerfServiceNative_levelBoost)
STUB0(PerfServiceNative_notifyDisplayType)
STUB0(PerfServiceNative_notifyFrameUpdate)
STUB0(PerfServiceNative_notifyRenderTime)
STUB0(PerfServiceNative_notifyUserStatus)
STUB0(PerfServiceNative_restoreBoostThread)
STUB0(PerfServiceNative_setBoostThread)
STUB0(PerfServiceNative_setExclusiveCore)
STUB0(PerfServiceNative_setFavorPid)
