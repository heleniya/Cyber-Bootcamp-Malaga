/*
 * libxml2_harness_template.c — Plantilla de arnés para libxml2 2.9.4
 * Ejercicio 2 🟢 (nivel verde) — CVE-2017-9048
 *
 * Tu tarea: completar los TODO marcados abajo para que el arnés:
 *   1. Inicialice el parser de libxml2 (una sola vez al inicio)
 *   2. Parsee el input del fuzzer con xmlReadMemory()
 *   3. Libere los recursos correctamente
 *
 * Compilar (una vez completado):
 *   AFL_USE_ASAN=1 \
 *   afl-clang-fast -O1 -g -fsanitize=address -fno-omit-frame-pointer \
 *       -I$WORKSHOP/objetivos/libxml2/include/libxml2 \
 *       -o harness_libxml2 libxml2_harness_template.c \
 *       -L$WORKSHOP/objetivos/libxml2/lib -lxml2 -lz -lm \
 *       -Wl,-rpath,$WORKSHOP/objetivos/libxml2/lib
 *
 * Documentación de referencia:
 *   https://gnome.pages.gitlab.gnome.org/libxml2/devhelp/libxml2-parser.html
 *
 * Basado en Fuzzing101 Exercise 5 por Antonio Morales / GitHub Security Lab
 * https://github.com/antonio-morales/Fuzzing101
 */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* TODO 1: Añade los includes necesarios de libxml2.
 * Pista: necesitas el parser y el árbol XML.
 * Los headers están en: $WORKSHOP/objetivos/libxml2/include/libxml2/
 * Busca libxml/parser.h y libxml/tree.h
 */
/* #include <libxml/...> */
/* #include <libxml/...> */

/*
 * xmlInitParser() inicializa las estructuras globales del parser.
 * Debe llamarse una sola vez antes de cualquier otro uso de libxml2.
 *
 * En un arnés de fuzzing, el lugar correcto es LLVMFuzzerInitialize
 * (se llama una vez al arrancar) o con un flag estático en la primera
 * llamada a LLVMFuzzerTestOneInput.
 *
 * Pista: usa la función __attribute__((constructor)) o un flag estático.
 */

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size == 0) return 0;

    /* TODO 2: Inicializa el parser de libxml2 la primera vez.
     * Usa una variable estática para evitar llamarlo en cada iteración.
     *
     *   static int initialized = 0;
     *   if (!initialized) {
     *       xmlInitParser();
     *       initialized = 1;
     *   }
     */

    /* TODO 3: Parsea el input con xmlReadMemory().
     *
     * Firma: xmlDocPtr xmlReadMemory(const char *buffer, int size,
     *                                const char *URL, const char *encoding,
     *                                int options)
     *
     *   - buffer: (const char*)data — el input del fuzzer
     *   - size:   (int)size         — longitud del input
     *   - URL:    "noname.xml"      — nombre ficticio (necesario)
     *   - encoding: NULL            — detectar automáticamente
     *   - options: 0                — sin opciones especiales
     *
     * Retorna xmlDocPtr (el árbol XML) o NULL si el parsing falla.
     * Un retorno NULL NO es un crash: libxml2 maneja errores internamente.
     */
    /* xmlDocPtr doc = xmlReadMemory(...); */

    /* TODO 4: Libera el árbol XML si se parseó correctamente.
     *
     * Si doc != NULL, libera la memoria con xmlFreeDoc(doc).
     * Si doc == NULL, no hay nada que liberar.
     */
    /* if (doc) { */
    /*     xmlFreeDoc(doc); */
    /* } */

    return 0;
}

/* TODO 5: Añade el main con soporte de persistent mode de AFL++.
 *
 * La estructura es siempre la misma para cualquier arnés AFL++:
 *
 *   __AFL_FUZZ_INIT();
 *
 *   int main(void) {
 *       __AFL_INIT();
 *       const uint8_t *buf = __AFL_FUZZ_TESTCASE_BUF;
 *       while (__AFL_LOOP(1000)) {
 *           uint32_t len = __AFL_FUZZ_TESTCASE_LEN;
 *           if (len == 0) continue;
 *           LLVMFuzzerTestOneInput(buf, len);
 *       }
 *       return 0;
 *   }
 *
 * Consulta libexif_harness.c para ver la implementación completa
 * con comentarios detallados sobre cada macro de AFL++.
 */

/*
 * EXTRA (opcional): Intenta añadir validación DTD.
 * Con la opción XML_PARSE_DTDVALID, el parser valida el documento
 * contra su DTD interna. Esto aumenta la cobertura del validador,
 * donde está el CVE-2017-9048 (stack buffer overflow).
 *
 * Cambia la opción de:  0
 * A:                    XML_PARSE_DTDVALID
 *
 * ¿Cambia la velocidad del fuzzer? ¿Por qué?
 */
