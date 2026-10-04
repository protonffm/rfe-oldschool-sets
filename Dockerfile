FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        tzdata \
        liquidsoap \
        ffmpeg \
        icecast2 \
        python3 \
        curl \
        dos2unix \
        bash \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Zeitzone einrichten
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

# Icecast für den automatischen Systemstart freischalten
RUN sed -i 's/ENABLE=false/ENABLE=true/g' /etc/default/icecast2

WORKDIR /home/radio
RUN mkdir -p /home/radio/music

COPY . /home/radio/
RUN dos2unix /home/radio/script.liq /home/radio/health.py

EXPOSE 10000

# Direktleitung im CMD-Block (Keine externen start.sh-Skripte mehr!)
CMD ["bash", "-c", "\
    python3 /home/radio/health.py & \
    \
    service icecast2 start && \
    \
    sleep 3; \
    \
    liquidsoap /home/radio/script.liq & \
    \
    sleep 8; \
    \
    while true; do \
      ffmpeg \
        -hide_banner \
        -loglevel info \
        -loop 1 \
        -framerate 25 \
        -i /home/radio/background.png \
        -i http://127.0.0 \
        -vf \"scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p\" \
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
