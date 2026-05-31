#!/usr/bin/env bash
# 下载视频(本地拷贝/yt-dlp/f2 智能分流),输出元数据
# 用法: download.sh <URL_OR_PATH> <WORKDIR>

set -euo pipefail

SRC="${1:?usage: download.sh <URL_OR_PATH> <WORKDIR>}"
WORKDIR="${2:?usage: download.sh <URL_OR_PATH> <WORKDIR>}"
mkdir -p "$WORKDIR"
OUT="$WORKDIR/source.mp4"

# --- 路径分流 ---
if [[ -f "$SRC" ]]; then
  echo "[download] 本地文件,直接拷贝"
  cp "$SRC" "$OUT"

elif [[ "$SRC" =~ douyin\.com|iesdouyin ]]; then
  echo "[download] 抖音链接,用 f2 + Chrome auto-cookie"
  command -v f2 >/dev/null || {
    echo "[download] ❌ f2 未安装。运行 \$SKILL_DIR/install.sh 或手动:"
    echo "         brew install python@3.12 pipx"
    echo "         pipx install --python /opt/homebrew/opt/python@3.12/bin/python3.12 f2"
    exit 4
  }
  CFG="$HOME/.config/f2/douyin.yaml"
  if [[ ! -f "$CFG" ]]; then
    mkdir -p "$(dirname "$CFG")"
    f2 dy --init-config "$CFG" >/dev/null 2>&1 || true
  fi
  TMP="$WORKDIR/_f2_dl"
  rm -rf "$TMP" && mkdir -p "$TMP"
  # 第一次跑:从 Chrome 自动取 cookie 并写入配置(yes 自动应答交互)
  set +e
  yes | f2 dy -c "$CFG" --auto-cookie chrome -M one -u "$SRC" -p "$TMP" -f no 2>&1 | tail -5
  f2_status=${PIPESTATUS[1]}
  set -e
  [[ "$f2_status" -eq 0 ]] || exit "$f2_status"
  # 再跑一次用刚保存的 cookie 真下载(第一次只是写配置)
  if [[ ! "$(find "$TMP" -name '*.mp4' -type f | head -1)" ]]; then
    f2 dy -c "$CFG" -M one -u "$SRC" -p "$TMP" -f no 2>&1 | tail -8
  fi
  RAW=$(find "$TMP" -name "*.mp4" -type f | head -1)
  if [[ -z "$RAW" ]]; then
    echo "[download] ❌ 抖音下载失败。常见原因:"
    echo "  1. Chrome 没有登录过 douyin.com — 请打开 https://www.douyin.com 扫码登录后重试"
    echo "  2. 视频已被作者删除或私密"
    echo "  3. f2 版本过老 — pipx upgrade f2"
    exit 5
  fi
  cp "$RAW" "$OUT"

else
  echo "[download] 远程链接,用 yt-dlp"
  yt-dlp \
    -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b" \
    --merge-output-format mp4 \
    -o "$OUT" --no-playlist \
    "$SRC" 2>&1 | tail -8 || {
      echo "[download] ❌ yt-dlp 失败,建议把视频文件直接拖给 Claude"
      exit 2
    }
fi

[[ -f "$OUT" ]] || { echo "[download] ❌ 未产出 source.mp4"; exit 3; }

echo
echo "[download] ✅ 下载完成"
echo "下一步推荐（长视频强烈建议先做）："
echo "  bash scripts/clip_demo.sh \"$OUT\" \"$WORKDIR\" 30"
echo "这会自动截取前 30 秒并生成 contact_sheet.jpg 便于 review"