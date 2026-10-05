#!/bin/sh
# Checks that a prebuilt kernel matches its EXPECTED-<rev>.txt (MD5/VERSION).
# Called from BoardConfig.mk: prints nothing on success; any output fails the
# build. This only checks file identity, not that the kernel boots Android 9.
#
#   $1 - path to Image.gz-dtb
#   $2 - path to the expectations file
set -u
IMG=$1
EXP=$2

# Details go to stderr; a short marker on stdout makes BoardConfig.mk fail.
[ -f "$IMG" ] || { echo "KERNEL NOT FOUND: $IMG" >&2; echo "prebuilt-kernel: kernel missing, see details above"; exit 0; }
[ -f "$EXP" ] || { echo "NO EXPECTATIONS FILE: $EXP" >&2; echo "prebuilt-kernel: expectations file missing, see details above"; exit 0; }

want_md5=$(awk '$1=="MD5"{print $2}' "$EXP")
have_md5=$(md5sum "$IMG" | cut -d' ' -f1)
[ "$want_md5" = "$have_md5" ] && exit 0

want_ver=$(sed -n 's/^VERSION //p' "$EXP")
have_ver=$(python3 - "$IMG" <<'PY' 2>/dev/null
import sys, zlib, re
d = open(sys.argv[1], 'rb').read()
i = d.find(b'\x1f\x8b\x08')
raw = b''
if i >= 0:
    try:
        raw = zlib.decompressobj(16 + zlib.MAX_WBITS).decompress(d[i:])
    except Exception:
        pass
m = re.search(rb'Linux version [0-9][^\x00]{0,140}', raw)
print(m.group(0).decode('utf-8', 'replace').strip() if m else 'could not extract the version')
PY
)

cat >&2 <<MSG
The kernel in prebuilt-kernel/ does not match its EXPECTED file.
  file:     $IMG
  expected: $want_md5
            $want_ver
  found:    $have_md5
            $have_ver
If the kernel was replaced by accident, restore it from git. If it was
replaced on purpose, update EXPECTED-<rev>.txt in the same commit as the kernel.
A matching md5 only means the file matches the tree, not that it boots.
MSG
echo "prebuilt-kernel: kernel does not match ($have_md5 instead of $want_md5), see details above"
