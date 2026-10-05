#!/system/bin/sh
# Seed /data/misc/wifi/wpa_supplicant.conf once: wpa_supplicant is started with
# -c on that path and exits if the file is missing (e.g. after a data wipe).
# Never overwrite: the file holds the saved networks.
F=/data/misc/wifi/wpa_supplicant.conf
[ -e "$F" ] && exit 0
cp /system/etc/wifi/wpa_supplicant.conf "$F" || exit 1
chown wifi:wifi "$F"
chmod 0660 "$F"
restorecon "$F"
