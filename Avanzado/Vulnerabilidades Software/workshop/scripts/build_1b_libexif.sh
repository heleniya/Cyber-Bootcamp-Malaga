#!/usr/bin/env bash
# build_1b_libexif.sh — Compila libexif 0.6.21 en tres variantes + arneses
# CVE-2012-2836: out-of-bounds read en tags EXIF
# Basado en Fuzzing101 Exercise 2 por Antonio Morales / GitHub Security Lab
# https://github.com/antonio-morales/Fuzzing101
set -euo pipefail

WORKSHOP="${WORKSHOP:-$HOME/workshop}"
SRC="$WORKSHOP/src/libexif"
CORPUS="$WORKSHOP/corpus/libexif"
HARNESS_SRC="$WORKSHOP/arneses/libexif_harness.c"
LIBEXIF_URL="https://sourceforge.net/projects/libexif/files/libexif/0.6.21/libexif-0.6.21.tar.bz2"

ts() { echo "[$(date +%H:%M:%S)] $*"; }

ts "=== build_1b_libexif.sh: libexif 0.6.21 (3 variantes) ==="

if ! command -v afl-clang-fast &>/dev/null; then
    echo "ERROR: afl-clang-fast no encontrado en PATH" >&2; exit 1
fi

mkdir -p "$SRC" "$CORPUS"

# Descargar fuente
if [ ! -f "$SRC/libexif-0.6.21.tar.bz2" ]; then
    ts "Descargando libexif 0.6.21..."
    wget -q --show-progress -O "$SRC/libexif-0.6.21.tar.bz2" "$LIBEXIF_URL"
fi

# ── Función para compilar una variante ─────────────────────────────────────
build_variant() {
    local name="$1"       # plain | asan | ubsan
    local cflags="$2"
    local use_asan="${3:-0}"
    local use_ubsan="${4:-0}"
    local target="$WORKSHOP/objetivos/libexif/$name"

    if [ -f "$target/harness" ] && [ -s "$target/harness" ]; then
        ts "Variante $name ya compilada — saltando"
        return 0
    fi

    # IMPORTANTE: AFL_USE_ASAN / AFL_USE_UBSAN activan la instrumentación de
    # afl-clang-fast por su mera PRESENCIA en el entorno, no por su valor.
    # "AFL_USE_ASAN=0" sigue activando ASan (comprobado: nm sobre el binario
    # resultante muestra símbolos __asan_report_* igual que con AFL_USE_ASAN=1).
    # Para la variante "plain" no hay que exportar estas variables en absoluto.
    local -a env_args=()
    [ "$use_asan" = "1" ]  && env_args+=("AFL_USE_ASAN=1")
    [ "$use_ubsan" = "1" ] && env_args+=("AFL_USE_UBSAN=1")

    ts "Compilando variante: $name..."
    rm -rf "$SRC/libexif-0.6.21"
    tar -xjf "$SRC/libexif-0.6.21.tar.bz2" -C "$SRC"
    mkdir -p "$target"

    cd "$SRC/libexif-0.6.21"

    env "${env_args[@]}" \
    CC=afl-clang-fast \
    CFLAGS="$cflags" \
    ./configure --prefix="$target" --disable-shared 2>&1 | tail -3

    env "${env_args[@]}" \
    make -j"$(nproc)" 2>&1 | tail -5

    env "${env_args[@]}" \
    make install 2>&1 | tail -3

    ts "Compilando arnés para variante $name..."
    # -lm: exif-entry.c usa exp2/log10. Con ASan de por medio el enlace pasa
    # igualmente porque el runtime de ASan arrastra libm de forma transitiva,
    # pero en un build genuinamente plano (sin sanitizar) falta y el enlace
    # falla con "undefined reference to 'exp2'/'log10'".
    env "${env_args[@]}" \
    afl-clang-fast \
        $cflags \
        -I "$target/include" \
        -o "$target/harness" \
        "$HARNESS_SRC" \
        -L "$target/lib" -lexif -lm \
        -Wl,-rpath,"$target/lib"

    [ -f "$target/harness" ] && [ -s "$target/harness" ] || {
        echo "ERROR: arnés $name no generado" >&2; exit 1
    }
    ts "OK: variante $name — harness $(du -h "$target/harness" | cut -f1)"
}

# Verificar que el arnés fuente existe
if [ ! -f "$HARNESS_SRC" ]; then
    echo "ERROR: $HARNESS_SRC no encontrado. Ejecuta primero desde el directorio raíz del workshop." >&2
    exit 1
fi

# Compilar las tres variantes
build_variant "plain" "-O1 -g" "0" "0"
build_variant "asan"  "-fsanitize=address -O1 -g -fno-omit-frame-pointer" "1" "0"
build_variant "ubsan" "-fsanitize=address,undefined -O1 -g -fno-omit-frame-pointer" "1" "1"

# Generar seeds JPEG mínimos
if [ -z "$(ls -A "$CORPUS" 2>/dev/null)" ]; then
    ts "Generando seeds JPEG mínimos..."
    python3 - "$CORPUS" <<'PYEOF'
import os, sys, struct

corpus = sys.argv[1]
os.makedirs(corpus, exist_ok=True)

def make_jpeg(path, width=8, height=8, comment=None):
    """JPEG mínimo válido con cabecera SOI + APP0 + SOF0 + EOI."""
    data = bytearray()
    # SOI
    data += b'\xff\xd8'
    # APP0 JFIF
    app0 = b'JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
    data += b'\xff\xe0' + struct.pack('>H', len(app0) + 2) + app0
    # APP1 EXIF mínimo (para que libexif lo procese)
    exif_header = b'Exif\x00\x00'
    # Cabecera TIFF little-endian
    tiff = bytearray()
    tiff += b'II'                    # byte order: little-endian
    tiff += struct.pack('<H', 42)    # magic
    tiff += struct.pack('<I', 8)     # offset primer IFD
    # IFD con 1 entrada (ImageWidth)
    tiff += struct.pack('<H', 1)     # número de entradas
    tiff += struct.pack('<HHI', 0x0100, 3, 1)  # tag, tipo SHORT, count
    tiff += struct.pack('<HH', width, 0)        # value + padding
    tiff += struct.pack('<I', 0)     # offset siguiente IFD = 0 (fin)
    app1_data = exif_header + bytes(tiff)
    data += b'\xff\xe1' + struct.pack('>H', len(app1_data) + 2) + app1_data
    # Comentario opcional
    if comment:
        com = comment.encode()
        data += b'\xff\xfe' + struct.pack('>H', len(com) + 2) + com
    # SOF0 (Start of Frame)
    sof0 = struct.pack('>HBHHB', 8 + 3*3, 8, height, width, 3)
    for c in range(3):
        sof0 += bytes([c+1, 0x11, 0])
    data += b'\xff\xc0' + sof0
    # EOI
    data += b'\xff\xd9'
    with open(path, 'wb') as f:
        f.write(data)

make_jpeg(f'{corpus}/seed_basic.jpg', 8, 8)
make_jpeg(f'{corpus}/seed_comment.jpg', 16, 16, 'AFL++ seed')
make_jpeg(f'{corpus}/seed_small.jpg', 4, 4)

print("Seeds libexif OK:")
for f in sorted(os.listdir(corpus)):
    print(f"  {corpus}/{f}: {os.path.getsize(os.path.join(corpus, f))} bytes")
PYEOF
fi

ts "=== build_1b_libexif.sh completado ==="
ts "Arneses:"
for v in plain asan ubsan; do
    ts "  $WORKSHOP/objetivos/libexif/$v/harness"
done
ts "Corpus: $CORPUS ($(ls "$CORPUS" | wc -l) ficheros)"
