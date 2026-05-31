# video-replicate

> 扔一个视频链接给 Claude Code,自动复刻成结构一致、主题可换的新视频。

## 30 秒入门（推荐）

```bash
git clone https://github.com/overcastshapero-hash/video-replicate ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

配好小云雀 key 后，直接运行：

```bash
./run.sh "https://v.douyin.com/xxxxx/"
```

这个脚本会自动帮你完成下载 + 智能截 30s demo，并告诉你后续每一步该干什么。

任何时候想知道现在该做什么：
```bash
bash scripts/next.sh <工作目录>
```

## 配置(一次性)

### 1. 装小云雀 skill

`xyq-nest-skill` 是字节家官方提供的 skill,需要单独装在 `~/.claude/skills/xyq-nest-skill/`。
本 skill 启动时会检查,缺了会告诉你怎么补。

### 2. 拿小云雀 Access Key

打开 https://xyq.jianying.com → 登录 → 用户中心 → Access Key。

**两种配置方法,任选一种:**

**A. 写进 shell(全局生效)**
```bash
echo 'export XYQ_ACCESS_KEY="ak-xxx"' >> ~/.zshrc
source ~/.zshrc
```

**B. 写进本目录的 .env(只对本 skill 生效)**
```bash
cp .env.example .env
# 编辑 .env 填入你的 key
```

`.env` 已经在 `.gitignore` 里,不会被提交。

### 3. 抖音视频要 Chrome 登过(可选)

复刻抖音视频前,用 Chrome 打开 `https://www.douyin.com` 扫码登录一次,关掉窗口(Chrome 进程别退)。

YouTube / B 站 / 本地文件不需要这步。

## 目录速览

```
video-replicate/
├── run.sh                   # 主入口脚本（最推荐）
├── SKILL.md                 # 主流程(给 Claude 看)
├── README.md                # 你正在看的
├── USAGE.md                 # 发给别人看的完整介绍
├── install.sh               # 一键装环境
├── .env.example             # 环境变量模板(不含真 key)
├── scripts/                 # 工具脚本（含 next.sh / check.sh 等）
├── agents/                  # 3 个虚拟角色 prompt
└── references/              # 12 份详细参考(按需读)
```

## 核心理念

- **结构复刻 + 主题改编**,不是一比一克隆
- **协作角色透明**(只有 3 个真有用的,Director/Critic/QC)
- **错误码独立处理**(意图确认/积分不足/限流/审核分开)
- **法律红线硬规则**(拒绝盗版克隆)

## License

MIT
