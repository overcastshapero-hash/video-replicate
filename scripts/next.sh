#!/usr/bin/env bash
# video-replicate 流程状态检查 + 下一步建议
# 用法: bash scripts/next.sh <WORKDIR>
# 根据当前工作目录里的文件，告诉你下一步应该干什么

set -euo pipefail

WORKDIR="${1:?usage: scripts/next.sh <WORKDIR>}"

if [[ ! -d "$WORKDIR" ]]; then
    echo "❌ 工作目录不存在: $WORKDIR"
    exit 1
fi

echo "════════════════════════════════════"
echo "  video-replicate 流程状态检查"
echo "  目录: $WORKDIR"
echo "════════════════════════════════════"
echo

has_source=false
has_demo=false
has_scenes=false
has_storyboard=false
has_brief=false
has_run=false
has_clips=false
has_final=false

[[ -f "$WORKDIR/source.mp4" ]] && has_source=true
[[ -f "$WORKDIR/source_demo_30s.mp4" || -f "$WORKDIR/contact_sheet.jpg" ]] && has_demo=true
[[ -d "$WORKDIR/scenes" && -f "$WORKDIR/scenes/scenes.json" ]] && has_scenes=true
[[ -f "$WORKDIR/storyboard.json" ]] && has_storyboard=true
[[ -f "$WORKDIR/brief.md" ]] && has_brief=true
[[ -f "$WORKDIR/xyq_run.json" ]] && has_run=true
[[ -d "$WORKDIR/clips" && $(ls "$WORKDIR/clips"/shot_*.mp4 2>/dev/null | wc -l) -gt 0 ]] && has_clips=true
[[ -f "$WORKDIR/final.mp4" ]] && has_final=true

# 状态判断 + 建议

if $has_final; then
    echo "✅ 已完成最终成片: final.mp4"
    echo
    echo "推荐操作："
    echo "  1. 查看质检报告: cat $WORKDIR/qc_report.md"
    echo "  2. 打开 final.mp4 验收"
    echo "  3. 如需重做某部分，可从相应步骤重新开始"
    exit 0
fi

if $has_clips; then
    echo "✅ 已生成 clips/ 片段"
    echo
    echo "下一步推荐："
    echo "  bash scripts/compose.sh $WORKDIR"
    echo "(会自动识别横屏/垂屏并生成 final.mp4)"
    exit 0
fi

if $has_run; then
    echo "⏳ 已提交小云雀，正在生成中..."
    echo
    echo "推荐操作："
    echo "  bash scripts/xyq_poll.sh $WORKDIR"
    echo
    echo "如果 poll 退出码为 2（需要确认），运行："
    echo "  bash scripts/xyq_suggest_resume.sh $WORKDIR"
    exit 0
fi

if $has_brief; then
    echo "✅ brief.md 已准备好"
    echo
    echo "两条路径选择（不会影响已有方式）："
    echo
    echo "路径一（原有方式，适合有小云雀额度的用户）："
    echo "  bash scripts/xyq_submit.sh \\"
    echo "      $WORKDIR/source_demo_30s.mp4 \\"
    echo "      $WORKDIR/brief.md \\"
    echo "      $WORKDIR"
    echo
    echo "  提交后立即运行："
    echo "  bash scripts/xyq_poll.sh $WORKDIR   (后台)"
    echo
    echo "路径二（新增：结构复刻 Prompt Factory，完全不用小云雀）："
    echo "  你的高质量复刻生产资料已完整："
    echo "    - $WORKDIR/contact_sheet.jpg     (关键帧一览)"
    echo "    - $WORKDIR/scenes/               (切镜 + 每镜帧)"
    echo "    - $WORKDIR/storyboard.json       (分镜表)"
    echo "    - $WORKDIR/brief.md              (已用实战硬化模板优化)"
    echo
    echo "  直接拿走这些文件，用于 Kling / 即梦 / 海蟹 / 本地工具等任何视频/图像生成工具。"
    echo "  需要后期拼接时可用： bash scripts/compose.sh $WORKDIR"
    exit 0
fi

if $has_storyboard; then
    echo "✅ storyboard.json 已生成"
    echo
    echo "下一步："
    echo "  切换到 Director + Storyboard Critic 角色"
    echo "  撰写并自检 brief.md"
    echo
    echo "完成后运行："
    echo "  bash scripts/next.sh $WORKDIR"
    exit 0
fi

if $has_scenes; then
    echo "✅ 已完成切镜 (scenes/)"
    echo
    echo "下一步："
    echo "  切换到 Director 角色，基于 scenes/frames/ 写 storyboard.json"
    echo
    echo "完成后运行："
    echo "  bash scripts/next.sh $WORKDIR"
    exit 0
fi

if $has_demo; then
    echo "✅ 已截取 demo (source_demo_*.mp4 + contact_sheet.jpg)"
    echo
    echo "下一步推荐："
    echo "  bash scripts/split_scenes.py \\"
    echo "      $WORKDIR/source_demo_30s.mp4 \\"
    echo "      $WORKDIR/scenes"
    echo
    echo "切镜完成后运行："
    echo "  bash scripts/next.sh $WORKDIR"
    exit 0
fi

if $has_source; then
    echo "✅ 已下载 source.mp4"
    echo
    echo "下一步（长视频强烈建议）："
    echo "  bash scripts/clip_demo.sh $WORKDIR/source.mp4 $WORKDIR 30"
    echo
    echo "（会自动生成 30s demo + contact_sheet.jpg，后续流程全部基于 demo）"
    exit 0
fi

echo "当前目录状态较空"
echo
echo "推荐从头开始："
echo "  对 Claude Code 说：复刻这个视频: <链接或文件路径>"
echo
echo "或手动："
    echo "  bash scripts/download.sh <URL> $WORKDIR"