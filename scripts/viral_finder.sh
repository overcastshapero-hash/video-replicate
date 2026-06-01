#!/usr/bin/env bash
# 爆款检索:输入关键词 → 输出 Top N 爆款链接 + 数据
# 用法: viral_finder.sh <PLATFORM> <KEYWORD> [TOP_N] [OUT_DIR]
#   PLATFORM: xhs (小红书) | douyin (抖音, TODO)
#   KEYWORD : 检索词
#   TOP_N   : 取前 N 条,默认 10
#   OUT_DIR : 输出目录,默认 ~/projects/video-replicate/viral-<timestamp>/
#
# 产出: <OUT_DIR>/viral.json + viral.md(给人看的列表)

set -euo pipefail

PLATFORM="${1:?usage: viral_finder.sh <xhs|douyin> <keyword> [top_n] [out_dir]}"
KEYWORD="${2:?usage: viral_finder.sh <xhs|douyin> <keyword> [top_n] [out_dir]}"
TOP_N="${3:-10}"
OUT_DIR="${4:-$HOME/projects/video-replicate/viral-$(date +%Y%m%d-%H%M)-${PLATFORM}}"

mkdir -p "$OUT_DIR"

case "$PLATFORM" in
  xhs|xiaohongshu|小红书)
    command -v xhs >/dev/null || {
      echo "[viral] ❌ xhs CLI 未安装"
      echo "  装法:见 agent-reach skill 的 references/social.md"
      exit 4
    }

    # 1. 检查登录态(set +e 临时关闭,避免 pipefail + SIGPIPE 误退出)
    set +e
    PROBE=$(xhs search "test" --sort popular --json 2>&1)
    set -e
    if ! echo "$PROBE" | grep -q '"ok": true\|"items"\|"notes"'; then
      if echo "$PROBE" | grep -q "not_authenticated\|Session expired"; then
        echo "[viral] ❌ xhs 需要登录"
        echo
        echo "解决方法(任选其一):"
        echo "  A. 浏览器登录小红书 → 然后跑: xhs login"
        echo "  B. 直接扫码: xhs login --qr"
        echo
        echo "登录后重跑本命令即可。"
        exit 5
      fi
    fi

    echo "[viral] 检索小红书爆款: \"$KEYWORD\" (Top $TOP_N, sort=popular, type=video)"
    RAW="$OUT_DIR/raw.json"
    xhs search "$KEYWORD" --sort popular --type video --json > "$RAW"

    # 提取关键字段 → viral.json + viral.md
    KEYWORD_ARG="$KEYWORD" TOP_N_ARG="$TOP_N" RAW_FILE="$RAW" OUT_DIR_ARG="$OUT_DIR" python3 <<'PY'
import json, os, pathlib
raw = json.loads(pathlib.Path(os.environ["RAW_FILE"]).read_text())
items = raw.get("items") or raw.get("notes") or raw.get("data") or []
if isinstance(items, dict):
    items = items.get("items") or items.get("notes") or []
top_n = int(os.environ["TOP_N_ARG"])
out_dir = pathlib.Path(os.environ["OUT_DIR_ARG"])

simplified = []
for it in items[:top_n]:
    if not isinstance(it, dict): continue
    note_id = it.get("id") or it.get("note_id") or ""
    title = it.get("title") or it.get("display_title") or ""
    url = it.get("url") or (f"https://www.xiaohongshu.com/explore/{note_id}" if note_id else "")
    likes = it.get("liked_count") or it.get("likes") or it.get("interact_info",{}).get("liked_count") or 0
    comments = it.get("comment_count") or it.get("comments") or 0
    collects = it.get("collected_count") or it.get("collects") or 0
    user = it.get("user",{}).get("nickname") or it.get("author") or ""
    simplified.append({
        "id": note_id, "title": title, "url": url,
        "likes": likes, "comments": comments, "collects": collects, "author": user,
    })

(out_dir / "viral.json").write_text(json.dumps({
    "keyword": os.environ["KEYWORD_ARG"],
    "platform": "xhs", "total": len(simplified), "items": simplified,
}, ensure_ascii=False, indent=2))

md = [f"# 爆款检索 — 小红书 — \"{os.environ['KEYWORD_ARG']}\"\n",
      f"共 {len(simplified)} 条\n",
      "| # | 标题 | 作者 | 赞 | 评 | 藏 | 链接 |",
      "|---|---|---|---|---|---|---|"]
for i, it in enumerate(simplified, 1):
    title = (it["title"] or "(无)")[:30]
    md.append(f"| {i} | {title} | {it['author']} | {it['likes']} | {it['comments']} | {it['collects']} | {it['url']} |")
(out_dir / "viral.md").write_text("\n".join(md))
print(f"[viral] ✅ 取到 {len(simplified)} 条")
print(f"[viral] 详细 JSON: {out_dir}/viral.json")
print(f"[viral] 人看的表:  {out_dir}/viral.md")
PY
    ;;

  douyin|抖音)
    echo "[viral] ⚠️ 抖音爆款检索暂未实现"
    echo "  抖音 API 反爬严,需要登录态 + 签名。三种可选实现路径:"
    echo "  1. mcporter call 'douyin.search_videos_v2(...)' (需装 mcporter + 配 douyin MCP server)"
    echo "  2. computer-use + Chrome 自动化(playwright 类)抖音网页搜索"
    echo "  3. 手动给链接,跳过爆款检索环节,直接走主流水线"
    echo
    echo "推荐当下用方案 3:从你刷到的抖音直接拿链接,本 skill 主流水线已能复刻。"
    exit 6
    ;;

  *)
    echo "[viral] ❌ 不支持的平台: $PLATFORM"
    echo "  支持: xhs | douyin"
    exit 2
    ;;
esac
