# video-replicate

> 扔一个视频链接给 Claude Code，自动复刻成结构一致、主题可换的新视频。

**核心价值**：不是绑定某个视频模型，而是把「爆款视频的结构、节奏、叙事逻辑」用可执行的工艺固化成高质量 prompt 包 + 分镜资产。现在 clone 这个仓库，你拿到的已经是经过真实项目打磨的「可 clone 高质量内部工具公开版」。

## 两条路径

- **路径一**：走小云雀完整一键出片（适合有额度时）
- **路径二**（推荐主力）：跑完分析和 prompt 后，用产出的 `contact_sheet.jpg` + `scenes/` + `storyboard.json` + `brief.md`（按 craft 框架 + 高级模板硬化）去任意视频/图像工具继续生成。**完全不依赖小云雀**。

## 30 秒入门（推荐）

```bash
git clone https://github.com/overcastshapero-hash/video-replicate ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

配好小云雀 key 后（可选），直接运行：

```bash
./run.sh "https://v.douyin.com/xxxxx/"
```

这个脚本会自动帮你完成下载 + 智能截 30s demo，并告诉你后续每一步该干什么（包括路径二怎么停在高质量 prompt 包阶段）。

任何时候想知道现在该做什么：
```bash
bash scripts/next.sh <工作目录>
```

## 完整介绍

**📄 看 [`USAGE.md`](USAGE.md) — 这是发给别人的那份文档。**
里面有:
- 两条路径的详细说明（重点推荐路径二：结构复刻 Prompt Factory）
- 你需要准备什么
- 你能拿到什么（尤其是路径二的核心资产）
- 真实使用场景
- 已知边界

**最近一次重大升级**：把《视频结构复刻工艺决策框架》 + 多套经过风筝等项目实战硬化的高级 brief 模板完整放进公开仓库，知识完整度大幅提升。详见 [CHANGELOG.md](CHANGELOG.md)。

## 配置(一次性)

### 1. 装小云雀 skill

`xyq-nest-skill` 是字节家官方提供的 skill，需要单独装在 `~/.claude/skills/xyq-nest-skill/`（只路径一需要）。

### 2. 拿小云雀 Access Key

只路径一需要。

## License

MIT
