#!/bin/bash

# INSTRUCTIONS
# ----------------------------------------------------
# Usage:
# ./crunchyroll-stream-merger.sh [dub,vf,419-dub,es-dub] [en-US,fr-FR,es-419,es-ES]
# [dub,vf,419-dub,es-dub] : versions
# [english,french,spanish-419,spanish] : subtitles
# ----------------------------------------------------

# $1 should be for the _versions *dub,vf*
# $2 should be for _subs languages *english,french*
[ -z "$@" ] && echo 'It lacks arguments' && exit 1
declare -A sub_langs=( [en-US]="English (US)" [fr-FR]="French" [es-419]="Spanish (Latin America)" [es-ES]="Spanish (European)" )
declare -A audio_titles=( [dub]="English (US)" [vf]="French" [419-dub]="Spanish (Latin America)" [es-dub]="Spanish (European)" )
declare -A audio_langs=( [dub]=en-US [vf]=fr-FR [419-dub]=es-419 [es-dub]=es-ES )
declare -A dubs_langs=( [dub]=en-US [vf]=fr-FR [419-dub]=es-419 [es-dub]=es-ES )
_versions=(${1//','/' '})
_subs=(${2//','/' '})

    # Merges the given mp4 file into an MKV file with audio and subtitle streams.
    #
    # Parameters:
    #   - $1: The path to the mp4 file.
    #
    # Returns:
    #   None.
    #
    # The function performs the following steps:
    #   1. Checks if the episode has chapters setup by checking the existence of a metadata file.
    #   2. Fetches the video and original audio streams.
    #   3. Fetches subtitles based on the values in the `_subs` array.
    #   4. Fetches audio and subtitle streams for each version specified in the `_versions` array.
    #   5. Builds the ffmpeg command to merge the streams into an MKV file.
    #   6. Appends the ffmpeg command to a temporary file.
merge_to_mkv(){
    # $1 is the mp4 file
    local metafile input_video input_audios input_subtitles maps map_index=1 metadata_audio meta_audio_index=1 metadata_sub meta_sub_index=0

    # Check if episode has chapters setup
    [ -e "${1%.mp4}.meta.txt" ] && metafile='-i "'${1%.mp4}'.meta.txt" -map_metadata 1 '

    # Fetch Video and original audio
    input_video='-i "'$1'" '
    maps='-map 0 '
    metadata_audio='-metadata:s:a:0 language=ja-JP -metadata:s:a:0 title="Japanese" '
    # Fetch subtitles
    for sub in ${_subs[@]}; do

        input_subtitles+='-i "'${1%.mp4}'.'$sub'.ass" '
        maps+="-map $map_index "
        (( map_index++ ))

        metadata_sub+="-metadata:s:s:$meta_sub_index language=${sub} -metadata:s:s:$meta_sub_index title=\"${sub_langs[$sub]}\" "
        (( meta_sub_index++ ))
    done
    # Fetch versions audio and sub if exist
    for version in ${_versions[@]}; do

        [ -e "${1%.mp4}.${version}.aac" ] && audio_ext=.aac || audio_ext=.m4a
        input_audios+='-i "'${1%.mp4}'.'${version}${audio_ext}'" '
        maps+="-map $map_index "
        (( map_index++ ))

        metadata_audio+="-metadata:s:a:${meta_audio_index} language=${audio_langs[$version]} -metadata:s:a:${meta_audio_index} title=\"${audio_titles[$version]}\" "
        (( meta_audio_index++ ))

        # Add subtitle for dubs
        if [ -e "${1%.mp4}.${version}.${dubs_langs[${version}]}.ass" ]; then

            input_subtitles+='-i "'${1%.mp4}'.'${version}'.'${dubs_langs[$version]}'.ass" '

            maps+="-map $map_index "
            (( map_index++ ))

            metadata_sub+="-metadata:s:s:$meta_sub_index language=${audio_langs[$version]} -metadata:s:s:$meta_sub_index title=\"${audio_titles[$version]} (CC)\" "
            (( meta_sub_index++ ))
        fi
    done

    echo ffmpeg ${input_video}${input_audios}${input_subtitles}${metafile}${maps}${metadata_audio}${metadata_sub}-c copy '"'${1%.mp4}'.mkv"' >> .temp.txt
}

echo '' > .temp.txt

for episode in *.mp4; do
    merge_to_mkv "$episode"
done

bash .temp.txt
rm .temp.txt
