FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Pakete
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y \
        tzdata \
        liquidsoap \
        ffmpeg \
        curl \
        dos2unix \
        coreutils \
        python3 \
        bash && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Zeitzone
# ------------------------------------------------------------
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

# ------------------------------------------------------------
# Arbeitsverzeichnis
# ------------------------------------------------------------
WORKDIR /home/radio

RUN mkdir -p /home/radio/music

# ------------------------------------------------------------
# Projektdateien kopieren
# ------------------------------------------------------------
COPY . /home/radio/

RUN dos2unix /home/radio/script.liq

# ------------------------------------------------------------
# Health-Port für Blitz.Cloud
# ------------------------------------------------------------
EXPOSE 10000

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------
CMD ["bash", "-c", "\
    set -m; \
    \
    rm -f /home/radio/live.wav /home/radio/live.pipe; \
    mkfifo -m 666 /home/radio/live.pipe; \
    \
    echo '=== RFE YOUTUBE: Starting Health-Check Dummy on Port 10000 ==='; \
    python3 -m http.server 10000 --bind 0.0.0.0 --directory /home/radio > /tmp/http.log 2>&1 & \
    HTTP_PID=$!; \
    \
    sleep 2; \
    \
    echo '=== RFE YOUTUBE: Starting Liquidsoap Engine ==='; \
    liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & \
    LIQ_PID=$!; \
    sleep 4; \
    \
    echo '=== RFE YOUTUBE: Starting Unstoppable FFmpeg YouTube Loop ==='; \
    bash -c '\
    while true; do \
      ffmpeg \
        -hide_banner \
        -loglevel info \
        -loop 1 \
        -framerate 25 \
        -i /home/radio/background.png \
        -f s16le \
        -ar 44100 \
        -ac 2 \
        -i /home/radio/live.pipe \
        -map 0:v:0 \
        -map 1:a:0 \
        -vf \"scale=1280:720,format=yuv420p\" \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -pix_fmt yuv420p \
        -profile:v main \
        -r 25 \
        -g 50 \
        -keyint_min 50 \
        -sc_threshold 0 \
        -b:v 1500k \
        -minrate 1500k \
        -maxrate 1500k \
        -bufsize 3000k \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -ac 2 \
        -f flv \
        \"rtmp://://youtube.com\" \
        >> /tmp/ffmpeg.log 2>&1; \
      sleep 2; \
    done' & \
    \
    wait $PYTHON_PID \
"]
