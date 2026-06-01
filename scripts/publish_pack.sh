#!/usr/bin/env bash
# 发布资产包生成器:从 final.mp4 + brief.md 产出发布前所有需要的素材
# 用法: publish_pack.sh <WORKDIR>
#
# 产出 <WORKDIR>/publish/ 目录:
#   cover_01.jpg, cover_02.jpg, cover_03.jpg  3 张候选封面(从成片均匀抽帧)
#   META.md                                    待 Claude 填的标题/文案/tag 模板
#   checklist.md                               发布前自检清单
#
# Claude 负责读 brief.md / qc_report.md / 关键帧,把 META.md 填上具体内容。
# 用户拿着 publish/ 目录里的东西去手动发抖音/小红书。

set -euo pipefail

WORKDIR="${1:?usage: publish_pack.sh <WORKDIR>}"
FINAL="$WORKDIR/final.mp4"
BRIEF="$WORKDIR/brief.md"
PUB="$WORKDIR/publish"

[[ -f "$FINAL" ]] || { echo "[pub] ❌ 没找到 $FINAL,先跑完主流水线产出成片"; exit 2; }
mkdir -p "$PUB"

# 1. 用 ffmpeg 抽 3 张候选封面(片头 / 1/3 / 2/3 处)
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$FINAL")
echo "[pub] 成片时长 ${DURATION}s,抽 3 张候选封面..."
python3 - <<PY
import subprocess, os
dur = float("$DURATION")
finalp = "$FINAL"
outp = "$PUB"
positions = [max(0.3, dur*0.1), dur*0.33, dur*0.66]
for i, t in enumerate(positions, 1):
    out = f"{outp}/cover_{i:02d}.jpg"
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error",
        "-ss", f"{t:.2f}", "-i", finalp,
        "-frames:v", "1", "-q:v", "2", out,
    ], check=True)
    print(f"  cover_{i:02d}.jpg @ {t:.2f}s")
PY

# 2. 写 META.md 模板(留待 Claude 填具体内容)
cat > "$PUB/META.md" <<'EOF'
# 发布元数据(Claude 待填)

> 这份文件由 Claude 在生成后自动填充。看 brief.md / qc_report.md / cover_*.jpg,产出下面所有字段。

## 三个候选标题(对应不同情绪/角度)
1. <悬念/疑问钩子>
2. <对比/反差钩子>
3. <利益/技巧钩子>

## 抖音文案(150 字内,带 3-5 个 #tag)

```
<在这里写抖音正文>

#tag1 #tag2 #tag3 ...
```

## 小红书文案(带 emoji,分行,5-10 个标签)

```
<标题加这里(可与上面三个不同)>

<正文,2-4 段,emoji 适度>

🔖 #tag1 #tag2 #tag3 ...
```

## 推荐封面

选 cover_01 / cover_02 / cover_03 中的哪一张 + 为什么:

- [ ] cover_01 — <理由>
- [ ] cover_02 — <理由>
- [ ] cover_03 — <理由>

## 发布平台 + 时间建议

- 抖音:<建议时段,例如 工作日 12:00 / 19:30 / 21:00>
- 小红书:<建议时段,例如 工作日 11:00 / 21:00 / 22:00>
EOF

# 3. 写 checklist.md
cat > "$PUB/checklist.md" <<'EOF'
# 发布前自检 ✓

## 法律 & IP
- [ ] 成片里没有原片 logo / 水印
- [ ] 没有可识别真人面孔
- [ ] BGM 来源可追溯(免版权 / 自己生成)
- [ ] 文案没抄原作者署名

## 技术
- [ ] 时长 / 画幅符合平台要求(抖音 ≤ 60s 推荐 / 小红书视频 ≤ 5min)
- [ ] 封面清晰,主体在画面 1/3 黄金分割位
- [ ] 标题 ≤ 25 字(否则手机端会被截断)

## 内容
- [ ] 标题前 8 个字有钩子(因为预览只显示前几个字)
- [ ] 文案第 1 行能独立成立(算法看完读率)
- [ ] tag 不堆,精选 3-5 个抖音 / 5-10 个小红书

## 发布动作
- [ ] 在最佳时段发(工作日 12:00 / 19:30 / 21:00)
- [ ] 发布后 10 分钟内自己留言一条置顶引导互动
- [ ] 截图保留首小时数据,失败时复盘
EOF

echo "[pub] ✅ 发布资产包已就绪: $PUB"
ls -la "$PUB"
echo
echo "下一步:"
echo "  Claude 读 brief.md / qc_report.md / 三张 cover,把 META.md 里的占位符填上具体内容。"
echo "  你拿 cover + META.md 里的标题文案 tag 去抖音/小红书手动发布(2 分钟)。"
