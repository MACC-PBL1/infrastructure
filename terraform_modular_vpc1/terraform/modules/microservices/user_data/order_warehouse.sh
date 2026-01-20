#!/bin/bash
set -eux

echo "Waiting for NAT / Internet..."
until ping -c1 8.8.8.8 >/dev/null 2>&1; do
  sleep 5
done

export DEBIAN_FRONTEND=noninteractive

# --- System update ---
sudo apt-get update -y

# --- Install base packages ---
sudo apt-get install -y \
  docker.io \
  docker-compose \
  git

# --- Enable Docker ---
sudo systemctl enable docker
sudo systemctl start docker

# --- Allow ubuntu user to run docker ---
sudo usermod -aG docker ubuntu

# --- Prepare compose directory ---
sudo mkdir -p /opt/compose
sudo chown ubuntu:ubuntu /opt/compose

cd /opt/compose

# --- Clone repo ---
git clone https://github.com/MACC-PBL1/Compose.git
cd Compose
git submodule update --init --recursive


# docker-compose up -d
