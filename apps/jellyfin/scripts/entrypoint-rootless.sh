#!/bin/bash

# YT-DLP Dependency for YouTube Metadata Plugin
if [[ ! -f "/bin/yt-dlp" ]]; then
    echo "Making /tmp/bin Directory"
    mkdir -p /tmp/bin

    echo "Downloading YT-DLP"
    curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64" -o /tmp/bin/yt-dlp
    chmod a+rx /tmp/bin/yt-dlp
fi

export PATH="/tmp/bin:$PATH"
echo "$PATH"
/jellyfin/jellyfin --ffmpeg /usr/lib/jellyfin-ffmpeg/ffmpeg
