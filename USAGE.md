# video-replicate — 扔一个视频链接,产一条新视频

> 你在抖音上刷到一条特别想"做一份同款"的视频。
>
> 以前你得自己拆分镜、自己写脚本、自己跑模型、自己拼接。
>
> 现在你只用对 Claude Code 说一句:
>
> **"复刻这个视频:https://v.douyin.com/xxxxxxx/"**
>
> 剩下的它全包。

这个 skill 最核心的价值不是「一定要用小云雀出片」，而是把「爆款视频的结构、节奏、叙事逻辑」用可执行的工艺固化下来，变成高质量的 prompt 包 + 分镜资产，让你可以用任何视频/图像工具继续完成。

## 两条使用路径

### 路径一：完整小云雀执行（当前默认）
适合有小云雀额度、想要一键出片的情况。

```
你扔一个链接
   ↓
① 自动下载原视频
   ↓
② 一键截前30秒 demo + 自动生成 contact sheet（关键帧拼图）
   ↓
③ PySceneDetect 自动切镜 + 每镜3帧
   ↓
④ Claude + Director/Critic 写 brief（带 IP 避坑 + 实战硬化模板）
   ↓
⑤ 提交小云雀 → 自动轮询（支持意图确认 resume）
   ↓
⑥ 自动下载 + compose.sh（自动识别横屏/竖屏）
   ↓
⑦ QC Reviewer 抽帧验收
   ↓
final.mp4 + qc_report.md + contact_sheet.jpg 给你
```

### 路径二：结构复刻 Prompt Factory（强烈推荐作为主力，无需小云雀）
**这是把这个项目变成「可 clone 的高质量内部工具公开版」后的核心能力。**

你跑完前四步后，直接停止。拿到的资产（contact sheet + scenes + storyboard + 按 craft 框架写出的硬化 brief）已经是极高质量的复刻生产资料，可以直接扔给 Kling、即梦、海螺、Luma、本地 ComfyUI、甚至 CapCut 模板继续生成。

优点：
- 完全不依赖小云雀 credits 和排队
- 结构准确度由我们这套经过风筝等真实项目打磨的 craft + 高级模板保障
- 你可以根据手头工具自由选择生成方式（图生视频 / 关键帧控制 / 手动微调）

**详细完整参考**：请阅读 `references/prompt-factory.md`（强烈建议认真读一遍）。

## 你需要准备什么(一次性,5 分钟)

### 1️⃣ 装这个 skill

```bash
git clone https://github.com/overcastshapero-hash/video-replicate ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

`install.sh` 会自动装好所有依赖(ffmpeg / yt-dlp / f2 / PySceneDetect 等)。它**只读不写你的配置**,看到啥缺啥会直接告诉你。

### 2️⃣ （可选）装「小云雀 skill」

只在你想走路径一时需要。路径二完全不需要。

### 3️⃣ （可选）拿小云雀 API Key

同上，只路径一需要。

### 4️⃣ (可选)抖音视频要 Chrome 登过

复刻抖音视频时必须。YouTube / B 站 / 本地文件不需要。

## 你能拿到什么（两条路径通用前半部分）

每跑一条会得到一个工作目录 `~/projects/video-replicate/<run-id>/`，核心高价值产出如下：

| 文件 | 内容 | 路径一用途 | 路径二用途 |
|---|---|---|---|
| `source.mp4` + `source_demo_30s.mp4` | 原片 + 推荐 demo 片段 | 输入给小云雀 | 结构参考 |
| `contact_sheet.jpg` | 所有镜头关键帧一览 | 辅助 QC | **最重要视觉参考** |
| `scenes/scenes.json` + `scenes/frames/` | 精确切镜 + 每镜头/中/尾帧 | - | **核心资产** |
| `storyboard.json` | Claude 按工艺框架写出的分镜表 | 给小云雀 | **可直接用于其他工具** |
| `brief.md` | 按最佳模板 + craft 框架硬化后的中文指令 | 提交小云雀 | **可直接复制给 Kling/即梦等** |
| `clips/shot_*.mp4` + `final.mp4` | 生成结果 | 最终交付 | - |
| `qc_report.md` | 结构准确度检查报告 | 验收 | 可用于人工 QC |

**路径二的核心交付物就是 `contact_sheet.jpg` + `scenes/` + `storyboard.json` + `brief.md`**。这四样东西组合起来，已经是目前能公开分享的最强「爆款视频结构复刻生产包」。

### 协作角色透明可见

本 skill 只保留 3 个**真有用**的虚拟角色：

- **Director** — 把你口头的改编要求，翻译成精确的中文指令（用 craft 框架 + 高级模板）
- **Storyboard Critic** — 提交前自检 IP 风险 / 连续性 / 结构忠实度
- **QC Reviewer** — 成片抽帧验收（路径一）或帮你 review prompt 包质量（路径二）

## 路径二详细操作（推荐主力用法）

详细完整的操作指南和注意事项，请直接阅读：

**`references/prompt-factory.md`**

这里只做简要流程：

1. 正常运行 `./run.sh <视频链接>`（或手动走 download + clip_demo + split_scenes）
2. 让 Claude 用 Director + Critic 基于 contact sheet + 帧写 brief（会自动使用我们同步进来的高级模板）
3. 运行 `bash scripts/next.sh <WORKDIR>` 查看当前状态
4. 当看到 `brief.md`、`storyboard.json`、`contact_sheet.jpg` 都ready后，停止。
5. 直接把整个 `<WORKDIR>` 里的核心资产拿去给其他工具使用：
   - 把 `brief.md` 内容 + 对应关键帧扔给 Kling / 即梦 / 海螺 的图生视频或文生视频
   - 用 `scenes/frames/` 做 Image-to-Video 的参考图
   - 按 `storyboard.json` 里的时长自己后期拼接
6. 需要后期一键横/竖屏拼接时，用 `scripts/compose.sh`（它不依赖小云雀）

这个路径下，你真正 clone 到的，是「高质量视频结构复刻的方法论 + 经过实战打磨的 prompt 工艺」，而不是对某个单一视频模型的依赖。

## 真实使用场景

### 场景 A — 抖音爆款仿做（路径一或二都可）

### 场景 B — YouTube 风格借鉴 + 用其他工具出片（路径二最优）

你想复刻某个 YouTube 视频的结构和节奏，但不想/不能用小云雀：

```
你: 按这个 YouTube 视频做一个结构复刻，主体换成熊猫，9:16 竖屏: https://youtube.com/...
Claude: 已下载，自动截 demo + contact sheet + 按 craft 框架写出硬化 brief + storyboard。
你: 好，brief 和 contact sheet 给我，我用 Kling 出片。
Claude: 已保存到 workdir。你可以直接把 brief.md 内容 + 对应帧扔给 Kling。
```

### 场景 C — 批量实验不同风格/工具

用同一套分镜 + brief 包，分别扔给不同视频模型做 A/B，研究哪个工具最吃这套结构。

## 关于"能不能 100% 跑通"

诚实说：
- 路径一的核心痛点是小云雀 credits。
- 路径二的核心价值已经固化在 repo 里（craft + 高级模板），**不需要任何外部视频模型就能获得极高质量的复刻生产资料**。

仍需注意：抖音下载需要 Chrome Cookie（skill 会明确告诉你）。

## 不做什么

- ❌ 一比一克隆别人视频(侵权)
- ❌ 复制 logo / 水印 / 真人脸 / 特定 IP 角色形象
- ❌ 把原片人声扒下来用 / 用原创 BGM
- ❌ 你坚持要做盗版，我会拒绝并解释

详见 `references/legal.md`。

## 适合谁

- 内容创作者: 看到别人爆款想做同款（不管用什么生成工具）
- AI 视频玩家: 想批量复刻不同风格做对照实验
- 想把「视频结构复刻方法论」沉淀成自己可复用的内部工具的人

## License

MIT — 随便用，改了源码也行，商用没问题。

---

**最近一次重大升级**：把经过真实项目（风筝等）打磨的《视频结构复刻工艺决策框架》 + 多套高级 brief 模板完整同步进公开仓库，使知识完整度大幅提升。现在 clone 这个 repo，你拿到的已经是目前能公开的最高质量「爆款视频结构复刻内部工具」版本。