#!/bin/bash
set -eux

apt-get update -y
apt-get install -y docker.io git docker-compose-plugin

systemctl enable docker
systemctl start docker

mkdir -p /opt/compose
cd /opt/compose

git clone https://github.com/MACC-PBL1/Compose.git
cd Compose
git submodule update --init --recursive

cd machine
docker compose up -d
