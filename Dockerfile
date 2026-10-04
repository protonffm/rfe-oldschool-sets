FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

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

# Zeitzone einrichten
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

WORKDIR /home/radio
RUN mkdir -p /home/radio/music /tmp/stream

COPY . /home/radio/
RUN dos2unix /home/radio/script.liq /home/radio/health.py

EXPOSE 10000

# Die unzerstörbare Direktleitung ohne Icecast-Sperren!
CMD ["bash", "-c", "\
    python3 /home/radio/health.py & \
    \
    echo '=== START LIQUIDSOAP AUDIO GENERATOR ==='; \
    liquidsoap /home/radio/script.liq & \
    \
    echo '=== CODER REBUILD FIX: START FFMPEG ENCODER ==='; \
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
        -i /tmp/stream/live.raw \
        -vf \"scale=1280:720,format=yuv420p\" \
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
        \"rtmp://://youtube.com\"; \
      sleep 5; \
    done \
"]
