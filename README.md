# The Shop That Sold Second Chances

A 12-scene Roblox Studio cinematic with a 2:54 picture timeline, portrait framing, and Noah's first-person narration. This place uses the uploaded `RObloxai.rbxl` as its foundation. The existing Roblox service and script structure is preserved, with new cinematic source in the original script slots. Each location is staged as a separate film set. The sets and cast are created when you press Play.

## Play the film

1. Open `deliverables/SecondChances.rbxl` in desktop Roblox Studio. Choose **Play** to start a local player session. The film starts when Roblox finishes loading the cast. If an avatar request fails, the loading screen identifies the role and Studio Output identifies the failed account.
2. For sound, upload `media/SecondChances-Mix.mp3` as an audio asset under the experience owner's account or group and grant the experience permission to use it. In **ReplicatedStorage → RobloxCinematic → Config**, set `MixAsset` to the resulting `rbxassetid://…` value. Save the place and press **Play** again. With the field empty, the film runs as a timed caption preview. The supplied mix contains the actual ElevenLabs recording at 0.94× tempo with pitch preserved, plus an original score and foley.
3. Use **V** for the portrait safe-area guide, **C** for captions, **[** or **]** to review neighboring scenes, and **R** to replay. Costume accounts, starting scene, autoplay, and initial caption visibility are editable in `Config`.

The role entries are Roblox account names. The cast loader asks Roblox for each account's current catalog appearance and builds R15 rigs with blocky proportions. It retains clothing, accessories, and the catalog head. Dynamic heads receive expression cues through FaceControls. Classic heads retain their face and use body and head acting. For a locked production look, set the role entries to dedicated styling accounts and review each resulting outfit in Studio. The child roles use smaller proportions and the same wardrobe sources to maintain recognition across the photograph and flashbacks.

## Review before capture

| Time | Review points |
| --- | --- |
| 0:00–0:23 | The watch immediately ticks backward. The classroom rumor, laughter, Lucas's eyeline, and Noah looking down read in portrait. |
| 0:23–1:05 | Lucas leaves, Noah's call fails, and the storefront sign comes on. Check the small refund warning, the door swing, the clock wall, and where the watch lands during the handoff. |
| 1:05–1:39 | S02 and S06 establish the same classroom geography and cast. Noah stands to defend Lucas. The river memory fails to resolve before the return to Noah. |
| 1:39–2:23 | Noah returns the watch and leaves. Lucas brings the photo to Noah's door. Check that the front of the photo is visible, that the transfer leads into the childhood flashback, and that Lucas's lost recognition and the watch reveal read in that order. |
| 2:23–2:54 | The ledger reads **LUCAS — ALL MEMORIES OF NOAH**. Check the ladder and sit poses, expressions during the introductions, and the photo on the bench before the final fade. |

Use a 9:16 Studio emulator viewport or crop to the center 9:16 region of a screen capture. For delivery, capture at **1080 × 1920** and **30 fps or higher**, with **V** off. Use the in-film captions or turn them off and apply `media/SecondChances.srt` in the edit. Record from playback time zero through the final fade. Review the recorded frames for clipping, eye lines, hand contact, foot planting, caption safe areas, and audio alignment.

## Source and verification

- **ReplicatedStorage → RobloxCinematic** contains `Config`, `StoryData`, `NarrationTiming`, and `PhotoArt`.
- **ServerScriptService → RobloxCinematic** contains `StoryWorld`, `WorldBuilder`, and `ActorController`.
- **StarterPlayer → StarterPlayerScripts → StoryCamera** contains the client director, picture and sound clock, portrait matte, props playback, and review controls.

The editable Luau files are in `src/`. The voice edit, 12-scene schedule, caption cues, and preserved first-person script are in `media/`. `tools/build_audio.py` rebuilds the mix, timeline, SRT, and Luau caption table from the source narration and measured alignment. On Linux, `tools/pack_place.py <uploaded-rbxl> <output-rbxl>` rebuilds the place from the original binary and current Luau using system zstd/LZ4 libraries. Add `--uncompressed` to produce a parser-friendly inspection copy. `tools/verify.mjs` takes a Node modules directory containing `luau-web` and `rbx-reader`, followed by that inspection copy.

Verified in the cloud: all eight Luau files compile and match the scripts embedded in the packaged place, the 12-scene director runs through 5,220 frames against a test harness, the world builder constructs all six location sets in a mocked Roblox object tree, the timed captions preserve the script, and the final MP3 decodes with a reported duration of 174.028 seconds. Desktop Roblox Studio and the live Roblox asset endpoints were unavailable in the cloud. The in-engine preview, current catalog costumes, facial rigs, animation permissions, picture and sound sync, shot composition, and capture performance still need the Studio review above. No MP4 is included.
