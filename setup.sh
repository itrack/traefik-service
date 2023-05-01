#!/bin/bash

# Remove old docker engine (if exist)
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg

# Get key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add docker engine repo
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Traefik
EXEPATH=./traefik
if [ ! -f "$EXEPATH" ]; then
    # Download & extract
    wget "https://github.com/traefik/traefik/releases/download/v2.10.1/traefik_v2.10.1_linux_amd64.tar.gz"
    tar -xzf traefik_v2.10.1_linux_amd64.tar.gz
fi

# Copy binary
sudo cp ./traefik /usr/local/bin
sudo chown root:root /usr/local/bin/traefik
sudo chmod 755 /usr/local/bin/traefik

# Give the traefik binary the ability to bind to privileged ports (e.g. 80, 443) as a non-root user
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik

# Add privileges
sudo groupadd -g 321 traefik
sudo useradd \
  -g traefik --no-user-group \
  --home-dir /var/www --no-create-home \
  --shell /usr/sbin/nologin \
  --system --uid 321 traefik
sudo usermod -aG docker traefik

# Make etc
sudo mkdir /etc/traefik
sudo mkdir /etc/traefik/acme
sudo chown -R root:root /etc/traefik
sudo chown -R traefik:traefik /etc/traefik/acme

# Copy to etc
sudo cp ./traefik.toml /etc/traefik/
sudo chown root:root /etc/traefik/traefik.toml
sudo chmod 644 /etc/traefik/traefik.toml

# Install service
sudo cp ./traefik.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/traefik.service
sudo chmod 644 /etc/systemd/system/traefik.service
sudo systemctl daemon-reload

# Start service and set to start at boot
sudo systemctl start traefik.service
sudo systemctl enable traefik.service


echo "Finish install"