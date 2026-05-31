#!/usr/bin/env bash
# 轮询小云雀任务,把进度写到 status.log,完成时退出
# 用法: xyq_poll.sh <WORKDIR>
# 配合 Claude Code 的 run_in_background=true 使用 — 退出时框架自动通知
# 产出: <WORKDIR>/xyq_status.log, <WORKDIR>/xyq_final.json (最终响应)

set -uo pipefail
WORKDIR="${1:?usage: xyq_poll.sh <WORKDIR>}"
RUN_JSON="$WORKDIR/xyq_run.json"
LOG="$WORKDIR/xyq_status.log"
FINAL="$WORKDIR/xyq_final.json"

[[ -f "$RUN_JSON" ]] || { echo "[poll] ❌ 没找到 xyq_run.json,先跑 xyq_submit.sh"; exit 2; }
[[ -n "${XYQ_ACCESS_KEY:-}" ]] || { echo "[poll] ❌ XYQ_ACCESS_KEY 未设置"; exit 4; }

SKILL_XYQ="$HOME/.claude/skills/xyq-nest-skill/scripts"
TID=$(python3 -c "import json; print(json.load(open('$RUN_JSON'))['thread_id'])")
RID=$(python3 -c "import json; print(json.load(open('$RUN_JSON'))['run_id'])")

INTERVAL="${XYQ_POLL_INTERVAL:-15}"
MAX_ITER="${XYQ_POLL_MAX_ITER:-200}"   # 200 * 15s = 50 分钟兜底
: > "$LOG"

for i in $(seq 1 "$MAX_ITER"); do
  RAW=$(python3 "$SKILL_XYQ/get_thread.py" --thread-id "$TID" --run-id "$RID" --after-seq 0 2>&1)
  echo "$RAW" > "$FINAL"
  TS=$(date +%H:%M:%S)
  PARSE=$(RAW_TXT="$RAW" python3 <<'PY'
import os, json, re, sys
raw = os.environ["RAW_TXT"]
i = raw.find("{")
if i < 0:
    print(f"NOJSON|0|0||{raw[:80]!r}")
    sys.exit()
prefix = raw[:i].strip()
try: d = json.loads(raw[i:])
except Exception as e:
    print(f"BADJSON|0|0||{e}")
    sys.exit()
msgs = d.get("messages", [])
stage = ""; status_msg = ""
urls = []
def walk(o):
    if isinstance(o, dict):
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
    elif isinstance(o, str):
        if o.startswith("http") and any(ext in o for ext in [".mp4",".mov",".png",".jpg",".jpeg",".webm"]):
            urls.append(o)
for m in msgs:
    c = m.get("content")
    if not isinstance(c, list): continue
    for it in c:
        st = it.get("sub_type","")
        data = it.get("data")
        if isinstance(data, str):
            try: dj = json.loads(data)
            except: dj = {}
        else:
            dj = data or {}
        if st == "biz/x_data_intermediate_message":
            stage = dj.get("stage","") or stage
            status_msg = dj.get("message","") or dj.get("loading_text","") or status_msg
        walk(dj)
urls = sorted(set(urls))
print(f"{prefix}|{len(msgs)}|{len(urls)}|{stage}|{status_msg}")
for u in urls: print(f"URL:{u}")
PY
)
  HEAD=$(echo "$PARSE" | head -1)
  echo "[$TS iter=$i] $HEAD" >> "$LOG"
  URLS=$(echo "$PARSE" | grep "^URL:" | sed 's/^URL://')
  if [[ -n "$URLS" ]]; then
    echo "[$TS] ✅ DONE: 检测到产物 URL" >> "$LOG"
    echo "$URLS" > "$WORKDIR/xyq_urls.txt"
    exit 0
  fi
  if echo "$HEAD" | grep -qi "本次创作完成\|run_succeeded\|completed"; then
    echo "[$TS] ✅ 状态完成" >> "$LOG"
    exit 0
  fi
  sleep "$INTERVAL"
done
echo "[$(date +%H:%M:%S)] ⏱ 兜底超时退出 (${MAX_ITER} * ${INTERVAL}s)" >> "$LOG"
exit 1
