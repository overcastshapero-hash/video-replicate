#!/usr/bin/env bash
# 把小云雀生成的产物 URL 下载到本地 clips/ 目录
# 用法: xyq_download.sh <WORKDIR>
# 依赖: <WORKDIR>/xyq_urls.txt (由 xyq_poll.sh 产出)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
if [[ -f "$ENV_FILE" && -z "${XYQ_ACCESS_KEY:-}" ]]; then
  set -a; source "$ENV_FILE"; set +a
fi
WORKDIR="${1:?usage: xyq_download.sh <WORKDIR>}"
URLS_FILE="$WORKDIR/xyq_urls.txt"
OUT_DIR="$WORKDIR/clips"

[[ -f "$URLS_FILE" ]] || {
    echo "[dl] ❌ 没找到 xyq_urls.txt"
    echo "请先确保 xyq_poll.sh 已成功完成（退出码 0）"
    exit 2
}
[[ -s "$URLS_FILE" ]] || {
    echo "[dl] ❌ xyq_urls.txt 为空"
    echo "小云雀可能没有生成有效产物，请检查 xyq_status.log 和 xyq_final.json"
    exit 3
}
[[ -n "${XYQ_ACCESS_KEY:-}" ]] || {
    echo "[dl] ❌ XYQ_ACCESS_KEY 未检测到"
    echo "请配置 Key 后再运行下载"
    exit 4
}

mkdir -p "$OUT_DIR"
SKILL_XYQ="$HOME/.claude/skills/xyq-nest-skill/scripts"
URLS=( $(cat "$URLS_FILE") )

echo "[dl] 待下载 ${#URLS[@]} 个产物..."
python3 "$SKILL_XYQ/download_results.py" \
  --urls "${URLS[@]}" \
  --output-dir "$OUT_DIR" \
  --prefix "shot" 2>&1 | tail -20

echo "[dl] ✅ 完成,产物在: $OUT_DIR"
ls -la "$OUT_DIR"