#!/bin/bash
echo "🚀 Let's Start to setup vps ! 🚀"
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release git
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Installation de nftables
sudo apt install -y nftables

# Configuration de règles de base avec nftables
# sudo nft add table inet filter
# sudo nft add chain inet filter input { type filter hook input priority 0 \; }
# sudo nft add rule inet filter input iif lo accept
# sudo nft add rule inet filter input tcp dport { http, https } accept
# sudo nft add rule inet filter input tcp dport 22 ip saddr Your_IP_Public accept
# sudo nft add rule inet filter input tcp dport 22 drop

# Sauvegarde de la configuration de nftables
# sudo nft list ruleset > /etc/nftables.conf

# Affichage des règles nftables
sudo nft list ruleset

sudo mkdir -p /var/log/crowdsec
sudo mkdir -p /etc/crowdsec
# Téléchargement et extraction de crowdsec-firewall-bouncer
curl -L https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/v0.0.28/crowdsec-firewall-bouncer-linux-amd64.tgz -o crowdsec-firewall-bouncer-linux-amd64.tgz
tar xzvf crowdsec-firewall-bouncer-linux-amd64.tgz

echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

sudo mkdir -p /opt/crowdsec


git clone https://github.com/aidalinfo/crowdsecurity-udpflood-traefik

cd crowdsecurity-udpflood-traefik
## TODO Faire echo nftables

echo "🚀 Let's goooo ! 🚀"
