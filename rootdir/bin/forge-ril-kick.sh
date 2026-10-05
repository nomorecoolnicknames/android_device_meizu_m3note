#!/system/bin/sh
# Bring telephony up after boot. Works around:
#  1. rild deadlocking on AT channel contention during its first start
#     ("Occupied Thread: AT+CPIN?"); one restart clears it, but only once the
#     gsm0710muxd AT channels exist.
#  2. DcTracker building no APN list (EF_ICCID unreadable) and sending the
#     "this_is_an_invalid_apn" placeholder; the attach APN is written to the
#     modem directly.

LOG=/data/local/tmp/forge-ril-kick.log
exec >>"$LOG" 2>&1
echo "=== $(date) forge-ril-kick start (v2)"

# Every wait below is poll-limited (about 25 min in total).

wait_for() {                 # wait_for <label> <max-polls> <interval> <test-cmd...>
    label=$1; max=$2; iv=$3; shift 3
    i=0
    while [ $i -lt "$max" ]; do
        if "$@" >/dev/null 2>&1; then echo "$label: ready after ${i} polls"; return 0; fi
        sleep "$iv"; i=$((i+1))
    done
    echo "$label: TIMED OUT after ${i} polls"; return 1
}

prop_is() { [ "$(getprop "$1")" = "$2" ]; }

wait_for boot_completed 120 5 prop_is sys.boot_completed 1

# Defect 1: restart rild only after the AT channels exist.
wait_for at_channels 60 5 test -e /dev/radio/pttycmd1
sleep 20
# Let the radio group create /dev/socket/rild-mal: rild already runs as
# uid 1001 when libril binds the socket, and init does not create it.
chown root:radio /dev/socket 2>/dev/null
chmod 0775 /dev/socket 2>/dev/null
echo "dev/socket now: $(ls -ld /dev/socket)"

echo "restarting ril-daemon-mtk (defect 1); muxd=$(getprop init.svc.gsm0710muxd)"
setprop ctl.restart ril-daemon-mtk

# gsm.sim.state is per slot, comma-separated: any LOADED slot is enough.
sim_any_loaded() { case ",$(getprop gsm.sim.state)," in *,LOADED,*) return 0 ;; esac; return 1; }
wait_for sim_loaded 60 5 sim_any_loaded
echo "sim.state=$(getprop gsm.sim.state) radio=$(getprop init.svc.ril-daemon-mtk)"

APN=$(getprop persist.m681.ril.attach_apn)
[ -z "$APN" ] && APN=internet.mts.ru
if [ -e /dev/radio/atci1 ]; then
    echo "writing attach apn '$APN' to the modem (defect 2)"
    printf 'AT+ES3G=1,7\r'                   > /dev/radio/atci1
    sleep 3
    printf 'AT+CGDCONT=0,"IP","%s"\r' "$APN" > /dev/radio/atci1
    sleep 3
    printf 'AT+COPS=0\r'                     > /dev/radio/atci1
else
    echo "no /dev/radio/atci1 - skipped"
fi

wait_for registered 40 5 sh -c '[ -n "$(getprop gsm.operator.numeric)" ] && [ "$(getprop gsm.operator.numeric)" != "000000" ]'
echo "result: op=$(getprop gsm.operator.alpha) num=$(getprop gsm.operator.numeric) net=$(getprop gsm.network.type)"

# Defect 3: rild sometimes comes up with an empty baseband or a SIM that is
# not LOADED; restart it once more in that case. ICCIDs are not logged.
slot_needs_rild() {          # slot_needs_rild <n>: SIM present, state not LOADED
    iccid=$(getprop ril.iccid.sim$1)
    case "$iccid" in ''|N/A|n/a) return 1 ;; esac
    st=$(getprop gsm.sim.state | cut -d, -f$1)
    [ "$st" != LOADED ]
}
if [ -z "$(getprop gsm.version.baseband)" ] || slot_needs_rild 1 || slot_needs_rild 2; then
    echo "defect 4: baseband='$(getprop gsm.version.baseband | cut -c1-30)' sim.state=$(getprop gsm.sim.state) -> one more restart of ril-daemon-mtk"
    setprop ctl.restart ril-daemon-mtk
    wait_for baseband 24 5 sh -c '[ -n "$(getprop gsm.version.baseband)" ]'
    sleep 30
    echo "after defect-4 restart: sim.state=$(getprop gsm.sim.state) op=$(getprop gsm.operator.alpha) baseband=$(getprop gsm.version.baseband | cut -c1-30)"
fi
echo "=== done"
