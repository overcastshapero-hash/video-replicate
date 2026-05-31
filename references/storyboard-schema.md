# Storyboard / Production JSON 字段定义

两个文件,同一棵树长大:
- `storyboard.json` — 第 ③ 段产出,描述**原片**结构
- `production.json` — 第 ④ 段产出,在 storyboard 基础上加生成所需字段

## storyboard.json

```jsonc
{
  "source": {
    "url": "原始链接或本地路径",
    "duration": 25.1,         // 秒
    "width": 1080,
    "height": 1920,
    "aspect_ratio": "9:16",
    "fps": 24
  },
  "scenes": [
    {
      "id": "S01",
      "start": 0.0,
      "end": 3.2,
      "duration": 3.2,
      "visual_summary": "POV 低角度沙滩前进,前景可见两只触须",
      "camera": "handheld POV, low to ground, slow forward dolly",
      "subject": "螃蟹(主视角)",
      "motion": "向前缓慢推进,沙地反光",
      "audio": "海浪、沙摩擦",
      "subtitle": "",            // 原片字幕,没有就空
      "reference_frame": "frames/S01_mid.jpg"
    }
  ],
  "join_strategy": {
    "mode": "tail_frame_to_next_first_frame",
    "critical_join_points": [15.5]   // 转场紧、视觉突变的秒数
  }
}
```

## production.json(在 storyboard 基础上增量)

每个 scene 多加这几个字段:

```jsonc
{
  "id": "S01",
  // ... storyboard 原字段保留 ...
  "generation_prompt": "POV low-angle shot, two lobster antennae visible in foreground, slow forward motion across wet sand at low tide, soft warm golden hour light, photorealistic documentary style, 9:16 vertical, 24fps",
  "voiceover": "在没人看见的角落,它开始了今天的旅程。",   // 没人声留空字符串
  "subtitle_text": "在没人看见的角落,它开始了今天的旅程。",
  "negative": ["原片 logo", "水印", "品牌名 XXX", "可识别人物面孔"],
  "reference_mode": "first_frame_from_previous_tail | text_only | image_ref",
  "reference_image": "frames/S01_head.jpg"   // 可选
}
```

## 字段约定

- 时间一律秒,保留两位小数
- prompt 用英文,模型对英文响应更稳;voiceover/subtitle_text 用中文(除非用户指定)
- `negative` 必须包含从原片识别到的任何品牌/水印/人物
- 单镜时长建议 2.5–6 秒,>6 秒拆成多段(生成模型对长片不稳)

## 写完自检

- [ ] 总时长 ≈ 原片时长(±5%)
- [ ] `critical_join_points` 上每个时间点附近的镜头都有 `reference_mode` 说明
- [ ] 每个 `generation_prompt` 都明确了主体外观、动作、镜头、光照、风格
- [ ] `negative` 已加入原片所有受版权保护元素
