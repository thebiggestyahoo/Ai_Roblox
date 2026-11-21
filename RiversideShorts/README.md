# Riverside Shorts · Production cut

Two portrait films staged in one connected Roblox town. The package contains a playable Roblox Studio place, two mixed soundtracks, subtitles and editable Luau.

| Short | Film runtime | Story |
| --- | ---: | --- |
| The Last Bus | 1:40.554 | A sister races through town with her brother's ticket and his forgotten backpack. |
| The Night the Park Went Dark | 1:40.610 | A player finds the real cause of a court blackout and brings back the kid everyone blamed. |

## Open and review in Roblox Studio

1. Extract the ZIP. From **File → Open from File**, open `deliverables/RiversideShorts.rbxl`. Press **Play** with a local player. The map, cast and cameras initialize on Play.
2. **N** switches stories, **R** restarts the current story, **[** and **]** jump between beats, and **C** toggles the in-game captions.
3. To walk through town with your avatar, change `ExploreTown` to `true` in **ReplicatedStorage → RobloxCinematic → Config** and restart Play.
4. To hear the mix in Studio, upload each `media/*-mix.mp3` as a Roblox audio asset under the experience owner, grant that experience usage, and paste the corresponding asset URL into `Config.AudioAssets`. For a video edit, place the desired mix and SRT against the first picture frame instead. Voice, score, city ambience and effects are already mixed together.

The Studio project uses real Roblox avatar rigs and live catalog appearances. For repeatable costumes, enter reviewed Roblox outfit IDs under `Config.Outfits`, keyed by role. Dynamic heads use FaceControls. Classic heads get a face overlay with authored expression cues. Account appearances and availability can change.

## Crew notes

- The 20 beats in each film were choreographed to that film's updated recording. The portraits use fixed focal lengths, full-figure and wider framing, and continuous action between cuts. The director checks candidate camera clearance and samples cast coverage throughout each angle before playback.
- The road and park sequences have separate lanes for moving actors. A final spacing pass runs before prop attachment. The handoff scenes use IK targets on the real R15 arms, and the return pass uses a separate ball trajectory. The bus set has clearance for seated avatars, opening doors and flashing indicators.
- The shared town includes housing blocks, storefront interiors, a school lobby, a town square, a riverfront promenade, a pair of transit stops, a park and a court.
- Playback falls back to a visual clock if the sound is unconfigured or unavailable. In capture, target **1080 × 1920 at 30 fps or better**, crop to the 9:16 picture area, and capture from beat 1. Use the Studio captions or the SRT export. In-game captions emphasize key words, and short time cards mark flashbacks and the next-day epilogue. Set `TimeCards = false` for a clean plate.

## Editorial pass

The opening cuts establish the stakes in action. The bus approach and crosswalk use cuts on movement, while the court sequence uses a lighting change, a reaction angle, and a visible rim-to-catch-to-return sequence. Camera setups stay at full figure or wider. Public YouTube and TikTok pages were blocked during this pass, so the edits apply general short-form techniques without a direct comparison to new videos.

## What was checked

All eight Luau scripts compile and match the packaged place. Offline tests sampled 6,075 frames, checked 40 camera marks against the mock town geometry, measured a minimum authored actor-center spacing of 3.04 studs, and verified the subtitle text and the 90–120 second runtime range. Geometry previews were rendered and inspected using simple stand-ins. The audio mixes were decoded and measured below clipping.

Desktop Roblox Studio and live catalog access were unavailable during these checks. Before capture, inspect the real rigs at the bakery handoff, bus doors, park gate and basketball catch. Verify cloth and accessory clipping, hand contact, staging, final lighting, and picture-to-audio sync in Studio. The package contains an editable project, with no final MP4 render.

## Rebuild

`python3 tools/build_audio.py --model <kokoro-v1.0.onnx> --voices <voices-v1.0.bin>` produces the mixes, SRT files, JSON cue sheet, and the Luau timing module. This build used local Kokoro neural voices, optional PocketSphinx alignment for 36 of 40 lines, and estimated phrase times for the remaining four. The model files are available from the [Kokoro ONNX release](https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0).

`python3 tools/pack_place.py <original-rbxl> deliverables/RiversideShorts.rbxl` embeds the current source into the Roblox place. To test the build with Node, use the packer's `--uncompressed` option for the parser-friendly verification copy and run `node tools/verify.mjs <node_modules> <verification-rbxl>` from the project root. The Node modules directory needs `luau-web` and `rbx-reader`.
