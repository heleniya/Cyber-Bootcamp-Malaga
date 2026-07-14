# crashes/

Este directorio contiene los inputs que causan crash en cada target.

## Estructura

```
crashes/
├── libexif/       ← crashes de libexif (CVE-2012-2836) — necesarios para Ejercicio 2 (advisory)
└── libxml2/       ← crashes de libxml2 (CVE-2017-9048) — Ejercicio 3 (opcional)
```

## Cómo generar los crashes

```bash
./scripts/verify.sh --generate-crashes
```

Esto ejecuta AFL++ durante 10 minutos por target con seed fija (`-s 123`)
y copia los crashes encontrados a este directorio. libxml2 ya trae un
PoC pre-verificado (`id:000000,...,src:preverified,...`) — no dependas
de que esta campaña encuentre uno nuevo por su cuenta.

## Reproducir un crash manualmente

```bash
# libexif (con ASan para ver el stacktrace)
$WORKSHOP/objetivos/libexif/asan/harness < crashes/libexif/id:000000*

# libxml2
$WORKSHOP/objetivos/libxml2/bin/xmllint --valid crashes/libxml2/id:000000*
```

## Minimizar un crash

```bash
# Minimizar el primer crash de libexif
afl-tmin \
    -i crashes/libexif/id:000000* \
    -o crashes/libexif/minimized \
    -- $WORKSHOP/objetivos/libexif/asan/harness
```
