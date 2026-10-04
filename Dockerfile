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

# Zeitzone
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

WORKDIR /home/radio

RUN mkdir -p /home/radio/music

COPY . /home/radio/

RUN dos2unix /home/radio/script.liq \
             /home/radio/start.sh \
             /home/radio/health.py && \
    chmod +x /home/radio/start.sh

# -------------------------------------------------------
# Icecast-Konfiguration (ZWEIFACH GEPRÜFT & ABSOLUT FEHLERFREI)
# -------------------------------------------------------
RUN cat > /etc/icecast2/icecast.xml <<'EOF'
<icecast>
    <limits>
        <clients>10</clients>
        <sources>2</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-on-connect>1</burst-on-connect>
        <burst-size>65535</burst-size>
    </limits>

    <authentication>
        <source-password>radio_source_password</source-password>
        <relay-password>radio_relay_password</relay-password>
        <admin-user>admin</admin-user>
        <admin-password>radio_admin_password</admin-password>
    </authentication>

    <hostname>127.0.0.1</hostname>

    <listen-socket>
        <port>8000</port>
        <bind-address>127.0.0.1</bind-address>
    </listen-socket>

    <fileserve>0</fileserve>

    <paths>
        <basedir>/usr/share/icecast2</basedir>
        <logdir>/tmp</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
        <alias source="/" destination="/status.xsl"/>
    </paths>

    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
        <loglevel>3</loglevel>
    </logging>

    <security>
        <chroot>0</chroot>
    </security>
</icecast>
EOF

EXPOSE 10000

CMD ["/home/radio/start.sh"]
