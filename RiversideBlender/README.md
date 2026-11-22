# Riverside Films for Blender

This Blender project opens on **The Toilet That Bought the School** (about **1:47**). **The Night the Park Went Dark** (about **1:41**) is a separate edit in the same file. They are set up for **1080 × 1920 at 30 fps**.

## Open and edit

1. Open `deliverables/Riverside-Films.blend` in **Blender 4.3 or newer**. It opens on **THE TOILET THAT BOUGHT THE SCHOOL · EDIT**. Use the scene selector at the top of Blender to switch to **THE NIGHT THE PARK WENT DARK · EDIT**.
2. The two **EDIT** scenes have a picture strip, a packed audio strip, and editable subtitle strips. Scrub the timeline or press Space to play. Each shot change is bound to a camera marker in its Stage scene.
3. Choose a **Stage** scene to change the town, camera positions, materials, lighting, poses, or prop animation. The Outliner groups these under **RIVERSIDE**, **CAMERAS**, **CAST**, **PROPS**, and **LIGHTING**. The characters use named FK joints such as shoulder, elbow, hand grip, and eyeline controls. Existing keys are editable in the Dope Sheet or Graph Editor.
4. To export a video, select the relevant **EDIT** scene and choose **Render → Render Animation**. H.264 picture and AAC audio are configured. The two scene outputs have separate names under the project's `renders` directory.

The park film uses the transferred town and performance data. The toilet film adds an original school courtyard, locker hall, new staged animation, and a separate voice and sound mix. The character meshes are original Roblox-style Blender models with yellow toy heads, printed expressions, bright outfits, and animated handoff poses. Live Roblox catalog avatar meshes and Roblox animation assets were unavailable for export. You can attach your own imported character meshes to the named FK controls if you want a particular Roblox look.

## Included

- `deliverables/Riverside-Films.blend` with both stages and both edit timelines, packed narration and caption font.
- Two portrait sample PNGs rendered from the edit scenes and next-story notes in `NEXT-STORIES.md`.
- `media/` with standalone mixes, SRT subtitles, story text, timing, and exported Blender staging data.
- `tools/` with the staging exporter, Blender builder, and saved-file check.

Blender 4.3.2 reopened and checked both edit timelines. Sample frames cover the new toilet villain and the basketball sequence. The full films have not been rendered to MP4.

## Rebuild

From this folder, run:

```sh
blender -b --python-exit-code 1 -P tools/build_blender.py -- media/town.json media/performance.json deliverables/Riverside-Films.blend
blender -b deliverables/Riverside-Films.blend --python-exit-code 1 -P tools/check_blender.py
```

Append `-- --renders` to the verification command to render the two samples. The toilet narration was generated locally using Kokoro. The optional `tools/build_toilet_audio.py` regenerates its mix and captions from the pinned source script if given the Kokoro ONNX model and voice file. The linked caption font is DejaVu Sans Bold. Its license is included in `media/DejaVu-LICENSE.txt`.
