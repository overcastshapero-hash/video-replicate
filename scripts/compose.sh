#!/usr/bin/env bash
# 把 clips/shot_*.mp4 顺序拼接,混入 voice.mp3,烧录 subtitles.srt
# 自动支持 16:9 横屏和 9:16 竖屏
# 用法: compose.sh <WORKDIR> [--aspect 16:9|9:16]
#   --aspect 不传时会尝试从 demo_info.json / source_info.json 自动识别

set -euo pipefail

WORKDIR="${1:?usage: compose.sh <WORKDIR> [--aspect 16:9|9:16]}"
shift || true

ASPECT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --aspect) ASPECT="$2"; shift 2 ;;
    *) echo "[compose] 未知参数: $1"; exit 1 ;;
  esac
done

CLIPS_DIR="$WORKDIR/clips"
OUT="$WORKDIR/final.mp4"
TMP="$WORKDIR/.compose"
mkdir -p "$TMP"

shopt -s nullglob
CLIPS=( "$CLIPS_DIR"/shot_*.mp4 )
[[ ${#CLIPS[@]} -gt 0 ]] || { echo "[compose] ❌ 找不到 clips/shot_*.mp4"; exit 2; }

# 自动识别画幅（优先 demo_info，其次 source_info）
if [[ -z "$ASPECT" ]]; then
  if [[ -f "$WORKDIR/demo_info.json" ]]; then
    ASPECT=$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
w,h = d["width"],d["height"]
print("16:9" if w > h*1.2 else "9:16" if h > w*1.2 else "16:9")
' "$WORKDIR/demo_info.json")
  elif [[ -f "$WORKDIR/source_info.json" ]]; then
    ASPECT=$(python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
v = next(s for s in d["streams"] if s["codec_type"]=="video")
w,h = v["width"],v["height"]
print("16:9" if w > h*1.2 else "9:16" if h > w*1.2 else "16:9")
' "$WORKDIR/source_info.json")
  else
    ASPECT="9:16"   # 向后兼容默认
  fi
fi

if [[ "$ASPECT" == "16:9" ]]; then
  TARGET_W=1280; TARGET_H=720
  echo "[compose] 检测到横屏 16:9，目标分辨率 ${TARGET_W}x${TARGET_H}"
elif [[ "$ASPECT" == "9:16" ]]; then
  TARGET_W=720; TARGET_H=1280
  echo "[compose] 检测到竖屏 9:16，目标分辨率 ${TARGET_W}x${TARGET_H}"
else
  echo "[compose] ❌ 不支持的画幅: $ASPECT，请用 --aspect 16:9 或 9:16"
  exit 3
fi

echo "[compose] 找到 ${#CLIPS[@]} 个片段，统一规格为 ${TARGET_W}x${TARGET_H}..."

# 1. 每段重编码到统一规格
NORM_LIST="$TMP/concat.txt"
: > "$NORM_LIST"
for clip in "${CLIPS[@]}"; do
  name=$(basename "$clip" .mp4)
  norm="$TMP/${name}_norm.mp4"
  ffmpeg -y -loglevel error -i "$clip" \
    -vf "scale=${TARGET_W}:${TARGET_H}:force_original_aspect_ratio=decrease,pad=${TARGET_W}:${TARGET_H}:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=24" \
    -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
    -an \
    "$norm"
  echo "file '$norm'" >> "$NORM_LIST"
done

# 2. 拼接
CONCAT="$TMP/concat.mp4"
ffmpeg -y -loglevel error -f concat -safe 0 -i "$NORM_LIST" -c copy "$CONCAT"

# 3. 加配音（可选）
VIDEO_WITH_AUDIO="$CONCAT"
if [[ -f "$WORKDIR/voice.mp3" ]]; then
  echo "[compose] 混入配音..."
  WITH_AUDIO="$TMP/with_audio.mp4"
  ffmpeg -y -loglevel error -i "$CONCAT" -i "$WORKDIR/voice.mp3" \
    -c:v copy -c:a aac -b:a 192k -shortest "$WITH_AUDIO"
  VIDEO_WITH_AUDIO="$WITH_AUDIO"
fi

# 4. 烧录字幕（可选）
if [[ -f "$WORKDIR/subtitles.srt" ]]; then
  echo "[compose] 烧录字幕..."
  ( cd "$WORKDIR" && ffmpeg -y -loglevel error \
      -i "$VIDEO_WITH_AUDIO" \
      -vf "subtitles=subtitles.srt:force_style='FontName=PingFang SC,FontSize=22,PrimaryColour=&Hffffff&,OutlineColour=&H000000&,Outline=2,Alignment=2,MarginV=80'" \
      -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
      -c:a copy \
      "$OUT" )
else
  cp "$VIDEO_WITH_AUDIO" "$OUT"
fi

echo "[compose] ✅ 成片: $OUT"
ffprobe -v error -print_format json -show_entries format=duration:stream=width,height,r_frame_rate,codec_name "$OUT"