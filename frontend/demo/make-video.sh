#!/usr/bin/env bash
# Builds the narrated demo video:
#   1. voice clips from narration.json with macOS `say`
#   2. a fresh, freshly seeded app in Docker (its own project and port)
#   3. the walkthrough recorded by Playwright, each scene lasting as long as its narration
#   4. video and voice merged into output/salary-manager-demo.mp4 with ffmpeg
#
#   frontend/demo/make-video.sh            VOICE=Rishi RATE=165 frontend/demo/make-video.sh
set -euo pipefail

cd "$(dirname "$0")"
VOICE="${VOICE:-Samantha}"
RATE="${RATE:-170}"
PORT="${DEMO_PORT:-8082}"
OUT=output

rm -rf "$OUT"
mkdir -p "$OUT/audio"

echo "1/4 Generating narration with the '$VOICE' voice"
node -e 'for (const s of require("./narration.json")) console.log(s.id + "\t" + s.text)' |
  while IFS=$'\t' read -r id text; do
    # The macOS speech service occasionally hangs without a terminal: give each clip a time limit and retry.
    for attempt in 1 2 3; do
      perl -e 'alarm shift; exec @ARGV' 60 say -v "$VOICE" -r "$RATE" -o "$OUT/audio/$id.aiff" "$text" < /dev/null && break
      echo "    retrying '$id' (attempt $attempt timed out)"
      [ "$attempt" = 3 ] && { echo "say kept hanging on '$id'"; exit 1; }
    done
  done
node -e '
  const { execSync } = require("child_process")
  const durations = {}
  for (const { id } of require("./narration.json")) {
    const info = execSync(`afinfo output/audio/${id}.aiff`).toString()
    durations[id] = Number(info.match(/estimated duration: ([\d.]+)/)[1])
  }
  require("fs").writeFileSync("output/durations.json", JSON.stringify(durations, null, 2))
  const total = Object.values(durations).reduce((a, b) => a + b, 0)
  console.log(`    ${Object.keys(durations).length} clips, ${total.toFixed(0)}s of narration`)
'

echo "2/4 Starting a fresh app on port $PORT"
stop_app() { (cd ../.. && docker compose -p sm-demo down --volumes >/dev/null 2>&1) || true; }
trap stop_app EXIT
(cd ../.. && APP_PORT="$PORT" docker compose -p sm-demo up --build --detach --wait --wait-timeout 180 >/dev/null)

echo "3/4 Recording the walkthrough"
(cd .. && DEMO_BASE_URL="http://localhost:$PORT" npx playwright test -c demo/playwright.demo.config.ts)
VIDEO=$(find "$OUT/playwright" -name '*.webm' | head -1)

echo "4/4 Merging video and narration"
if ! command -v ffmpeg >/dev/null; then
  echo "ffmpeg is needed for this step (brew install ffmpeg). The silent recording is at $VIDEO"
  exit 1
fi
FILTER=$(node -e '
  const timeline = require("./output/timeline.json")
  const parts = timeline.map((s, i) => `[${i + 1}:a]adelay=${s.startMs}|${s.startMs}[a${i}]`)
  const inputs = timeline.map((_, i) => `[a${i}]`).join("")
  console.log(parts.join(";") + `;${inputs}amix=inputs=${timeline.length}:normalize=0[voice]`)
')
AUDIO_INPUTS=$(node -e 'for (const s of require("./output/timeline.json")) console.log(`-i output/audio/${s.id}.aiff`)' | tr '\n' ' ')
# shellcheck disable=SC2086
ffmpeg -loglevel error -y -i "$VIDEO" $AUDIO_INPUTS -filter_complex "$FILTER" \
  -map 0:v -map "[voice]" -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -b:a 160k -shortest \
  "$OUT/salary-manager-demo.mp4"
# Flag frames with no content after the first page load, e.g. a full reload flashing white.
BLANKS=$(./blank-frames.sh "$OUT/salary-manager-demo.mp4" 3)
if [ -n "$BLANKS" ]; then
  echo "Warning: blank frames at these seconds: $BLANKS"
fi
echo "Done: frontend/demo/$OUT/salary-manager-demo.mp4"
