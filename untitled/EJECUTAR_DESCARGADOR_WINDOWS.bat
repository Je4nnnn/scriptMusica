@echo off
setlocal

cd /d "%~dp0"

echo ====================================================================
echo  DESCARGADOR DE AUDIO - YOUTUBE / SOUNDCLOUD / BANDCAMP / BEATPORT
echo ====================================================================
echo  Uso permitido: musica propia, libre, Creative Commons o con permiso.
echo ====================================================================
echo.

rem ============================================================
rem 1) VERIFICAR PYTHON
rem ============================================================

set "PYTHON_CMD="

where py >nul 2>nul
if not errorlevel 1 (
    py -3 --version >nul 2>nul
    if not errorlevel 1 set "PYTHON_CMD=py -3"
)

if not defined PYTHON_CMD (
    where python >nul 2>nul
    if not errorlevel 1 set "PYTHON_CMD=python"
)

if not defined PYTHON_CMD (
    echo [ERROR] No se encontro Python 3.10 o superior.
    echo Instala Python desde https://www.python.org/downloads/windows/
    echo Durante la instalacion, marca la opcion "Add python.exe to PATH".
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem 2) VERIFICAR VERSION PYTHON
rem ============================================================

%PYTHON_CMD% -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)"
if errorlevel 1 (
    echo [ERROR] Necesitas Python 3.10 o superior.
    echo Instala una version reciente desde https://www.python.org/downloads/windows/
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem 3) CREAR ENTORNO VIRTUAL
rem ============================================================

if not exist ".venv\Scripts\python.exe" (
    echo.
    echo Creando entorno virtual de Python...
    %PYTHON_CMD% -m venv .venv
    if errorlevel 1 (
        echo [ERROR] No se pudo crear el entorno virtual.
        echo.
        pause
        exit /b 1
    )
)

set "VENV_PY=.venv\Scripts\python.exe"

rem ============================================================
rem 4) INSTALAR / ACTUALIZAR DEPENDENCIAS
rem ============================================================

echo.
echo Actualizando pip...
"%VENV_PY%" -m pip install --upgrade pip
if errorlevel 1 (
    echo [ERROR] No se pudo actualizar pip.
    echo.
    pause
    exit /b 1
)

echo.
echo Instalando / actualizando yt-dlp...
"%VENV_PY%" -m pip install --upgrade "yt-dlp[default]"
if errorlevel 1 (
    echo [ERROR] No se pudo instalar yt-dlp.
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem 5) VERIFICAR FFMPEG
rem ============================================================

where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo.
    echo [AVISO] No se encontro FFmpeg.
    echo FFmpeg es necesario para convertir audio a MP3, WAV, FLAC o M4A.
    echo.
    echo Puedes instalarlo con winget ejecutando:
    echo winget install Gyan.FFmpeg
    echo.
    echo O descargarlo manualmente desde:
    echo https://www.gyan.dev/ffmpeg/builds/
    echo.
    pause
)

rem ============================================================
rem 6) EJECUTAR DESCARGADOR
rem ============================================================

echo.
echo Abriendo descargador...
echo.

"%VENV_PY%" descargar.py

echo.
pause
