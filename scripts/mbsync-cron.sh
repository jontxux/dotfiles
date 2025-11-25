#!/bin/bash

# Todo se ejecuta en un subshell para aislamiento
(
    # Configurar entorno solo para este subshell
    export HOME="/home/jb"
    export USER="jb"
    export GNUPGHOME="/home/jb/.autosync/gpg"
    export PASSWORD_STORE_DIR="/home/jb/.autosync/password-store"
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
    export LANG="es_ES.UTF-8"

    # Ejecutar sincronización
    echo "[INICIO] $(date +"%F %T")" >> /home/jb/mbsync-cron.log
    /usr/bin/mbsync -c "/home/jb/.mbsyncrc" gmail >> /home/jb/mbsync-cron.log 2>&1
    echo "[FIN]    $(date +"%F %T")" >> /home/jb/mbsync-cron.log
)
