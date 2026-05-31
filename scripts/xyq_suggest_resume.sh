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

# 智能生成建议
python3 - <<'PY' "$PENDING_CONTENT" "$BRIEF_CONTENT" "$WORKDIR"
import sys

pending = sys.argv[1]
brief = sys.argv[2]
workdir = sys.argv[3]

pending_lower = pending.lower()

# 智能分析 pending 问题类型
problem_type = "general"
specific_advice = ""

if any(kw in pending_lower for kw in ["主体", "人物", "角色", "服装", "颜色", "偏差", "不同", "不像", "不一致"]):
    problem_type = "subject"
    specific_advice = "请特别注意 brief 中对主体差异化的具体描述（服装、颜色、轮廓等），严格按照 brief 执行，避免与原片人物形象重合。"
elif any(kw in pending_lower for kw in ["风格", "氛围", "调色", "质感", "电影感", "光影"]):
    problem_type = "style"
    specific_advice = "请严格保持 brief 中要求的视觉氛围和调色风格，与参考素材一致。"
elif any(kw in pending_lower for kw in ["节奏", "结构", "镜头顺序", "叙事"]):
    problem_type = "structure"
    specific_advice = "请严格遵循故事板中的镜头节奏和叙事顺序，不要改变原片结构。"
else:
    specific_advice = "请严格按照当前 brief 和故事板继续生成。"

# 三个高质量选项
option1 = f"""继续按照当前 brief 和故事板生成最终视频。

已明确确认：
- 严格保持原片镜头节奏、构图逻辑、叙事结构和视觉氛围
- 主体形象已按 brief 要求进行具体差异化处理（避免与原片 IP 冲突）
- 画幅、总时长、字幕与配音策略完全遵循 brief 要求

{specific_advice}

请直接基于已提供的故事板和参考素材，生成完整成片。"""

option2 = f"""请继续生成。重点确保以下几点：
- 严格遵循 brief 中对镜头节奏、构图和叙事结构的描述
- 主体差异化已按 brief 具体要求完成（{specific_advice}）
- 整体视觉风格与参考素材和 brief 保持高度一致

直接出最终 30 秒成片即可。"""

option3 = """按当前 brief 直接生成最终视频。
所有关键要求（镜头结构、主体差异化、氛围）均已确认。
请基于现有素材和故事板直接出片，不要再做额外调整。"""

options = [
    ("推荐（最平衡，成功率高）", option1),
    ("更强调关键约束", option2),
    ("最直接推进（适合问题已明确）", option3),
]

print("=== 推荐 resume 消息 ===\n")
for i, (label, msg) in enumerate(options, 1):
    print(f"【选项 {i} - {label}】")
    print(msg)
    print()
    print("完整可执行命令：")
    print(f'bash xyq_resume.sh "{workdir}" "{msg}"')
    print("\n" + "="*60 + "\n")

print("使用建议：")
print("- 大多数情况下直接用【选项 1】即可。")
print("- 如果小云雀反复纠结某个具体问题（如主体偏差），可以尝试【选项 2】。")
print("- 如果问题已经很明确，只是需要确认，可以用【选项 3】快速推进。")
PY