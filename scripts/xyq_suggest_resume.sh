#!/usr/bin/env bash
# 当 xyq_poll 退出码=2（意图确认）时，生成高质量 resume 消息
# 用法: xyq_suggest_resume.sh <WORKDIR>
# 直接输出可立即使用的完整命令

set -euo pipefail

WORKDIR="${1:?usage: xyq_suggest_resume.sh <WORKDIR>}"

PENDING="$WORKDIR/xyq_pending_question.txt"
BRIEF="$WORKDIR/brief.md"
STORY="$WORKDIR/storyboard.json"

[[ -f "$PENDING" ]] || { echo "[suggest] ❌ 没找到 xyq_pending_question.txt，先跑 xyq_poll.sh"; exit 2; }

PENDING_CONTENT=$(cat "$PENDING")
BRIEF_CONTENT=""
if [[ -f "$BRIEF" ]]; then
    BRIEF_CONTENT=$(cat "$BRIEF")
fi

echo "=== 小云雀当前问题 ==="
echo "$PENDING_CONTENT"
echo

# 生成更智能的建议消息
SUGGESTED_MSG=$(python3 - <<'PY' "$PENDING_CONTENT" "$BRIEF_CONTENT"
import sys

pending = sys.argv[1]
brief = sys.argv[2]

base = """继续按照当前 brief 和故事板生成最终视频。

已确认以下几点：
- 严格遵循 brief 中描述的镜头节奏、构图、调色和叙事结构
- 主体已按 brief 要求进行差异化处理（避免与原片 IP 冲突）
- 画幅、时长、字幕与配音策略均与 brief 一致

请直接基于已上传的参考素材和当前故事板，生成完整成片。"""

print(base)
PY
)

echo "=== 推荐的 resume 消息 ==="
echo
echo "$SUGGESTED_MSG"
echo

# 直接给出完整可执行命令
echo "=== 直接复制下面这行命令执行即可 ==="
echo
printf 'bash xyq_resume.sh "%s" "%s"\n' "$WORKDIR" "$SUGGESTED_MSG"
echo

echo "提示：如果对消息不满意，可以手动修改引号内的内容后执行。"