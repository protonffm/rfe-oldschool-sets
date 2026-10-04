#!/bin/bash
set -u

echo "=========================================="
echo " === CODER RESET FINAL STEP ==="
echo "=========================================="

echo "[1/4] Starting health server..."
python3 /home/radio/health.py &

echo "[2/4] Starting Icecast as user icecast2..."
su -s /bin/bash -c "icecast2 -c /etc/icecast2/icecast.xml" icecast2 &

sleep 4

echo "[3/4] Starting Liquidsoap Engine..."
liquidsoap /home/radio/script.liq &

sleep 8

echo "[4/4] Starting Unstoppable FFmpeg Broadcast..."
while true; do
    ffmpeg \
        -hide_banner \
        -loglevel info \
        -loop 1 \
        -framerate 25 \
        -i /home/radio/background.png \
        -i http://127.0.0 \
        -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -pix_fmt yuv420p \
        -r 25 \
        -g 50 \
        -keyint_min 50 \
        -b:v 1800k \
        -maxrate 1800k \
        -bufsize 3600k \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -ac 2 \
        -f flv \
        "rtmp://://youtube.com"

    echo "FFmpeg beendet. Neustart in 5 Sekunden..."
    sleep 5
done
