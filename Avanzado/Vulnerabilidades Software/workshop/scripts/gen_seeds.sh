#!/usr/bin/env bash
# gen_seeds.sh — Regenera todos los seeds del workshop desde cero
# Útil si los seeds se corrompieron o se necesita un corpus limpio
set -euo pipefail

WORKSHOP="${WORKSHOP:-$HOME/workshop}"

ts() { echo "[$(date +%H:%M:%S)] $*"; }

ts "=== gen_seeds.sh: generando corpus para todos los targets ==="

# ── libexif: JPEGs con cabecera EXIF ────────────────────────────────────────
CORPUS="$WORKSHOP/corpus/libexif"
mkdir -p "$CORPUS"
ts "Generando seeds libexif en $CORPUS..."
python3 - "$CORPUS" <<'PYEOF'
import os, sys, struct

corpus = sys.argv[1]

def make_jpeg(path, width=8, height=8, comment=None):
    data = bytearray()
    data += b'\xff\xd8'
    app0 = b'JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
    data += b'\xff\xe0' + struct.pack('>H', len(app0) + 2) + app0
    exif_header = b'Exif\x00\x00'
    tiff = bytearray()
    tiff += b'II'
    tiff += struct.pack('<H', 42)
    tiff += struct.pack('<I', 8)
    tiff += struct.pack('<H', 1)
    tiff += struct.pack('<HHI', 0x0100, 3, 1)
    tiff += struct.pack('<HH', width, 0)
    tiff += struct.pack('<I', 0)
    app1_data = exif_header + bytes(tiff)
    data += b'\xff\xe1' + struct.pack('>H', len(app1_data) + 2) + app1_data
    if comment:
        com = comment.encode()
        data += b'\xff\xfe' + struct.pack('>H', len(com) + 2) + com
    sof0 = struct.pack('>HBHHB', 8 + 3*3, 8, height, width, 3)
    for c in range(3):
        sof0 += bytes([c+1, 0x11, 0])
    data += b'\xff\xc0' + sof0
    data += b'\xff\xd9'
    with open(path, 'wb') as f:
        f.write(data)

make_jpeg(f'{corpus}/seed_basic.jpg', 8, 8)
make_jpeg(f'{corpus}/seed_comment.jpg', 16, 16, 'AFL++ seed')
make_jpeg(f'{corpus}/seed_small.jpg', 4, 4)
print(f"  libexif: {len(os.listdir(corpus))} seeds")
PYEOF

# ── libxml2: XMLs mínimos ────────────────────────────────────────────────────
CORPUS="$WORKSHOP/corpus/libxml2"
mkdir -p "$CORPUS"
ts "Generando seeds libxml2 en $CORPUS..."
cat > "$CORPUS/seed_minimal.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <item id="1">Hello</item>
</root>
XML
cat > "$CORPUS/seed_attrs.xml" <<'XML'
<?xml version="1.0"?>
<!DOCTYPE note [<!ELEMENT note (body)><!ELEMENT body (#PCDATA)>]>
<note lang="en"><body>Test</body></note>
XML
echo "  libxml2: $(ls "$CORPUS" | wc -l) seeds"

ts "=== gen_seeds.sh completado ==="
for t in libexif libxml2; do
    n=$(ls "$WORKSHOP/corpus/$t" 2>/dev/null | wc -l)
    echo "  $t: $n ficheros en $WORKSHOP/corpus/$t"
done
