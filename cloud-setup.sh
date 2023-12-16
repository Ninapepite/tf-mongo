#!/bin/bash

# Chemin du fichier de log
log_file="/home/debian/setup-init.log"

{
    echo "🚀 Let's Start to setup vps ! 🚀"
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install -y ca-certificates curl gnupg lsb-release git
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Installation de nftables
    sudo apt install -y nftables
    # sudo nft list ruleset

    sudo mkdir -p /var/log/crowdsec
    sudo mkdir -p /etc/crowdsec
    # Téléchargement et extraction de crowdsec-firewall-bouncer
    curl -L https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/v0.0.28/crowdsec-firewall-bouncer-linux-amd64.tgz -o crowdsec-firewall-bouncer-linux-amd64.tgz
    tar xzvf crowdsec-firewall-bouncer-linux-amd64.tgz

    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    sudo mkdir -p /opt/crowdsec

    sudo docker network create proxy
    sudo docker compose up -d
    cd crowdsec-firewall-bouncer-v0.0.28/
    echo 'nftables' | sudo ./install.sh
    ## TODO Faire echo nftables

    cd ..
    git clone https://github.com/aidalinfo/crowdsecurity-udpflood-traefik

    sudo cp crowdsecurity-udpflood-traefik/parsers/s01-parse/parser-udp-flood.yaml /opt/crowdsec/parsers/s01-parse/
    sudo cp crowdsecurity-udpflood-traefik/parsers/scenarios/sc-udp-flood.yaml /opt/crowdsec/scenarios/
    outputAddBouncer=$(sudo docker exec crowdsec cscli bouncers add firewall-local)
    api_key=$(echo "$outputAddBouncer" | tail -n 3 | head -n 1 | xargs)
    config_file="/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml"
    sudo sed -i "s/<API_KEY>/$api_key/g" "$config_file"
    sudo sed -i 's/# - DOCKER-USER/  - DOCKER-USER/' "$config_file"
    # Nom du conteneur Docker pour CrowdSec
    container_name="crowdsec"
    container_ip=$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)
    sudo sed -i "s|api_url: http://.*|api_url: http://$container_ip:8080/|" "$config_file"
    sudo systemctl restart crowdsec-firewall-bouncer
    
    # tcpudp-traefik

    # Setup Acquis Crowdsec
    acquis_traefik="
---
filenames:
  - /var/log/crowdsec/traefik-tcpudp.log
labels:
  type: tcpudp-traefik"
    # Chemin du fichier de configuration
    acquisFile="/opt/crowdsec/acquis.yaml"

    # Ajouter la nouvelle configuration à la fin du fichier
    echo "$acquis_traefik" | sudo tee -a "$acquisFile" > /dev/null

    echo "🚀 Let's goooo ! 🚀"

} >> "$log_file" 2>&1
