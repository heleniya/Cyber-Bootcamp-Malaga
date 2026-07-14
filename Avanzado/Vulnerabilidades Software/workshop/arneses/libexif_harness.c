/*
 * libexif_harness.c — Arnés de fuzzing para libexif 0.6.21
 * Ejercicio 1B del taller. Este fichero se da ya escrito a los estudiantes.
 *
 * Compilar (variante plain, asan o ubsan según $PREFIX y $CFLAGS):
 *   afl-clang-fast $CFLAGS -I$PREFIX/include -o harness \
 *       libexif_harness.c -L$PREFIX/lib -lexif -Wl,-rpath,$PREFIX/lib
 *
 * Para el reto extra de modo persistente, añadir -DAFL_PERSISTENT:
 *   afl-clang-fast $CFLAGS -DAFL_PERSISTENT -I$PREFIX/include -o harness_pm \
 *       libexif_harness.c -L$PREFIX/lib -lexif -Wl,-rpath,$PREFIX/lib
 *
 * Basado en Fuzzing101 Exercise 2 por Antonio Morales / GitHub Security Lab
 * https://github.com/antonio-morales/Fuzzing101
 */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <libexif/exif-data.h>

/*
 * ASan solo instala manejadores para SIGSEGV, SIGBUS y SIGFPE por defecto.
 * Algunos bugs de libexif (lecturas OOB que el compilador convierte en una
 * instrucción inválida) terminan en SIGILL, que ASan no captura salvo que
 * se le indique explícitamente con handle_sigill=1. Sin esto, el binario
 * "asan" moriría en silencio exactamente igual que uno sin sanitizar.
 *
 * __asan_default_options() es el mecanismo soportado por ASan para
 * incrustar opciones por defecto en el propio binario: el runtime lo
 * busca y lo invoca durante su inicialización, ANTES de main() (y antes
 * de que main() pueda hacer setenv("ASAN_OPTIONS", ...) — demasiado
 * tarde, porque para entonces ASan ya ha leído sus opciones). Solo tiene
 * efecto si el binario está enlazado con el runtime de ASan; en la
 * variante "plain" (sin sanitizar) esta función queda simplemente sin usar.
 */
const char *__asan_default_options(void) {
    return "handle_sigill=1:symbolize=1";
}

/*
 * LLVMFuzzerTestOneInput es la interfaz de LibFuzzer, adoptada también
 * por AFL++ como punto de entrada estándar para arneses de librería.
 *
 * Firma obligatoria: int LLVMFuzzerTestOneInput(const uint8_t*, size_t)
 *   - data: puntero al input generado por el fuzzer (no termina en '\0')
 *   - size: longitud del input en bytes
 *   - retorno: siempre 0 (retornar != 0 indica que el input debe descartarse)
 *
 * Esta función contiene la lógica de fuzzing real.
 * Es llamada desde main() en cada iteración del bucle de AFL++.
 *
 * ¿Por qué exif_data_new_from_data y no otras funciones?
 * Es el punto de entrada de más alto nivel: parsea la cabecera EXIF
 * completa desde un buffer en memoria, maximizando la cobertura del
 * parser con una sola llamada.
 */
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size == 0) return 0;

    /*
     * exif_data_new_from_data parsea el buffer como datos EXIF.
     * Retorna NULL si el buffer no tiene cabecera EXIF válida,
     * o un ExifData* válido que debemos liberar explícitamente.
     */
    ExifData *ed = exif_data_new_from_data(data, size);

    if (ed) {
        /*
         * exif_data_unref libera la memoria del objeto ExifData.
         * libexif usa conteo de referencias: unref decrementa el contador
         * y libera cuando llega a cero. Sin esto, el proceso acumula
         * memoria y el fuzzer se degrada con el tiempo.
         */
        exif_data_unref(ed);
    }

    return 0;
}

#ifdef AFL_PERSISTENT
/*
 * MODO PERSISTENTE (compilar con -DAFL_PERSISTENT)
 *
 * AFL++ escribe cada input directamente en un buffer de memoria compartida.
 * El proceso reutiliza el mismo pid entre inputs, eliminando el coste de
 * fork() y la carga dinámica de la librería en cada iteración.
 *
 * Mejora típica sobre el modo fork-server: 5–10x de exec/s.
 *
 * __AFL_FUZZ_INIT() declara las variables de estado para la memoria
 * compartida. Debe estar en el ámbito global, antes de main().
 */
__AFL_FUZZ_INIT();

int main(void) {
    __AFL_INIT();
    const uint8_t *buf = __AFL_FUZZ_TESTCASE_BUF;
    while (__AFL_LOOP(1000)) {
        uint32_t len = __AFL_FUZZ_TESTCASE_LEN;
        if (len == 0) continue;
        LLVMFuzzerTestOneInput(buf, len);
    }
    return 0;
}

#else
/*
 * MODO FORK SERVER (por defecto, sin -DAFL_PERSISTENT)
 *
 * afl-clang-fast instrumenta automáticamente el binario con un fork server.
 * AFL++ hace fork() desde este punto antes de que llegue cada input:
 * el proceso hijo ejecuta LLVMFuzzerTestOneInput una vez y termina.
 *
 * Más lento que el modo persistente (un fork() + carga de librería por input),
 * pero sencillo y suficiente para encontrar crashes en el taller.
 *
 * Para probar el arnés manualmente sin AFL++:
 *   echo -n "test" | ./harness
 *   ./harness < corpus/libexif/seed_basic.jpg
 */
int main(void) {
    uint8_t buf[1024 * 1024];
    ssize_t n = read(STDIN_FILENO, buf, sizeof(buf));
    if (n > 0) LLVMFuzzerTestOneInput(buf, (size_t)n);
    return 0;
}
#endif
