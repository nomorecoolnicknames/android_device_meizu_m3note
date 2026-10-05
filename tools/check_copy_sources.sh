#!/bin/sh
# Static check, no build: every PRODUCT_COPY_FILES source that lineage_m3note
# uses exists on disk.
#
# Reads device.mk, lineage_m3note.mk and BoardConfig.mk of this tree,
# vendor/meizu/m681/m681-vendor.mk and the vendor/meizu/m3note profile makefiles.
# Variables are substituted as the build sees them:
#   $(LOCAL_PATH), $(DEVICE_PATH)  -> device/meizu/m3note (this tree)
#   $(L681_STOCK_DIR)              -> $2 (L681H stock)
#   $(TARGET_COPY_OUT_VENDOR)      -> vendor
# Everything else is looked up in the LOS 16 source tree $1.
#
# This checks file existence only; rules built with $(foreach)/$(wildcard) are
# listed separately and '%' filters are skipped.
#
#   $1 - root of the LOS 16 source tree (required)
#   $2 - L681_STOCK_DIR, unpacked stock system (required)
#   $3 - vendor/meizu/m3note (default: ../../../vendor/meizu/m3note from here)
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd)
LOS=${1:?usage: check_copy_sources.sh <LOS16 tree> <stock system dir> [vendor/meizu/m3note]}
STOCK=${2:?usage: check_copy_sources.sh <LOS16 tree> <stock system dir> [vendor/meizu/m3note]}
VEND=${3:-$HERE/../../../vendor/meizu/m3note}
exec python3 - "$HERE" "$LOS" "$STOCK" "$VEND" <<'PY'
import os, re, sys
here, los, stock, vend = sys.argv[1:5]
vend = os.path.realpath(vend)
files = [os.path.join(here, f) for f in ('device.mk', 'lineage_m3note.mk', 'BoardConfig.mk')]
files.append(os.path.join(los, 'vendor/meizu/m681/m681-vendor.mk'))
files += [os.path.join(vend, f) for f in ('m3note-vendor.mk', 'profile-m681.mk', 'profile-l681.mk')]
subst = {
    '$(LOCAL_PATH)': 'device/meizu/m3note',
    '$(DEVICE_PATH)': 'device/meizu/m3note',
    '$(L681_STOCK_DIR)': stock,
    '$(TARGET_COPY_OUT_VENDOR)': 'vendor',
    '$(M3NOTE_M681_SET_DIR)': 'vendor/meizu/m681/proprietary',
    '$(M3NOTE_L681_DIR)': 'vendor/meizu/l681',
}
tok = re.compile(r'(\S+):(\S+)')
ok = missing = skipped = 0
miss = []
dynamic = []
for fn in files:
    for ln, line in enumerate(open(fn, encoding='utf-8', errors='replace'), 1):
        s = line.split('#', 1)[0].strip().rstrip('\\').strip()
        if not s or '%' in s:
            continue
        if '$(foreach' in s or '$(wildcard' in s:
            dynamic.append('%s:%d: %s' % (os.path.relpath(fn, here) if fn.startswith(here) else fn, ln, s))
            continue
        for m in tok.finditer(s):
            src, dst = m.group(1), m.group(2)
            if '/' not in src or src.startswith('$(shell'):
                continue
            for k, v in subst.items():
                src = src.replace(k, v)
            if '$(' in src:
                skipped += 1
                continue
            if src.startswith('/'):
                path = src
            elif src.startswith('device/meizu/m3note/'):
                path = os.path.join(here, src[len('device/meizu/m3note/'):])
            elif src.startswith('vendor/meizu/m3note/'):
                path = os.path.join(vend, src[len('vendor/meizu/m3note/'):])
            else:
                path = os.path.join(los, src)
            if os.path.exists(path):
                ok += 1
            else:
                missing += 1
                miss.append('%s:%d: %s' % (os.path.basename(fn), ln, src))
print('LOS16 tree:   %s' % los)
print('stock dir:    %s' % stock)
print('sources found: %d, missing: %d, unresolved-variable: %d' % (ok, missing, skipped))
for m in miss:
    print('MISSING  ' + m)
for d in dynamic:
    print('DYNAMIC  ' + d)
sys.exit(1 if missing else 0)
PY
