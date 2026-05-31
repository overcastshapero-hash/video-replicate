#!/usr/bin/env bash
# 上传源视频 + 用 brief.md 内容作为 message 提交小云雀
# 用法: xyq_submit.sh <SOURCE_VIDEO> <BRIEF_MD> <WORKDIR>
# 产出: <WORKDIR>/xyq_run.json (含 thread_id / run_id / web_thread_link / asset_id)

set -euo pipefail
SRC="${1:?usage: xyq_submit.sh <SOURCE_VIDEO> <BRIEF_MD> <WORKDIR>}"
BRIEF="${2:?usage: xyq_submit.sh <SOURCE_VIDEO> <BRIEF_MD> <WORKDIR>}"
WORKDIR="${3:?usage: xyq_submit.sh <SOURCE_VIDEO> <BRIEF_MD> <WORKDIR>}"

[[ -n "${XYQ_ACCESS_KEY:-}" ]] || {
  echo "[xyq] ❌ XYQ_ACCESS_KEY 未设置。从 https://xyq.jianying.com 拿 key 后:"
  echo "       echo 'export XYQ_ACCESS_KEY=\"ak-xxx\"' >> ~/.zshrc && source ~/.zshrc"
  exit 4
}

SKILL_XYQ=$(dirname "$0")/../../xyq-nest-skill/scripts
[[ -d "$SKILL_XYQ" ]] || SKILL_XYQ="$HOME/.claude/skills/xyq-nest-skill/scripts"
[[ -f "$SKILL_XYQ/submit_run.py" ]] || {
  echo "[xyq] ❌ xyq-nest-skill 未安装。需要它在 ~/.claude/skills/xyq-nest-skill/"
  exit 5
}

[[ -f "$SRC" ]] || { echo "[xyq] ❌ 源视频不存在: $SRC"; exit 2; }
[[ -f "$BRIEF" ]] || { echo "[xyq] ❌ brief 不存在: $BRIEF"; exit 2; }

# 文件大小校验(skill 限 200MB)
SIZE_MB=$(du -m "$SRC" | cut -f1)
if (( SIZE_MB > 200 )); then
  echo "[xyq] ❌ 源视频 ${SIZE_MB}MB 超过 200MB 限制,请先截短"
  exit 3
fi

echo "[xyq] 上传源视频 (${SIZE_MB}MB)..."
ASSET_JSON=$(python3 "$SKILL_XYQ/upload_file.py" "$SRC")
ASSET_ID=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['asset_id'])" "$ASSET_JSON")
[[ -n "$ASSET_ID" ]] || { echo "[xyq] ❌ 上传失败: $ASSET_JSON"; exit 6; }
echo "[xyq] ✅ asset_id=$ASSET_ID"

# brief 直接作为 message
MSG="$(cat "$BRIEF")"
[[ -n "$MSG" ]] || { echo "[xyq] ❌ brief 为空"; exit 7; }

echo "[xyq] 提交任务..."
RUN_JSON=$(python3 "$SKILL_XYQ/submit_run.py" --message "$MSG" --asset-ids "$ASSET_ID")

# 把 asset_id 合并进结果文件,方便后续查询
python3 -c "
import json, sys
d = json.loads(sys.argv[1])
d['asset_id'] = sys.argv[2]
print(json.dumps(d, ensure_ascii=False, indent=2))
" "$RUN_JSON" "$ASSET_ID" > "$WORKDIR/xyq_run.json"

WEB=$(python3 -c "import json; print(json.load(open('$WORKDIR/xyq_run.json'))['web_thread_link'])")
echo "[xyq] ✅ 已提交,run.json 保存在 $WORKDIR/xyq_run.json"
echo "[xyq] 🌐 浏览器查看进度: $WEB"
