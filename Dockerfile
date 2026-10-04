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

RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

WORKDIR /home/radio
RUN mkdir -p /home/radio/music

COPY . /home/radio/
RUN dos2unix /home/radio/script.liq

EXPOSE 10000

CMD ["bash", "-c", "\
    echo '=== 1. STARTE HEALTH-CHECK DUMMY ==='; \
    python3 -m http.server 10000 --bind 0.0.0.0 --directory /home/radio & \
    \
    echo '=== 2. STARTE LIQUIDSOAP ENGINE ==='; \
    liquidsoap /home/radio/script.liq & \
    \
    echo '=== 3. WARTE AUF LIVE-AUDIO IM RAM ==='; \
    sleep 8; \
    \
    echo '=== 4. STARTE FFMPEG YOUTUBE BROADCAST ==='; \
    ffmpeg \
      -hide_banner \
      -loop 1 \
      -framerate 25 \
      -i /home/radio/background.png \
      -i http://127.0.0 \
      -c:v libx264 \
      -preset ultrafast \
      -tune zerolatency \
      -pix_fmt yuv420p \
      -r 25 \
      -g 50 \
      -c:a copy \
      -f flv \
      \"rtmp://://youtube.com\" \
"]
