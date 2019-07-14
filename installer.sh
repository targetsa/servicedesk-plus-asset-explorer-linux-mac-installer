#! /usr/bin/env bash

# Copyright (c) TARGET S.A.

set -f

VERSION=1.0
URL=${URL:-"http://127.0.0.1"} # TODO Podria "inferir" URL de propio servidor web
AESCAN_SCRIPT="ae_scan_%s.sh"
AESCAN_SCRIPT_URL="$URL/$AESCAN_SCRIPT"

install() {
    local os=$(uname -s)
    local command="curl -sS $AESCAN_SCRIPT_URL"
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

    cron="${MINUTES:-"*"} ${HOUR:-"0,6,12,18"} ${DAY:-"*"} ${MONTH:-"*"} ${DAY_OF_WEEK:-"*"}"

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
        echo "(v.$VERSION)"

        command=$(printf "$command" "linux")
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
        echo "(v.$VERSION)"

        command=$(printf "$command" "mac")
    fi

    printf "\n"
    printf "1/2 Ejecutando ae_scan...\r"

    # Quizas algo "hacky", no obstante, fue la unica manera eficiente que logre
    # evaluar `curl` cuando 1) $URL y 2) ae_scan_$OS.sh.

    ($command &>/dev/null) && result=$($command | bash 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        printf "1/2 Ejecutando ae_scan...(\033[0;31mERR\033[m)\n"
        printf "\033[0;31merror\033[m No se puede enviar la información de su sistema al servidor ServiceDesk Plus \033[4;30m$AESCAN_SCRIPT_URL\033[m.\n"

        # Output devuelto por ejecucion ae_scan_$OS.sh.

        if [[ -n $result ]]; then
            printf "\n"
            printf "\033[0;31m$result\033[m\n"
            printf "\n"
        fi

        printf "¿Te gustaría continuar con la instalación de todos modos? (si)\n"

        # Asegura leer stdin (Ver https://stackoverflow.com/a/49802113).

        read </dev/tty -ep "> " yn

        yn=${yn:-"s"}

        # Responder "no" finaliza la instalacion. Por defecto, "si" continua
        # con la instalacion.

        case $yn in
            n|no|No|NO)
            exit 1
            ;;
        esac

        printf "\n"
    else
        printf "1/2 Ejecutando ae_scan...(\033[0;32mOK\033[m)\n"
    fi

    printf "2/2 Instalando ae_scan...\r"

    sleep 5

    # Anexa crontab.

    (crontab -l 2>/dev/null; echo "$cron cd $TMPDIR && $command | bash &>/dev/null") | crontab -

    if [[ $? -ne 0 ]]; then
        printf "2/2 Instalando ae_scan...(\033[0;31mERR\033[m)\n"
        exit 1
    fi

    printf "2/2 Instalando ae_scan...(\033[0;32mOK\033[m)\n"
    exit 0
}

install $*
