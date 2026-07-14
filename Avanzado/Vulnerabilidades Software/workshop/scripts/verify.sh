#!/usr/bin/env bash
# verify.sh — Verificación del entorno del taller de fuzzing
# Uso: ./verify.sh [--generate-crashes]
set -euo pipefail

WORKSHOP="${WORKSHOP:-$HOME/workshop}"
GENERATE_CRASHES=0
if [[ "${1:-}" == "--generate-crashes" ]]; then
    GENERATE_CRASHES=1
fi

# ── Colores y contadores ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
PASS=0; FAIL=0; WARN=0

ok()   { echo -e "  ${GREEN}✓${NC} $*"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $*"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; WARN=$((WARN + 1)); }
hdr()  { echo ""; echo "── $* ──────────────────────────────────────────"; }

# Detectar si estamos dentro de Docker
IN_DOCKER=0
[ -f /.dockerenv ] && IN_DOCKER=1

echo "======================================================"
echo "  Taller de Fuzzing con AFL++ — Verificación"
echo "  WORKSHOP = $WORKSHOP"
[ "$IN_DOCKER" -eq 1 ] && echo "  [Ejecutando dentro de Docker]"
echo "======================================================"

# ── 1. Herramientas AFL++ ───────────────────────────────────────────────────
hdr "1. Herramientas AFL++"
for tool in afl-fuzz afl-clang-fast afl-tmin afl-cmin afl-plot afl-showmap; do
    if command -v "$tool" &>/dev/null; then
        ok "$tool → $(which "$tool")"
    else
        fail "$tool — no encontrado en PATH"
    fi
done

# ── 2. Binarios compilados ──────────────────────────────────────────────────
hdr "2. Binarios compilados"

check_bin() {
    local path="$1"
    local label="${2:-$path}"
    if [ -f "$path" ] && [ -s "$path" ]; then
        ok "$label ($(du -h "$path" | cut -f1))"
    else
        fail "$label — no encontrado: $path"
    fi
}

check_bin "$WORKSHOP/objetivos/libexif/plain/harness"        "libexif harness (plain)"
check_bin "$WORKSHOP/objetivos/libexif/asan/harness"         "libexif harness (asan)"
check_bin "$WORKSHOP/objetivos/libexif/ubsan/harness"        "libexif harness (ubsan)"
check_bin "$WORKSHOP/objetivos/libxml2/bin/xmllint"          "libxml2 xmllint"

# ── 3. Corpus ───────────────────────────────────────────────────────────────
hdr "3. Corpus de seeds"
for target in libexif libxml2; do
    dir="$WORKSHOP/corpus/$target"
    if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null | wc -l)" -gt 0 ]; then
        n=$(ls "$dir" | wc -l)
        ok "$target — $n fichero(s) en $dir"
    else
        fail "$target — corpus vacío o no existe: $dir"
    fi
done

# Diccionario XML
if [ -f "$WORKSHOP/diccionarios/xml.dict" ] && [ -s "$WORKSHOP/diccionarios/xml.dict" ]; then
    ok "xml.dict — $(wc -l < "$WORKSHOP/diccionarios/xml.dict") líneas"
else
    fail "xml.dict — no encontrado: $WORKSHOP/diccionarios/xml.dict"
fi

# ── 4. Configuración del sistema ────────────────────────────────────────────
hdr "4. Configuración del sistema"

if [ -f /proc/sys/kernel/core_pattern ]; then
    core_pat=$(cat /proc/sys/kernel/core_pattern)
    if echo "$core_pat" | grep -q '|'; then
        warn "core_pattern contiene pipe: '$core_pat'"
        echo "    → Dentro del contenedor: echo core | sudo tee /proc/sys/kernel/core_pattern"
        echo "    → O usar: AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1"
    else
        ok "core_pattern: '$core_pat'"
    fi
else
    warn "core_pattern: no accesible (¿dentro de contenedor sin privilegios?)"
fi

if [ -f /proc/sys/kernel/perf_event_paranoid ]; then
    pep=$(cat /proc/sys/kernel/perf_event_paranoid)
    if [ "$pep" -le 1 ]; then
        ok "perf_event_paranoid: $pep"
    else
        warn "perf_event_paranoid: $pep (recomendado ≤ 1 para mejor rendimiento)"
        echo "    → sudo sh -c 'echo 1 > /proc/sys/kernel/perf_event_paranoid'"
    fi
else
    warn "perf_event_paranoid: no accesible"
fi

if [ "$IN_DOCKER" -eq 1 ]; then
    echo "    ℹ Dentro de Docker: algunos checks de kernel pueden fallar"
    echo "      Usar: AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 AFL_SKIP_CPUFREQ=1"
fi

# ── 5. Test básico de arneses (input vacío) ─────────────────────────────────
hdr "5. Test básico de arneses"

test_harness() {
    local name="$1"
    local harness="$2"
    local input="${3:-}"

    if [ ! -f "$harness" ]; then
        fail "$name — binario no existe"
        return
    fi

    local exit_code=0
    if [ -n "$input" ]; then
        "$harness" < "$input" >/dev/null 2>&1 || exit_code=$?
    else
        echo "" | "$harness" >/dev/null 2>&1 || exit_code=$?
    fi

    # Para arneses: exit 0 con input vacío es el comportamiento esperado
    if [ "$exit_code" -eq 0 ]; then
        ok "$name — exit 0 con input vacío"
    elif [ "$exit_code" -eq 1 ]; then
        # libexif puede retornar 1 con input inválido pero sin crash
        ok "$name — exit $exit_code con input vacío (sin crash)"
    else
        warn "$name — exit $exit_code (puede ser normal con input vacío)"
    fi
}

test_harness "libexif plain" "$WORKSHOP/objetivos/libexif/plain/harness"
test_harness "libexif asan"  "$WORKSHOP/objetivos/libexif/asan/harness"
test_harness "libexif ubsan" "$WORKSHOP/objetivos/libexif/ubsan/harness"

# ── 6. Test de crashes pre-generados ────────────────────────────────────────
hdr "6. Crashes pre-generados"

has_crashes() {
    local target="$1"
    local dir="$WORKSHOP/crashes/$target"
    [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null | wc -l)" -gt 0 ]
}

targets_with_crashes=()
targets_without_crashes=()

for target in libexif libxml2; do
    if has_crashes "$target"; then
        n=$(ls "$WORKSHOP/crashes/$target" | wc -l)
        ok "$target — $n crash(es) en $WORKSHOP/crashes/$target"
        targets_with_crashes+=("$target")
        # Reproducir el primer crash disponible
        crash_file=$(ls "$WORKSHOP/crashes/$target" | head -1)
        crash_path="$WORKSHOP/crashes/$target/$crash_file"
        case "$target" in
            libexif)
                exit_code=0
                "$WORKSHOP/objetivos/libexif/asan/harness" < "$crash_path" \
                    >/dev/null 2>&1 || exit_code=$?
                [ "$exit_code" -ne 0 ] && \
                    ok "  $target crash reproducible con ASan (exit $exit_code)" || \
                    warn "  $target crash no reproduce con ASan"
                ;;
        esac
    else
        warn "$target — sin crashes pre-generados"
        targets_without_crashes+=("$target")
    fi
done

if [ "${#targets_without_crashes[@]}" -gt 0 ]; then
    echo "    → Para generar crashes: ./scripts/verify.sh --generate-crashes"
fi

# ── 7. Generar crashes ──────────────────────────────────────────────────────
if [ "$GENERATE_CRASHES" -eq 1 ]; then
    hdr "7. Generando crashes (10 minutos por target)"
    echo "    ⏱ Esto tardará aprox. $(( ${#targets_without_crashes[@]} * 10 )) minutos"

    if ! command -v afl-fuzz &>/dev/null; then
        fail "afl-fuzz no disponible — no se pueden generar crashes"
    else
        generate_crashes_for() {
            local target="$1"
            local cmd="${@:2}"
            local out_dir="$WORKSHOP/crashes/${target}_run"
            local crash_dir="$WORKSHOP/crashes/$target"

            echo ""
            echo "  Fuzzeando $target durante 10 minutos..."
            mkdir -p "$out_dir" "$crash_dir"

            # Timeout de 600s = 10 minutos
            # -m none: sin límite de memoria de AFL. Los cuatro targets están
            # compilados con ASan, cuyas reservas de shadow-memory exceden
            # con facilidad el límite por defecto de afl-fuzz.
            AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
            AFL_SKIP_CPUFREQ=1 \
            timeout 620 \
            afl-fuzz -s 123 \
                -m none \
                -i "$WORKSHOP/corpus/$target" \
                -o "$out_dir" \
                -V 600 \
                -- $cmd >/dev/null 2>&1 || true

            # Copiar crashes al directorio definitivo
            local found=0
            if [ -d "$out_dir/default/crashes" ]; then
                cp "$out_dir/default/crashes/"id:* "$crash_dir/" 2>/dev/null && \
                    found=$(ls "$crash_dir" | wc -l) || true
            fi

            if [ "$found" -gt 0 ]; then
                ok "$target — $found crash(es) guardados en $crash_dir"
            else
                warn "$target — no se encontraron crashes en 10 minutos"
                echo "    → Intenta aumentar el tiempo o revisa la configuración"
            fi
        }

        generate_crashes_for libexif \
            "$WORKSHOP/objetivos/libexif/asan/harness"

        generate_crashes_for libxml2 \
            "$WORKSHOP/objetivos/libxml2/bin/xmllint" --valid @@
    fi
fi

# ── Resumen final ────────────────────────────────────────────────────────────
echo ""
echo "======================================================"
echo "  RESUMEN"
echo "======================================================"
echo -e "  ${GREEN}✓ Passed: $PASS${NC}"
[ "$WARN" -gt 0 ] && echo -e "  ${YELLOW}⚠ Warnings: $WARN${NC}"
[ "$FAIL" -gt 0 ] && echo -e "  ${RED}✗ Failed: $FAIL${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "  Comandos de remedio:"
    echo "  ─────────────────────"
    command -v afl-clang-fast &>/dev/null || \
        echo "  • AFL++ no instalado: docker pull aflplusplus/aflplusplus"
    [ ! -f "$WORKSHOP/objetivos/libexif/asan/harness" ] && \
        echo "  • libexif: bash scripts/build_1b_libexif.sh"
    [ ! -f "$WORKSHOP/objetivos/libxml2/bin/xmllint" ] && \
        echo "  • libxml2: bash scripts/build_2a_libxml2.sh"
    echo ""
    exit 1
fi

echo "  El entorno está listo para el taller."
if [ "$GENERATE_CRASHES" -eq 0 ] && [ "$FAIL" -eq 0 ]; then
    echo "  Para pre-generar crashes: ./scripts/verify.sh --generate-crashes"
fi
echo ""
