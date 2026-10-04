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
    set -u; \
    \
    echo '================================================'; \
    echo ' RFE YOUTUBE STREAM'; \
    echo '================================================'; \
    echo ''; \
    \
    # --------------------------------------------------- \
    # YouTube Einstellungen prüfen \
    # --------------------------------------------------- \
    if [ -z \"${YOUTUBE_STREAM_URL:-}\" ]; then \
        echo 'FEHLER: YOUTUBE_STREAM_URL fehlt!'; \
        echo 'Bitte in Blitz.Cloud als Environment Variable setzen.'; \
        exit 10; \
    fi; \
    \
    if [ -z \"${YOUTUBE_STREAM_KEY:-}\" ]; then \
        echo 'FEHLER: YOUTUBE_STREAM_KEY fehlt!'; \
        echo 'Bitte in Blitz.Cloud als Environment Variable setzen.'; \
        exit 11; \
    fi; \
    \
    case \"$YOUTUBE_STREAM_URL\" in \
        rtmps://*) \
            echo 'YouTube: RTMPS aktiviert'; \
            ;; \
        rtmp://*) \
            echo 'WARNUNG: RTMP erkannt.'; \
            echo 'YouTube empfiehlt RTMPS.'; \
            ;; \
        *) \
            echo 'FEHLER: YOUTUBE_STREAM_URL ist keine RTMP/RTMPS URL.'; \
            exit 12; \
            ;; \
    esac; \
    \
    echo 'YouTube Stream URL: konfiguriert'; \
    echo 'YouTube Stream Key: konfiguriert (nicht angezeigt)'; \
    echo ''; \
    \
    # --------------------------------------------------- \
    # FIFO neu erstellen \
    # --------------------------------------------------- \
    rm -f /home/radio/live.pipe; \
    mkfifo -m 666 /home/radio/live.pipe; \
    \
    # --------------------------------------------------- \
    # Musik prüfen \
    # --------------------------------------------------- \
    echo '=== Musikdateien ==='; \
    find /home/radio/music -type f | head -20 || true; \
    \
    MUSIC_COUNT=$(find /home/radio/music -type f | wc -l); \
    echo \"Gefundene Dateien: $MUSIC_COUNT\"; \
    \
    if [ \"$MUSIC_COUNT\" -eq 0 ]; then \
        echo 'FEHLER: Keine Musik in /home/radio/music gefunden!'; \
        exit 20; \
    fi; \
    \
    echo ''; \
    \
    # --------------------------------------------------- \
    # Health-Check Server für Blitz.Cloud \
    # --------------------------------------------------- \
    echo '=== Starte Health-Check auf Port 10000 ==='; \
    python3 -m http.server 10000 --bind 0.0.0.0 --directory /home/radio > /tmp/http.log 2>&1 & \
    HTTP_PID=$!; \
    \
    sleep 2; \
    \
    # --------------------------------------------------- \
    # Liquidsoap starten \
    # --------------------------------------------------- \
    echo '=== Starte Liquidsoap ==='; \
    liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & \
    LIQ_PID=$!; \
    \
    sleep 5; \
    \
    if ! kill -0 \"$LIQ_PID\" 2>/dev/null; then \
        echo 'FEHLER: Liquidsoap ist sofort beendet worden!'; \
        echo '--------------- Liquidsoap Log ---------------'; \
        cat /tmp/liquidsoap.log || true; \
        exit 30; \
    fi; \
    \
    echo 'Liquidsoap läuft.'; \
    echo ''; \
    \
    # --------------------------------------------------- \
    # YouTube Ziel zusammensetzen \
    # --------------------------------------------------- \
    YOUTUBE_TARGET=\"${YOUTUBE_STREAM_URL%/}/${YOUTUBE_STREAM_KEY}\"; \
    \
    echo '=== YouTube Ziel vorbereitet ==='; \
    echo 'Stream-Key wird aus Sicherheitsgründen nicht ausgegeben.'; \
    echo ''; \
    \
    # --------------------------------------------------- \
    # FFmpeg / YouTube \
    # --------------------------------------------------- \
    echo '================================================'; \
    echo ' STARTE YOUTUBE STREAM'; \
    echo '================================================'; \
    \
    while true; do \
        echo ''; \
        echo '=== FFmpeg startet ==='; \
        date; \
        echo ''; \
        \
        ffmpeg \
            -hide_banner \
            -loglevel info \
            -re \
            -loop 1 \
            -framerate 25 \
            -i /home/radio/background.png \
            -f s16le \
            -ar 44100 \
            -ac 2 \
            -i /home/radio/live.pipe \
            -map 0:v:0 \
            -map 1:a:0 \
            -vf \"scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p\" \
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
            \"$YOUTUBE_TARGET\" \
            > /tmp/ffmpeg.log 2>&1; \
        \
        FF_STATUS=$?; \
        \
        echo ''; \
        echo '================================================'; \
        echo \" FFmpeg beendet - Exit Code: $FF_STATUS\"; \
        echo '================================================'; \
        \
        echo ''; \
        echo '--------------- Letzte FFmpeg Meldungen ---------------'; \
        tail -100 /tmp/ffmpeg.log || true; \
        echo '--------------------------------------------------------'; \
        \
        echo ''; \
        echo 'Neustart in 5 Sekunden...'; \
        sleep 5; \
    done \
"]
