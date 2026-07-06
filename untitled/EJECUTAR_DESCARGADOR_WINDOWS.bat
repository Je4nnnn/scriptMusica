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
rem 4) INSTALAR DEPENDENCIAS DE PYTHON
rem ============================================================

"%VENV_PY%" -c "import yt_dlp" >nul 2>nul
if errorlevel 1 (
    echo.
    echo Instalando yt-dlp por primera vez...
    "%VENV_PY%" -m pip install --upgrade pip
    if errorlevel 1 goto :error_pip

    "%VENV_PY%" -m pip install "yt-dlp[default]"
    if errorlevel 1 goto :error_ytdlp
)

rem ============================================================
rem 5) PREPARAR FFMPEG LOCALMENTE (NO REQUIERE WINGET)
rem ============================================================

set "FFMPEG_BIN="

rem Primero se acepta una instalacion que ya este en PATH.
where ffmpeg >nul 2>nul
if not errorlevel 1 (
    where ffprobe >nul 2>nul
    if not errorlevel 1 goto :ffmpeg_listo
)

rem Si ya fue descargado por este lanzador, se reutiliza.
if exist ".tools\ffmpeg" (
    for /f "delims=" %%D in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$f = Get-ChildItem -Path '.tools\ffmpeg' -Filter 'ffmpeg.exe' -Recurse -File ^| Select-Object -First 1; if ($f) { $f.DirectoryName }"') do set "FFMPEG_BIN=%%D"
)

if not defined FFMPEG_BIN (
    echo.
    echo FFmpeg no esta instalado. Descargando una copia local...
    echo Esto solo se realiza la primera vez y no requiere winget.
    echo.

    if not exist ".tools" mkdir ".tools"
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$ErrorActionPreference = 'Stop';" ^
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
      "$url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';" ^
      "$zip = Join-Path (Get-Location) '.tools\ffmpeg.zip';" ^
      "$dest = Join-Path (Get-Location) '.tools\ffmpeg';" ^
      "Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing;" ^
      "if (Test-Path $dest) { Remove-Item $dest -Recurse -Force };" ^
      "Expand-Archive -Path $zip -DestinationPath $dest -Force;" ^
      "Remove-Item $zip -Force"
    if errorlevel 1 goto :error_ffmpeg_download

    for /f "delims=" %%D in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$f = Get-ChildItem -Path '.tools\ffmpeg' -Filter 'ffmpeg.exe' -Recurse -File ^| Select-Object -First 1; if ($f) { $f.DirectoryName }"') do set "FFMPEG_BIN=%%D"
)

if not defined FFMPEG_BIN goto :error_ffmpeg_files
set "PATH=%FFMPEG_BIN%;%PATH%"

:ffmpeg_listo
where ffmpeg >nul 2>nul
if errorlevel 1 goto :error_ffmpeg_files
where ffprobe >nul 2>nul
if errorlevel 1 goto :error_ffmpeg_files

rem ============================================================
rem 6) EJECUTAR DESCARGADOR
rem ============================================================

echo.
echo Abriendo descargador...
echo.

"%VENV_PY%" descargar.py
set "SCRIPT_EXIT=%errorlevel%"

echo.
pause
exit /b %SCRIPT_EXIT%

:error_pip
echo.
echo [ERROR] No se pudo preparar pip. Revisa tu conexion a Internet.
goto :error_exit

:error_ytdlp
echo.
echo [ERROR] No se pudo instalar yt-dlp. Revisa tu conexion a Internet.
goto :error_exit

:error_ffmpeg_download
echo.
echo [ERROR] No se pudo descargar o descomprimir FFmpeg.
echo Revisa tu conexion a Internet y vuelve a ejecutar este archivo.
goto :error_exit

:error_ffmpeg_files
echo.
echo [ERROR] La descarga de FFmpeg no contiene ffmpeg.exe y ffprobe.exe.
echo Borra la carpeta .tools\ffmpeg y vuelve a ejecutar este archivo.

:error_exit
echo.
pause
exit /b 1
