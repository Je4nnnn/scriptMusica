#!/bin/bash

cd "$(dirname "$0")"

echo "===================================================================="
echo " DESCARGADOR DE AUDIO - YOUTUBE / SOUNDCLOUD / BANDCAMP / BEATPORT"
echo "===================================================================="
echo " Uso permitido: musica propia, libre, Creative Commons o con permiso."
echo "===================================================================="
echo ""

# ============================================================
# 1) VERIFICAR PYTHON
# ============================================================

if ! command -v python3 &> /dev/null; then
    echo "[ERROR] No se encontró Python 3."

    if command -v apt &> /dev/null; then
        echo "Instalando Python con apt..."
        sudo apt update
        sudo apt install -y python3 python3-pip python3-venv
    elif command -v dnf &> /dev/null; then
        echo "Instalando Python con dnf..."
        sudo dnf install -y python3 python3-pip python3-venv
    elif command -v pacman &> /dev/null; then
        echo "Instalando Python con pacman..."
        sudo pacman -Sy --noconfirm python python-pip
    else
        echo "No pude detectar tu gestor de paquetes."
        echo "Instala manualmente: python3, pip y venv."
        exit 1
    fi
fi

# ============================================================
# 2) VERIFICAR VERSIÓN PYTHON
# ============================================================

python3 - <<EOF
import sys
exit(0 if sys.version_info >= (3, 10) else 1)
EOF

if [ $? -ne 0 ]; then
    echo "[ERROR] Necesitas Python 3.10 o superior."
    exit 1
fi

# ============================================================
# 3) VERIFICAR VENV
# ============================================================

if ! python3 -m venv --help &> /dev/null; then
    echo "[AVISO] No se encontró python3-venv."

    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y python3-venv
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-venv
    else
        echo "Instala manualmente el módulo venv de Python."
        exit 1
    fi
fi

# ============================================================
# 4) CREAR ENTORNO VIRTUAL
# ============================================================

if [ ! -f ".venv/bin/python" ]; then
    echo ""
    echo "Creando entorno virtual de Python..."
    python3 -m venv .venv
fi

VENV_PY=".venv/bin/python"

# ============================================================
# 5) INSTALAR / ACTUALIZAR DEPENDENCIAS
# ============================================================

echo ""
echo "Actualizando pip..."
"$VENV_PY" -m pip install --upgrade pip

echo ""
echo "Instalando / actualizando yt-dlp..."
"$VENV_PY" -m pip install --upgrade "yt-dlp[default]"

# ============================================================
# 6) VERIFICAR FFMPEG
# ============================================================

if ! command -v ffmpeg &> /dev/null; then
    echo ""
    echo "[AVISO] No se encontró FFmpeg."
    echo "FFmpeg es necesario para convertir audio a MP3, WAV, FLAC o M4A."

    if command -v apt &> /dev/null; then
        echo "Instalando FFmpeg con apt..."
        sudo apt update
        sudo apt install -y ffmpeg
    elif command -v dnf &> /dev/null; then
        echo "Instalando FFmpeg con dnf..."
        sudo dnf install -y ffmpeg
    elif command -v pacman &> /dev/null; then
        echo "Instalando FFmpeg con pacman..."
        sudo pacman -Sy --noconfirm ffmpeg
    else
        echo "No pude detectar tu gestor de paquetes."
        echo "Instala FFmpeg manualmente."
        exit 1
    fi
fi

# ============================================================
# 7) EJECUTAR DESCARGADOR
# ============================================================

echo ""
echo "Abriendo descargador..."
echo ""

"$VENV_PY" descargar.py

echo ""
read -p "Presiona ENTER para salir..."