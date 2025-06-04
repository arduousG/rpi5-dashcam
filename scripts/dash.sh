#!/bin/bash
# dash.sh
# config
SEGMENT_DURATION_MS=420000          # 7 min segs -- 420sec 
OUTPUT_BASE_DIR="/home/t-pi/rpi5-dashcam/media"
TMP_DIR="/home/t-pi/rpi5-dashcam/tmp"
CAMERA_WIDTH=1920
CAMERA_HEIGHT=1080
CAMERA_FPS=30
LIBCAMERA_EXTRA_OPTS=""

#global flags
STOP_FLAG=0          #1 to exit after current conversion
STAGE="idle"         # else “recording” || “converting”
VID_PID=""           # PID -- libcamera-vid

# ctrl+c graceful exit strat -- SIGINT
function clean_exit {
    echo
    if [[ "$STAGE" == "recording" && -n "$VID_PID" ]]; then
        echo "SIGINT received -> stopping libcamera-vid (PID=${VID_PID})..."
        STOP_FLAG=1
        kill -SIGINT "$VID_PID"
    elif [[ "$STAGE" == "converting" ]]; then
        echo "SIGINT received -> will exit once conversion finishes..."
        STOP_FLAG=1
        #let ffmpeg finish -- problem fucking solved
    else
        # idle//between segs
        STOP_FLAG=1
    fi
}
trap clean_exit SIGINT

#dir setups
mkdir -p "${TMP_DIR}"
mkdir -p "${OUTPUT_BASE_DIR}"

echo "=-=- Starting dash.sh -=-="
echo "Press Ctrl+C to stop recording"
echo

#running loop
while true; do
    #timestamps & folder paths
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S") # exact file name - secs
    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")
    HOUR=$(date +"%H")

    OUTPUT_DIR="${OUTPUT_BASE_DIR}/${YEAR}/${MONTH}/${DAY}/${HOUR}"
    mkdir -p "${OUTPUT_DIR}"

    RAW_FILENAME="segment_${TIMESTAMP}.h264"
    RAW_FILEPATH="${TMP_DIR}/${RAW_FILENAME}"

    FINAL_FILENAME="${TIMESTAMP}.mp4"
    FINAL_FILEPATH="${OUTPUT_DIR}/${FINAL_FILENAME}"

    #recording -- 
    STAGE="recording" #set flag
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Recording -> ${RAW_FILENAME}"
    libcamera-vid \
        --width ${CAMERA_WIDTH} \
        --height ${CAMERA_HEIGHT} \
        --framerate ${CAMERA_FPS} \
        --codec h264 \
        --timeout ${SEGMENT_DURATION_MS} \
        ${LIBCAMERA_EXTRA_OPTS} \
        -o "${RAW_FILEPATH}" &
    VID_PID=$!
    wait "$VID_PID"
    VID_PID=""

    #converting raw.h264 -> MP4; do ALWAYS
    if [[ -f "${RAW_FILEPATH}" ]]; then
        STAGE="converting"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] Re-encoding -> ${FINAL_FILENAME}"

	#ffmpeg flags -- make sure specs are same for less chance of conversion corruption
        ffmpeg -y -loglevel error \
            -r ${CAMERA_FPS} -f h264 \
            -i "${RAW_FILEPATH}" \
            -c:v libx264 -preset ultrafast -crf 23 \
            "${FINAL_FILEPATH}"

	#TEST
	#something wrong
        if [[ ! -f "${FINAL_FILEPATH}" ]]; then
            echo "[ERROR] Re-encode failed for ${RAW_FILEPATH}. Keeping raw .h264 for inspection."
        else
            echo "[$(date +"%Y-%m-%d %H:%M:%S")] Deleting tmp raw H264: ${RAW_FILENAME}"
            rm -f "${RAW_FILEPATH}"
            echo "[$(date +"%Y-%m-%d %H:%M:%S")] Saved → ${FINAL_FILEPATH}"
        fi
    else
        echo "[WARN] No raw file found at ${RAW_FILEPATH}. Skipping conversion."
    fi

    # 4)exit or keep going
    STAGE="idle" #idle flag 
    if [[ $STOP_FLAG -eq 1 ]]; then
        echo
        echo "=-=- Exiting dash.sh (all done) -=-="
        exit 0
    fi

    #else, restart
done
