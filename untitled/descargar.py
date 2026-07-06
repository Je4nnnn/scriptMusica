import sys
import re
import shutil
from pathlib import Path

try:
    import yt_dlp
except ImportError:
    print("\n[ERROR] No se encontró yt-dlp.")
    print("Ejecuta primero el archivo EJECUTAR_DESCARGADOR.bat para instalar dependencias.")
    input("\nPresiona ENTER para salir...")
    sys.exit(1)


# ==========================
# CONFIGURACIÓN GENERAL
# ==========================

BASE_DIR = Path(__file__).resolve().parent
DOWNLOAD_DIR = BASE_DIR / "descargas"
ARCHIVE_FILE = BASE_DIR / "historial_descargas.txt"

DOWNLOAD_DIR.mkdir(exist_ok=True)

FORMATOS = {
    "1": {
        "codec": "mp3",
        "quality": "320",
        "name": "MP3 320 kbps",
        "desc": "Recomendado para Serato: buena compatibilidad y tamaño razonable."
    },
    "2": {
        "codec": "wav",
        "quality": "0",
        "name": "WAV",
        "desc": "Archivo pesado. No mejora la calidad si la fuente viene comprimida."
    },
    "3": {
        "codec": "flac",
        "quality": "0",
        "name": "FLAC",
        "desc": "Buena opción si quieres conservar máxima calidad disponible."
    },
    "4": {
        "codec": "m4a",
        "quality": "256",
        "name": "M4A/AAC",
        "desc": "Liviano y buena calidad, aunque menos universal que MP3."
    }
}


def limpiar_url(texto: str) -> str:
    """
    Limpia comillas, espacios y caracteres innecesarios al pegar una URL.
    """
    return texto.strip().strip('"').strip("'")


def extraer_links(texto: str):
    """
    Permite pegar uno o varios links en una sola línea.
    """
    texto = limpiar_url(texto)
    links = re.findall(r"https?://\S+", texto)
    return [link.strip().strip('"').strip("'") for link in links]


def mostrar_header():
    print("=" * 70)
    print(" DESCARGADOR DE AUDIO - YOUTUBE / SOUNDCLOUD")
    print("=" * 70)
    print("Uso permitido: música propia, libre, Creative Commons o con permiso.")
    print("Los archivos quedarán dentro de la carpeta: descargas/")
    print("=" * 70)


def verificar_ffmpeg():
    ffmpeg = shutil.which("ffmpeg")
    ffprobe = shutil.which("ffprobe")

    if not ffmpeg or not ffprobe:
        print("\n[ERROR] No se detectó FFmpeg/FFprobe.")
        print("Inicia el programa mediante EJECUTAR_DESCARGADOR_WINDOWS.bat.")
        return False

    return True


def elegir_formato():
    print("\nElige formato de salida:\n")

    for key, data in FORMATOS.items():
        print(f"{key}) {data['name']}")
        print(f"   {data['desc']}")

    while True:
        opcion = input("\nOpción [1-4] | Recomendado para Serato: 1 = MP3 320: ").strip()

        if opcion == "":
            opcion = "1"

        if opcion in FORMATOS:
            formato = FORMATOS[opcion]
            print(f"\nFormato elegido: {formato['name']}")
            return formato

        print("Opción inválida. Intenta nuevamente.")


def elegir_playlist():
    print("\nSi pegas una playlist o set completo:")
    respuesta = input("¿Quieres descargar la playlist completa? [s/N]: ").strip().lower()
    return respuesta in ["s", "si", "sí", "y", "yes"]


def crear_opciones_yt_dlp(formato, descargar_playlist):
    codec = formato["codec"]
    quality = formato["quality"]

    carpeta_formato = DOWNLOAD_DIR / codec.upper()
    carpeta_formato.mkdir(parents=True, exist_ok=True)

    postprocessors = [
        {
            "key": "FFmpegExtractAudio",
            "preferredcodec": codec,
            "preferredquality": quality,
        },
        {
            "key": "FFmpegMetadata",
        }
    ]

    opciones = {
        # Mejor audio disponible desde la fuente
        "format": "bestaudio/best",

        # Nombre del archivo final
        "outtmpl": str(carpeta_formato / "%(title).180B [%(id)s].%(ext)s"),

        # Windows-friendly filenames
        "windowsfilenames": True,

        # Si es False, evita bajar playlists completas por accidente
        "noplaylist": not descargar_playlist,

        # No repetir descargas ya hechas
        "download_archive": str(ARCHIVE_FILE),

        # Reintentos útiles si falla la conexión
        "retries": 10,
        "fragment_retries": 10,
        "continuedl": True,

        # Manejo de errores
        "ignoreerrors": True,

        # Muestra progreso en consola
        "quiet": False,
        "no_warnings": False,

        # Conversión de audio
        "postprocessors": postprocessors,
    }

    return opciones


def descargar_audio(urls, formato, descargar_playlist):
    opciones = crear_opciones_yt_dlp(formato, descargar_playlist)

    print("\nIniciando descarga...")
    print("Carpeta:", DOWNLOAD_DIR)
    print("-" * 70)

    try:
        with yt_dlp.YoutubeDL(opciones) as ydl:
            ydl.download(urls)

        print("\nDescarga finalizada.")
        print(f"Revisa la carpeta: {DOWNLOAD_DIR}")

    except Exception as error:
        print("\n[ERROR] Ocurrió un problema al descargar.")
        print("Detalle:", error)
        print("\nSoluciones rápidas:")
        print("1) Vuelve a ejecutar el .bat para actualizar yt-dlp.")
        print("2) Verifica que el link sea público o que tengas acceso.")
        print("3) Si instalaste FFmpeg recién, cierra y abre de nuevo el .bat.")


def main():
    if sys.version_info < (3, 10):
        print("[ERROR] Necesitas Python 3.10 o superior.")
        input("Presiona ENTER para salir...")
        return

    mostrar_header()
    if not verificar_ffmpeg():
        input("\nPresiona ENTER para salir...")
        return

    formato = elegir_formato()
    descargar_playlist = elegir_playlist()

    while True:
        print("\n" + "=" * 70)
        entrada = input("Pega link de YouTube/SoundCloud o escribe SALIR: ").strip()

        if entrada.lower() in ["salir", "exit", "q", "quit"]:
            print("\nSaliendo...")
            break

        urls = extraer_links(entrada)

        if not urls:
            print("\nNo detecté ningún link válido. Intenta nuevamente.")
            continue

        print("\nLinks detectados:")
        for i, url in enumerate(urls, start=1):
            print(f"{i}) {url}")

        descargar_audio(urls, formato, descargar_playlist)


if __name__ == "__main__":
    main()
