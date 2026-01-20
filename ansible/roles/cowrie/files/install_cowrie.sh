#!/bin/bash
set -e

COWRIE_USER="cowrie"
COWRIE_HOME="/home/$COWRIE_USER"

# Clonar repositorio
if [ ! -d "$COWRIE_HOME/cowrie" ]; then
    git clone https://github.com/cowrie/cowrie.git $COWRIE_HOME/cowrie
    chown -R $COWRIE_USER:$COWRIE_USER $COWRIE_HOME/cowrie
fi

# Crear entorno virtual e instalar
su - $COWRIE_USER << 'EOF'
cd ~/cowrie
if [ ! -d "cowrie-env" ]; then
    python3 -m venv cowrie-env
fi
source cowrie-env/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install -e .

# Configurar si no existe
if [ ! -f etc/cowrie.cfg ]; then
    cp etc/cowrie.cfg.dist etc/cowrie.cfg
fi
EOF

# Copiar archivos honeyfs si no existen
if [ -d "$COWRIE_HOME/cowrie/honeyfs.example" ] && [ ! -f "$COWRIE_HOME/cowrie/honeyfs/etc/passwd" ]; then
    cp -r $COWRIE_HOME/cowrie/honeyfs.example/* $COWRIE_HOME/cowrie/honeyfs/ 2>/dev/null || true
    chown -R $COWRIE_USER:$COWRIE_USER $COWRIE_HOME/cowrie/honeyfs
fi

echo "Cowrie instalado correctamente"

echo "Cowrie instalado correctamente"