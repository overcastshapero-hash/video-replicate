#!/usr/bin/env bash
# 把 clips/shot_*.mp4 顺序拼接,混入 voice.mp3,烧录 subtitles.srt
# 统一规格:9:16 / 720x1280 / 24fps / H.264
# 用法: compose.sh <WORKDIR>

set -euo pipefail

WORKDIR="${1:?usage: compose.sh <WORKDIR>}"
CLIPS_DIR="$WORKDIR/clips"
OUT="$WORKDIR/final.mp4"
TMP="$WORKDIR/.compose"
mkdir -p "$TMP"

shopt -s nullglob
CLIPS=( "$CLIPS_DIR"/shot_*.mp4 )
[[ ${#CLIPS[@]} -gt 0 ]] || { echo "[compose] ❌ 找不到 clips/shot_*.mp4"; exit 2; }

echo "[compose] 找到 ${#CLIPS[@]} 个片段,统一规格..."

# 1. 每段重编码到统一规格(避免 concat 失败)
NORM_LIST="$TMP/concat.txt"
: > "$NORM_LIST"
for clip in "${CLIPS[@]}"; do
  name=$(basename "$clip" .mp4)
  norm="$TMP/${name}_norm.mp4"
  ffmpeg -y -loglevel error -i "$clip" \
    -vf "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=24" \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
    -an \
    "$norm"
  echo "file '$norm'" >> "$NORM_LIST"
done

# 2. 拼接(无音轨)
CONCAT="$TMP/concat.mp4"
ffmpeg -y -loglevel error -f concat -safe 0 -i "$NORM_LIST" -c copy "$CONCAT"

# 3. 加配音(可选)
VIDEO_WITH_AUDIO="$CONCAT"
if [[ -f "$WORKDIR/voice.mp3" ]]; then
  echo "[compose] 混入配音..."
  WITH_AUDIO="$TMP/with_audio.mp4"
  ffmpeg -y -loglevel error -i "$CONCAT" -i "$WORKDIR/voice.mp3" \
    -c:v copy -c:a aac -b:a 192k -shortest "$WITH_AUDIO"
  VIDEO_WITH_AUDIO="$WITH_AUDIO"
fi

# 4. 烧录字幕(可选)
if [[ -f "$WORKDIR/subtitles.srt" ]]; then
  echo "[compose] 烧录字幕..."
  # 用相对路径避免 subtitle filter 对绝对路径的转义问题
  ( cd "$WORKDIR" && ffmpeg -y -loglevel error \
      -i "$VIDEO_WITH_AUDIO" \
      -vf "subtitles=subtitles.srt:force_style='FontName=PingFang SC,FontSize=22,PrimaryColour=&Hffffff&,OutlineColour=&H000000&,Outline=2,Alignment=2,MarginV=80'" \
      -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
      -c:a copy \
      "final.mp4" )
else
  cp "$VIDEO_WITH_AUDIO" "$OUT"
fi

echo "[compose] ✅ 成片: $OUT"
ffprobe -v error -print_format json -show_entries format=duration:stream=width,height,r_frame_rate,codec_name "$OUT"
