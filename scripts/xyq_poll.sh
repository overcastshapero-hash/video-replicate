#!/usr/bin/env bash
# 轮询小云雀任务,把进度写到 status.log,完成时退出
# 用法: xyq_poll.sh <WORKDIR>
# 配合 Claude Code 的 run_in_background=true 使用 — 退出时框架自动通知
# 产出: <WORKDIR>/xyq_status.log, <WORKDIR>/xyq_final.json (最终响应)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
if [[ -f "$ENV_FILE" && -z "${XYQ_ACCESS_KEY:-}" ]]; then
  set -a; source "$ENV_FILE"; set +a
fi
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

  # 情况 ERR: 检测到 API 错误码(积分不足、限流、内容审核失败等)
  ERR_INFO=$(RAW_TXT="$RAW" python3 <<'PY' 2>/dev/null
import os, json
raw = os.environ["RAW_TXT"]
i = raw.find("{")
try: d = json.loads(raw[i:])
except: print(""); raise SystemExit
def walk(o):
    if isinstance(o, dict):
        if 'code' in o and 'message' in o and isinstance(o.get('code'),(int,float)):
            yield o
        for v in o.values(): yield from walk(v)
    elif isinstance(o, list):
        for v in o: yield from walk(v)
errs = []
for m in d.get("messages", []):
    c = m.get("content")
    if not isinstance(c, list): continue
    for it in c:
        if it.get("sub_type") == "biz/error":
            data = it.get("data")
            if isinstance(data, str):
                try: data = json.loads(data)
                except: continue
            if isinstance(data, dict):
                errs.append(data)
if errs:
    e = errs[-1]
    print(f"CODE={e.get('code')}|KEY={e.get('starling_key','')}|MSG={e.get('message','')}")
PY
)
  if [[ -n "$ERR_INFO" ]]; then
    echo "[$TS] ❌ API 错误: $ERR_INFO" >> "$LOG"
    echo "$ERR_INFO" > "$WORKDIR/xyq_error.txt"
    exit 4   # 退出码 4 = API 业务错误(积分不足/限流/审核等)
  fi


  # 情况 A: 检测到产物 URL — 真完成
  if [[ -n "$URLS" ]]; then
    echo "[$TS] ✅ DONE: 检测到产物 URL" >> "$LOG"
    echo "$URLS" > "$WORKDIR/xyq_urls.txt"
    exit 0
  fi

  # 情况 B: run 完成但没 URL — 几乎一定是"意图确认中断"
  # 区分真完成 vs 中断的关键:看 assistant 最后一条 text 消息是否在问问题/要确认
  if echo "$HEAD" | grep -qi "本次创作已完成\|本次创作完成\|run_succeeded\|completed"; then
    # 抽出最后一条 assistant text(确认问题或下一步指引)
    PROMPT_HEAD=$(RAW_TXT="$RAW" python3 <<'PY' 2>/dev/null
import os, json
raw = os.environ["RAW_TXT"]
i = raw.find("{")
d = json.loads(raw[i:])
last_text = ""
for m in d.get("messages", []):
    if m.get("role") != "assistant": continue
    c = m.get("content")
    if not isinstance(c, list): continue
    for it in c:
        if it.get("type") == "text":
            data = it.get("data")
            if isinstance(data, str): last_text = data
elif_kw = ("请确认", "是否", "需要先和你确认", "如果符合预期", "请回答", "请告诉我")
need_confirm = any(k in last_text for k in elif_kw)
print(f"NEED_CONFIRM={1 if need_confirm else 0}|{last_text[:200]}")
PY
)
    NEED=$(echo "$PROMPT_HEAD" | grep -o "NEED_CONFIRM=[01]" | head -1 | cut -d= -f2)
    if [[ "$NEED" == "1" ]]; then
      echo "[$TS] ⏸ 意图确认中断 — assistant 在等用户确认" >> "$LOG"
      echo "$PROMPT_HEAD" | sed 's/^NEED_CONFIRM=[01]|//' > "$WORKDIR/xyq_pending_question.txt"
      exit 2   # 退出码 2 = 需人工确认
    fi
    echo "[$TS] ✅ run 结束且无确认问题 — 视为完成(无产物 URL 异常)" >> "$LOG"
    exit 3   # 退出码 3 = run 结束但无产物,异常
  fi
  sleep "$INTERVAL"
done
echo "[$(date +%H:%M:%S)] ⏱ 兜底超时退出 (${MAX_ITER} * ${INTERVAL}s)" >> "$LOG"
exit 1
