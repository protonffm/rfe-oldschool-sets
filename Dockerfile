FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------
# Pakete installieren
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
# Zeitzone festlegen
# ------------------------------------------------------------
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

WORKDIR /home/radio
RUN mkdir -p /home/radio/music

# ------------------------------------------------------------
# Projektdateien kopieren
# ------------------------------------------------------------
COPY . /home/radio/
RUN dos2unix /home/radio/script.liq

EXPOSE 10000

# ------------------------------------------------------------
# Start-Befehl (Live-Logs direkt auf den Bildschirm!)
# ------------------------------------------------------------
CMD ["bash", "-c", "\
    set -m; \
    \
    rm -f /home/radio/live.pipe; \
    mkfifo -m 666 /home/radio/live.pipe; \
    \
    echo '=== 1. STARTE HEALTH-CHECK ==='; \
    python3 -m http.server 10000 --bind 0.0.0.0 --directory /home/radio & \
    \
    echo '=== 2. STARTE LIQUIDSOAP AUDIO ENGINE ==='; \
    liquidsoap /home/radio/script.liq & \
    \
    sleep 5; \
    \
    echo '=== 3. STARTE FFMPEG DIRECT YOUTUBE STREAM ==='; \
    while true; do \
      ffmpeg \
        -hide_banner \
        -loop 1 \
        -framerate 25 \
        -i /home/radio/background.png \
        -f s16le \
        -ar 44100 \
        -ac 2 \
        -i /home/radio/live.pipe \
        -map 0:v:0 \
        -map 1:a:0 \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -pix_fmt yuv420p \
        -r 25 \
        -g 50 \
        -keyint_min 50 \
        -sc_threshold 0 \
        -b:v 1500k \
        -maxrate 1500k \
        -bufsize 3000k \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -ac 2 \
        -f flv \
        \"rtmp://://youtube.com\"; \
      echo 'FFmpeg wurde unerwartet beendet. Neustart in 5 Sekunden...'; \
      sleep 5; \
    done \
"]
