#!/usr/bin/env bash
# build_all.sh — Compila todos los targets del taller en orden
# Ejecutar desde el directorio raíz del workshop o con WORKSHOP= configurado
set -euo pipefail

WORKSHOP="${WORKSHOP:-$HOME/workshop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ts() { echo "[$(date +%H:%M:%S)] $*"; }

ts "======================================================"
ts "  Taller de Fuzzing con AFL++ — Compilación completa"
ts "  WORKSHOP = $WORKSHOP"
ts "======================================================"

# Verificar que estamos en el directorio correcto
for dir in scripts arneses; do
    if [ ! -d "$SCRIPT_DIR/../$dir" ]; then
        echo "ERROR: No se encuentra $dir/. Ejecuta desde el directorio raíz del workshop." >&2
        exit 1
    fi
done

export WORKSHOP

run_step() {
    local script="$1"
    local label="$2"
    ts "──────────────────────────────────────────────────"
    ts "PASO: $label"
    ts "──────────────────────────────────────────────────"
    bash "$SCRIPT_DIR/$script" || {
        echo ""
        echo "ERROR en $script. Abortando." >&2
        exit 1
    }
}

run_step "build_1b_libexif.sh" "1 — libexif 0.6.21 (3 variantes)"
run_step "build_2a_libxml2.sh" "2 — libxml2 2.9.4"
run_step "gen_seeds.sh"        "Seeds — generando corpus inicial"

ts "======================================================"
ts "  Compilación completada. Verificando instalación..."
ts "======================================================"

bash "$SCRIPT_DIR/verify.sh"
