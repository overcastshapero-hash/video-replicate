# 安装疑难

## 一键装(推荐)

```bash
git clone <repo-url> ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

`install.sh` 会按顺序装 / 检查:

| 组件 | 来源 | 用途 |
|---|---|---|
| Homebrew | 系统级 | 包管理(已装跳过) |
| ffmpeg | brew | 切镜、抽帧、拼接、烧字幕 |
| yt-dlp | brew | YouTube / B 站 / 其他平台下载 |
| uv | brew | split_scenes.py 用 PEP 723 内联依赖跑 |
| pipx | brew | Python 应用隔离安装 |
| python@3.12 | brew | f2 在 3.13 上装不上,必须 3.12 |
| f2 | pipx | 抖音无水印下载 |
| xyq-nest-skill | 手动放进 ~/.claude/skills/ | 小云雀 API 封装 |
| XYQ_ACCESS_KEY | 用户手动 export | 小云雀认证 |

## 常见报错

### `pip install f2` 失败:`pydantic-core` 编译错误

**根因**:Python 3.13 上 `pydantic-core==2.23.4` 没预编译 wheel,要 Rust 编译;Rust 默认 toolchain 缺失。

**解法**:用 Python 3.12 装。`install.sh` 已处理:
```bash
brew install python@3.12
pipx install --python /opt/homebrew/opt/python@3.12/bin/python3.12 f2
```

### `mcporter: command not found`

agent-reach skill 推荐用 `mcporter` 调抖音工具,但本 skill 不依赖 mcporter,改用 f2,可以忽略。

### 抖音下载报 `Fresh cookies needed`

**根因**:你 Chrome 里没访问过 douyin.com,没 cookie。

**解法**:
1. 用 Chrome 打开 `https://www.douyin.com`
2. 扫码登录
3. 关掉 Chrome 窗口(进程不退出)
4. 重跑本 skill

### `XYQ_ACCESS_KEY 未设置`

**解法**:从 `https://xyq.jianying.com` 拿 key,然后:
```bash
echo 'export XYQ_ACCESS_KEY="ak-xxx"' >> ~/.zshrc
source ~/.zshrc
```

### `xyq-nest-skill 未安装`

**解法**:本 skill 依赖 xyq-nest-skill。如果它没装在 `~/.claude/skills/xyq-nest-skill/`,你得自己装一份(从字节家拿)。

### split_scenes.py 第一次跑很慢

**正常**。`uv run` 第一次会下载 scenedetect + opencv-python wheel(共 ~80MB),之后缓存复用,瞬时启动。

## 平台支持

- ✅ macOS (验证过)
- ⚠️ Linux:`brew install` 改成 `apt`/`dnf`,其余流程相同
- ⚠️ Windows:f2 + Chrome cookie 在 Windows 上的路径不同,需要适配 `--auto-cookie chrome` 的 Chrome 路径
