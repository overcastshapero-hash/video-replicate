# video-replicate

> 把一个视频链接复刻成新视频。结构相似、主题可换、自动避开原 IP。

## 它做什么

你扔一个抖音/B 站/YouTube 链接(或本地视频)给 Claude Code,说**"复刻这个视频"**。它会自动:

1. 下载原视频(抖音用 f2,其他用 yt-dlp)
2. PySceneDetect 切镜 + 抽关键帧
3. 我(Claude)阅读关键帧,写分镜表
4. 询问改编方向(主体换不换、画幅、字幕)
5. 把分镜+改编要求,写成一条**中文 brief**
6. 上传源视频 + brief 给**小云雀**(字节家的 AI 视频 agent)
7. 后台轮询,生成完成自动下载产物
8. 拼接成 9:16 或 16:9 成片
9. 抽帧质检,IP 残留 / 水印 / 主体一致性

整条流水线**端到端**——你只动嘴。

## 与"agent 协作"的真相

视频里那些"项目经理 + 分镜师 + 创作者"小组,90% 是表演。真正多 agent 协作发生在**小云雀后端**(它内部已经有理解素材→拆分镜→选模型→生成→拼接的多 agent 工作流)。

本 skill 在用户侧只保留 3 个**真有用**的虚拟角色,由同一个 Claude 切换思维:

| 角色 | 何时登场 | 干什么 |
|---|---|---|
| **Director** | 出分镜 → 写 brief | 把口头要求翻译成精确的中文改编指令 |
| **Storyboard Critic** | 提交前自检 | IP 风险、连续性、画幅、字幕 4 项 checklist |
| **QC Reviewer** | 成片质检 | 抽帧对照原片,决定回炉还是放行 |

需要并行处理多种改编风格时,可用 `superpowers:dispatching-parallel-agents` 真分派 subagent —— 但简单场景默认就是同一个 Claude 切换角色。

## 安装

```bash
git clone <repo-url> ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

`install.sh` 会装:
- `ffmpeg` / `yt-dlp` / `uv`(brew)
- `pipx` + `python@3.12`(brew)
- `f2`(pipx,**必须 3.12,3.13 装不上**)

并检查:
- `xyq-nest-skill` 是否已在 `~/.claude/skills/xyq-nest-skill/`
- `XYQ_ACCESS_KEY` 是否在环境里

## 配置(一次性)

1. **拿小云雀 key**:打开 https://xyq.jianying.com → 用户中心 → API/Access Key,然后:
   ```bash
   echo 'export XYQ_ACCESS_KEY="ak-xxx"' >> ~/.zshrc && source ~/.zshrc
   ```

2. **抖音 Cookie**(只复刻抖音才需要):用 Chrome 访问 https://www.douyin.com 扫码登录一次,关掉窗口(Chrome 进程别退)。以后 f2 自动读 cookie。

## 使用

启动 Claude Code,直接说:

```
复刻这个视频:https://v.douyin.com/xxxxxxx/
```

或者:

```
按这个视频做一个,把主体换成熊猫:
/Users/me/Downloads/参考视频.mp4
```

Claude 会自动触发本 skill,8 段流水线一气跑完。

## 目录结构

```
video-replicate/
├── SKILL.md                  # 主流程(给 Claude 看的)
├── README.md                 # 给装的人看的(就是这个)
├── install.sh                # 一键装环境
├── scripts/
│   ├── download.sh           # 智能分流:抖音→f2,其他→yt-dlp
│   ├── split_scenes.py       # PySceneDetect 切镜+抽帧
│   ├── xyq_submit.sh         # 上传+提交小云雀
│   ├── xyq_poll.sh           # 后台轮询(配合 run_in_background)
│   ├── xyq_download.sh       # 下载产物
│   └── compose.sh            # ffmpeg 拼接+烧字幕
├── agents/
│   ├── director.md           # Director 角色 prompt
│   ├── storyboard-critic.md  # Critic 角色 prompt
│   └── qc-reviewer.md        # QC 角色 prompt
└── references/
    ├── storyboard-schema.md  # JSON 结构定义
    ├── brief-template.md     # 给小云雀的中文指令模板
    ├── join-strategy.md      # 衔接策略 + 长视频规则
    ├── legal.md              # 法律红线 + 拒绝模板
    └── install.md            # 安装疑难
```

## 已知陷阱(踩过的坑)

1. **抖音 + yt-dlp = 必失败** — 抖音要 Cookie。脚本默认走 `f2 + --auto-cookie chrome`,要求 Chrome 登录过 douyin.com。
2. **f2 在 Python 3.13 装不上** — `pydantic-core` 编译失败。`install.sh` 已用 `brew install python@3.12` 绕开。
3. **不要给小云雀写英文 prompt 或拆多段提交** — 它是端到端 agent,**一条中文指令 + 一次 submit_run** 最高效。
4. **>15 秒的整片不要直接复刻** — 默认截前 30 秒做 demo,看质量再决定。
5. **整片复刻成本不可控** — 小云雀按生成次数扣 credits,长视频可能烧几百到上千次。

## 不做什么

- ❌ 一比一克隆(侵权)
- ❌ 复制 logo / 水印 / 真人肖像 / 特定 IP 角色
- ❌ 用原片人声 / 原创音乐(BGM 必须重新生成或用免版权)

详见 `references/legal.md`。

## 路线图(按需扩展)

- [ ] 支持小红书 / B 站国际版 / Twitter 视频下载
- [ ] 替换视频引擎为 Veo / Runway / 可灵(逐镜调用模式)
- [ ] 自动生成中英文字幕(TTS + 烧录)
- [ ] BGM 库 + 智能选曲
- [ ] 一键发布到目标平台

## License

MIT
