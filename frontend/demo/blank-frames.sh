#!/usr/bin/env bash
# Prints time ranges (seconds) where a video shows no content at all: every pixel near white.
# Real pages always contain dark text, so their darkest pixel is far below the video white level (235).
# Usage: demo/blank-frames.sh video.mp4 [skip_seconds]
set -euo pipefail
ffmpeg -hide_banner -i "$1" -vf "signalstats,metadata=print:key=lavfi.signalstats.YMIN:file=-" -an -f null - 2>/dev/null |
  paste - - |
  awk -v skip="${2:-3}" '{
    split($3, t, ":"); split($4, y, "=")
    if (y[2] + 0 >= 230 && t[2] + 0 > skip) {
      if (start == "" || t[2] - last > 0.2) { if (start != "") printf "%.1f-%.1f ", start, last; start = t[2] }
      last = t[2]
    }
  } END { if (start != "") printf "%.1f-%.1f", start, last }'
