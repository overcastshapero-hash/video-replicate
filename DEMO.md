# 演示指南（推荐发给老师或演示时使用）

本文件用于快速、安全地向老师或他人展示 video-replicate 的核心能力。

## 推荐演示流程（低风险、高展示度）

### 第一步：环境自检（强烈建议先跑这个）

```bash
cd ~/.claude/skills/video-replicate
bash scripts/check.sh
```

这个脚本会清楚告诉你当前环境是否准备就绪，以及缺少什么。

### 第二步：演示命令

在 Claude Code 中直接输入：

```
复刻这个视频: https://v.douyin.com/xxxxx/   （换成任意你想演示的短视频链接）
```

推荐选择**时长在 1 分钟以内**、画面清晰、有明显镜头节奏的视频效果更好。

### 第三步：演示重点（建议按这个顺序讲）

1. **自动截 30 秒 demo + 生成 contact sheet**  
   运行后会自动调用 `clip_demo.sh`，生成 `source_demo_30s.mp4` 和 `contact_sheet.jpg`。

2. **结构理解 + IP 安全改编**  
   系统会先让 Claude（Director + Critic）写出 `brief.md`，里面明确写了“要如何差异化主体以避免侵权”。

3. **小云雀多轮处理能力**（这是本次最大亮点之一）  
   如果小云雀触发意图确认（常见情况），直接运行：
   ```bash
   bash scripts/xyq_suggest_resume.sh <对应工作目录>
   ```
   它会自动给出高质量的回复建议，大幅降低手动操作成本。

4. **最终输出**  
   展示 `final.mp4` + `qc_report.md` + `contact_sheet.jpg`

## 诚实说明（建议演示时主动提到）

- 这个工具目前需要 **Claude Code 环境** + **小云雀 API Key**。
- 抖音视频需要 Chrome 提前登录一次。
- 生成质量取决于小云雀当前模型水平，不是 100% 稳定。
- 适合有一定技术基础的内容创作者使用。

这样既展示了能力，也显得专业和诚实。

## 快速故障排除

如果演示时卡住，可以直接运行：

```bash
bash scripts/check.sh
```

它会给出最准确的诊断信息。

---

需要我再帮你准备一段更口语化的“演示时说的话”版本吗？（适合当场给老师讲解用）