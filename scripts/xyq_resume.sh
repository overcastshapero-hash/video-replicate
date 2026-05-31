#!/usr/bin/env bash
# 当 xyq_poll.sh 退出码=2(意图确认中断)时,用同一 thread_id 发后续消息继续
# 用法: xyq_resume.sh <WORKDIR> <FOLLOWUP_MESSAGE>
# 产出: 更新 <WORKDIR>/xyq_run.json 用新 run_id 覆盖,然后可以再跑 xyq_poll.sh

set -euo pipefail
WORKDIR="${1:?usage: xyq_resume.sh <WORKDIR> <MESSAGE>}"
MSG="${2:?usage: xyq_resume.sh <WORKDIR> <MESSAGE>}"
RUN_JSON="$WORKDIR/xyq_run.json"

[[ -f "$RUN_JSON" ]] || { echo "[resume] ❌ 没找到 xyq_run.json"; exit 2; }
[[ -n "${XYQ_ACCESS_KEY:-}" ]] || { echo "[resume] ❌ XYQ_ACCESS_KEY 未设置"; exit 4; }

SKILL_XYQ="$HOME/.claude/skills/xyq-nest-skill/scripts"
TID=$(python3 -c "import json; print(json.load(open('$RUN_JSON'))['thread_id'])")

echo "[resume] 用 thread_id=$TID 发后续消息..."
RES=$(python3 "$SKILL_XYQ/submit_run.py" --message "$MSG" --thread-id "$TID")

# 合并保留 asset_id
python3 -c "
import json, sys
old = json.load(open(sys.argv[1]))
new = json.loads(sys.argv[2])
old['run_id'] = new['run_id']
old['web_thread_link'] = new['web_thread_link']
print(json.dumps(old, ensure_ascii=False, indent=2))
" "$RUN_JSON" "$RES" > "$RUN_JSON.new" && mv "$RUN_JSON.new" "$RUN_JSON"

NEW_RUN=$(python3 -c "import json; print(json.load(open('$RUN_JSON'))['run_id'])")
echo "[resume] ✅ 新 run_id=$NEW_RUN,run.json 已更新"
echo "[resume] 下一步:bash xyq_poll.sh $WORKDIR"
