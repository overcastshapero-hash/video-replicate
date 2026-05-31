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

## 它到底替你做了什么

```
你扔一个链接
   ↓
① 自动下载原视频
   ↓
② 一键截前30秒 demo + 自动生成 contact sheet（关键帧拼图）
   ↓
③ PySceneDetect 自动切镜 + 每镜3帧
   ↓
④ Claude + Director/Critic 写 brief（带 IP 避坑）
   ↓
⑤ 提交小云雀 → 自动轮询
   ↓
⑥ 遇到意图确认时，运行 xyq_suggest_resume.sh 直接给出高质量回复建议
   ↓
⑦ 自动下载 + compose.sh（自动识别横屏/竖屏，无需手写脚本）
   ↓
⑧ QC Reviewer 抽帧验收
   ↓
final.mp4 + qc_report.md + contact_sheet.jpg 给你
```

**整条管道你只动嘴 + 少量确认。**

## 你需要准备什么(一次性,5 分钟)

### 1️⃣ 装这个 skill

```bash
git clone https://github.com/overcastshapero-hash/video-replicate ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

`install.sh` 会自动装好所有依赖(ffmpeg / yt-dlp / f2 / PySceneDetect 等)。它**只读不写你的配置**,看到啥缺啥会直接告诉你。

### 2️⃣ 装「小云雀 skill」(本 skill 的视频生成引擎)

`xyq-nest-skill` 是字节家小云雀官方提供的 skill,放在 `~/.claude/skills/xyq-nest-skill/`。
没装的话,本 skill 启动时会告诉你怎么拿。

### 3️⃣ 拿一个小云雀 API Key

打开 https://xyq.jianying.com → 登录 → 用户中心找 Access Key,然后:

```bash
echo 'export XYQ_ACCESS_KEY="ak-xxx你自己的key"' >> ~/.zshrc
source ~/.zshrc
```

> 💡 **小云雀按生成次数扣 credits**。一条 30 秒 demo 大约要 30 个生成额度,新账户通常自带一定免费额度。**长视频或多轮迭代会烧得快**,记得监控余额。

### 4️⃣ (可选)抖音视频要 Chrome 登过

如果你要复刻抖音视频,**必须用 Chrome 登录过一次 douyin.com**(扫码登录 30 秒,然后关掉窗口,Chrome 进程不退)。f2 会自动读 Cookie。

> 这是抖音平台限制,不是 skill 的问题。任何工具都绕不开。

YouTube / B 站 / 本地文件不需要这步。

## 你能拿到什么

### 自动产出

每跑一条会得到一个工作目录 `~/projects/video-replicate/<run-id>/`,里面有:

| 文件 | 内容 |
|---|---|
| `source.mp4` | 自动下载的原片 |
| `source_demo_30s.mp4` | 自动截取的 30 秒 demo（默认） |
| `contact_sheet.jpg` | 关键帧拼图，一眼看清镜头结构 |
| `scenes/scenes.json` | 自动切出来的分镜列表 |
| `scenes/frames/SXX_*.jpg` | 每镜的头/中/尾关键帧 |
| `storyboard.json` | Claude 看完帧写出的分镜表(给你看,也给小云雀参考) |
| `brief.md` | 给小云雀的中文复刻指令(你能 review 也能改) |
| `clips/shot_*.mp4` | 小云雀生成的每个片段 |
| **`final.mp4`** | **拼接后的成片**(主交付) |
| `qc_report.md` | 自动质检报告 |

### 协作角色透明可见

跟那种"11 个 agent 协作"的炫技不一样,本 skill 只保留 3 个**真有用**的虚拟角色,在不同阶段切换:

- **Director** — 把你口头的改编要求,翻译成精确的中文指令
- **Storyboard Critic** — 提交前自检 IP 风险 / 连续性 / 字幕策略
- **QC Reviewer** — 成片抽帧验收,标出主体残留 / 水印 / 转场断裂

每个角色的具体职责在 `agents/` 目录,完全透明。

## 真实使用场景

### 场景 A — 抖音爆款仿做

```
你: 复刻这个视频:https://v.douyin.com/xxxxxxx/
Claude: 已下载,2 分 14 秒 / 46 镜 / 16:9。自动截前 30 秒 + contact sheet 已生成。
你: 主题别变,画幅也别变,无字幕
Claude: brief 已写,Critic 自检通过,提交小云雀...
[10-30 分钟后，可能有 1 次意图确认]
Claude: 用 suggest_resume 拿到推荐消息 → 已 resume
[出片]
Claude: ✅ 成片在 ~/projects/video-replicate/.../final.mp4
        QC 全过 + contact sheet 可快速验收
```

### 场景 B — YouTube 风格借鉴

```
你: 按这个 YouTube 视频做一个,主体换成熊猫,9:16 竖屏:
    https://youtube.com/watch?v=xxx
Claude: 已下载,15 镜 / 22 秒。自动截 demo + contact sheet。
        改编方向:主角→熊猫,画幅切 9:16。
        brief 已写,准备提交。
你: 走
[出片]
```

## 关于"能不能 100% 跑通"

诚实说:**核心痛点已大幅缓解**（30s 裁剪、横竖屏拼接、意图确认回复建议）。

仍需注意的两个外部依赖:
1. **小云雀积分**:商业 API，要钱。账户没额度就出不了片(skill 会立刻告诉你 `error code 11001`,不藏)。
2. **抖音 Cookie**:Chrome 没登过 douyin.com → 下载失败。Skill 会立刻告诉你怎么解,不让你猜。

## 不做什么

- ❌ 一比一克隆别人视频(侵权)
- ❌ 复制 logo / 水印 / 真人脸 / 特定 IP 角色形象(米老鼠/皮卡丘/明星/虚拟主播等)
- ❌ 把原片人声扒下来用 / 用原创 BGM
- ❌ 你坚持要做盗版,我会拒绝并解释,不让步

详见 `references/legal.md`。

## 适合谁

- 内容创作者:看到别人爆款想做同款
- AI 视频玩家:想批量复刻不同风格做对照实验
- 短视频运营:同一个分镜结构换不同主体跑 A/B
- 课程/广告制作:借鉴成熟视频结构,改编成自己的素材

不适合:想完全照搬别人作品的人(skill 会拒绝)。

## License

MIT — 随便用,改了源码也行,商用没问题。