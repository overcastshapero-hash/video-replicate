#!/usr/bin/env bash
# video-replicate 主入口脚本
# 用法: ./run.sh <视频链接或本地文件路径> [可选工作目录名]
#
# 目标：大幅降低使用门槛，让新用户也能比较顺地走完流程

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "用法: $0 <视频链接或本地文件> [工作目录名]"
    echo "示例: $0 https://v.douyin.com/xxxxxx/"
    echo "      $0 /path/to/video.mp4 my-demo"
    exit 1
fi

SRC="$1"
CUSTOM_NAME="${2:-}"

# 生成工作目录名
if [[ -n "$CUSTOM_NAME" ]]; then
    WORKDIR_NAME="$CUSTOM_NAME"
else
    DATE=$(date +%Y%m%d-%H%M)
    # 简单从 URL 或路径提取短描述
    BASENAME=$(basename "$SRC" | sed 's/[^a-zA-Z0-9]//g' | cut -c1-20)
    [[ -z "$BASENAME" ]] && BASENAME="video"
    WORKDIR_NAME="${DATE}-${BASENAME}"
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="$HOME/projects/video-replicate/$WORKDIR_NAME"

echo "════════════════════════════════════════════════"
echo "  video-replicate 启动"
    echo "  源: $SRC"
    echo "  工作目录: $WORKDIR"
    echo "════════════════════════════════════════════════"
    echo

mkdir -p "$WORKDIR"

# 步骤 1: 下载
echo "→ 步骤 1/3: 下载视频..."
bash "$PROJECT_ROOT/scripts/download.sh" "$SRC" "$WORKDIR"

echo
echo "→ 视频已下载到: $WORKDIR/source.mp4"

# 步骤 2: 智能处理 demo
echo
echo "→ 步骤 2/3: 处理 demo 片段..."

# 读取时长
if [[ -f "$WORKDIR/source_info.json" ]]; then
    DURATION=$(python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
print(float(d['format']['duration']))
" "$WORKDIR/source_info.json" 2>/dev/null || echo "0")
else
    DURATION=0
fi

DO_CLIP="y"

if (( $(echo "$DURATION > 35" | bc -l 2>/dev/null || echo 0) )); then
    echo "检测到视频长度 ${DURATION}s（>35s），推荐先截取 30 秒 demo 进行验证。"
    read -p "是否现在截取 30 秒 demo？ [Y/n] " -n 1 -r REPLY || true
    echo
    if [[ "$REPLY" =~ ^[Nn]$ ]]; then
        DO_CLIP="n"
    fi
fi

if [[ "$DO_CLIP" == "y" ]]; then
    echo "正在截取 30 秒 demo + 生成 contact sheet..."
    bash "$PROJECT_ROOT/scripts/clip_demo.sh" "$WORKDIR/source.mp4" "$WORKDIR" 30
    DEMO_VIDEO="$WORKDIR/source_demo_30s.mp4"
else
    echo "跳过 demo 截取，后续将使用完整 source.mp4"
    DEMO_VIDEO="$WORKDIR/source.mp4"
fi

echo
echo "→ Demo 处理完成"

# 步骤 3: 给出清晰的后续指引
echo
echo "════════════════════════════════════════════════"
echo "  前期准备已完成"
echo "════════════════════════════════════════════════"
echo
echo "当前状态："
echo "  - 源视频: $WORKDIR/source.mp4"
if [[ "$DO_CLIP" == "y" ]]; then
    echo "  - Demo 片段: $DEMO_VIDEO"
    echo "  - Contact sheet: $WORKDIR/contact_sheet.jpg （建议先看这个）"
fi
echo
echo "下一步推荐操作："
echo
echo "1. 让 Claude 基于 demo 写分镜和 brief"
    echo "   （推荐先让 Claude 看 contact_sheet.jpg + scenes 关键帧）"
echo
echo "2. 当 brief 写好后，执行："
echo "   bash $PROJECT_ROOT/scripts/xyq_submit.sh \\"
    echo "       \"$DEMO_VIDEO\" \\"
    echo "       \"$WORKDIR/brief.md\" \\"
    echo "       \"$WORKDIR\""
echo
echo "3. 提交后立即在后台运行："
echo "   bash $PROJECT_ROOT/scripts/xyq_poll.sh \"$WORKDIR\""
echo
echo "4. 任何时候想知道当前该干什么，运行："
echo "   bash $PROJECT_ROOT/scripts/next.sh \"$WORKDIR\""
echo
echo "════════════════════════════════════════════════"
echo "提示：整个流程仍然需要你在 Claude Code 中驱动，"
echo "      但现在有了更清晰的状态检查和下一步指引。"
echo "════════════════════════════════════════════════"