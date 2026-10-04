    echo '=== RFE YOUTUBE: Starting Unstoppable FFmpeg YouTube Loop ==='; \
    bash -c '\
    while true; do \
      ffmpeg \
        -hide_banner \
        -loglevel info \
        -loop 1 \
        -framerate 25 \
        -video_size 1672x941 \
        -i /home/radio/background.png \
        -f s16le \
        -ar 44100 \
        -ac 2 \
        -i /home/radio/live.pipe \
        -vf \"scale=1280:720,format=yuv420p\" \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -pix_fmt yuv420p \
        -r 25 \
        -g 50 \
        -keyint_min 25 \
        -sc_threshold 0 \
        -b:v 600k \
        -maxrate 600k \
        -bufsize 1200k \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -ac 2 \
        -f flv \
        \"rtmp://://youtube.com\" \
        >> /tmp/ffmpeg.log 2>&1; \
      sleep 2; \
    done' & \
