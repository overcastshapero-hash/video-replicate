#!/usr/bin/env -S uv run --quiet
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "scenedetect[opencv]>=0.6.4",
# ]
# ///
"""自动切镜 + 抽关键帧(头/中/尾各一张)。

用法: split_scenes.py <video> <out_dir>
输出:
  <out_dir>/scenes.csv         scenedetect 默认 CSV
  <out_dir>/scenes.json        简化版,Claude 读这个
  <out_dir>/frames/S01_head.jpg  S01_mid.jpg  S01_tail.jpg ...
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

import cv2
from scenedetect import ContentDetector, SceneManager, open_video


def detect(video_path: Path, out_dir: Path) -> list[dict]:
    out_dir.mkdir(parents=True, exist_ok=True)
    frames_dir = out_dir / "frames"
    frames_dir.mkdir(exist_ok=True)

    video = open_video(str(video_path))
    sm = SceneManager()
    sm.add_detector(ContentDetector(threshold=27.0))
    sm.detect_scenes(video=video, show_progress=False)
    scenes = sm.get_scene_list()

    # 写 CSV
    csv_path = out_dir / "scenes.csv"
    with csv_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["id", "start_sec", "end_sec", "start_frame", "end_frame"])
        for i, (s, e) in enumerate(scenes, 1):
            w.writerow([f"S{i:02d}", s.seconds, e.seconds, s.frame_num, e.frame_num])

    # 抽帧 + JSON
    cap = cv2.VideoCapture(str(video_path))
    out_scenes: list[dict] = []
    for i, (s, e) in enumerate(scenes, 1):
        sid = f"S{i:02d}"
        sf, ef = s.frame_num, e.frame_num
        mid = (sf + ef) // 2
        positions = {"head": sf, "mid": mid, "tail": max(ef - 1, sf)}
        frame_paths: dict[str, str] = {}
        for tag, fn in positions.items():
            cap.set(cv2.CAP_PROP_POS_FRAMES, fn)
            ok, frame = cap.read()
            if not ok:
                continue
            fp = frames_dir / f"{sid}_{tag}.jpg"
            cv2.imwrite(str(fp), frame, [cv2.IMWRITE_JPEG_QUALITY, 88])
            frame_paths[tag] = str(fp.relative_to(out_dir))
        out_scenes.append({
            "id": sid,
            "start": round(s.seconds, 2),
            "end": round(e.seconds, 2),
            "duration": round(e.seconds - s.seconds, 2),
            "frames": frame_paths,
        })
    cap.release()

    json_path = out_dir / "scenes.json"
    json_path.write_text(json.dumps(
        {"video": str(video_path), "scene_count": len(out_scenes), "scenes": out_scenes},
        ensure_ascii=False, indent=2,
    ))
    return out_scenes


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    video = Path(sys.argv[1])
    out = Path(sys.argv[2])
    if not video.exists():
        print(f"[split_scenes] ❌ 视频不存在: {video}")
        return 3
    scenes = detect(video, out)
    print(f"[split_scenes] ✅ 切出 {len(scenes)} 个镜头,关键帧写入 {out/'frames'}")
    if len(scenes) < 3:
        print("[split_scenes] ⚠️  镜头数偏少,参考片可能不适合做结构复刻")
    elif len(scenes) > 15:
        print("[split_scenes] ⚠️  镜头数偏多,建议缩短或选取片段")
    return 0


if __name__ == "__main__":
    sys.exit(main())
