/*
 * barra.c
 *
 * Programa único que integra:
 *  - temporizador minuto a minuto (timerfd)
 *  - eventos de PulseAudio (volumen / sink) usando pa_threaded_mainloop
 *  - eventos de foco de ventana desde sway/i3 IPC
 *
 * Todo integrado en un único bucle con poll(), emitiendo por stdout
 * líneas JSON (arrays de bloques) compatibles con i3bar/swaybar.
 *
 * Compilar:
 *   gcc -Wall -O2 -o barra barra.c -lpulse -lpulse-simple -ljson-c -lpulse-mainloop-glib
 *
 * Uso:
 *   Ejecutar y conectarlo a swaybar/sway: ./barra | swaybar
 *
 * Autor: (integración solicitada por Jon)
 * Versión refactorizada para mayor legibilidad
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include <sys/timerfd.h>
#include <sys/eventfd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <signal.h>
#include <fcntl.h>
#include <wchar.h>
#include <locale.h>

#include <json-c/json.h>
#include <pulse/pulseaudio.h>
#include <pulse/thread-mainloop.h>
#include <pulse/subscribe.h>
#include <pulse/introspect.h>

/* -------------------------
 *  Constantes
 * -------------------------*/
#define MAGIC "i3-ipc"
#define MAGIC_LEN 6
#define SUBSCRIBE 2
#define GET_TREE 4
#define MAX_CHARS_FOCO 110
#define TAM_BUFFER_NOMBRE 256
#define TAM_BUFFER_FECHA 64
#define TAM_BUFFER_VOLUMEN 64
#define TAM_TEXTO_TRUNCADO 128
#define TAMAÑO_MAX_MENSAJE_IPC (2 * 1024 * 1024)  // 2MB es más que suficiente
#define TAMAÑO_MAX_JSON_SWAY (1024 * 1024)     /* 1MB máximo para JSON de sway */
#define PROFUNDIDAD_MAX_JSON 50                /* Evitar stack overflow en recursión */
//

/* -------------------------
 *  Estructuras
 * -------------------------*/

/* Estado compartido que se muestra en la barra */
struct EstadoAudio {
    int volumen_porcentaje;          /* Último volumen conocido (0..200) */
    uint32_t indice_sumidero;        /* Índice del sumidero actual */
    char nombre_sumidero[TAM_BUFFER_NOMBRE]; /* Nombre del sumidero por defecto */
    bool listo;                      /* Contexto PA listo */
    char foco_actual[TAM_BUFFER_NOMBRE]; /* Nombre de la ventana con foco */
    bool mute;                       /* Estado de silencio */
};

/* Contexto general de la aplicación */
struct Contexto {
    pa_threaded_mainloop *ml;
    pa_mainloop_api *api;
    pa_context *ctx;
    int efd_notificacion;            /* eventfd para notificar al hilo principal */
    pthread_mutex_t candado;
    struct EstadoAudio estado;
};

/* -------------------------
 *  Prototipos de funciones
 * -------------------------*/

// Utilidades básicas
static ssize_t escribir_exacto(int fd, const void *buf, size_t count);
static ssize_t leer_exacto(int fd, void *buf, size_t count);
static void notificar_evento(struct Contexto *cx);

// Formateo y conversión
static int volumen_a_porcentaje(const pa_cvolume *cv);
static void formatear_fecha_hora(char *dest, size_t tam);
static void truncar_texto_utf8(char *destino, size_t tam_destino, const char *texto_original);

// Temporizador
static int crear_timer_minutero(void);
static void programar_siguiente_minuto(int tfd);

// PulseAudio
static int inicializar_pulseaudio(struct Contexto *cx);
static void cb_estado_pa(pa_context *c, void *userdata);
static void cb_info_servidor(pa_context *c, const pa_server_info *info, void *userdata);
static void cb_info_sumidero(pa_context *c, const pa_sink_info *info, int eol, void *userdata);
static void cb_suscripcion_pa(pa_context *c, pa_subscription_event_type_t tipo, uint32_t idx, void *userdata);
static void solicitar_info_sumidero_actual(struct Contexto *cx);
static void configurar_suscripciones_pa(struct Contexto *cx);

// Sway/i3 IPC
static int conectar_sway_ipc(const char *socket_path);
static int enviar_ipc(int fd, uint32_t type, const char *payload);
static int leer_ipc(int fd, uint32_t *type_out, char **out_buf, uint32_t *out_len);
static int suscribirse_eventos_sway(int sway_fd);
static void actualizar_foco_desde_sway(struct Contexto *cx, int sway_fd);
static char *extraer_ventana_foco_de_arbol(const char *json_str, uint32_t len);

// Funciones auxiliares para Sway/i3 (nuevas)
static char *crear_cadena_fallback(const char *mensaje_fallback);
static bool validar_json_entrada(const char *json_str, uint32_t len);
static void buscar_foco_recursivo_seguro(struct json_object *array, char **nombre_salida, int profundidad);

// JSON / i3bar
static void crear_bloque_foco(struct json_object *array, const struct EstadoAudio *estado);
static void crear_bloque_volumen(struct json_object *array, const struct EstadoAudio *estado);
static void crear_bloque_fecha(struct json_object *array);
static void imprimir_bloques_json(const struct EstadoAudio *estado, bool *es_primera_salida);
static const char *obtener_icono_volumen(int volumen, bool mute);
static void obtener_colores_volumen(bool mute, const char **color_fondo, const char **color_texto);

// Bucle principal
static int configurar_descriptores_poll(struct pollfd *fds, int tfd, int efd, int sway_fd);
static void copiar_estado_actual(struct Contexto *cx, struct EstadoAudio *copia);
static void manejar_evento_timer(int tfd, struct Contexto *cx, bool *es_primera_salida);
static void manejar_evento_notificacion(int efd, struct Contexto *cx, bool *es_primera_salida);
static void manejar_evento_sway(int sway_fd, struct Contexto *cx, int *nfds);

/* -------------------------
 *  Implementación: Utilidades básicas
 * -------------------------*/

static ssize_t escribir_exacto(int fd, const void *buf, size_t count) {
    size_t written = 0;
    const char *p = buf;
    while (written < count) {
        ssize_t w = write(fd, p + written, count - written);
        if (w < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        written += (size_t)w;
    }
    return (ssize_t)written;
}

static ssize_t leer_exacto(int fd, void *buf, size_t count) {
    size_t got = 0;
    char *p = buf;
    while (got < count) {
        ssize_t r = read(fd, p + got, count - got);
        if (r < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        if (r == 0) return 0; /* EOF */
        got += (size_t)r;
    }
    return (ssize_t)got;
}

static void notificar_evento(struct Contexto *cx) {
    uint64_t uno = 1;
    ssize_t r = write(cx->efd_notificacion, &uno, sizeof(uno));
    if (r != sizeof(uno)) {
        perror("eventfd write");
    }
}

/* -------------------------
 *  Implementación: Formateo y conversión
 * -------------------------*/

static int volumen_a_porcentaje(const pa_cvolume *cv) {
    if (!cv || cv->channels == 0) return -1;
    pa_volume_t v = pa_cvolume_avg(cv);
    long pct = (long)((v * 100ULL + (PA_VOLUME_NORM / 2)) / PA_VOLUME_NORM);
    if (pct < 0) pct = 0;
    if (pct > 200) pct = 200;
    return (int)pct;
}

static void formatear_fecha_hora(char *dest, size_t tam) {
    time_t t = time(NULL);
    struct tm tm;
    localtime_r(&t, &tm);
    strftime(dest, tam, "%Y-%m-%d %H:%M", &tm);
}

static void truncar_texto_utf8(char *destino, size_t tam_destino, const char *texto_original) {
    if (!texto_original || !destino || tam_destino < 4) {
        if (destino && tam_destino > 0)
            destino[0] = '\0';
        return;
    }

    mbstate_t estado = {0};
    size_t len_original = strlen(texto_original);
    size_t wchar_count = mbsnrtowcs(NULL, &texto_original, len_original, 0, &estado);

    if (wchar_count == (size_t)(-1)) {
        /* Error de codificación UTF-8: fallback a truncado simple */
        strncpy(destino, texto_original, tam_destino - 1);
        destino[tam_destino - 1] = '\0';
        return;
    }

    if (wchar_count <= MAX_CHARS_FOCO) {
        strncpy(destino, texto_original, tam_destino - 1);
        destino[tam_destino - 1] = '\0';
    } else {
        wchar_t wbuf[MAX_CHARS_FOCO + 1];
        mbstate_t estado2 = {0};
        size_t conv = mbsnrtowcs(wbuf, &texto_original, len_original, MAX_CHARS_FOCO, &estado2);
        if (conv == (size_t)(-1)) {
            strncpy(destino, texto_original, tam_destino - 1);
            destino[tam_destino - 1] = '\0';
            return;
        }

        wbuf[MAX_CHARS_FOCO - 3] = L'\0';
        char *p = destino;
        size_t restante = tam_destino;

        for (size_t i = 0; i < MAX_CHARS_FOCO - 3 && restante > 1; i++) {
            size_t n = wcrtomb(p, wbuf[i], &estado2);
            if (n == (size_t)(-1)) break;
            if (n >= restante) break;
            p += n;
            restante -= n;
        }

        if (restante > 4) {
            strcpy(p, "...");
        } else if (restante > 1) {
            strcpy(p, ".");
        }
        destino[tam_destino - 1] = '\0';
    }
}

/* -------------------------
 *  Implementación: Temporizador
 * -------------------------*/

static void programar_siguiente_minuto(int tfd) {
    time_t ahora = time(NULL);
    struct tm tm;
    localtime_r(&ahora, &tm);
    tm.tm_sec = 0;
    tm.tm_min += 1;
    time_t siguiente = mktime(&tm);

    struct itimerspec its = {0};
    its.it_value.tv_sec = siguiente;

    if (timerfd_settime(tfd, TFD_TIMER_ABSTIME, &its, NULL) < 0) {
        perror("timerfd_settime");
    }
}

static int crear_timer_minutero(void) {
    int tfd = timerfd_create(CLOCK_REALTIME, TFD_NONBLOCK | TFD_CLOEXEC);
    if (tfd < 0) {
        perror("timerfd_create");
        return -1;
    }
    programar_siguiente_minuto(tfd);
    return tfd;
}

/* -------------------------
 *  Implementación: PulseAudio
 * -------------------------*/

static void solicitar_info_sumidero_actual(struct Contexto *cx) {
    if (!cx || !cx->ctx) return;

    if (cx->estado.nombre_sumidero[0] != '\0') {
        pa_operation *op = pa_context_get_sink_info_by_name(cx->ctx, cx->estado.nombre_sumidero, cb_info_sumidero, cx);
        if (op) pa_operation_unref(op);
    } else if (cx->estado.indice_sumidero != (uint32_t) -1) {
        pa_operation *op = pa_context_get_sink_info_by_index(cx->ctx, cx->estado.indice_sumidero, cb_info_sumidero, cx);
        if (op) pa_operation_unref(op);
    }
}

static void configurar_suscripciones_pa(struct Contexto *cx) {
    pa_operation *op;

    /* Obtener información del servidor */
    op = pa_context_get_server_info(cx->ctx, cb_info_servidor, cx);
    if (op) pa_operation_unref(op);

    /* Configurar callback de suscripción */
    pa_context_set_subscribe_callback(cx->ctx, cb_suscripcion_pa, cx);

    /* Suscribirse a eventos de sink y servidor */
    op = pa_context_subscribe(cx->ctx,
                              (pa_subscription_mask_t)(PA_SUBSCRIPTION_MASK_SINK | PA_SUBSCRIPTION_MASK_SERVER),
                              NULL, NULL);
    if (op) pa_operation_unref(op);
}

static void cb_info_sumidero(pa_context *c, const pa_sink_info *info, int eol, void *userdata) {
    (void)c;
    if (eol > 0 || !info) return;

    struct Contexto *cx = (struct Contexto*)userdata;
    pthread_mutex_lock(&cx->candado);
    cx->estado.indice_sumidero = info->index;
    cx->estado.volumen_porcentaje = volumen_a_porcentaje(&info->volume);
    cx->estado.mute = info->mute;
    pthread_mutex_unlock(&cx->candado);

    notificar_evento(cx);
}

static void cb_info_servidor(pa_context *c, const pa_server_info *info, void *userdata) {
    (void)c;
    struct Contexto *cx = (struct Contexto*)userdata;

    pthread_mutex_lock(&cx->candado);
    if (info && info->default_sink_name) {
        strncpy(cx->estado.nombre_sumidero, info->default_sink_name, sizeof(cx->estado.nombre_sumidero) -1);
        cx->estado.nombre_sumidero[sizeof(cx->estado.nombre_sumidero) -1] = '\0';
    }
    pthread_mutex_unlock(&cx->candado);

    solicitar_info_sumidero_actual(cx);
}

static void cb_suscripcion_pa(pa_context *c, pa_subscription_event_type_t tipo, uint32_t idx, void *userdata) {
    (void)c;
    struct Contexto *cx = (struct Contexto*)userdata;
    pa_subscription_event_type_t fac = tipo & PA_SUBSCRIPTION_EVENT_FACILITY_MASK;

    if (fac == PA_SUBSCRIPTION_EVENT_SINK) {
        (void)idx;
        solicitar_info_sumidero_actual(cx);
    } else if (fac == PA_SUBSCRIPTION_EVENT_SERVER) {
        pa_operation *op = pa_context_get_server_info(cx->ctx, cb_info_servidor, cx);
        if (op) pa_operation_unref(op);
    }
}

static void cb_estado_pa(pa_context *c, void *userdata) {
    struct Contexto *cx = (struct Contexto*)userdata;
    pa_context_state_t st = pa_context_get_state(c);

    if (st == PA_CONTEXT_READY) {
        configurar_suscripciones_pa(cx);

        pthread_mutex_lock(&cx->candado);
        cx->estado.listo = true;
        pthread_mutex_unlock(&cx->candado);

        notificar_evento(cx);
    }
}

static int inicializar_pulseaudio(struct Contexto *cx) {
    cx->ml = pa_threaded_mainloop_new();
    if (!cx->ml) {
        fprintf(stderr, "Error: no se pudo crear pa_threaded_mainloop\n");
        return -1;
    }
    cx->api = pa_threaded_mainloop_get_api(cx->ml);

    cx->ctx = pa_context_new(cx->api, "barra_i3_volumen");
    if (!cx->ctx) {
        fprintf(stderr, "Error: no se pudo crear pa_context\n");
        return -1;
    }

    pa_context_set_state_callback(cx->ctx, cb_estado_pa, cx);

    if (pa_context_connect(cx->ctx, NULL, PA_CONTEXT_NOFLAGS, NULL) < 0) {
        fprintf(stderr, "Error: pa_context_connect: %s\n", pa_strerror(pa_context_errno(cx->ctx)));
        return -1;
    }

    if (pa_threaded_mainloop_start(cx->ml) < 0) {
        fprintf(stderr, "Error: pa_threaded_mainloop_start\n");
        return -1;
    }

    return 0;
}

/* -------------------------
 *  Implementación: Sway/i3 IPC
 * -------------------------*/

static int enviar_ipc(int fd, uint32_t type, const char *payload) {
    uint32_t len = payload ? (uint32_t)strlen(payload) : 0;
    unsigned char header[MAGIC_LEN + 4 + 4];

    memcpy(header, MAGIC, MAGIC_LEN);
    /* len y type little-endian */
    header[MAGIC_LEN + 0] = (unsigned char)(len & 0xff);
    header[MAGIC_LEN + 1] = (unsigned char)((len >> 8) & 0xff);
    header[MAGIC_LEN + 2] = (unsigned char)((len >> 16) & 0xff);
    header[MAGIC_LEN + 3] = (unsigned char)((len >> 24) & 0xff);
    header[MAGIC_LEN + 4] = (unsigned char)(type & 0xff);
    header[MAGIC_LEN + 5] = (unsigned char)((type >> 8) & 0xff);
    header[MAGIC_LEN + 6] = (unsigned char)((type >> 16) & 0xff);
    header[MAGIC_LEN + 7] = (unsigned char)((type >> 24) & 0xff);

    if (escribir_exacto(fd, header, sizeof(header)) != (ssize_t)sizeof(header)) return -1;
    if (len > 0) {
        if (escribir_exacto(fd, payload, len) != (ssize_t)len) return -1;
    }
    return 0;
}

static int leer_ipc(int fd, uint32_t *type_out, char **out_buf, uint32_t *out_len) {
    /* === VALIDACIÓN DE PARÁMETROS === */
    if (fd < 0) {
        fprintf(stderr, "Error: descriptor de archivo inválido\n");
        return -1;
    }
    if (!type_out || !out_buf) {
        fprintf(stderr, "Error: parámetros de salida nulos\n");
        return -1;
    }

    /* Inicializar valores de salida para evitar basura en caso de error */
    *type_out = 0;
    *out_buf = NULL;
    if (out_len) *out_len = 0;

    /* === LEER CABECERA IPC === */
    unsigned char header[MAGIC_LEN + 4 + 4];
    ssize_t r = leer_exacto(fd, header, sizeof(header));

    if (r == 0) {
        /* EOF - socket cerrado limpiamente */
        return 1;
    }

    if (r != (ssize_t)sizeof(header)) {
        fprintf(stderr, "Error: cabecera IPC incompleta (recibidos %zd de %zu bytes)\n",
                r, sizeof(header));
        return -1;
    }

    /* === VALIDAR MAGIC NUMBER === */
    if (memcmp(header, MAGIC, MAGIC_LEN) != 0) {
        fprintf(stderr, "Error: magic number IPC inválido\n");
        return -1;
    }

    /* === EXTRAER LONGITUD Y TIPO (little-endian) === */
    uint32_t len = (uint32_t)header[MAGIC_LEN + 0]
                   | ((uint32_t)header[MAGIC_LEN + 1] << 8)
                   | ((uint32_t)header[MAGIC_LEN + 2] << 16)
                   | ((uint32_t)header[MAGIC_LEN + 3] << 24);

    uint32_t type = (uint32_t)header[MAGIC_LEN + 4]
                    | ((uint32_t)header[MAGIC_LEN + 5] << 8)
                    | ((uint32_t)header[MAGIC_LEN + 6] << 16)
                    | ((uint32_t)header[MAGIC_LEN + 7] << 24);

    /* === VALIDACIONES DE SEGURIDAD CRÍTICAS === */
    if (len > TAMAÑO_MAX_MENSAJE_IPC) {
        fprintf(stderr, "Error crítico: mensaje IPC demasiado grande (%u bytes, máximo %d)\n",
                len, TAMAÑO_MAX_MENSAJE_IPC);
        return -1;
    }

    /* Validar que no hay integer overflow al hacer len + 1 */
    if (len == UINT32_MAX) {
        fprintf(stderr, "Error: longitud de mensaje causa overflow\n");
        return -1;
    }

    /* === ASIGNAR MEMORIA DE FORMA SEGURA === */
    char *buf;

    if (len == 0) {
        /* Mensaje vacío - asignar buffer mínimo */
        buf = malloc(1);
        if (!buf) {
            fprintf(stderr, "Error: no se pudo asignar memoria para mensaje vacío\n");
            return -1;
        }
        buf[0] = '\0';
    } else {
        /* Mensaje con contenido */
        buf = malloc(len + 1);
        if (!buf) {
            fprintf(stderr, "Error: no se pudo asignar %u bytes para mensaje IPC\n", len + 1);
            return -1;
        }

        /* === LEER PAYLOAD DEL MENSAJE === */
        ssize_t r_payload = leer_exacto(fd, buf, len);
        if (r_payload != (ssize_t)len) {
            fprintf(stderr, "Error: payload IPC incompleto (recibidos %zd de %u bytes)\n",
                    r_payload, len);
            free(buf);
            return -1;
        }

        /* Asegurar terminación nula */
        buf[len] = '\0';

        /* === VALIDACIÓN BÁSICA DEL CONTENIDO === */
        /* Verificar que no hay bytes nulos en medio del mensaje (excepto al final) */
        for (uint32_t i = 0; i < len; i++) {
            if (buf[i] == '\0') {
                fprintf(stderr, "Advertencia: byte nulo encontrado en posición %u del mensaje\n", i);
                break; /* No es fatal, pero sí sospechoso */
            }
        }
    }

    /* === ASIGNAR RESULTADOS DE FORMA ATÓMICA === */
    *type_out = type;
    *out_buf = buf;
    if (out_len) *out_len = len;

    return 0; /* Éxito */
}

static int conectar_sway_ipc(const char *socket_path) {
    if (!socket_path) return -1;

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

static int suscribirse_eventos_sway(int sway_fd) {
    const char *payload = "[\"window\", \"workspace\"]";
    if (enviar_ipc(sway_fd, SUBSCRIBE, payload) != 0) {
        return -1;
    }

    /* Leer reply inicial para consumirlo */
    uint32_t rtype;
    char *reply = NULL;
    uint32_t rlen = 0;
    int rc = leer_ipc(sway_fd, &rtype, &reply, &rlen);
    if (rc == 0 && reply) {
        free(reply);
        return 0;
    }
    return -1;
}


/* Función auxiliar para crear cadenas de fallback seguras */
static char *crear_cadena_fallback(const char *mensaje_fallback) {
    if (!mensaje_fallback) {
        mensaje_fallback = "[error interno]";
    }

    char *resultado = strdup(mensaje_fallback);
    if (!resultado) {
        fprintf(stderr, "Error crítico: no se pudo asignar memoria para mensaje de fallback\n");
        /* En caso extremo, devolver una cadena estática */
        static char fallback_estatico[] = "[sin memoria]";
        return fallback_estatico;
    }
    return resultado;
}

/* Función auxiliar para validar JSON de entrada */
static bool validar_json_entrada(const char *json_str, uint32_t len) {
    if (!json_str) {
        fprintf(stderr, "Error: cadena JSON es NULL\n");
        return false;
    }

    if (len == 0) {
        fprintf(stderr, "Error: longitud JSON es cero\n");
        return false;
    }

    if (len > TAMAÑO_MAX_JSON_SWAY) {
        fprintf(stderr, "Error: JSON demasiado grande (%u bytes, máximo %d)\n",
                len, TAMAÑO_MAX_JSON_SWAY);
        return false;
    }

    /* Verificar que la cadena no esté truncada */
    if (strlen(json_str) != len) {
        fprintf(stderr, "Advertencia: longitud JSON no coincide con strlen()\n");
        /* No es fatal, pero sí sospechoso */
    }

    /* Verificar que contenga al menos caracteres básicos de JSON */
    if (json_str[0] != '{' && json_str[0] != '[') {
        fprintf(stderr, "Error: JSON no comienza con { o [\n");
        return false;
    }

    return true;
}

/* Versión mejorada de buscar_foco_recursivo con protección contra stack overflow */
static void buscar_foco_recursivo_seguro(struct json_object *array, char **nombre_salida, int profundidad) {
    /* === VALIDACIONES DE SEGURIDAD === */
    if (!array || !nombre_salida) {
        fprintf(stderr, "Error: parámetros inválidos en buscar_foco_recursivo_seguro\n");
        return;
    }

    if (*nombre_salida) {
        return; /* Ya encontramos el foco */
    }

    /* Protección contra stack overflow */
    if (profundidad > PROFUNDIDAD_MAX_JSON) {
        fprintf(stderr, "Advertencia: profundidad JSON excesiva (%d), abortando búsqueda\n", profundidad);
        *nombre_salida = crear_cadena_fallback("[JSON demasiado profundo]");
        return;
    }

    if (!json_object_is_type(array, json_type_array)) {
        fprintf(stderr, "Advertencia: objeto JSON no es array en profundidad %d\n", profundidad);
        return;
    }

    int len = json_object_array_length(array);
    if (len < 0) {
        fprintf(stderr, "Error: longitud de array JSON inválida\n");
        return;
    }

    if (len > 10000) { /* Límite razonable para evitar DoS */
        fprintf(stderr, "Advertencia: array JSON muy grande (%d elementos), limitando a 1000\n", len);
        len = 1000;
    }

    /* === BÚSQUEDA EN EL ARRAY === */
    for (int i = 0; i < len && !*nombre_salida; i++) {
        struct json_object *item = json_object_array_get_idx(array, i);
        if (!item) {
            continue; /* Elemento nulo, seguir con el siguiente */
        }

        /* Verificar si este nodo tiene foco */
        struct json_object *focused = NULL;
        if (json_object_object_get_ex(item, "focused", &focused) &&
                json_object_is_type(focused, json_type_boolean) &&
                json_object_get_boolean(focused)) {

            /* Este nodo tiene foco - extraer información */
            struct json_object *type_obj = NULL;
            const char *tipo_nodo = NULL;

            if (json_object_object_get_ex(item, "type", &type_obj) &&
                    json_object_is_type(type_obj, json_type_string)) {
                tipo_nodo = json_object_get_string(type_obj);
            }

            if (tipo_nodo && strcmp(tipo_nodo, "workspace") == 0) {
                *nombre_salida = crear_cadena_fallback("");
                return;
            }

            /* Es una ventana real - extraer nombre */
            if (tipo_nodo && (strcmp(tipo_nodo, "con") == 0 || strcmp(tipo_nodo, "floating_con") == 0)) {
                struct json_object *name_obj = NULL;
                if (json_object_object_get_ex(item, "name", &name_obj) &&
                        json_object_is_type(name_obj, json_type_string)) {

                    const char *nombre_ventana = json_object_get_string(name_obj);
                    if (nombre_ventana && strlen(nombre_ventana) > 0) {
                        *nombre_salida = strdup(nombre_ventana);
                        if (!*nombre_salida) {
                            *nombre_salida = crear_cadena_fallback("[sin memoria para nombre]");
                        }
                    } else {
                        *nombre_salida = crear_cadena_fallback("[ventana sin nombre]");
                    }
                    return;
                }
            }

            /* Foco encontrado pero sin información útil */
            *nombre_salida = crear_cadena_fallback("[ventana desconocida]");
            return;
        }

        /* Buscar recursivamente en nodos hijos */
        struct json_object *nodes = NULL;
        if (json_object_object_get_ex(item, "nodes", &nodes) &&
                json_object_is_type(nodes, json_type_array)) {
            buscar_foco_recursivo_seguro(nodes, nombre_salida, profundidad + 1);
            if (*nombre_salida) return;
        }

        /* Buscar recursivamente en nodos flotantes */
        struct json_object *floating = NULL;
        if (json_object_object_get_ex(item, "floating_nodes", &floating) &&
                json_object_is_type(floating, json_type_array)) {
            buscar_foco_recursivo_seguro(floating, nombre_salida, profundidad + 1);
            if (*nombre_salida) return;
        }
    }
}

static char *extraer_ventana_foco_de_arbol(const char *json_str, uint32_t len) {
    /* === VALIDACIÓN DE ENTRADA === */
    if (!validar_json_entrada(json_str, len)) {
        return crear_cadena_fallback("[JSON inválido]");
    }

    /* === CREAR PARSER JSON === */
    struct json_tokener *tok = json_tokener_new();
    if (!tok) {
        fprintf(stderr, "Error: no se pudo crear tokener JSON\n");
        return crear_cadena_fallback("[error parser JSON]");
    }

    /* === PARSEAR JSON === */
    struct json_object *root = json_tokener_parse_ex(tok, json_str, (int)len);
    enum json_tokener_error error_parse = json_tokener_get_error(tok);
    json_tokener_free(tok); /* Liberar tokener inmediatamente */

    if (!root) {
        fprintf(stderr, "Error al parsear JSON: %s\n", json_tokener_error_desc(error_parse));
        return crear_cadena_fallback("[JSON malformado]");
    }

    /* === VALIDAR ESTRUCTURA RAÍZ === */
    if (!json_object_is_type(root, json_type_object)) {
        fprintf(stderr, "Error: JSON raíz no es un objeto\n");
        json_object_put(root);
        return crear_cadena_fallback("[JSON no es objeto]");
    }

    /* === BUSCAR NODOS === */
    char *resultado = NULL;
    struct json_object *nodes = NULL;

    if (json_object_object_get_ex(root, "nodes", &nodes) &&
            json_object_is_type(nodes, json_type_array)) {

        /* Buscar foco en el árbol */
        buscar_foco_recursivo_seguro(nodes, &resultado, 0);

        if (!resultado) {
            resultado = crear_cadena_fallback("[sin ventana con foco]");
        }
    } else {
        fprintf(stderr, "Advertencia: no se encontró campo 'nodes' o no es array\n");
        resultado = crear_cadena_fallback("[estructura JSON inesperada]");
    }

    /* === LIMPIEZA === */
    json_object_put(root); /* SIEMPRE liberar la raíz */

    return resultado;
}

static void actualizar_foco_desde_sway(struct Contexto *cx, int sway_fd) {
    if (!cx || sway_fd < 0) return;

    /* Enviar GET_TREE */
    if (enviar_ipc(sway_fd, GET_TREE, NULL) != 0) {
        fprintf(stderr, "Warning: fallo al enviar GET_TREE a sway\n");
        return;
    }

    /* Leer la respuesta */
    uint32_t rtype;
    char *reply = NULL;
    uint32_t rlen = 0;
    int rc = leer_ipc(sway_fd, &rtype, &reply, &rlen);
    if (rc != 0) {
        if (rc == 1) {
            fprintf(stderr, "Aviso: socket sway cerrado al pedir GET_TREE\n");
        } else {
            fprintf(stderr, "Error leyendo reply GET_TREE de sway\n");
        }
        if (reply) free(reply);
        return;
    }

    if (rtype == GET_TREE && reply) {
        char *nombre_foco = extraer_ventana_foco_de_arbol(reply, rlen);
        if (!nombre_foco) {
            nombre_foco = strdup("[sin ventana]");
            if (!nombre_foco) {
                fprintf(stderr, "Error: no se pudo asignar memoria para nombre_foco\n");
                free(reply);
                return;
            }
        }

        char nombre_truncado[TAM_TEXTO_TRUNCADO];
        truncar_texto_utf8(nombre_truncado, sizeof(nombre_truncado), nombre_foco);

        pthread_mutex_lock(&cx->candado);
        strncpy(cx->estado.foco_actual, nombre_truncado, sizeof(cx->estado.foco_actual) - 1);
        cx->estado.foco_actual[sizeof(cx->estado.foco_actual) - 1] = '\0';
        pthread_mutex_unlock(&cx->candado);

        free(nombre_foco);
        notificar_evento(cx);
    }

    free(reply);
}

/* -------------------------
 *  Implementación: JSON / i3bar
 * -------------------------*/

static const char *obtener_icono_volumen(int volumen, bool mute) {
    if (mute) {
        return "";  // Icono de mute
    } else if (volumen >= 100) {
        return ""; // Dos iconos para volumen alto
    } else if (volumen > 40) {
        return "";  // Icono de volumen alto
    } else if (volumen > 10) {
        return "";  // Icono de volumen medio
    } else {
        return "";  // Icono de volumen bajo
    }
}

static void obtener_colores_volumen(bool mute, const char **color_fondo, const char **color_texto) {
    if (mute) {
        *color_fondo = "#fb4934ff"; // Rojo para mute
        *color_texto = "#282828ff"; // Texto oscuro
    } else {
        *color_fondo = "#282828ff"; // Fondo estándar
        *color_texto = "#ebdbb2ff"; // Texto estándar
    }
}

static void crear_bloque_foco(struct json_object *array, const struct EstadoAudio *estado) {
    const char *texto_ventana_foco = estado->foco_actual;

    struct json_object *bloque = json_object_new_object();
    json_object_object_add(bloque, "name", json_object_new_string("foco"));
    json_object_object_add(bloque, "full_text", json_object_new_string(texto_ventana_foco));
    json_object_object_add(bloque, "min_width", json_object_new_int(1070));
    json_object_object_add(bloque, "align", json_object_new_string("center"));
    json_object_object_add(bloque, "separator", json_object_new_boolean(false));
    json_object_array_add(array, bloque);
}

static void crear_bloque_volumen(struct json_object *array, const struct EstadoAudio *estado) {
    char buffer_volumen[TAM_BUFFER_VOLUMEN];
    int volumen_actual = estado->volumen_porcentaje;
    const char *color_fondo, *color_texto;
    const char *icono;

    obtener_colores_volumen(estado->mute, &color_fondo, &color_texto);
    icono = obtener_icono_volumen(volumen_actual, estado->mute);

    if (estado->mute) {
        // Silenciado: icono '' + dos espacios para mantener alineación
        snprintf(buffer_volumen, sizeof(buffer_volumen), "%s  %3d%%", icono, volumen_actual);
    } else if (volumen_actual >= 0) {
        if (volumen_actual >= 100) {
            // Volumen >= 100%: formato con dos iconos ""
            snprintf(buffer_volumen, sizeof(buffer_volumen), "%s %3d%%", icono, volumen_actual);
        } else {
            // Volumen < 100%: icono + dos espacios para alineación
            snprintf(buffer_volumen, sizeof(buffer_volumen), "%s  %3d%%", icono, volumen_actual);
        }
    } else {
        // Caso de error o volumen no disponible
        snprintf(buffer_volumen, sizeof(buffer_volumen), "Volumen —");
    }

    struct json_object *bloque = json_object_new_object();
    json_object_object_add(bloque, "name", json_object_new_string("volumen"));
    json_object_object_add(bloque, "full_text", json_object_new_string(buffer_volumen));
    json_object_object_add(bloque, "separator", json_object_new_boolean(false));
    json_object_object_add(bloque, "background", json_object_new_string(color_fondo));
    json_object_object_add(bloque, "color", json_object_new_string(color_texto));
    json_object_object_add(bloque, "min_width", json_object_new_int(71));
    json_object_object_add(bloque, "align", json_object_new_string("center"));
    json_object_array_add(array, bloque);
}

static void crear_bloque_fecha(struct json_object *array) {
    char fecha[TAM_BUFFER_FECHA];
    formatear_fecha_hora(fecha, sizeof(fecha));

    struct json_object *bloque = json_object_new_object();
    json_object_object_add(bloque, "name", json_object_new_string("fecha_hora"));
    json_object_object_add(bloque, "full_text", json_object_new_string(fecha));
    json_object_object_add(bloque, "separator", json_object_new_boolean(false));
    json_object_object_add(bloque, "min_width", json_object_new_int(140));
    json_object_object_add(bloque, "align", json_object_new_string("center"));
    json_object_array_add(array, bloque);
}

static void imprimir_bloques_json(const struct EstadoAudio *estado, bool *es_primera_salida) {
    struct json_object *array = json_object_new_array();

    crear_bloque_foco(array, estado);
    crear_bloque_volumen(array, estado);
    crear_bloque_fecha(array);

    /* Emisión conforme a protocolo i3bar (coma entre arrays) */
    if (*es_primera_salida) {
        *es_primera_salida = false;
    } else {
        fputs(",\n", stdout);
    }

    fputs(json_object_to_json_string(array), stdout);
    fputc('\n', stdout);
    fflush(stdout);

    json_object_put(array);
}

/* -------------------------
 *  Implementación: Bucle principal
 * -------------------------*/

static int configurar_descriptores_poll(struct pollfd *fds, int tfd, int efd, int sway_fd) {
    memset(fds, 0, sizeof(struct pollfd) * 3);

    fds[0].fd = tfd;
    fds[0].events = POLLIN;
    fds[1].fd = efd;
    fds[1].events = POLLIN;

    int nfds = 2;
    if (sway_fd >= 0) {
        fds[2].fd = sway_fd;
        fds[2].events = POLLIN;
        nfds = 3;
    }

    return nfds;
}

static void copiar_estado_actual(struct Contexto *cx, struct EstadoAudio *copia) {
    pthread_mutex_lock(&cx->candado);
    *copia = cx->estado;
    pthread_mutex_unlock(&cx->candado);
}

static void manejar_evento_timer(int tfd, struct Contexto *cx, bool *es_primera_salida) {
    /* Consumir eventos del timer */
    uint64_t expiraciones;
    while (read(tfd, &expiraciones, sizeof(expiraciones)) > 0) {
        (void)expiraciones;
    }

    /* Reprogramar próximo minuto */
    programar_siguiente_minuto(tfd);

    /* Imprimir estado actual */
    struct EstadoAudio copia;
    copiar_estado_actual(cx, &copia);
    imprimir_bloques_json(&copia, es_primera_salida);
}

static void manejar_evento_notificacion(int efd, struct Contexto *cx, bool *es_primera_salida) {
    /* Consumir eventos de notificación */
    uint64_t cuenta;
    while (read(efd, &cuenta, sizeof(cuenta)) > 0) {
        (void)cuenta;
    }

    /* Imprimir estado actual */
    struct EstadoAudio copia;
    copiar_estado_actual(cx, &copia);
    imprimir_bloques_json(&copia, es_primera_salida);
}

static void manejar_evento_sway(int sway_fd, struct Contexto *cx, int *nfds) {
    /* Consumir el evento que llegó */
    uint32_t ev_type;
    char *ev_msg = NULL;
    uint32_t ev_len = 0;

    int rc = leer_ipc(sway_fd, &ev_type, &ev_msg, &ev_len);
    if (rc == 1) {
        /* EOF: socket cerrado por sway */
        fprintf(stderr, "Aviso: socket sway cerrado\n");
        close(sway_fd);
        *nfds = 2;
        return;
    } else if (rc != 0) {
        fprintf(stderr, "Error leyendo mensaje IPC de sway (evento)\n");
        close(sway_fd);
        *nfds = 2;
        return;
    }

    /* Liberar el mensaje del evento */
    if (ev_msg) free(ev_msg);

    /* Actualizar foco consultando el árbol completo */
    actualizar_foco_desde_sway(cx, sway_fd);
}

static void inicializar_contexto(struct Contexto *cx) {
    memset(cx, 0, sizeof(*cx));
    cx->estado.volumen_porcentaje = -1;
    cx->estado.indice_sumidero = (uint32_t) -1;
    cx->estado.nombre_sumidero[0] = '\0';
    cx->estado.foco_actual[0] = '\0';
    cx->estado.listo = false;
    cx->estado.mute = false;
    pthread_mutex_init(&cx->candado, NULL);
}

static void limpiar_recursos(struct Contexto *cx, int sway_fd, int tfd) {
    if (sway_fd >= 0) close(sway_fd);
    if (tfd >= 0) close(tfd);
    if (cx->efd_notificacion >= 0) close(cx->efd_notificacion);

    if (cx->ctx) {
        pa_context_disconnect(cx->ctx);
        pa_context_unref(cx->ctx);
    }
    if (cx->ml) {
        pa_threaded_mainloop_stop(cx->ml);
        pa_threaded_mainloop_free(cx->ml);
    }
    pthread_mutex_destroy(&cx->candado);
}

static int configurar_sway_ipc(void) {
    const char *socket_path = getenv("SWAYSOCK");
    if (!socket_path) socket_path = getenv("I3SOCK");

    if (!socket_path) {
        fprintf(stderr, "Warning: $SWAYSOCK y $I3SOCK no definidos; skip sway events\n");
        return -1;
    }

    int sway_fd = conectar_sway_ipc(socket_path);
    if (sway_fd < 0) {
        fprintf(stderr, "Warning: no se pudo conectar a socket sway/i3 en '%s'\n", socket_path);
        return -1;
    }

    if (suscribirse_eventos_sway(sway_fd) != 0) {
        fprintf(stderr, "Warning: fallo al suscribirse a eventos de sway\n");
        close(sway_fd);
        return -1;
    }

    return sway_fd;
}

static void ejecutar_bucle_principal(struct Contexto *cx, int tfd, int sway_fd) {
    struct pollfd fds[3];
    int nfds = configurar_descriptores_poll(fds, tfd, cx->efd_notificacion, sway_fd);
    bool es_primera_salida = true;

    /* Encabezado i3bar */
    printf("{\"version\":1}\n[\n");
    fflush(stdout);

    for (;;) {
        int r = poll(fds, nfds, -1);
        if (r < 0) {
            if (errno == EINTR) continue;
            perror("poll");
            break;
        }

        /* Evento de temporizador */
        if (fds[0].revents & POLLIN) {
            manejar_evento_timer(tfd, cx, &es_primera_salida);
        }

        /* Evento de notificación (PulseAudio) */
        if (fds[1].revents & POLLIN) {
            manejar_evento_notificacion(cx->efd_notificacion, cx, &es_primera_salida);
        }

        /* Evento de sway IPC */
        if (nfds == 3 && (fds[2].revents & POLLIN)) {
            manejar_evento_sway(sway_fd, cx, &nfds);
            /* Actualizar nfds en el array de fds si el socket se cerró */
            if (nfds == 2) {
                sway_fd = -1;
            }
        }
    }
}

/* -------------------------
 *  Función principal
 * -------------------------*/

int main(void) {
    setlocale(LC_ALL, "");
    signal(SIGPIPE, SIG_IGN);

    /* Inicialización del contexto */
    struct Contexto cx;
    inicializar_contexto(&cx);

    /* Crear eventfd para notificaciones */
    cx.efd_notificacion = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (cx.efd_notificacion < 0) {
        perror("eventfd");
        return 1;
    }

    /* Inicializar PulseAudio */
    if (inicializar_pulseaudio(&cx) < 0) {
        fprintf(stderr, "No se pudo inicializar PulseAudio\n");
        close(cx.efd_notificacion);
        return 1;
    }

    /* Crear timer minutero */
    int tfd = crear_timer_minutero();
    if (tfd < 0) {
        limpiar_recursos(&cx, -1, -1);
        return 1;
    }

    /* Configurar conexión con sway/i3 */
    int sway_fd = configurar_sway_ipc();

    /* Actualizar foco inicial si hay conexión con sway */
    if (sway_fd >= 0) {
        actualizar_foco_desde_sway(&cx, sway_fd);
    }

    /* Ejecutar bucle principal */
    ejecutar_bucle_principal(&cx, tfd, sway_fd);

    /* Limpieza de recursos */
    limpiar_recursos(&cx, sway_fd, tfd);

    return 0;
}
