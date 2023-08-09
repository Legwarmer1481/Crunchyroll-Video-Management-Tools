""" --------------------------------------------------
DESCRIPTION
--------------------------------------------------

Using crunchy-cli, it downloads series from Crunchyroll
with the naming convention by Kodi Media Center.

--------------------------------------------------
INSTRUCTION
--------------------------------------------------

Usage: ./crunchyroll-downloader-v2.sh [Options...] ETP_RT SERIES_URL
-s Subtitle filtering
   Available languages: ar-ME, ar-SA, de-DE, en-IN, en-US, es-419, es-ES, es-LA, fr-FR, hi-IN, it-IT, ja-JP, pt-BR, pt-PT, ru-RU, zh-CN
   Default: en-US fr-FR
-a Audio filtering
   Available languages: ar-ME, ar-SA, de-DE, en-IN, en-US, es-419, es-ES, es-LA, fr-FR, hi-IN, it-IT, ja-JP, pt-BR, pt-PT, ru-RU, zh-CN
   Default: ja-JP en-US fr-FR
-t Title
   If it is specified it will create a folder and operate inside, otherwise it assumes it is already in the show folder
-m Streams merging
   In case the video length differ from different dubs, you can set to auto or video to download additional video streams for every versions
   Refer to the link for more details: https://github.com/crunchy-labs/crunchy-cli/blob/master/README.md
   Available options: auto, video, audio
   The default here is 'audio'

--------------------------------------------------

Dependencies
- crunchy-cli https://github.com/crunchy-labs/crunchy-cli

-------------------------------------------------- """

import subprocess
import re
import os
import argparse

TITLE = os.getcwd().split("/")[-1]
ETP_RT = ""
SERIES_URL = ""
NEW_DIR = False
SUBTITLES = ["en-US", "fr-FR"]
AUDIOS = ["ja-JP", "en-US", "fr-FR"]
AVAILABLE_LANGUAGES = [
    "ar-ME", "ar-SA", "de-DE", "en-IN", "en-US", "es-419", "es-ES",
    "es-LA", "fr-FR", "hi-IN", "it-IT", "ja-JP", "pt-BR", "pt-PT",
    "ru-RU", "zh-CN"
]
MERGE = "audio"

def get_args():
    global ETP_RT, SERIES_URL, SUBTITLES, AUDIOS, TITLE, MERGE, NEW_DIR
    parser = argparse.ArgumentParser()
    parser.add_argument("ETP_RT", help="The value of the ETP_RT cookie")
    parser.add_argument("SERIES_URL", help="The series URL")
    parser.add_argument("-s", "--subtitle", nargs="+", default=["en-US", "fr-FR"], help="Subtitle filtering")
    parser.add_argument("-a", "--audio", nargs="+", default=["ja-JP", "en-US", "fr-FR"], help="Audio filtering")
    parser.add_argument("-t", "--title", help="Title")
    parser.add_argument("-m", "--merge", choices=["auto", "video", "audio"], default="audio", help="Streams merging")
    args = parser.parse_args()
    ETP_RT = args.ETP_RT
    SERIES_URL = args.SERIES_URL
    SUBTITLES = args.subtitle
    AUDIOS = args.audio
    TITLE = args.title if args.title else TITLE
    MERGE = args.merge
    NEW_DIR = bool(args.title)

def validate_inputs():
    global ETP_RT, SERIES_URL, SUBTITLES, AUDIOS, AVAILABLE_LANGUAGES
    if not re.match(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', ETP_RT):
        print("The cookie ETP-RT is incorrect")
        exit(1)
    if not re.match(r'^(http|https)://(www)?\.crunchyroll\.com/series/[A-Z0-9]{9}(/[a-z0-9-]*)?(\[.*\])?$', SERIES_URL):
        print("The URL is incorrect")
        exit(1)
    for subtitle in SUBTITLES:
        if subtitle not in AVAILABLE_LANGUAGES:
            print(f"{subtitle} is not an available language")
            exit(1)
    for audio in AUDIOS:
        if audio not in AVAILABLE_LANGUAGES:
            print(f"{audio} is not an available language")
            exit(1)

def download():
    global NEW_DIR, SUBTITLES, AUDIOS, MERGE, SERIES_URL, TITLE
    audios = ' '.join(['-a ' + audio for audio in AUDIOS])
    subs = ' '.join(['-s ' + sub for sub in SUBTITLES])
    if not NEW_DIR:
        command = f"./crunchy-cli.exe archive {audios} {subs} -m {MERGE} -o 'Season {{season_number}}/{TITLE} S{{season_number}}E{{episode_number}}.mkv' {SERIES_URL}"
        # print(f"./crunchy-cli.exe archive {audios} {subs} -m {MERGE} -o 'Season {{season_number}}/{TITLE} S{{season_number}}E{{episode_number}}.mkv' {SERIES_URL}")
    else:
        command = f"./crunchy-cli.exe archive {audios} {subs} -m {MERGE} -o '{TITLE}/Season {{season_number}}/{TITLE} S{{season_number}}E{{episode_number}}.mkv' {SERIES_URL}"
        # print(f"./crunchy-cli.exe archive {audios} {subs} -m {MERGE} -o '{TITLE}/Season {{season_number}}/{TITLE} S{{season_number}}E{{episode_number}}.mkv' {SERIES_URL}")
    subprocess.run(command, shell=True)

get_args()
validate_inputs()
download()