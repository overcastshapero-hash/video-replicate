#!/usr/bin/env bash
# 自动截取前 N 秒做 demo，并生成高质量 contact sheet（关键帧拼图）
# 用法: clip_demo.sh <source.mp4> <WORKDIR> [seconds]
# 默认 30 秒
# 产出:
#   <WORKDIR>/source_demo_XXs.mp4
#   <WORKDIR>/contact_sheet.jpg
#   <WORKDIR>/demo_info.json

set -euo pipefail

SRC="${1:?usage: clip_demo.sh <source.mp4> <WORKDIR> [seconds]}"
WORKDIR="${2:?usage: clip_demo.sh <source.mp4> <WORKDIR> [seconds]}"
DURATION="${3:-30}"

[[ -f "$SRC" ]] || { echo "[clip] ❌ 源视频不存在: $SRC"; exit 2; }

mkdir -p "$WORKDIR"

DEMO="$WORKDIR/source_demo_${DURATION}s.mp4"
CONTACT="$WORKDIR/contact_sheet.jpg"
DEMO_INFO="$WORKDIR/demo_info.json"

echo "[clip] 截取前 ${DURATION}s 做 demo..."

# 先探测原片信息
ffprobe -v error -print_format json -show_format -show_streams "$SRC" > "$WORKDIR/_src_info.json"

# 安全截取（避免关键帧对齐问题，用重新编码保证准确时长）
ffmpeg -y -loglevel error \
  -ss 0 -t "$DURATION" -i "$SRC" \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart \
  "$DEMO"

[[ -f "$DEMO" ]] || { echo "[clip] ❌ demo 视频生成失败"; exit 3; }

# 生成 demo 元数据
ffprobe -v error -print_format json -show_format -show_streams "$DEMO" > "$WORKDIR/demo_info_raw.json"

# 提取关键信息 + 生成 contact sheet（纯 ffmpeg 可靠实现，4x3 网格）
python3 - <<'PY' "$WORKDIR" "$DEMO" "$DURATION" "$CONTACT" "$DEMO_INFO"
import json, subprocess, sys
from pathlib import Path

wdir = Path(sys.argv[1])
demo = sys.argv[2]
dur = float(sys.argv[3])
contact = sys.argv[4]
info_out = sys.argv[5]

with open(wdir / "demo_info_raw.json") as f:
    d = json.load(f)

fmt = d["format"]
v = next(s for s in d["streams"] if s["codec_type"] == "video")
demo_dur = float(fmt["duration"])
w, h = int(v["width"]), int(v["height"])
orient = "横屏 16:9" if w > h * 1.2 else "竖屏 9:16" if h > w * 1.2 else "方屏"

# 12 张均匀采样（4x3 网格）
grid_cols, grid_rows = 4, 3
total = grid_cols * grid_rows
step = demo_dur / (total + 2)
times = [step * (i + 1) for i in range(total)]

thumb_w = 320
thumb_h = int(thumb_w * h / max(w, 1))

tmp_dir = wdir / ".contact_frames"
tmp_dir.mkdir(exist_ok=True)

# 抽指定时间的帧
for i, t in enumerate(times):
    fp = tmp_dir / f"f{i:02d}.jpg"
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error",
        "-ss", f"{t:.3f}", "-i", demo,
        "-vframes", "1", "-q:v", "2",
        str(fp)
    ], check=True)

# 用 ffmpeg tile 合成（先 scale 所有帧再 tile）
select_expr = "+".join(f"eq(t,{t:.3f})" for t in times)
vf = (
    f"select='{select_expr}',"
    f"scale={thumb_w}:{thumb_h}:force_original_aspect_ratio=decrease,"
    f"pad={thumb_w}:{thumb_h}:(ow-iw)/2:(oh-ih)/2,setsar=1,"
    f"tile={grid_cols}x{grid_rows}:padding=6:margin=10"
)

subprocess.run([
    "ffmpeg", "-y", "-loglevel", "error",
    "-i", demo,
    "-vf", vf,
    "-frames:v", "1", "-q:v", "2",
    contact
], check=True)

import shutil
shutil.rmtree(tmp_dir, ignore_errors=True)

# 写 demo_info.json
num, den = v.get("r_frame_rate", "24/1").split("/")
fps = round(float(num) / float(den or 1), 2)
info = {
    "source": demo,
    "duration": round(demo_dur, 2),
    "width": w,
    "height": h,
    "orientation": orient,
    "fps": fps,
    "size_mb": round(int(fmt.get("size", 0)) / 1024 / 1024, 2),
    "contact_sheet": contact,
}
with open(info_out, "w", encoding="utf-8") as f:
    json.dump(info, f, ensure_ascii=False, indent=2)

print(f"[clip] ✅ Demo: {demo}")
print(f"[clip] ✅ Contact sheet: {contact}")
print(f"[clip]    {demo_dur:.2f}s | {w}x{h} {orient} | {fps}fps | {info['size_mb']}MB")
PY

# 清理临时文件
rm -f "$WORKDIR/_src_info.json" "$WORKDIR/demo_info_raw.json" 2>/dev/null || true

echo "[clip] ✅ 完成，可继续用 source_demo_${DURATION}s.mp4 做后续流程"
ls -lh "$DEMO" "$CONTACT"