#!/usr/bin/env bash
# video-replicate 环境健康检查脚本
# 用法: bash scripts/check.sh
# 用于演示前自检，或发给别人快速诊断问题

set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"

ok()    { echo -e "  ${GREEN}✅${NC} $*"; }
fail()  { echo -e "  ${RED}❌${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠️${NC} $*"; }
info()  { echo -e "  ${BLUE}ℹ️${NC} $*"; }

echo "════════════════════════════════════════════════"
echo "   video-replicate 环境自检报告"
echo "════════════════════════════════════════════════"
echo

has_error=0

# 1. 检查核心依赖
echo "【核心依赖】"

command -v ffmpeg >/dev/null 2>&1 && ok "ffmpeg 已安装" || { fail "ffmpeg 未安装"; has_error=1; }
command -v yt-dlp >/dev/null 2>&1 && ok "yt-dlp 已安装" || { fail "yt-dlp 未安装"; has_error=1; }
command -v uv >/dev/null 2>&1 && ok "uv 已安装" || { fail "uv 未安装"; has_error=1; }
command -v f2 >/dev/null 2>&1 && ok "f2 已安装" || { fail "f2 未安装（抖音下载需要）"; has_error=1; }

# 2. 检查 xyq-nest-skill
echo
echo "【小云雀依赖】"
XYQ_SKILL_DIR="$HOME/.claude/skills/xyq-nest-skill"
if [[ -f "$XYQ_SKILL_DIR/scripts/submit_run.py" ]]; then
    ok "xyq-nest-skill 已正确安装"
else
    fail "xyq-nest-skill 未找到"
    info "请确保已将 xyq-nest-skill 放在 ~/.claude/skills/xyq-nest-skill/"
    has_error=1
fi

# 3. 检查 XYQ_ACCESS_KEY
echo
echo "【认证信息】"
if [[ -n "${XYQ_ACCESS_KEY:-}" ]]; then
    ok "XYQ_ACCESS_KEY 已通过环境变量设置"
elif [[ -f ".env" ]] && grep -q "XYQ_ACCESS_KEY" .env 2>/dev/null; then
    ok "XYQ_ACCESS_KEY 已通过 .env 文件配置"
else
    fail "XYQ_ACCESS_KEY 未检测到"
    info "请执行：cp .env.example .env 然后编辑填入你的 key"
    has_error=1
fi

# 4. 检查新脚本是否存在（本次升级重点）
echo
echo "【本次升级脚本】"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for script in clip_demo.sh compose.sh xyq_suggest_resume.sh; do
    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        ok "$script 存在"
    else
        fail "$script 缺失"
        has_error=1
    fi
done

# 5. 抖音准备提示
echo
echo "【抖音下载准备】"
warn "如果要复刻抖音视频，请确保 Chrome 已登录过 douyin.com"

# 总结
echo
echo "════════════════════════════════════════════════"
if [[ $has_error -eq 0 ]]; then
    echo -e "${GREEN}✅ 环境检查通过，可以正常使用 video-replicate${NC}"
    echo
    echo "推荐演示命令："
    echo "  复刻这个视频: https://v.douyin.com/xxxxx/"
else
    echo -e "${RED}❌ 发现问题，请按上方提示修复后重试${NC}"
fi
echo "════════════════════════════════════════════════"