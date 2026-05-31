---
name: video-replicate
description: 把一个抖音/B 站/YouTube 链接(或本地视频文件)复刻成一条结构一致、主题可改编的新视频。整条流水线:下载 → 切镜 → 出分镜表 → 改编 brief → 小云雀端到端生成 → 拼接 → 质检。当用户说"复刻这个视频""按这个视频做一个""仿照这个视频""做个同款""把这个视频换成XX主题",或者发来视频链接/文件并要求据此产出新视频时触发。不要用于"只想下载视频"(用 youtube-downloader)或"只想知道视频讲什么"(用 video-transcript)——本 skill 是产出新视频。
---

# Video Replicate

参考视频 → 拆分镜 → 改编 → AI 生成 → 成片。**不是一比一克隆**,是结构复刻 + 主题改编。

## 法律红线(硬规则,优先级最高)

- ❌ 复制原片 logo、水印、品牌标识、可识别人物肖像
- ❌ 照搬原片人声/原创音乐(BGM 用免版权或重新生成)
- ❌ 复刻特定 IP 角色(吉祥物、虚拟主播、知名形象)
- ✅ 复刻"分镜节奏、镜头语言、叙事结构、视觉风格"——这些是不受版权保护的思想表达层
- 用户想做一比一盗版克隆时直接拒绝,见 `references/legal.md`

## 何时不要用这个 skill

- 用户只想**下载**视频 → `youtube-downloader`
- 用户只想**知道视频讲什么** → `video-transcript`
- 用户想做**短视频但无参考视频** → 直接 `xyq-nest-skill`,跳过本 skill

## 协作角色(virtual agents,不是真 subagent)

我在跑这条流水线时按三个角色切换思维:

| 角色 | 在哪一段登场 | 干什么 |
|---|---|---|
| **Director** | 第 ③→④ 段之间 | 把用户口头要求 + 原片视觉风格,翻译成精确的"改编 brief"(给小云雀的中文指令) |
| **Storyboard Critic** | 第 ④ 段结束、提交前 | 自检 brief 有没有 IP 风险、视觉连续性是否考虑、画幅/时长是否一致 |
| **QC Reviewer** | 第 ⑦→⑧ 段 | 抽帧对照原片,标出主体残留、转场断裂、水印漏网,决定回炉还是放行 |

需要并行处理多种改编风格时,可以真分派 subagent(用 `superpowers:dispatching-parallel-agents` 一次开多个),但**默认是同一个 Claude 切换角色**——多 agent 在简单场景下是负担。

## 工作流(8 段,每段都有验收点)

工作目录约定:`~/projects/video-replicate/<run-id>/`,`<run-id>` 用 `YYYYMMDD-HHMM-<短描述>`。

### ① 下载

```bash
bash $SKILL_DIR/scripts/download.sh <URL_OR_PATH> <WORKDIR>
```

智能分流:
- **抖音链接** → 用 `f2`(必须用户 Chrome 登过 douyin.com,Cookie 自动读)
- **YouTube / B 站 / 其他** → 用 `yt-dlp`
- **本地文件路径** → 直接拷贝

输出:`source.mp4` + `source_info.json`(ffprobe 元数据)

**抖音失败的兜底**:告诉用户"麻烦在 Chrome 里登录一次 douyin.com 再重试"。这是一次性配置,以后任何抖音链接都通。

### ② 切镜 + 抽关键帧

```bash
$SKILL_DIR/scripts/split_scenes.py <WORKDIR>/source.mp4 <WORKDIR>/scenes
```

PySceneDetect 自动切镜,每镜抽 3 帧(头/中/尾)。

输出:`scenes/scenes.json`、`scenes/frames/S{NN}_{head|mid|tail}.jpg`

异常处理:
- 镜头数 < 3 → 提示参考片不合适
- 镜头数 > 30 → 提示**强烈建议截取片段做 demo**,整片复刻成本高

### ③ 出分镜表(Director 上场)

读 `scenes/frames/` 里每镜的关键帧,按 `references/storyboard-schema.md` 写 `storyboard.json`。

每个分镜必须填:`id, start, end, visual_summary, camera, subject, motion, audio, reference_frame`。

`join_strategy` 默认 `tail_frame_to_next_first_frame`,把转场紧的位置标进 `critical_join_points`。

### ④ 改编 brief(Director 收尾)

询问用户两件事(只问一次,默认走推荐):
1. **改编方向** — 主体/主题换不换?(默认:原样结构复刻,只替换 IP 边界元素)
2. **画幅与时长** — 保持原画幅或切换?(默认:同原片)

把答案 + storyboard 摘要,写成一段**中文指令**(给小云雀的 `message`),保存到 `brief.md`。

指令模板见 `references/brief-template.md`。**关键:不要写英文 prompt、不要拆成多段——小云雀是端到端 agent,简洁中文指令最高效。**

**Storyboard Critic 自检**(不通过就改 brief 再提交):
- [ ] brief 里有没有明确说"避开原 IP 的角色名/形象特征"
- [ ] 有没有声明画幅(`16:9` / `9:16`)
- [ ] 有没有说"无字幕"或"加中文字幕"
- [ ] 有没有把原片水印/logo 列进禁用

### ⑤ 小云雀端到端生成

```bash
bash $SKILL_DIR/scripts/xyq_submit.sh <WORKDIR>/source.mp4 <WORKDIR>/brief.md <WORKDIR>
```

脚本干这些事:
1. 上传源视频拿 `asset_id`
2. 读 brief.md 作为 message,调 `submit_run.py` 提交
3. 把 `thread_id` / `run_id` / `web_thread_link` 写入 `<WORKDIR>/xyq_run.json`
4. **立刻把 web_thread_link 报给用户**(让他能在浏览器实时看后端)

然后启动**后台轮询**:

```bash
bash $SKILL_DIR/scripts/xyq_poll.sh <WORKDIR>
```

用 Claude Code 的 `run_in_background=true` 启动,完成时框架自动通知,不阻塞前台。

**xyq_poll.sh 的三个退出码必须分别处理**(实战吃过的亏:小云雀经常给出"故事板/方案"后中断等用户确认,不是真完成):

| 退出码 | 含义 | 下一步 |
|---|---|---|
| **0** | 真完成,有产物 URL | 跑 xyq_download.sh |
| **2** | 意图确认中断,assistant 在问"请确认" | 读 `xyq_pending_question.txt`,把方案展示给用户;用户确认/修改后,跑 `xyq_resume.sh <WORKDIR> "<确认或修改消息>"`,再启 xyq_poll.sh 等下一轮 |
| **3** | run 结束但既无产物又无问题 — 异常 | 把 `xyq_final.json` 给用户人工判断 |
| **1** | 超时(默认 50 分钟) | 同 3 |

意图确认是**正常流程**而不是错误。小云雀的典型节奏:
1. 第 1 个 run:理解素材 → 生成故事板/参考图 → 等用户确认 (退出码 2)
2. resume 一句"确认,继续" → 第 2 个 run:逐镜生成 → 拼接 → 产物 URL (退出码 0)
3. 可能还有第 3 轮:精修。

每出现退出码 2,就停下来把 assistant 的方案给用户看,等他拍板再 resume。

最多 3 轮 resume,仍没产物 → 把 web_thread_link 给用户人工接管。

### ⑥ 下载产物

```bash
bash $SKILL_DIR/scripts/xyq_download.sh <WORKDIR>
```

从轮询日志最后一次响应里抽出所有产物 URL,调 `download_results.py` 下载到 `<WORKDIR>/clips/`。

### ⑦ 拼接成片(可选)

如果小云雀返回的是单个成片,跳过这步。
如果返回多个片段,用 `compose.sh` 统一规格拼接:

```bash
bash $SKILL_DIR/scripts/compose.sh <WORKDIR>
```

输出:`final.mp4`(默认 16:9 / 720p / 24fps;9:16 模式从 brief 推断)

### ⑧ 质检(QC Reviewer 上场)

抽 `final.mp4` 关键帧对照 `storyboard.json`,逐项检查(详见 `references/legal.md` 的检测清单):

- [ ] 主体替换无残留(原 IP 角色完全消失)
- [ ] 无原片 logo / 水印 / 品牌标识
- [ ] 无可识别真人面孔
- [ ] 转场连续、字幕(如有)对齐

写 `qc_report.md`。
- 全过关 → 把 `final.mp4` 路径 + qc 摘要交给用户
- 任一项不过关 → 改 brief 重新提交一次小云雀(最多 2 轮),仍不过则把报告给用户人工决策

## 长视频处理规则(>30 秒)

参考视频时长 > 30 秒时,**强制按以下路径**:
1. 先问用户:复刻整片还是截取片段做 demo?
2. 默认推荐"前 30 秒 demo",成本可控、能看到产出质量
3. 用户坚持整片再走,提交前明确告知"credits 消耗未知,可能要几百次生成"

## 详细参考(按需读)

- `references/storyboard-schema.md` — JSON 字段定义
- `references/brief-template.md` — 给小云雀的中文指令模板
- `references/join-strategy.md` — 跨段衔接、长视频规则
- `references/legal.md` — 法律红线 + 拒绝模板
- `references/install.md` — 给装这个 skill 的人:依赖、Cookie、key 配置

## 最终交付

跑完报告里包含:
- `final.mp4` 路径
- 对照原片:时长 / 镜头数 / 画幅
- `qc_report.md` 摘要
- 总耗时 + 小云雀任务 web_thread_link(用户可以回看)

## 已知陷阱(实战吃过的亏)

1. **抖音 + yt-dlp = 必失败**,要 Cookie。脚本默认走 f2 + Chrome auto-cookie。
2. **f2 在 Python 3.13 装不上**,要 brew 装 python@3.12 + pipx 指定 python。
3. **不要给小云雀写英文 prompt 或拆 14 段提交**——它是端到端 agent,简洁中文指令一次提交,反模式见 `xyq-nest-skill` 的"用户侧不做创作"原则。
4. **>15 秒的整片不要直接复刻整片**,默认截前 30 秒 demo 看质量再决定。
