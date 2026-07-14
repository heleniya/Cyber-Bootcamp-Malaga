# Advisory de Seguridad — [Nombre del software] [Versión]

> **Ejercicio 2 del taller** — Rellena este documento con tus propios hallazgos
> sobre el crash que encontraste en el Ejercicio 1 (libexif con ASan).
> **No busques el CVE real**: el objetivo es que tu análisis sea independiente.
> Usa solo el output de ASan y lo que observas ejecutando el binario.

---

## Resumen

[1-2 frases describiendo el problema. Ejemplo:
"Se ha identificado un defecto de memoria en el parser de datos EXIF de
[software] [versión] que puede ser activado mediante un fichero JPEG
especialmente construido."]

---

## Información del bug

| Campo | Valor |
|-------|-------|
| **Tipo de vulnerabilidad** | [CWE-... — ¿qué dice el reporte de ASan?] |
| **Componente afectado** | [¿Qué función aparece en el tope del stacktrace?] |
| **Versión afectada** | [versión que compilaste] |
| **Versión parcheada** | [desconocida / buscar en el changelog del proyecto] |
| **Fecha de descubrimiento** | [hoy] |

---

## Descripción técnica

[Describe qué ocurre exactamente. Copia el output relevante de ASan aquí.
Incluye: el tipo de error (READ/WRITE), el tamaño del acceso inválido,
y las primeras líneas del stacktrace.]

```
[Pega aquí el output de ASan]
```

---

## Vector de ataque

Responde a estas preguntas:

- **¿Es necesaria interacción del usuario?**
  [Sí / No — ¿el usuario tiene que abrir el fichero manualmente?]

- **¿El vector es local o de red?**
  [Local / Adyacente / Red — ¿el atacante puede enviar el fichero por red?]

- **¿Qué privilegios necesita el atacante?**
  [Ninguno / Bajo / Alto — ¿necesita cuenta en el sistema?]

- **¿Afecta a otros componentes del sistema, más allá del proceso que
  crashea?**
  [¿El proceso crasheado tiene acceso a información sensible o a otros
  sistemas? En CVSS 4.0 esto se llama "Subsequent System" — ver más abajo.]

---

## Impacto

| Dimensión | Impacto | Justificación |
|-----------|---------|---------------|
| **Confidencialidad** | Ninguno / Bajo / Alto | [¿Se puede leer memoria fuera de límites?] |
| **Integridad** | Ninguno / Bajo / Alto | [¿Se modifica memoria? ¿Es un OOB write o solo read?] |
| **Disponibilidad** | Ninguno / Bajo / Alto | [¿El programa crashea? ¿Siempre?] |

---

## CVSS v4.0

> Calculadora oficial (usa esta calculadora para construir el vector y
> obtener la puntuación — no hay una guía aparte en este taller, la
> propia calculadora explica cada métrica al pasar el ratón por encima):
> **https://www.first.org/cvss/calculator/4.0**
>
> Especificación completa si quieres el detalle de cada métrica:
> https://www.first.org/cvss/v4.0/specification-document

CVSS 4.0 cambia la estructura respecto a 3.1: ya no existe la métrica
"Scope" — en su lugar hay dos grupos de impacto separados, el del
**sistema vulnerable** (`VC`/`VI`/`VA`) y el de **sistemas
subsecuentes** (`SC`/`SI`/`SA`, cualquier otro sistema al que el bug dé
alcance más allá del proceso afectado). También se añade `AT` (Attack
Requirements: ¿hace falta alguna condición previa además del propio
ataque, como una carrera de condición o una configuración concreta?) y
`UI` ahora distingue interacción **Pasiva** (el usuario simplemente abre
algo) de **Activa** (el usuario tiene que hacer algo más específico).

Preguntas guía para cada métrica base (no sustituyen la calculadora,
solo orientan qué mirar en tu propio crash):

| Métrica | Pregunta |
|---|---|
| `AV` (Attack Vector) | ¿Cómo le llega el fichero malicioso a la víctima — red, mismo segmento, disco local, acceso físico? |
| `AC` (Attack Complexity) | ¿Hace falta algo más que construir el fichero — condiciones de carrera, bypass de mitigaciones? |
| `AT` (Attack Requirements) | ¿Hace falta una configuración o estado previo concreto del sistema objetivo? |
| `PR` (Privileges Required) | ¿Qué cuenta/privilegio necesita quien entrega el fichero? |
| `UI` (User Interaction) | ¿La víctima solo tiene que abrir el fichero (Pasiva), o tiene que hacer algo más (Activa)? |
| `VC`/`VI`/`VA` (impacto en el sistema vulnerable) | De tu tabla de Impacto de arriba, directamente. |
| `SC`/`SI`/`SA` (impacto en sistemas subsecuentes) | ¿El proceso que crashea tiene acceso a otros sistemas/datos que también quedarían comprometidos? Si no ves ninguno, es válido poner los tres a Ninguno. |

- **Vector string**: `CVSS:4.0/AV:.../AC:.../AT:.../PR:.../UI:.../VC:.../VI:.../VA:.../SC:.../SI:.../SA:...`
- **Puntuación base**: [X.X]
- **Severidad**: [None / Low / Medium / High / Critical]

---

## Reproducción

Pasos mínimos para reproducir el crash:

```bash
# 1. Compilar el arnés con ASan
afl-clang-fast -fsanitize=address -O1 -g \
    -I $WORKSHOP/objetivos/libexif/asan/include \
    -o harness arneses/libexif_harness.c \
    -L $WORKSHOP/objetivos/libexif/asan/lib -lexif

# 2. Ejecutar el arnés con el input problemático
./harness < [ruta al fichero que causa el crash]
```

Salida esperada:
```
[Copia aquí las primeras líneas del output de ASan que confirman el crash]
```

---

## Mitigación

[¿Qué puede hacer un usuario o administrador afectado mientras no hay parche?]

Opciones habituales:
- Evitar procesar ficheros EXIF/JPEG de fuentes no confiables
- Aislar la aplicación que usa la librería (sandbox, contenedor)
- Monitorizar crashes del proceso

---

## Notas adicionales

[Cualquier observación sobre el impacto real, la explotabilidad más allá
de un DoS, o diferencias observadas entre las tres variantes del binario
(plain, asan, ubsan).]
