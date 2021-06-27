#!/bin/bash
# create some testdata for the carl music box. Dependencies
#  * espeak, ffmpeg
# (c) 2021 by Jan Delgado

set -eou pipefail

function usage {
    echo "usage: $0 [--large-folders] [--dir DIR]"
    exit 1
}

NUM_FORMAT="%03d"
SD_DIR="./sd"

while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
        --large-folders)
            NUM_FORMAT="%04d"
            ;;
        --dir)
            SD_DIR=$2; shift;
            ;;
        *)
            usage 
            ;;
    esac
    shift
done

[ -d "$SD_DIR" ] && { echo "output directory $SD_DIR exists. remove first."; exit 2;}
mkdir "$SD_DIR"

# start with 3 songs in the first folder, incrementing by one on each 
# following folder
num_songs=3

for playlist in $(seq 1 10); do
    pldir=$(printf "$SD_DIR/%02d" $playlist)
    mkdir -p "$pldir"
    for song in $(seq 1 $num_songs); do
        wavfile="$pldir/$(printf $NUM_FORMAT $song).wav"
        mp3file="$(dirname $wavfile)/$(basename $wavfile wav)mp3"
        echo "rendering $mp3file"

        espeak -w "$wavfile"\
               -m  "<speak version=\"1.0\" xmlns=\"http://www.w3.org/2001/10/synthesis\" xml:lang=\"string\">playlist $playlist, song $song.<break time=\"1000ms\"/></speak>" > /dev/null

        ffmpeg -hide_banner -loglevel error \
               -i "$wavfile" -i jingle.mp3 -filter_complex "[0:a][1:a]concat=n=2:a=1:v=0" "$mp3file"

        rm -f "$wavfile"
    done
    num_songs=$(($num_songs + 1))
done

