#!/usr/bin/env bash
# build_2a_libxml2.sh — Compila libxml2 2.9.4 con AFL_USE_ASAN y xmllint
# CVE-2017-9048: stack buffer overflow en el validador XML
# Basado en Fuzzing101 Exercise 5 por Antonio Morales / GitHub Security Lab
# https://github.com/antonio-morales/Fuzzing101
set -euo pipefail

WORKSHOP="${WORKSHOP:-$HOME/workshop}"
SRC="$WORKSHOP/src/libxml2"
TARGET="$WORKSHOP/objetivos/libxml2"
CORPUS="$WORKSHOP/corpus/libxml2"
DICTS="$WORKSHOP/diccionarios"
LIBXML2_URL="https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.9.4/libxml2-v2.9.4.tar.gz"
XML_DICT_URL="https://raw.githubusercontent.com/AFLplusplus/AFLplusplus/stable/dictionaries/xml.dict"

ts() { echo "[$(date +%H:%M:%S)] $*"; }

ts "=== build_2a_libxml2.sh: libxml2 2.9.4 ==="

if [ -f "$TARGET/bin/xmllint" ] && [ -s "$TARGET/bin/xmllint" ]; then
    ts "libxml2 ya compilada — saltando"
    exit 0
fi

if ! command -v afl-clang-fast &>/dev/null; then
    echo "ERROR: afl-clang-fast no encontrado" >&2; exit 1
fi

mkdir -p "$SRC" "$TARGET" "$CORPUS" "$DICTS"

# Descargar fuente
if [ ! -d "$SRC/libxml2-v2.9.4" ]; then
    ts "Descargando libxml2 2.9.4..."
    if ! wget -q --show-progress -O "$SRC/libxml2-v2.9.4.tar.gz" "$LIBXML2_URL"; then
        ts "GitLab falló, intentando clonar con git..."
        git clone --depth 1 --branch v2.9.4 \
            https://gitlab.gnome.org/GNOME/libxml2.git \
            "$SRC/libxml2-v2.9.4"
    else
        tar -xzf "$SRC/libxml2-v2.9.4.tar.gz" -C "$SRC"
    fi
fi

ts "Configurando libxml2 2.9.4..."
cd "$SRC/libxml2-v2.9.4"

# Generar configure si viene de git (sin tarball)
if [ ! -f configure ]; then
    autoreconf -fiv 2>&1 | tail -5
fi

AFL_USE_ASAN=1 \
CC=afl-clang-fast \
CFLAGS="-fsanitize=address -O1 -g -fno-omit-frame-pointer" \
./configure \
    --prefix="$TARGET" \
    --disable-shared \
    --without-python \
    --without-lzma \
    2>&1 | tail -5

ts "Compilando libxml2 + xmllint..."
AFL_USE_ASAN=1 make -j"$(nproc)" 2>&1 | tail -10
AFL_USE_ASAN=1 make install 2>&1 | tail -3

ts "Verificando..."
[ -f "$TARGET/bin/xmllint" ] && [ -s "$TARGET/bin/xmllint" ] || {
    echo "ERROR: xmllint no generado" >&2; exit 1
}
ts "OK: xmllint — $(du -h "$TARGET/bin/xmllint" | cut -f1)"

# Descargar diccionario XML de AFL++
if [ ! -f "$DICTS/xml.dict" ]; then
    ts "Descargando diccionario XML de AFL++..."
    wget -q -O "$DICTS/xml.dict" "$XML_DICT_URL" || {
        ts "Creando diccionario XML mínimo de fallback..."
        cat > "$DICTS/xml.dict" <<'DICT'
# Diccionario XML para AFL++ — tokens frecuentes en documentos XML
"<?xml"
"?>"
"<!--"
"-->"
"<![CDATA["
"]]>"
"<!DOCTYPE"
"<!ELEMENT"
"<!ATTLIST"
"<!ENTITY"
"&amp;"
"&lt;"
"&gt;"
"&quot;"
"&apos;"
"encoding="
"version="
"standalone="
"<root>"
"</root>"
"xmlns:"
DICT
    }
fi
ts "OK: $DICTS/xml.dict ($(wc -l < "$DICTS/xml.dict") líneas)"

# Seed corpus
if [ -z "$(ls -A "$CORPUS" 2>/dev/null)" ]; then
    ts "Generando seed XML..."
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
fi

ts "=== build_2a_libxml2.sh completado ==="
ts "xmllint: $TARGET/bin/xmllint"
ts "Dict:    $DICTS/xml.dict"
ts "Corpus:  $CORPUS ($(ls "$CORPUS" | wc -l) ficheros)"
