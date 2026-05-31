# 跨段衔接策略

视频生成模型的硬限:单次生成通常 ≤ 8 秒,>15 秒必须分段。分段最大的坑是**转场跳变**——观众一眼就看出"AI 拼接"。

## 默认策略:tail_frame_to_next_first_frame

后一段把前一段的**最后一帧**作为**首帧参考**喂回生成模型。绝大多数引擎(xyq-nest、可灵、即梦、Runway、Veo)都支持"image-to-video / first frame conditioning"。

### 提取尾帧

```bash
# 从前一段成片拿尾帧
ffmpeg -y -sseof -0.04 -i clips/shot_03.mp4 -vframes 1 -q:v 2 _ref/shot_03_tail.jpg
```

把这张图作为下一段的首帧参考传给生成 skill。

## 何时偏离默认

- **硬切镜头**(`critical_join_points` 中标了"hard_cut") → 不传首帧,改用新的 `reference_image`,prompt 里明写 "hard cut from previous shot"
- **慢推/摇/缩放**的连续运动 → 一定要尾帧接首帧,否则会跳
- **主体变换**(从俯拍接特写) → 用 storyboard 给的 `reference_frame`,不要用前段尾帧

每一段生成前必须在执行报告里写出:
- `reference_mode`: 用了哪种
- `tradeoff`: 这次妥协了什么(例:首帧风格被前段拖累)

## >15 秒视频的硬规则

1. 必须先有完整 `storyboard.json` 才能开始第 ⑤ 段(逐镜生成)
2. 必须显式声明 `join_strategy`,不能"凭感觉"
3. 每段先出**低成本预览**(分辨率减半 / 简化 prompt),通过抽检再出高清
4. 单段失败重试 ≤ 2 次,仍失败必须停下来问用户
5. 整片生成完成前不要烧字幕、不要混音 —— 节省迭代成本

## 拼接前的统一规格

无论各段引擎是否一致,拼接前 `compose.sh` 已经强制:
- 720×1280, 9:16, 黑边补齐
- 24 fps
- H.264 + yuv420p
- SAR=1

各段引擎吐出来 25fps / 30fps / 不同分辨率都不影响,但**音频采样率不一致会爆**——所以策略是各段静音,最后用单独的 `voice.mp3` 整体混。
