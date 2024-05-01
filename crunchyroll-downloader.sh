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
# Usage: ./crunchyroll-downloader-v2.sh EMAIL PASSWORD SERIES_URL [Options...]
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
[ "$1" = '' ] && echo "Your email used on crunchyroll is needed" && exit || EMAIL=$1
[ "$2" = '' ] && echo "Your password used on crunchyroll is needed" && exit || PASSWORD=$2
[ "$3" = '' ] && echo "The series URL is needed" && exit || SERIES_URL=$3
NEW_DIR=false
SUBTITLES=(en-US fr-FR es-419 es-ES)
AUDIOS=(ja-JP en-US fr-FR es-419 es-ES)
declare -A dubs_langs=( [en-US]=dub [fr-FR]=vf [es-419]=419-dub [es-ES]=es-dub )
AVAILABLE_LANGUAGES=(ar-ME ar-SA de-DE en-IN en-US es-419 es-ES es-LA fr-FR hi-IN it-IT ja-JP pt-BR pt-PT ru-RU zh-CN)
MERGE=audio
shift 3

# This function processes command line arguments and sets variables accordingly.
#
# It uses the `getopts` command to parse the command line arguments.
# The available options are:
# - `s`: sets the SUBTITLES variable to an array of subtitles selected by the user.
# - `a`: sets the AUDIOS variable to an array of audios selected by the user.
# - `t`: sets the TITLE variable to the name of the directory to be created or the name of the existing directory to be used.
# - `m`: sets the MERGE variable to the type of merge selected by the user.
#
# If an invalid option is encountered, an error message is displayed and the script exits with a status of 1.
#
# The function also checks if the directory specified by the TITLE variable does not exist and creates it if necessary.
get_args(){

    while getopts "s:a:t:m:" opt; do
        case $opt in
        s)
            SUBTITLES=(${OPTARG//,/" "})
            echo "Selected subtitles: ${SUBTITLES[@]}"
            ;;
        a)
            AUDIOS=(${OPTARG//,/" "})
            echo "Selected audio: ${AUDIOS[@]}"
            ;;
        t)
            TITLE="$OPTARG"
            NEW_DIR=true
            [ ! -d "$TITLE" ] && mkdir "$TITLE"
            echo "Folder $TITLE made!"
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


    # Validates the inputs for email, series URL, subtitle languages, and audio languages.
    #
    # No parameters.
    # No return value.
validate_inputs(){

    # Validate email
    [[ ! $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && echo "The email is incorrect" && exit

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


    # Downloads the series from Crunchyroll into an mkv file.
    #
    # This function uses the crunchy-cli tool to download the series and organize the directories by seasons.
    # The function takes no parameters.
    #
    # Returns:
    #   None
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

    crunchy-cli archive${audios}${subs} -m $MERGE --include-chapters -o "{series_name} ({release_year})/Season {season_number}/{series_name} ({release_year}) S{season_number}E{episode_number}.mkv" --output-specials "{series_name} ({release_year})/Season 00/{series_name} ({release_year}) S{season_number}E{episode_number}.mkv" $SERIES_URL
    
    for audio in "${AUDIOS[@]}"; do
        crunchy-cli download -a ${audio} -o "{series_name} ({release_year})/${dubs_lang[$audio]}/Season {season_number}/{series_name} ({release_year}) S{season_number}E{episode_number}.mkv" --output-specials "{series_name} ({release_year})/${dubs_lang[$audio]}/Season 00/{series_name} ({release_year}) S{season_number}E{episode_number}.mkv" $SERIES_URL
    done

}

# Execute functions

get_args "$@"
validate_inputs
# Login to Crunchyroll
[ $NEW_DIR = false ] && crunchy-cli login --credentials ${EMAIL}':'${PASSWORD}
download