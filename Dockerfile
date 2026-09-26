FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server curl unzip python3 netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

# Root password
RUN echo 'root:dev' | chpasswd

# SSH config
RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Ngrok install
RUN curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
    tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
    tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && apt-get install -y ngrok && \
    rm -rf /var/lib/apt/lists/*

# Ngrok config - updated token
RUN mkdir -p /root/.config/ngrok && \
    printf 'version: "2"\nauthtoken: 3JrmUD5GguXzQxmT5a1kEXiaH9d_2P1U39YmSA5VY4gzQZsZz\nregion: ap\ntunnels:\n  ssh:\n    proto: tcp\n    addr: 22\n' \
    > /root/.config/ngrok/ngrok.yml

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8080
CMD ["/start.sh"]
