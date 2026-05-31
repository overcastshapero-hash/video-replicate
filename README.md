**video-replicate** — 结构级视频复刻神器（Claude Code 生态）

> 扔一个抖音/ B站 / YouTube / 本地视频链接，让 Claude Code 自动完成：下载 → 智能截 demo → 精准切镜 → 分镜理解 → IP安全改编 → 小云雀端到端生成 → 自动拼接 → 质量验收。

最终交付**结构高度一致、主体可控差异化**的新视频。

---

## 核心价值（为什么值得用）

- **真正的结构复刻**：不是简单风格迁移，而是完整保留原片镜头节奏、构图逻辑、叙事顺序、转场质感。
- **可控的主题改编 + IP安全**：通过 Director + Storyboard Critic 双重把关，强制要求主体做具体外观差异化，避免直接侵权。
- **工程级健壮性**：完整处理小云雀的多轮意图确认、积分不足、限流、内容审核等真实世界问题（最近刚完成重大鲁棒性升级）。
- **生产可用输出**：自动生成 contact sheet、双画幅自适应拼接、结构化 QC 报告。

适合**已经在用 Claude Code 的内容创作者、短视频团队、IP 实验者**使用。

---

## 最近重大升级（2026.5）

本次针对真实跑通案例（风筝父子复刻等）进行了重点打磨：

- 新增 `clip_demo.sh`：一键截取前 30 秒 demo 并自动生成高质量 contact sheet（关键帧 4x3 拼图）
- 重构 `compose.sh`：自动识别并支持 16:9 横屏 / 9:16 竖屏，无需再手写自定义拼接脚本
- 新增 `xyq_suggest_resume.sh`：小云雀触发意图确认时，自动给出高质量 resume 建议消息，大幅降低多轮交互成本
- 全流程文档与实际体验对齐

---

## 快速开始（5-10 分钟）

```bash
git clone https://github.com/overcastshapero-hash/video-replicate ~/.claude/skills/video-replicate
cd ~/.claude/skills/video-replicate
./install.sh
```

### 必要前置

1. **安装依赖的 xyq-nest-skill**（字节官方封装）
   放在 `~/.claude/skills/xyq-nest-skill/`

2. **获取小云雀 Access Key**
   访问 https://xyq.jianying.com → 登录 → 用户中心拿 `XYQ_ACCESS_KEY`

   推荐方式（不污染全局）：
   ```bash
   cp .env.example .env
   # 编辑 .env 填入你的 key
   ```

3. **抖音视频额外要求**（仅抖音链接需要）
   用 Chrome 打开 https://www.douyin.com 扫码登录一次，保持登录态（进程可关闭）。

配好 Key 后，在 Claude Code 里直接说：

```
复刻这个视频: https://v.douyin.com/xxxxxx/
```

---

## 真实交付物

每次运行会在 `~/projects/video-replicate/<run-id>/` 生成：

- `source_demo_30s.mp4` + `contact_sheet.jpg`（强烈建议先用 30s demo 验证）
- `storyboard.json` + `brief.md`（可 review）
- `clips/` 原始生成片段
- `final.mp4`（最终成片）
- `qc_report.md`（结构化质量验收报告）

---

## 它擅长什么 / 不擅长什么

**擅长**：
- 短视频结构复刻 + 主题/主体安全换皮（30s~2 分钟 demo）
- 风格、节奏、叙事逻辑的精准迁移
- 需要强 IP 规避的商业/内容实验

**不擅长 / 目前不推荐**：
- 给完全不会折腾的技术小白一键使用（有一定上手门槛）
- 完全零手动介入的批量生产（小云雀本身存在多轮确认机制）
- 对生成质量 100% 稳定的极致要求场景（AI 视频模型当前普遍特性）

详细边界见仓库内 `USAGE.md`。

---

## 技术亮点

- 3 个真正有用的虚拟角色（Director / Storyboard Critic / QC Reviewer），全程透明可审计
- 完整的错误分类处理（4 种 poll 退出码 + 详细小云雀错误码字典）
- 最近针对真实生产摩擦点做了大量工程化收尾
- 法律红线意识内置（默认拒绝一比一克隆）

---

## 下一步演进方向

- 进一步降低意图确认交互成本
- 支持更多视频生成引擎作为 fallback
- 更强的自动 QC 与迭代建议

---

## License

MIT

---

**想试？** 先把小云雀 Key 准备好，装完 skill 后直接对 Claude Code 说「复刻这个视频 + 链接」即可。

有问题欢迎提 Issue 或直接在 Claude Code 里用这个 skill 本身来讨论。