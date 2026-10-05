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

# Ultra-sparsamer Einzeiler (2 FPS / 1000k Bitrate) - Bringt jede schwache Gratis-CPU auf Echtzeit!
CMD ["bash", "-c", "python3 /home/radio/health.py & echo '=== CREATING LIVE RAM PIPE ==='; rm -f /tmp/stream/live.mp3; mkfifo -m 666 /tmp/stream/live.mp3; echo '=== START LIQUIDSOAP AUDIO GENERATOR ==='; liquidsoap /home/radio/script.liq & echo '=== CODER REBUILD FIX: START FFMPEG ENCODER ==='; while true; do ffmpeg -hide_banner -loglevel info -loop 1 -framerate 2 -i /home/radio/background.png -i /tmp/stream/live.mp3 -vf 'scale=1280:720,format=yuv420p' -c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p -r 2 -g 4 -keyint_min 2 -b:v 1000k -maxrate 1000k -bufsize 2000k -c:a aac -b:a 128k -ar 44100 -ac 2 -f flv 'rtmp://a.rtmp.youtube.com/live2/2t99-w0zu-mku7-6m0y-8qch'; sleep 5; done"]
