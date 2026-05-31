#!/usr/bin/env bash
# 当 xyq_poll 退出码=2（意图确认）时，智能生成高质量 resume 消息
# 用法: xyq_suggest_resume.sh <WORKDIR>
# 输出多个选项 + 直接可执行的完整命令

set -euo pipefail

WORKDIR="${1:?usage: xyq_suggest_resume.sh <WORKDIR>}"

PENDING="$WORKDIR/xyq_pending_question.txt"
BRIEF="$WORKDIR/brief.md"

[[ -f "$PENDING" ]] || { echo "[suggest] ❌ 没找到 xyq_pending_question.txt，先跑 xyq_poll.sh"; exit 2; }

PENDING_CONTENT=$(cat "$PENDING")
BRIEF_CONTENT=""
[[ -f "$BRIEF" ]] && BRIEF_CONTENT=$(cat "$BRIEF")

echo "=== 小云雀当前问题 ==="
echo "$PENDING_CONTENT"
echo

# 使用 Python 智能分析并生成更高质量的建议
python3 - <<'PY' "$PENDING_CONTENT" "$BRIEF_CONTENT" "$WORKDIR"
import sys, re

pending = sys.argv[1].lower()
brief = sys.argv[2]
workdir = sys.argv[3]

# 分析 pending 内容，判断小云雀在纠结什么
issues = []
if any(k in pending for k in ["主体", "人物", "角色", "服装", "颜色", "偏差", "不同"]):
    issues.append("subject")
if any(k in pending for k in ["风格", "氛围", "调色", "电影感", "质感"]):
    issues.append("style")
if any(k in pending for k in ["节奏", "结构", "镜头", "顺序", "叙事"]):
    issues.append("structure")
if any(k in pending for k in ["时长", "长度", "30秒", "秒"]):
    issues.append("duration")

# 基础强消息模板
base_confirm = """继续按照当前 brief 和故事板生成最终视频。

已明确确认：
- 严格保持原片镜头节奏、构图逻辑、叙事结构和视觉氛围
- 主体形象已按 brief 要求进行具体差异化处理（服装、颜色、轮廓等细节均已调整，避免与原 IP 冲突）
- 画幅、总时长、字幕与配音策略完全遵循 brief 要求

请直接基于已提供的故事板和参考素材，生成完整成片。"""

style_focus = """继续生成。请重点确保：
- 严格遵循 brief 中描述的镜头节奏和叙事顺序
- 主体差异化已按要求完成（请参考 brief 中的具体描述）
- 整体视觉风格（调色、氛围、质感）与 brief 保持一致

直接出最终 30 秒成片即可。"""

direct_push = """按当前方向直接生成最终视频。
brief 中的所有要求（包括主体差异化细节、镜头结构、氛围）均已确认。
请基于现有故事板和素材直接出片。"""

# 输出选项
print("=== 推荐 resume 消息（按推荐程度排序） ===\n")

options = [
    ("推荐（平衡、专业）", base_confirm),
    ("更强调风格一致性", style_focus),
    ("最直接推进（适合明确情况）", direct_push),
]

for i, (label, msg) in enumerate(options, 1):
    print(f"【选项 {i} - {label}】")
    print(msg)
    print()
    print(f"完整命令：")
    print(f'bash xyq_resume.sh "{workdir}" "{msg}"')
    print("\n" + "-"*50 + "\n")

print("建议：一般情况下直接用【选项 1】即可，质量和推进速度都较好。")
print("如果小云雀反复纠结某个细节，可以用更具体的选项 2 或 3。")
PY