# video-replicate

> **扔一个视频链接给 Claude Code,自动复刻成结构一致、主题可换的新视频。**
> 仅限视觉驱动型(AI 短片、MV、广告、纯运镜、视觉创意)——不做口播/解说类。

---

## 30 秒看懂它在干什么

```
你扔链接                                                   你拿到
──────                                                    ──────
抖音 / B站 / YouTube / 本地文件                          final.mp4    成片
   │                                                      qc_report.md 质检报告
   ▼                                                      cover_*.jpg  3 张封面候选
①下载 (f2 / yt-dlp,智能分流抖音)                        META.md      标题+文案+tag
   │
②切镜 (PySceneDetect 自动 + 每镜 3 帧 + contact sheet)
   │
③Claude·Director  看帧写 storyboard.json
   │
④Claude·Director  写中文 brief.md (硬化模板,防漂移)
   │
⑤Claude·Critic    自检 IP / 连续性 / 字幕策略
   │
⑥小云雀 API       端到端生成 (意图确认中断自动处理)
   │
⑦ffmpeg 拼接     16:9 / 9:16 自动识别
   │
⑧Claude·QC       抽帧验收 + 写报告
   │
⑨publish_pack    生成封面+标题+文案+tag+发布 checklist
```

整条管道你只动嘴。**唯一手动步骤:复制 publish/ 里的素材去抖音/小红书发(2 分钟)**。

---

## 两种使用路径

- **路径一(默认)**:有小云雀额度,走端到端一键出片
- **路径二**:没小云雀也能用——跑到第 ⑤ 步停下,拿 `contact_sheet.jpg` + `scenes/` + `storyboard.json` + `brief.md` 喂给 Kling / 即梦 / Veo / Runway / ComfyUI / 任意工具继续

价值不在绑定某个模型,在于**把"爆款视频的结构/节奏/叙事"固化成可执行的高质量 prompt 包 + 分镜资产**。

---

## 30 秒装好它

```bash
git clone https://github.com/overcastshapero-hash/video-replicate ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

`install.sh` 会自动装好 ffmpeg / yt-dlp / f2 / PySceneDetect 等。**只读不写你的配置**,缺啥告诉你。

## 一次性配置(5 分钟)

1. **小云雀 Access Key**(只有走路径一才需要,从 [xyq.jianying.com](https://xyq.jianying.com) → 用户中心拿):
   ```bash
   cp .env.example .env   # 编辑填入 XYQ_ACCESS_KEY
   # 或追加到 ~/.zshrc
   ```
2. **抖音视频**(只有要复刻抖音才需要)用 Chrome 登录一次 [douyin.com](https://www.douyin.com)。f2 自动读 Cookie。

> 💡 小云雀按生成次数扣 credits,一条 30s demo 约 30 个。**没额度走路径二**,本地照样出 prompt 包。

## 用法

启动 Claude Code,说一句:

```
复刻这个视频: https://v.douyin.com/xxx/
```

它自动触发 skill,8 段流水线一气跑完。

---

## 为啥它值得用

### 它做对了什么

- 🎯 **结构复刻 + 主题改编**,不是一比一克隆(规避侵权)
- 🤖 **3 个真有用的协作角色**(Director / Critic / QC),不是 11 个表演 agent
- 🔁 **4 种退出码独立处理**(意图确认 / 积分不足 / 限流 / 审核失败),不藏错误
- 🛡 **法律红线硬规则**:想做盗版克隆,skill 会拒绝
- 📦 **双路径**:有小云雀走端到端,没小云雀拿 prompt 包去任意工具

### 不做什么(看清边界)

| ❌ | 为什么 |
|---|---|
| 口播 / 解说 / 知识科普 / 做菜 / reaction / vlog | 灵魂在讲稿,skill 不做 ASR/TTS/讲稿改写 |
| 一比一盗版克隆 | 法律红线,skill 会拒绝 |
| 复制 logo / 水印 / 真人脸 / 特定 IP 角色 | 同上 |
| 自动上传到抖音/小红书 | 无公开 API,playwright 易封号;手动 2 分钟 |

## 目录速览

```
video-replicate/
├── SKILL.md                 # 主流程(Claude 看)
├── README.md                # 你正在看这里
├── USAGE.md                 # 详细使用指南 + 真实场景 + 路线图
├── install.sh / run.sh      # 一键装 + 一键开跑
├── .env.example             # 配 key 模板
├── scripts/                 # 13 个 shell/python 脚本
├── agents/                  # Director / Critic / QC 三个角色 prompt
└── references/              # 9 份按需读的详解(法律 / brief 模板 / 错误码…)
```

## 想深入

- 📖 [USAGE.md](USAGE.md) — 完整使用指南、3 个真实场景、路线图
- 🛠 [references/prompt-factory.md](references/prompt-factory.md) — 不用小云雀也能用的"Prompt Factory"路径
- 🎨 [references/brief-template.md](references/brief-template.md) — 实战硬化 brief 模板(防颜色漂移)
- ⚖️ [references/legal.md](references/legal.md) — 法律红线 + 拒绝模板

## License

MIT — 随便用,改源码、商用都行。
