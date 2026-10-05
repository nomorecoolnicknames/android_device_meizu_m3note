#!/system/bin/sh

TAG=m681_conn_autostart
WPA_SOCKET=/data/misc/wifi/sockets/wlan0

log -t "$TAG" "begin"

# Connsys power-up: /dev/stpwmt, /dev/wmtWifi and /dev/stpbt only appear after
# wmt_loader issues COMBO_IOCTL_DO_MODULE_INIT.
STAGE=/sys/module/mtk_wcn_consys_hw/parameters/forge_conn_pwron_stage
EMI=/sys/module/mtk_wcn_consys_hw/parameters/forge_conn_emi
AUTO=/sys/module/wmt_dev/parameters/forge_conn_autopwr

# Only start the loader if the nodes are missing: a second DO_MODULE_INIT pass
# re-runs BT_init, whose register_chrdev_region(major 192) then fails.
if [ ! -c /dev/wmtWifi ]; then
    setprop debug.m681.wmt.start 1
    n=0
    while [ ! -c /dev/wmtWifi ] && [ "$n" -lt 10 ]; do
        n=$((n + 1)); sleep 1
    done
    if [ ! -c /dev/wmtWifi ]; then
        /vendor/bin/wmt_loader &
        sleep 3
    fi
fi

# Stop m681_wifi_kick.sh from triggering a second loader pass.
[ -c /dev/wmtWifi ] && setprop debug.m681.wmt.ready 1

# The EMI knob only accepts writes once hw_init has run, i.e. after the loader.
n=0
while [ "$n" -lt 15 ]; do
    echo 7 > "$EMI" 2>/dev/null
    [ "`cat $EMI 2>/dev/null`" = "7" ] && break
    n=$((n + 1)); sleep 2
done
echo 4 > "$STAGE" 2>/dev/null

# PSM stays at the default (on): with PSM off BTIF never suspends.
# forge_conn_autopwr stays 0: it lets WMT power consys on screen blank/unblank,
# which can cause a reset loop at boot. The BT HAL powers consys on open.
log -t "$TAG" "knobs: stage=`cat $STAGE 2>/dev/null` emi=`cat $EMI 2>/dev/null` auto=`cat $AUTO 2>/dev/null`"

# ueventd already sets these; kept as a fallback.
if [ -c /dev/stpbt ]; then
    chown bluetooth:bluetooth /dev/stpbt 2>/dev/null || chown bluetooth.bluetooth /dev/stpbt 2>/dev/null
    chmod 0660 /dev/stpbt 2>/dev/null
fi

wifi_status()
{
    /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 status 2>/dev/null
}

wifi_has_ip()
{
    /system/bin/ip addr show wlan0 2>/dev/null | /system/bin/grep -q " inet "
}

wifi_connected()
{
    if [ ! -S "$WPA_SOCKET" ]; then
        return 1
    fi

    case "`wifi_status`" in
        *"wpa_state=COMPLETED"*)
            if wifi_has_ip; then
                return 0
            fi
            ;;
    esac

    return 1
}

wifi_reconnect()
{
    if [ -S "$WPA_SOCKET" ]; then
        if wifi_connected; then
            log -t "$TAG" "wifi already connected with ip; skip reconnect"
            return 0
        fi
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 enable_network all >/dev/null 2>&1
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 scan >/dev/null 2>&1
        sleep 4
        if wifi_connected; then
            /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 save_config >/dev/null 2>&1
            log -t "$TAG" "wifi connected after scan; skip reconnect"
            return 0
        fi
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 reconnect >/dev/null 2>&1
        /system/bin/wpa_cli -p/data/misc/wifi/sockets -iwlan0 save_config >/dev/null 2>&1
        log -t "$TAG" "requested wifi reconnect"
        return 0
    fi
    return 1
}

bluetooth_ready()
{
    case "`/system/bin/getprop service.wcn.driver.ready`:`/system/bin/getprop debug.m681.wmt.ready`" in
        yes:*|*:1)
            ;;
        *)
            return 1
            ;;
    esac

    [ -c /dev/stpbt ] || return 1
    return 0
}

# Single gated Wi-Fi re-enable. The framework reads WIFI_ON only once, at boot
# phase 500, which is before wlan0 exists, and never retries.
# debug.m681.wifi.reenable is claimed at entry so a restarted instance (init
# re-runs this on every sys.boot_completed) does not enable Wi-Fi again.
wifi_reenable_once()
{
    if [ -n "`getprop debug.m681.wifi.reenable`" ]; then
        return 0
    fi
    setprop debug.m681.wifi.reenable running

    # Gate 1: wlan0 must exist, otherwise STA start fails.
    g1=absent
    n=0
    while [ "$n" -lt 60 ]; do
        if [ -d /sys/class/net/wlan0 ]; then g1=present; break; fi
        n=$((n + 1)); sleep 2
    done

    # Gate 2: WifiController must have started (it has state machine records).
    # CMD_WIFI_TOGGLED before start() crashes system_server.
    g2=0
    n=0
    while [ "$n" -lt 30 ]; do
        g2=`dumpsys wifi 2>/dev/null | grep -A1 "WifiController:" \
            | sed -n 's/.*total records=\([0-9][0-9]*\).*/\1/p'`
        [ -z "$g2" ] && g2=0
        if [ "$g2" -gt 0 ]; then break; fi
        n=$((n + 1)); sleep 2
    done

    if [ "$g1" = present ] && [ "$g2" -gt 0 ]; then
        setprop debug.m681.wifi.reenable done
        log -t "$TAG" "wifi re-enable FIRING: gate1 wlan0=$g1 gate2 WifiController_records=$g2"
        /system/bin/svc wifi enable
    else
        setprop debug.m681.wifi.reenable "blocked_g1_${g1}_g2_${g2}"
        log -t "$TAG" "wifi re-enable BLOCKED: gate1 wlan0=$g1 gate2 WifiController_records=$g2"
    fi
}

# Let system_server, SettingsProvider and the MTK connectivity services settle.
sleep 12

/system/bin/settings put global wifi_on 1
/system/bin/settings put global wifi_saved_state 1 2>/dev/null
/system/bin/setprop debug.m681.wifi.power 1
# Do not call `svc wifi enable` here: checkAndStartWifi() enables Wi-Fi from
# the persisted setting right after WifiController starts, while an early
# CMD_WIFI_TOGGLED crashes a restarting system_server.
log -t "$TAG" "wifi_on persisted; framework enables Wi-Fi at boot phase 500"

wait_count=0
while [ "$wait_count" -lt 30 ]; do
    if wifi_reconnect; then
        break
    fi
    wait_count=$((wait_count + 1))
    sleep 2
done

if bluetooth_ready; then
    /system/bin/settings put global bluetooth_on 1
    # svc rather than `service call bluetooth_manager`, whose transaction
    # numbers change between releases.
    /system/bin/svc bluetooth enable >/dev/null 2>&1
    log -t "$TAG" "requested bluetooth enable"
else
    /system/bin/settings put global bluetooth_on 0 2>/dev/null
    log -t "$TAG" "skip bluetooth enable: wmt/stpbt not ready"
fi

wifi_reenable_once

sleep 8
wifi_reconnect

for delay in 10 20 35; do
    sleep "$delay"
    if wifi_connected; then
        log -t "$TAG" "wifi stable; stop retry loop"
        break
    fi
    wifi_reconnect
done

log -t "$TAG" "end"
