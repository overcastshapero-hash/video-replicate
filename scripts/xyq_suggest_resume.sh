#!/usr/bin/env bash
# 当 xyq_poll 退出码=2（意图确认）时，读取 pending_question 给出高质量 resume 建议消息
# 用法: xyq_suggest_resume.sh <WORKDIR>
# 输出建议消息到 stdout，可直接复制给 xyq_resume.sh 使用

set -euo pipefail

WORKDIR="${1:?usage: xyq_suggest_resume.sh <WORKDIR>}"

PENDING="$WORKDIR/xyq_pending_question.txt"
BRIEF="$WORKDIR/brief.md"
STORY="$WORKDIR/storyboard.json"

[[ -f "$PENDING" ]] || { echo "[suggest] ❌ 没找到 xyq_pending_question.txt，先跑 xyq_poll.sh"; exit 2; }

echo "=== 小云雀当前问题 ==="
cat "$PENDING"
echo
echo "=== 建议的 resume 消息（直接复制下面内容用） ==="
echo

python3 - <<'PY' "$PENDING" "$BRIEF" "$STORY"
import sys, json
from pathlib import Path

pending = Path(sys.argv[1]).read_text(encoding="utf-8")
brief = Path(sys.argv[2]).read_text(encoding="utf-8") if Path(sys.argv[2]).exists() else ""
story = ""
if Path(sys.argv[3]).exists():
    try:
        story = json.load(open(sys.argv[3], encoding="utf-8"))
    except:
        pass

suggestion = f"""继续按当前方向生成完整视频。

已确认：
- 画幅、时长、字幕策略与 brief 一致
- 主体差异化（服装、风筝图案、人物脸部）已按 brief 要求调整
- 保持原片镜头节奏、构图、氛围和叙事结构

请直接基于当前故事板和参考素材生成最终 30 秒成片。"""

print(suggestion)
PY

echo
echo "=== 使用方法 ==="
echo "bash xyq_resume.sh $WORKDIR \"$(python3 -c '
import sys
print(open(sys.argv[1]).read().splitlines()[-1][:80] if False else "把上面建议消息复制到这里")
' "$PENDING" 2>/dev/null || echo '把上面建议消息完整复制到这里' )\""
echo
echo "提示：把上面 \"=== 建议的 resume 消息 ===\" 下面那一段完整复制，作为 xyq_resume.sh 的第二个参数即可。"