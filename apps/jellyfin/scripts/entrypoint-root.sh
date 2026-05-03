#!/bin/bash

# YT-DLP Dependency for YouTube Metadata Plugin
if [[ ! -f "/bin/yt-dlp" ]]; then
    echo "Downloading YT-DLP"
    curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64" -o /tmp/yt-dlp
    chmod a+rx /tmp/yt-dlp
    mv /tmp/yt-dlp /bin/yt-dlp
fi

# Restore original ffmpeg if a previous wrapper was in place.
# The wrapper (which stripped -hwaccel_output_format drm_prime) was needed for
# jellyfin-ffmpeg 7.0.x but breaks 7.1.x+ where drm_prime is required for RKMPP.
if [[ -f "/usr/lib/jellyfin-ffmpeg/ffmpeg.bin" ]]; then
    echo "Restoring original ffmpeg binary (removing old wrapper)"
    mv -f /usr/lib/jellyfin-ffmpeg/ffmpeg.bin /usr/lib/jellyfin-ffmpeg/ffmpeg
    chmod +x /usr/lib/jellyfin-ffmpeg/ffmpeg
fi

/jellyfin/jellyfin --ffmpeg /usr/lib/jellyfin-ffmpeg/ffmpeg
