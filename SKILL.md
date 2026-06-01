---
name: video-replicate
description: 把一个抖音/B站/YouTube 链接(或本地视频文件)复刻成结构一致、主题可换的新视频。**仅限"视觉驱动型"视频**(AI 短片、MV、广告、纯运镜、视觉创意片)——只复刻镜头/构图/调色/节奏,不处理音频和讲稿。流水线:下载→切镜→分镜→改编 brief→小云雀 API 生成→拼接→质检。当用户说"复刻这个视频""按这个视频做一个""仿照这个视频""做个同款""把这个视频改成XX主题""抄个视频做一份",或者发来视频链接/文件并要求据此产出新视频时触发。**不要用于口播/解说/知识科普/做菜/reaction/vlog/手绘解说类视频**——这些灵魂在讲稿不在画面,本 skill 不做 ASR/TTS/讲稿改写,产出会"看着像但啥都没说"。也不要用于"只想下载视频"(用 youtube-downloader)或"只想知道视频讲什么"(用 video-transcript)。
---

# Video Replicate

参考视频 → AI 生成新片。**结构复刻 + 主题改编,不是一比一克隆。**

## 法律红线(最高优先级)

- ❌ 不复制 logo / 水印 / 真人肖像 / 特定 IP 角色
- ❌ 不用原片人声/原创音乐
- ✅ 复刻"分镜节奏、镜头语言、叙事结构、视觉风格"(思想表达层,不受版权保护)

详见 `references/legal.md`。用户想做一比一盗版克隆时直接拒绝。

## 前置检查(每次都做)

1. `XYQ_ACCESS_KEY` 在环境里 → 没有就让用户跑 `./install.sh` 或参考 `references/install.md`
2. 抖音链接 → 提醒"需要 Chrome 登过 douyin.com 一次"
3. 工作目录:`~/projects/video-replicate/<run-id>/`,`<run-id>` = `YYYYMMDD-HHMM-<短描述>`

## 当不要用

**绝对不适用的类型 — 见到这些直接拒绝并解释:**

- ❌ **口播/讲解类**(知识科普、解说、reaction、新闻评论、产品介绍)
- ❌ **手绘 + 解说类**(白板动画、漫画解说)
- ❌ **做菜 / 教程 / vlog**(灵魂在口述步骤)
- ❌ **TED 演讲 / 访谈类**

**为什么**:这些视频的信息密度全在讲稿里,画面只是配图。本 skill 不做 ASR / 讲稿改写 / TTS / 字幕重生成。强行做的产出是**"画面酷炫但什么都没说"**。

遇到上述类型,告诉用户:"本 skill 只做视觉驱动型复刻,口播类需要 `video-transcript` 拿讲稿 + 人工改写 + HeyGen/D-ID 之类的口播生成工具,本 skill 暂不端到端支持。"

**其他更精确的工具:**

- 只想下载 → `youtube-downloader`
- 只想转写文字 → `video-transcript`
- 没有参考视频 → 直接用 `xyq-nest-skill`,跳过本 skill

## 协作角色(virtual,同一个 Claude 切换 — **必须主动读 prompt**)

每个角色登场前,**Claude 必须先用 Read 工具读完对应 agents/xxx.md 再行动**。不读不切换。这不是装饰,是强制流程。

| 角色 | 在哪段登场 | 进场动作(必须执行) |
|---|---|---|
| Director | ④ 写 brief 前 | `Read agents/director.md` 全文 → 按里面的"5 件事"框架和模板写 brief → 保存到 `<WORKDIR>/brief.md` |
| Storyboard Critic | ⑤ 提交前 | `Read agents/storyboard-critic.md` 全文 → 按里面的 4 项 checklist 自检 brief → 不通过回 Director |
| QC Reviewer | ⑧ 拿到 final.mp4 后 | `Read agents/qc-reviewer.md` 全文 → 按里面的 6 项硬性检查抽帧验收 → 写 `<WORKDIR>/qc_report.md` |

**为什么强制**:这三份 agent prompt 是真实有用的检查清单,口头记"我在切换 Director 角色"等于没切。每次必须真读,才能保证你这次按角色干活。

## 推荐使用方式（最推荐）

### 方式一：使用主入口脚本（强烈推荐新用户使用）

```bash
./run.sh <视频链接或本地文件路径>
```

这个脚本会自动：
- 创建规范的工作目录
- 下载视频
- 智能判断是否需要截 30s demo（并询问你）
- 完成后给你清晰的下一步指引（支持两种路径：完整小云雀出片，或停止在高质量 prompt 包阶段用于其他工具）

之后任何时候想知道想干什么，运行：
```bash
bash scripts/next.sh <工作目录>
```

**注意**：当 brief 准备好后，`next.sh` 会同时展示原有小云雀提交路径和新路径（使用产出的 contact_sheet + scenes + storyboard + brief 去任意视频工具）。原有小云雀流程完全保留。

### 方式二：手动分步执行（进阶用户）

```
① 下载 + 智能 demo 处理   ./run.sh <链接>   （或手动调用 download + clip_demo）
② 切镜抽帧                 scripts/split_scenes.py ...
③ 写分镜 + brief           [Director + Critic]
④ 提交小云雀               scripts/xyq_submit.sh ...     （或停止于此，走 Prompt Factory 路径）
⑤ 轮询 + 意图确认处理      scripts/xyq_poll.sh + scripts/xyq_suggest_resume.sh
⑥ 下载产物 + 拼接           scripts/xyq_download.sh + scripts/compose.sh
⑦ 质检                     [QC Reviewer]
```

**长视频铁律**：超过 35 秒强烈建议先走 demo 路径。

第 ⑤ 段 `xyq_poll.sh` 用 `run_in_background=true` 启动,框架完成时通知,无需主动轮询。

## xyq_poll.sh 4 种退出码(每种必须分别处理)

| 退出码 | 含义 | 下一步 |
|---|---|---|
| **0** | 有产物 URL,真完成 | `xyq_download.sh` |
| **2** | 意图确认中断 — 小云雀给出方案等用户确认 | 运行 `bash scripts/xyq_suggest_resume.sh <WORKDIR>` 获取高质量建议消息，确认后 `xyq_resume.sh <WORKDIR> "建议消息"` |
| **3** | run 结束既无产物又无问题 | 把 `xyq_final.json` 给用户 |
| **4** | API 业务错误 | 读 `xyq_error.txt` 拿 code,查 `references/xyq-errors.md` 给方案。**11001 = 积分不足,要充值,不是 bug** |
| **1** | 超时(默认 50 分钟) | 同 3 |

意图确认(退出码 2)是**正常流程**:小云雀典型节奏是 第 1 run 出故事板→等确认→ resume → 第 2 run 真出片。最多 3 轮 resume。

## 长视频规则(>30 秒) —— 强烈推荐走 demo 路径

**默认流程（强烈推荐，几乎所有情况都应该走这条路）：**
1. 下载完成后，**立即执行**：
   ```bash
   bash scripts/clip_demo.sh <WORKDIR>/source.mp4 <WORKDIR> 30
   ```
   这会自动生成 `source_demo_30s.mp4` + 高质量 `contact_sheet.jpg`。

2. 后面所有步骤（切镜 → 分镜 → brief → 生成）全部基于这个 demo 进行。

3. 只有当你对 30s demo 的效果非常满意后，才考虑生成整片（并提前做好 credits 消耗的心理准备）。

## 最终交付

报告含:`final.mp4` 路径 / 原片对照(时长/镜头数/画幅) / `qc_report.md` / 小云雀 web_thread_link。

## 可选扩展段(独立脚本,主流水线不依赖它们)

### 前置:爆款检索 — `scripts/viral_finder.sh`

不知道复刻哪条?用关键词找 Top N 爆款列表:

```bash
bash scripts/viral_finder.sh xhs "AI 工具" 10      # 小红书,xhs CLI 直接出 JSON,需登录一次
bash scripts/viral_finder.sh douyin "..." 10       # 抖音,脚本输出引导后 Claude 接管
```

**小红书路径**:`xhs CLI` 已装好,登录后直接出 `viral.json` + `viral.md`。

**抖音路径**(设计妥协):抖音搜索 API 反爬严,所有第三方 MCP server 都靠 reverse engineering 维护,寿命短;且 MCP 工具无法从 shell 调用。脚本退化为**引导 Claude 接管**:

1. 脚本输出明确指令 + 建好 `<OUT_DIR>/_claude_handoff.md`
2. **Claude 检测到 `_claude_handoff.md` 后,主动用 `firecrawl_search` 或 `firecrawl_scrape` 抓抖音搜索结果**
3. 失败回退:`web-search` skill(本地 Chrome)→ 实在不行告诉用户"本次失败,请直接给链接"
4. 输出格式跟 xhs 分支保持一致(viral.json + viral.md)

挑一条链接,丢回主流水线复刻。

### 后置:发布资产包 — `scripts/publish_pack.sh`

成片就绪后,生成发布前所有手动素材(不自动上传,避免封号风险):

```bash
bash scripts/publish_pack.sh <WORKDIR>
```

产出 `publish/`:
- 3 张候选封面(从成片均匀抽帧)
- `META.md` — Claude 自动填:3 个候选标题 / 抖音文案 / 小红书文案 / tag / 推荐封面 / 最佳发布时段
- `checklist.md` — 发布前自检(法律 / 技术 / 内容 / 时机)

Claude 在脚本跑完后**自动读 brief + qc_report + 封面帧**,把 META.md 占位符填成具体内容。你拿着这堆素材去手动发,2 分钟搞定。

**为什么不自动上传**:抖音/小红书无公开发布 API,playwright 模拟容易封号;真正的瓶颈在标题/文案/封面/时段(系统化生成 30 分钟价值),不在那 2 分钟点击。

## 详细参考(按需读)

- `references/install.md` — 安装、依赖、Cookie、key 配置、已知陷阱
- `references/brief-template.md` — 给小云雀的中文 brief 模板(含**实战硬化版** + 防颜色漂移 checklist)
- `references/xiaoyunque-structure-prompt-modules.md` — 可乐高组合的 prompt 模块包(任务声明、结构锁定、反美化节奏等)
- `references/prompt-factory.md` — **路径二完整操作指南**(结构复刻 Prompt Factory,无需小云雀也能用)
- `references/video-replication-craft.md` — 完整结构复刻工艺决策框架 + 常见失败模式对策 + 真实案例
- `references/storyboard-schema.md` — JSON 结构
- `references/join-strategy.md` — 衔接策略、长视频
- `references/legal.md` — 法律红线 + 拒绝模板
- `references/xyq-errors.md` — 小云雀 API 错误码字典
- `agents/director.md` `agents/storyboard-critic.md` `agents/qc-reviewer.md` — 三个虚拟角色的工作 prompt(流程中**必须** Read)
