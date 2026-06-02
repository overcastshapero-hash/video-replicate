## Changelog

### 2026-06-01 — 边界 + 扩展 + 瘦身 (v0.3)

**主线**:明确"仅限视觉驱动型"边界,加可选前后端,瘦身仓库,激活协作角色。

#### 新增
- `scripts/viral_finder.sh` — 爆款检索:小红书走 `xhs` CLI,抖音走 firecrawl/web-search(Claude 接管 MCP 工具)
- `scripts/publish_pack.sh` — 发布资产包:3 张候选封面 + META.md(标题/文案/tag) + checklist.md

#### 改动
- **边界声明**:SKILL frontmatter + USAGE 顶部明确"口播/解说/科普/做菜/reaction/vlog/手绘解说类不做"
- **协作角色激活**:SKILL.md 改"Director/Critic/QC 进场前必须 Read agents/xxx.md"
- **README 重写**:30 秒 ASCII 流水线图 + 双路径并列 + 入口对照表
- **xyq_poll 退出码**:加退出码 4 = API 业务错误(如 11001 积分不足),不再藏在退出码 3 里
- `xyq_*.sh` 全部自动加载本地 `.env`

#### 瘦身
- references 13 → 9:删 4 份冗余 brief 模板,精华合到 `brief-template.md`
- 删根目录 `DEMO.md`(临时演示稿不当门面)

#### 修复
- `download.sh` f2 pipefail 误退出
- `viral_finder.sh xhs` 未登录分支因 `head -20` SIGPIPE 触发 `set -e` 误退出

---

### 2026-05-31 — Dual-Path Release (v0.2)

**Major improvement**: This repo is now positioned as a **cloneable high-quality internal tool public version** for video structure replication.

#### Key Changes
- Added full support for **Path 2: Structure Replication Prompt Factory** (no Xiaoyunque required).
  - When `brief.md` is ready, users can now cleanly stop and use the high-quality assets (`contact_sheet.jpg`, `scenes/`, `storyboard.json`, `brief.md`) with any video/image generation tool (Kling, 即梦, 海螺, Luma, local ComfyUI, CapCut, etc.).
  - `scripts/next.sh` now clearly presents both paths side-by-side without removing or altering any original Xiaoyunque recommendations.
- Synchronized the complete battle-tested knowledge base:
  - `video-replication-craft.md` (full 工艺决策框架)
  - All advanced brief templates (`xiaoyunque-structure-replication-best-brief-template.md` and variants) + `xiaoyunque-structure-prompt-modules.md`
  - These were developed from real runs (e.g., 风筝 project clothing drift issues) and dramatically improve prompt reliability.
- Added dedicated high-quality reference: `references/prompt-factory.md` (完整操作指南和注意事项)。
- Updated documentation (README.md, USAGE.md, SKILL.md) to prominently feature the dual-path model and the value of the prompt package as the primary deliverable.

#### Preservation
- The original full Xiaoyunque pipeline (Path 1) remains 100% intact and is still the first recommended option in `next.sh` for users who have credits and want one-click generation.

This release makes the repo valuable even for people who never use Xiaoyunque.