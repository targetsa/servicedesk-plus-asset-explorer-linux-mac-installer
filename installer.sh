#! /usr/bin/env bash

# Copyright (c) TARGET S.A.

set -f

INSTALLER_VERSION=1.2.0


AESCAN="ae_scan_%s.sh"
AESCAN_HOME="$HOME/.local"
AESCAN_SCRIPT_REMOTE_PATH="${AESCAN_CDN:-"http://127.0.0.1:8082"}/$AESCAN"
AESCAN_SCRIPT_EXECUTION_PATH="$AESCAN_HOME/$AESCAN"

install() {
    local os=$(uname -s)
    local cron
    local should_continue=1

    # Instalador intenta seleccionar el mejor Sistema Opertivo, sin embargo,
    # puede fijar *explicitamente* $os.

    # eg. `installer.sh (linux|Linux)`
    # eg. `installer.sh (darwin|Darwin|osx|mac|macOS)`

    case "$1" in
        linux|Linux)
            os=Linux
            shift
            ;;
        darwin|Darwin|osx|mac|macOS)
            os=Darwin
            shift
            ;;
    esac

    # Opcional, puede ajustar horario que debe ejecutar ae_scan. Por defecto,
    # cada 6 horas a partir 00:00 h. Formato de horario lleva el formato "crontab",
    # aqui un recurso de mucha ayuda https://crontab.guru.

    # eg. `installer.sh -m "*/5"`; cada 5 minutos entre 0,6,12,18 horas
    # eg. `installer.sh` -m "*/5" -h "*"; cada 5 minutos
    # eg. `installer.sh` -D "1-5"; lunes a sabado a las 0,6,12,18 horas

    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
        case "$1" in
            -m|--minutes)
                shift; MINUTES="$1"
                ;;
            -h|--hour)
                shift; HOUR="$1"
                ;;
            -d|--day)
                shift; DAY="$1"
                ;;
            -M|--month)
                shift; MONTH="$1"
                ;;
            -D|--dayofweek)
                shift; DAY_OF_WEEK="$1"
                ;;
        esac

        shift
    done

    cron="${MINUTES:-"0"} ${HOUR:-"0,6,12,18"} ${DAY:-"*"} ${MONTH:-"*"} ${DAY_OF_WEEK:-"*"}"

    if [[ "$os" == Linux ]]; then
cat <<"EOC"
            .-"""-.
           '       \
          |,.  ,-.  |
          |()L( ()| |           ServiceDesk Plus AssetExplorer Linux
          |,'  `".| |
          |.___.',| `           Copyright (c) 2019
         .j `--"' `  `.         TARGET S.A.
        / '        '   \
       / /          `   `.
      / /            `    .
     / /              l   |
    . ,               |   |
    ,"`.             .|   |
 _.'   ``.          | `..-'l
|       `.`,        |      `.
|         `.    __.j         )
|__        |--""___|      ,-'
   `"--...,+""""   `._,.-' mh
EOC

        echo
        echo "(v.$INSTALLER_VERSION)"

        AESCAN_SCRIPT_REMOTE_PATH=$(printf "$AESCAN_SCRIPT_REMOTE_PATH" "linux")
        AESCAN_SCRIPT_EXECUTION_PATH=$(printf "$AESCAN_SCRIPT_EXECUTION_PATH" "linux")        
    elif [[ "$os" == Darwin ]]; then
cat <<"EOC"
                        .8
                      .888
                    .8888'
                   .8888'
                   888'
                   8'
      .88888888888. .88888888888.
   .8888888888888888888888888888888.
 .8888888888888888888888888888888888.
.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'            ServiceDesk Plus AssetExplorer macOS
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:             Copyright (c) 2019
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:             TARGET S.A.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
`%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
 `00000000000000000000000000000000000'
  `000000000000000000000000000000000'
   `0000000000000000000000000000000'
     `###########################'
jgs    `#######################'
         `#########''########'
           `""""""'  `"""""'
EOC

        echo
        echo "(v.$INSTALLER_VERSION)"

        AESCAN_SCRIPT_REMOTE_PATH=$(printf "$AESCAN_SCRIPT_REMOTE_PATH" "mac")
        AESCAN_SCRIPT_EXECUTION_PATH=$(printf "$AESCAN_SCRIPT_EXECUTION_PATH" "mac")
    fi

    download
    run

    printf "\n\n"
    printf "¿Le gustaría configurar una tarea programada que escanee el activo automáticamente?"
    printf "\n"

    read </dev/tty -ep "(por defecto, 'si')> " yn

    yn=${yn:-"s"}

    # Responder "no" finaliza la instalacion. Por defecto, "si" continua
    # con la instalacion.

    case $yn in
        n|no|No|NO)
        exit 0
        ;;
    esac

    setup

    printf "\n"
}

download() {
    printf "\n"
    printf "\xE2\xA6\xBF Descargando [$AESCAN_SCRIPT_REMOTE_PATH] (...)"

    { mkdir $AESCAN_HOME; cd $AESCAN_HOME; curl -ksS $AESCAN_SCRIPT_REMOTE_PATH -O; } &>/dev/null
    sleep 1

    if [[ $? -ne 0 ]]; then
        printf "\33[2K\r\xE2\xA6\xBF Descargando [$AESCAN_SCRIPT_REMOTE_PATH] (\033[0;31mERROR\033[m)"
    else
        printf "\33[2K\r\xE2\xA6\xBF Descargando [$AESCAN_SCRIPT_REMOTE_PATH] (\033[0;32mOK\033[m)"
    fi
}

run() {
    printf "\n"
    printf "\xE2\xA6\xBF Ejecutando [$AESCAN_SCRIPT_EXECUTION_PATH] (...)"

    result=$(cat $AESCAN_SCRIPT_EXECUTION_PATH | bash 2>&-)

    if [[ $? -ne 0 ]]; then
        printf "\33[2K\r\xE2\xA6\xBF Ejecutando [$AESCAN_SCRIPT_EXECUTION_PATH] (\033[0;31mERROR\033[m)"
    else
        printf "\33[2K\r\xE2\xA6\xBF Ejecutando [$AESCAN_SCRIPT_EXECUTION_PATH] (\033[0;32mOK\033[m)"
        printf "\n\n"
        printf "$result"
    fi
}

setup() {
    schedule_command=$(printf "$cron cat \"$AESCAN_SCRIPT_EXECUTION_PATH\" | bash -l &>/dev/null")

    printf "\n"
    printf "\xE2\xA6\xBF Configurando Cron [$schedule_command] (...)"

    (crontab -l 2>/dev/null; echo "$schedule_command") | crontab -

    if [[ $? -ne 0 ]]; then
        printf "\33[2K\r\xE2\xA6\xBF Configurando Cron [$schedule_command] (\033[0;33mPASS\033[m)"
    else
        printf "\33[2K\r\xE2\xA6\xBF Configurando Cron [$schedule_command] (\033[0;32mOK\033[m)"
    fi
}

install $*
