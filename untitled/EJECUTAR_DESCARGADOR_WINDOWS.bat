@echo off
setlocal EnableExtensions

cd /d "%~dp0"

echo ====================================================================
echo  DESCARGADOR DE AUDIO - YOUTUBE / SOUNDCLOUD / BANDCAMP / BEATPORT
echo ====================================================================
echo  Uso permitido: musica propia, libre, Creative Commons o con permiso.
echo ====================================================================
echo.

rem ============================================================
rem 1) PREPARAR HERRAMIENTAS BASE DE WINDOWS
rem ============================================================

set "WINGET_AVAILABLE=0"
call :ensure_powershell
if errorlevel 1 goto :error_powershell

call :ensure_winget

rem ============================================================
rem 2) VERIFICAR / INSTALAR PYTHON
rem ============================================================

call :detect_python
if errorlevel 1 (
    echo.
    echo Python 3.10 o superior no esta instalado. Instalando Python...

    if "%WINGET_AVAILABLE%"=="1" (
        winget install --id Python.Python.3.12 -e --source winget --accept-package-agreements --accept-source-agreements
    )

    call :refresh_common_paths
    call :detect_python
)

if not defined PYTHON_CMD (
    echo.
    echo No se pudo preparar Python con winget. Probando instalador oficial...
    call :install_python_direct
    if errorlevel 1 goto :error_python_install

    call :refresh_common_paths
    call :detect_python
)

if not defined PYTHON_CMD goto :error_python_install

rem ============================================================
rem 3) CREAR ENTORNO VIRTUAL
rem ============================================================

if not exist ".venv\Scripts\python.exe" (
    echo.
    echo Creando entorno virtual de Python...
    %PYTHON_CMD% -m venv .venv
    if errorlevel 1 goto :error_venv
)

set "VENV_PY=.venv\Scripts\python.exe"

if exist "%VENV_PY%" (
    "%VENV_PY%" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
    if errorlevel 1 (
        echo.
        echo El entorno virtual existente no sirve para este programa. Recreandolo...
        rmdir /s /q ".venv"
        %PYTHON_CMD% -m venv .venv
        if errorlevel 1 goto :error_venv
    )
)

if not exist "%VENV_PY%" goto :error_venv

rem ============================================================
rem 4) INSTALAR / ACTUALIZAR DEPENDENCIAS DE PYTHON
rem ============================================================

echo.
echo Preparando dependencias de Python...
"%VENV_PY%" -m ensurepip --upgrade >nul 2>nul
"%VENV_PY%" -m pip install --upgrade pip
if errorlevel 1 goto :error_pip

"%VENV_PY%" -m pip install --upgrade setuptools wheel
if errorlevel 1 goto :error_pip

"%VENV_PY%" -m pip install --upgrade "yt-dlp[default]"
if errorlevel 1 goto :error_ytdlp

"%VENV_PY%" -c "import yt_dlp" >nul 2>nul
if errorlevel 1 goto :error_ytdlp

rem ============================================================
rem 5) VERIFICAR / INSTALAR FFMPEG Y FFPROBE
rem ============================================================

call :ensure_ffmpeg
if errorlevel 1 goto :error_ffmpeg_files

rem ============================================================
rem 6) EJECUTAR DESCARGADOR
rem ============================================================

echo.
echo Abriendo descargador...
echo.

if not exist "descargar.py" goto :error_script_missing

"%VENV_PY%" descargar.py
set "SCRIPT_EXIT=%errorlevel%"

echo.
pause
exit /b %SCRIPT_EXIT%


:detect_python
set "PYTHON_CMD="

where py >nul 2>nul
if not errorlevel 1 (
    for %%V in (3.13 3.12 3.11 3.10 3) do (
        if not defined PYTHON_CMD (
            py -%%V -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
            if not errorlevel 1 set "PYTHON_CMD=py -%%V"
        )
    )
)

if not defined PYTHON_CMD (
    where python >nul 2>nul
    if not errorlevel 1 (
        python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
        if not errorlevel 1 set "PYTHON_CMD=python"
    )
)

if defined PYTHON_CMD (
    echo Python listo: %PYTHON_CMD%
    exit /b 0
)

exit /b 1


:ensure_powershell
where powershell >nul 2>nul
if not errorlevel 1 exit /b 0

echo [ERROR] No se encontro PowerShell.
echo Este instalador lo necesita para descargar Python, winget o FFmpeg.
exit /b 1


:ensure_winget
where winget >nul 2>nul
if not errorlevel 1 (
    set "WINGET_AVAILABLE=1"
    echo winget listo.
    exit /b 0
)

echo winget no esta disponible. Intentando instalar App Installer...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$ProgressPreference = 'SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$pkg = Join-Path $env:TEMP 'Microsoft.DesktopAppInstaller.msixbundle';" ^
  "Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $pkg -UseBasicParsing;" ^
  "Add-AppxPackage -Path $pkg"

call :refresh_common_paths
where winget >nul 2>nul
if not errorlevel 1 (
    set "WINGET_AVAILABLE=1"
    echo winget instalado.
    exit /b 0
)

echo winget no se pudo instalar automaticamente. Se usaran metodos directos.
set "WINGET_AVAILABLE=0"
exit /b 0


:install_python_direct
if not exist ".tools" mkdir ".tools"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$ProgressPreference = 'SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
  "$url = 'https://www.python.org/ftp/python/3.12.11/python-3.12.11-amd64.exe';" ^
  "$exe = Join-Path (Get-Location) '.tools\python-installer.exe';" ^
  "Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing"
if errorlevel 1 exit /b 1

".tools\python-installer.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_pip=1 Include_test=0
if errorlevel 1 exit /b 1

exit /b 0


:refresh_common_paths
set "PATH=%LOCALAPPDATA%\Programs\Python\Launcher;%LOCALAPPDATA%\Programs\Python\Python313;%LOCALAPPDATA%\Programs\Python\Python313\Scripts;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%LOCALAPPDATA%\Programs\Python\Python311;%LOCALAPPDATA%\Programs\Python\Python311\Scripts;%LOCALAPPDATA%\Programs\Python\Python310;%LOCALAPPDATA%\Programs\Python\Python310\Scripts;%LOCALAPPDATA%\Microsoft\WindowsApps;%ProgramFiles%\Python313;%ProgramFiles%\Python313\Scripts;%ProgramFiles%\Python312;%ProgramFiles%\Python312\Scripts;%ProgramFiles%\Python311;%ProgramFiles%\Python311\Scripts;%ProgramFiles%\Python310;%ProgramFiles%\Python310\Scripts;%PATH%"
exit /b 0


:ensure_ffmpeg
set "FFMPEG_BIN="

where ffmpeg >nul 2>nul
if not errorlevel 1 (
    where ffprobe >nul 2>nul
    if not errorlevel 1 (
        echo FFmpeg listo.
        exit /b 0
    )
)

if "%WINGET_AVAILABLE%"=="1" (
    echo.
    echo FFmpeg no esta instalado. Instalando FFmpeg con winget...
    winget install --id Gyan.FFmpeg -e --source winget --accept-package-agreements --accept-source-agreements
    call :refresh_common_paths

    where ffmpeg >nul 2>nul
    if not errorlevel 1 (
        where ffprobe >nul 2>nul
        if not errorlevel 1 (
            echo FFmpeg listo.
            exit /b 0
        )
    )
)

rem Si winget no esta disponible o no dejo FFmpeg en el PATH actual,
rem se descarga una copia local reutilizable dentro de .tools.
if exist ".tools\ffmpeg" (
    for /f "delims=" %%D in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$f = Get-ChildItem -Path '.tools\ffmpeg' -Filter 'ffmpeg.exe' -Recurse -File ^| Select-Object -First 1; if ($f) { $f.DirectoryName }"') do set "FFMPEG_BIN=%%D"
)

if not defined FFMPEG_BIN (
    echo.
    echo Descargando copia local de FFmpeg...

    if not exist ".tools" mkdir ".tools"
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$ErrorActionPreference = 'Stop';" ^
      "$ProgressPreference = 'SilentlyContinue';" ^
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
      "$url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';" ^
      "$zip = Join-Path (Get-Location) '.tools\ffmpeg.zip';" ^
      "$dest = Join-Path (Get-Location) '.tools\ffmpeg';" ^
      "Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing;" ^
      "if (Test-Path $dest) { Remove-Item $dest -Recurse -Force };" ^
      "Expand-Archive -Path $zip -DestinationPath $dest -Force;" ^
      "Remove-Item $zip -Force"
    if errorlevel 1 exit /b 1

    for /f "delims=" %%D in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$f = Get-ChildItem -Path '.tools\ffmpeg' -Filter 'ffmpeg.exe' -Recurse -File ^| Select-Object -First 1; if ($f) { $f.DirectoryName }"') do set "FFMPEG_BIN=%%D"
)

if not defined FFMPEG_BIN exit /b 1
set "PATH=%FFMPEG_BIN%;%PATH%"

where ffmpeg >nul 2>nul
if errorlevel 1 exit /b 1
where ffprobe >nul 2>nul
if errorlevel 1 exit /b 1

echo FFmpeg listo.
exit /b 0


:error_powershell
echo.
echo [ERROR] PowerShell no esta disponible.
echo En Windows 10/11 normalmente viene instalado. Habilitalo o ejecuta este .bat en una instalacion normal de Windows.
goto :error_exit

:error_python_install
echo.
echo [ERROR] No se pudo instalar Python 3.10 o superior.
echo Revisa tu conexion a Internet o instala Python manualmente desde:
echo https://www.python.org/downloads/windows/
goto :error_exit

:error_venv
echo.
echo [ERROR] No se pudo crear el entorno virtual de Python.
goto :error_exit

:error_pip
echo.
echo [ERROR] No se pudo preparar pip. Revisa tu conexion a Internet.
goto :error_exit

:error_ytdlp
echo.
echo [ERROR] No se pudo instalar yt-dlp. Revisa tu conexion a Internet.
goto :error_exit

:error_script_missing
echo.
echo [ERROR] No se encontro descargar.py en esta carpeta.
echo Ejecuta el .bat desde la carpeta original del proyecto.
goto :error_exit

:error_ffmpeg_files
echo.
echo [ERROR] No se pudo preparar FFmpeg/FFprobe.
echo Revisa tu conexion a Internet y vuelve a ejecutar este archivo.
echo Si existe la carpeta .tools\ffmpeg, puedes borrarla para forzar una descarga limpia.
goto :error_exit

:error_exit
echo.
pause
exit /b 1
