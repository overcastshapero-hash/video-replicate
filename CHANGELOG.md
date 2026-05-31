## Changelog

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