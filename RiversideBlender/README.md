# Riverside Films for Blender

This Blender project contains the two complete Riverside Story Edit films. **The Last Bus** and **The Night the Park Went Dark** are each about **1:41**. They are set up for **1080 × 1920 at 30 fps**.

## Open and edit

1. Open `deliverables/Riverside-Films.blend` in **Blender 4.3 or newer**. It opens on **THE LAST BUS · EDIT**. Use the scene selector at the top of Blender to switch to **THE NIGHT THE PARK WENT DARK · EDIT**.
2. The two **EDIT** scenes have a picture strip, a packed audio strip, and editable subtitle strips. Scrub the timeline or press Space to play. Each shot change is bound to a camera marker in its Stage scene.
3. Choose a **Stage** scene to change the town, camera positions, materials, lighting, poses, or prop animation. The Outliner groups these under **RIVERSIDE**, **CAMERAS**, **CAST**, **PROPS**, and **LIGHTING**. The characters use named FK joints such as shoulder, elbow, hand grip, and eyeline controls. Existing keys are editable in the Dope Sheet or Graph Editor.
4. To export a video, select the relevant **EDIT** scene and choose **Render → Render Animation**. H.264 picture and AAC audio are configured. The two scene outputs have separate names under the project's `renders` directory.

The town layout and performances were transferred from the Roblox scene data, with restaging for Blender. The character meshes are original stylized Blender models with distinct outfits, animated expressions, and handoff poses. Live Roblox catalog avatar meshes and Roblox animation assets were unavailable for export. You can attach your own imported character meshes to the named FK controls if you want a particular Roblox look.

## Included

- `deliverables/Riverside-Films.blend` with both stages and both edit timelines, 46 camera cuts, packed narration and caption font.
- Two portrait sample PNGs rendered from the edit scenes.
- `media/` with standalone mixes, SRT subtitles, story text, timing, and exported Blender staging data.
- `tools/` with the staging exporter, Blender builder, and saved-file check.

Blender 4.3.2 reopened and checked both edit timelines. Sample frames were rendered from the bakery handoff and the basketball sequence. A full movie render and visual review of all 6,036 frames were outside this conversion pass.

## Rebuild

From this folder, run:

```sh
blender -b --python-exit-code 1 -P tools/build_blender.py -- media/town.json media/performance.json deliverables/Riverside-Films.blend
blender -b deliverables/Riverside-Films.blend --python-exit-code 1 -P tools/check_blender.py
```

Append `-- --renders` to the verification command to render the two samples. The linked caption font is DejaVu Sans Bold. Its license is included in `media/DejaVu-LICENSE.txt`.
