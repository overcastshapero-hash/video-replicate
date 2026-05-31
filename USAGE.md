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
① 自动下载原视频(抖音、B站、YouTube、本地文件都行)
   ↓
② PySceneDetect 自动切镜,每个镜头抽 3 张关键帧
   ↓
③ Claude 看每张关键帧,写出完整分镜表
   ↓
④ 询问你的改编方向(主体换成啥、画幅、字幕)→ 翻译成精确指令
   ↓
⑤ 调用「小云雀」AI 视频 agent 端到端生成(字节家的)
   ↓
⑥ 自动下载产物
   ↓
⑦ ffmpeg 统一规格拼接成片(9:16 或 16:9)
   ↓
⑧ 自动质检:IP 残留 / 水印 / 主体一致性
   ↓
final.mp4 + qc_report.md 给你
```

**整条管道你只动嘴。**

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
Claude: 已下载,2 分 14 秒 / 46 镜 / 16:9。建议截前 30 秒做 demo。
你: 行,主题别变,画幅也别变,无字幕
Claude: brief 已写,Critic 自检通过,提交小云雀...
[10-30 分钟后]
Claude: ✅ 成片在 ~/projects/video-replicate/.../final.mp4
        QC 全过,IP 残留 0,水印 0,转场连续。
```

### 场景 B — YouTube 风格借鉴

```
你: 按这个 YouTube 视频做一个,主体换成熊猫,9:16 竖屏:
    https://youtube.com/watch?v=xxx
Claude: 已下载,15 镜 / 22 秒。
        改编方向:主角→熊猫,画幅切 9:16。
        brief 已写,准备提交。
你: 走
[出片]
```

### 场景 C — 本地视频复刻

```
你: 按这个文件做一条同款 → /Users/me/Downloads/参考.mp4
Claude: 文件读取成功,7 镜 / 18 秒 / 9:16。
        Director 默认走"原样结构 + 角色形象差异化避 IP"。
        确认?
你: 确认
[出片]
```

## 关于"能不能 100% 跑通"

诚实说:**整条流水线已经被实战打通**,卡点只有两个,都不是 skill 的 bug:

1. **小云雀积分**:商业 API,要钱。账户没额度就出不了片(skill 会立刻告诉你 `error code 11001`,不藏)。
2. **抖音 Cookie**:Chrome 没登过 douyin.com → 下载失败。Skill 会立刻告诉你怎么解,不让你猜。

skill 的健壮性体现在:**4 种退出码各自有明确分支**,意图确认(小云雀要你确认方案)/积分不足/限流/审核失败全部独立处理,不会把所有错误埋成"未知错误"。

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

## 路线图

- [x] 抖音 / B站 / YouTube / 本地下载
- [x] PySceneDetect 自动切镜
- [x] 小云雀端到端生成
- [x] 意图确认 / 积分不足 / 限流 4 种退出码独立处理
- [ ] 替换视频引擎为 Veo / Runway / 可灵(逐镜调用模式)
- [ ] 自动生成中英文字幕 + TTS 烧录
- [ ] BGM 库 + 智能选曲
- [ ] 一键发布到目标平台

## License

MIT — 随便用,改了源码也行,商用没问题。
