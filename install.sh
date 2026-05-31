#!/usr/bin/env bash
# video-replicate skill 一键装环境
# 装:ffmpeg / yt-dlp / Python 3.12(给 f2 用) / f2 / scenedetect(脚本里 uv run 内联,无需全局装)
# 检查:xyq-nest-skill 是否就位 / XYQ_ACCESS_KEY 是否配置 / Chrome 是否登过抖音

set -euo pipefail

GREEN="\033[0;32m"; RED="\033[0;31m"; YELLOW="\033[0;33m"; NC="\033[0m"
ok()    { echo -e "${GREEN}✅${NC} $*"; }
miss()  { echo -e "${RED}❌${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠️${NC} $*"; }

echo "═══ video-replicate skill 环境检查与安装 ═══"
echo

# 如果有本地 .env,自动 source(优先级低于 shell 已 export 的)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
  ok "读取本地 .env"
fi

# --- 系统级前置 ---
if [[ "$(uname)" != "Darwin" ]]; then
  warn "本 skill 在 macOS 上调通过;Linux/Windows 路径需要你自己适配 brew/pipx 部分。"
fi

command -v brew >/dev/null 2>&1 || {
  miss "Homebrew 未安装。先装 brew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" 
  exit 1
}
ok "Homebrew 已安装"

# --- ffmpeg / yt-dlp ---
for pkg in ffmpeg yt-dlp; do
  if command -v "$pkg" >/dev/null 2>&1; then
    ok "$pkg 已安装 ($("$pkg" -version 2>/dev/null | head -1 | cut -d' ' -f1-3 || echo OK))"
  else
    echo "安装 $pkg..."
    brew install "$pkg"
  fi
done

# --- uv (split_scenes.py 用 PEP 723 inline deps 跑) ---
if command -v uv >/dev/null 2>&1; then
  ok "uv 已安装"
else
  echo "安装 uv..."
  brew install uv
fi

# --- pipx + Python 3.12 + f2 ---
command -v pipx >/dev/null 2>&1 || { echo "安装 pipx..."; brew install pipx; }
ok "pipx 已安装"

PY312_PREFIX="$(brew --prefix python@3.12 2>/dev/null || true)"
if [[ -z "$PY312_PREFIX" || ! -x "$PY312_PREFIX/bin/python3.12" ]]; then
  echo "安装 python@3.12 (f2 在 3.13 上装不上 pydantic-core)..."
  brew install python@3.12
  PY312_PREFIX="$(brew --prefix python@3.12)"
fi
PY312="$PY312_PREFIX/bin/python3.12"
ok "python3.12 在: $PY312"

if command -v f2 >/dev/null 2>&1; then
  ok "f2 已安装 ($(f2 --version 2>&1 | head -1))"
else
  echo "用 python3.12 装 f2..."
  pipx install --python "$PY312" f2
fi

# --- xyq-nest-skill ---
XYQ_DIR="$HOME/.claude/skills/xyq-nest-skill"
if [[ -f "$XYQ_DIR/scripts/submit_run.py" ]]; then
  ok "xyq-nest-skill 已就位"
else
  miss "xyq-nest-skill 未安装。从小云雀官方拿到这个 skill 后放在 $XYQ_DIR/"
fi

# --- XYQ_ACCESS_KEY ---
if [[ -n "${XYQ_ACCESS_KEY:-}" ]]; then
  ok "XYQ_ACCESS_KEY 已配置 (长度 ${#XYQ_ACCESS_KEY})"
else
  miss "XYQ_ACCESS_KEY 未配置"
  echo "      1) 打开 https://xyq.jianying.com 登录 → 拿 Access Key"
  echo "      2) 追加到 shell 配置:"
  echo "         echo 'export XYQ_ACCESS_KEY=\"ak-xxx\"' >> ~/.zshrc && source ~/.zshrc"
fi

# --- Chrome + 抖音 Cookie 提示 ---
echo
warn "抖音功能依赖 Chrome 浏览器有登录态。如果你要复刻抖音视频:"
echo "      1) 打开 Chrome 访问 https://www.douyin.com 并扫码登录一次"
echo "      2) 关掉 Chrome 窗口(进程别退),f2 会自动读 cookie"
echo "      不打算用抖音可以跳过这步。"

# --- 烟雾测试:split_scenes.py 能跑 ---
echo
echo "═══ 烟雾测试: scripts/split_scenes.py ═══"
SMOKE=$(mktemp -d)
ffmpeg -y -loglevel error \
  -f lavfi -i "color=c=red:s=320x240:d=1.5:r=24" \
  -f lavfi -i "color=c=green:s=320x240:d=1.5:r=24" \
  -filter_complex "[0:v][1:v]concat=n=2:v=1:a=0[v]" -map "[v]" \
  -c:v libx264 -pix_fmt yuv420p "$SMOKE/in.mp4"
"$(dirname "$0")/scripts/split_scenes.py" "$SMOKE/in.mp4" "$SMOKE/out" >/dev/null 2>&1 && \
  ok "切镜脚本运行正常" || miss "切镜脚本失败 — 检查 uv 和 PySceneDetect"
rm -rf "$SMOKE"

echo
ok "安装与检查完成。"
echo
echo "════════════════════════════════════════"
echo "下一步操作建议（2026.5 最新流程）"
echo "════════════════════════════════════════"
echo
echo "1. 配置小云雀 Key（二选一）："
echo "   - 推荐：cp .env.example .env 然后编辑填入 XYQ_ACCESS_KEY"
echo "   - 或全局：echo 'export XYQ_ACCESS_KEY=\"ak-xxx\"' >> ~/.zshrc && source ~/.zshrc"
echo
echo "2. 在 Claude Code 中触发："
echo "   复刻这个视频: https://v.douyin.com/xxxxx/"
echo
echo "3. 推荐先用 30 秒 demo 验证："
echo "   系统会自动调用 clip_demo.sh + 生成 contact sheet"
echo
echo "4. 遇到小云雀意图确认（最常见卡点）："
echo "   直接运行：bash scripts/xyq_suggest_resume.sh <你的工作目录>"
echo "   复制它给出的建议消息，再用 xyq_resume.sh 继续"
echo
echo "详细使用说明见仓库 README.md 和 USAGE.md"
echo "演示/自检推荐命令："
echo "  bash scripts/check.sh          # 完整环境检查"
echo "  cat DEMO.md                    # 给老师演示时的推荐流程"
echo "════════════════════════════════════════"