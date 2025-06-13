#!/usr/bin/env bash
# fetch_dashcam.sh
#copy all .mp4 files + subfolders from Pi’s media dir
#to local WSL folder ~/DashcamMedia

#should look like (hardcoded)
/home/t-pi/rpi5-dashcam/media/   →   ~/DashcamMedia/
#

#var config
PI_USER="t-pi" #hardcoded user and host/IP
PI_HOST="raspberrypi.local`" #replace with pi IP -- was changed to default before commit
REMOTE_DIR="/home/t-pi/rpi5-dashcam/media"
LOCAL_DIR="$HOME/DashcamMedia"


#local dir
if [[ ! -d "$LOCAL_DIR" ]]; then
  echo "Creating local folder: $LOCAL_DIR"
  mkdir -p "$LOCAL_DIR"
else
  echo "Using existing local folder: $LOCAL_DIR"
fi

##rsync not scp
#copy recursively -- preserve mod time -- skip up to date files.
echo -e "\nStarting transfer from Pi → Local..."
rsync -avz --progress \
  "${PI_USER}@${PI_HOST}:${REMOTE_DIR}/" \
  "$LOCAL_DIR/"

if [[ $? -eq 0 ]]; then
  echo -e "\n[SUCCESS] All files copied into $LOCAL_DIR"
else
  echo -e "\n[ERROR] Something went wrong during rsync."
fi
