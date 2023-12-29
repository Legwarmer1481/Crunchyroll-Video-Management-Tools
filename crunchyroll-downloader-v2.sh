#!/bin/bash

# --------------------------------------------------
# DESCRIPTION
# --------------------------------------------------
#
# Using crunchy-cli, it downloads series from Crunchyroll
# with the naming convention by Kodi Media Center.
#
# --------------------------------------------------
# INSTRUCTION
# --------------------------------------------------
#
# Usage: ./crunchyroll-downloader-v2.sh ETP_RT SERIES_URL [Options...]
# -s Subtitle filtering
#    Available languages: ar-ME, ar-SA, de-DE, en-IN, en-US, es-419, es-ES, es-LA, fr-FR, hi-IN, it-IT, ja-JP, pt-BR, pt-PT, ru-RU, zh-CN
#    Default: en-US fr-FR
# -a Audio filtering
#    Available languages: ar-ME, ar-SA, de-DE, en-IN, en-US, es-419, es-ES, es-LA, fr-FR, hi-IN, it-IT, ja-JP, pt-BR, pt-PT, ru-RU, zh-CN
#    Default: ja-JP en-US fr-FR
# -t Title
#    If it is specified it will create a folder and operate inside, otherwise it assumes it is already in the show folder
# -m Streams merging
#    In case the video length differ from different dubs, you can set to auto or video to download additional video streams for every versions
#    Refer to the link for more details: https://github.com/crunchy-labs/crunchy-cli/blob/master/README.md
#    Available options: auto, video, audio
#    The default here is 'audio'
#
# --------------------------------------------------
#
# Dependencies
# - crunchy-cli https://github.com/crunchy-labs/crunchy-cli
# - pwd
# - mkdir
#
# --------------------------------------------------

# Prepare Default Data
TITLE="$(pwd | sed 's/\/.*\/\(.*\)/\1/')"
[ "$1" = '' ] && echo "The cookie etp-rt is needed" && exit || ETP_RT=$1
[ "$2" = '' ] && echo "The series URL is needed" && exit || SERIES_URL=$2
NEW_DIR=false
SUBTITLES=(en-US fr-FR es-419 es-ES)
AUDIOS=(ja-JP en-US fr-FR es-419 es-ES)
AVAILABLE_LANGUAGES=(ar-ME ar-SA de-DE en-IN en-US es-419 es-ES es-LA fr-FR hi-IN it-IT ja-JP pt-BR pt-PT ru-RU zh-CN)
MERGE=audio
shift 2

# Processing Options
get_args(){

    while getopts "s:a:t:m:" opt; do
        case $opt in
        s)
            SUBTITLES=(${OPTARG//,/" "})
            ;;
        a)
            AUDIOS=(${OPTARG//,/" "})
            ;;
        t)
            TITLE="$OPTARG"
            NEW_DIR=true
            [ ! -d "$TITLE" ] && mkdir "$TITLE"
            cd "$TITLE"
            ;;
        m)
            MERGE=$OPTARG
            ;;
        *)
            echo "There are some invalid options"
            exit 1
            ;;
        esac
    done
}

# Validates Arguments Inputs
validate_inputs(){

    # Validate etp-rt
    [[ ! $ETP_RT =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] && echo "The cookie etp-rt is incorrect" && exit

    # Validate Series URL
    [[ ! $SERIES_URL =~ ^(http|https)://(www)?\.crunchyroll\.com/series/[A-Z0-9]{9}(/[a-z0-9-]*)?(\[.*\])?$ ]] && echo "The URL is incorrect" && exit

    # Validate subtitle languages
    for subtitle in ${SUBTITLES[@]}; do
        
        local found=false

        for language in "${AVAILABLE_LANGUAGES[@]}"; do
            if [ $subtitle = $language ]; then
                found=true
                break
            fi
        done

        if [ $found = false ]; then
            echo "$subtitle is not an available language"
            exit
        fi

    done

    # Validate audio languages
    for audio in ${AUDIOS[@]}; do
        
        local found=false

        for language in "${AVAILABLE_LANGUAGES[@]}"; do
            if [ $audio = $language ]; then
                found=true
                break
            fi
        done

        if [ $found = false ]; then
            echo "$audio is not an available language"
            exit
        fi

    done
}

# Download Crunchyroll series into an mkv file
download(){
    
    local subs audios

    # Specify audio languages
    for audio in "${AUDIOS[@]}"; do
        audios="${audios} -a ${audio}"
    done

    # Specify subtitle languages
    for sub in "${SUBTITLES[@]}"; do
        subs="${subs} -s ${sub}"
    done

    if [ $NEW_DIR = false ]; then
        ./crunchy-cli archive${audios}${subs} -m $MERGE -o "Season {season_number}/$TITLE S{season_number}E{episode_number}.mkv" $SERIES_URL
    else
        ../crunchy-cli archive${audios}${subs} -m $MERGE -o "Season {season_number}/$TITLE S{season_number}E{episode_number}.mkv" $SERIES_URL
    fi

}

# Execute functions

get_args "$@"
validate_inputs
# Login to Crunchyroll
[ $NEW_DIR = false ] && ./crunchy-cli --etp-rt "$ETP_RT" login || ../crunchy-cli --etp-rt "$ETP_RT" login
download