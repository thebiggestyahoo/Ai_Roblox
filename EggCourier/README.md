# Don’t Crack the Egg!

A Roblox obstacle racing game with standard player avatars, a three-hit egg, and five Green Meadows courses. The lobby, courses, props, obstacles, shop previews, and HUD are built in Luau.

## Open and play in Studio

1. Open `DontCrackTheEgg.rbxlx` with Roblox Studio on Windows or macOS. The place already contains the ModuleScripts, server Script, and LocalScript. Rojo is optional.
2. Open **View → Output** and press **Play**. Click **Play** in the HUD or use the **Race Queue** pad. The queue runs a 15-second intermission, eight seconds of voting, and a three-second starting countdown.
3. Run toward **Deliver Here** and cross each checkpoint in order. A broken egg costs 2.5 seconds before checkpoint recovery. Finish with an intact egg to earn coins and unlock the next course.
4. In **Courses**, select an unlocked course. Use **Practice selected course** for a solo run without rewards. Practice uses the same race arena and starts when no multiplayer race is queued or underway. **Play** with one racer starts a time trial that grants progression, coins, and personal records. Placement bonuses and wins require at least two starters.
5. For competition, use **Test → Server & Clients**, select at least two clients, and queue both. Unlock Spinner Showdown on both clients first. In a Crack Zone, face another eligible racer within eight studs and press **E**, controller **X**, or the on-screen **Shove** button. Try again immediately, from outside the border, and after a checkpoint respawn.
6. Use Studio’s device emulator to review the shop, results, native thumbstick, jump, and Shove controls in a narrow phone viewport. Test controller focus and navigation with an actual controller.

The source workflow uses Rojo 7. Build with `rojo build -o DontCrackTheEgg.rbxlx`, or run `rojo serve` and connect the Roblox Studio plugin to an empty place. Edit the source and rebuild after config changes.

## Implemented

- Green Meadows runs Big Ball Boulevard, Spinner Showdown, Punch Wall Panic, The Wobbly Bridge, and Meadow Mayhem. The lobby has race and practice entrances, shop and course portals, a golden egg stage, a podium, and a live server leaderboard.
- The server controls phases, ordered checkpoints, damage, recovery, Crack Zones, timed finishes, ranks, rewards, and validated shop actions. A course vote is limited to levels every queued racer has unlocked.
- Eggs display cosmetic colors, wobble, crack in two stages, and break into shell chips. Results include finish time, condition, rewards, and best-time feedback. A 25-coin perfect bonus requires reaching the finish without any damage during the run.
- Profiles track coins, wins, XP, unlocks, egg ownership and equip state, trails, personal records, and equipped titles. Live profile load failures stop the session to protect saved data. Studio play can use a temporary profile if Roblox API access is unavailable.
- There are seven free or coin eggs, two coin trails, five configurable cosmetic passes including VIP, and four reachable titles. Cosmic Champion and Egg Legend are reserved for World 4.

## Required configuration

- The bundled place uses standard avatars and disables streaming. In Creator Dashboard, set server capacity to **12** and use **R15** for the experience. The server also caps each race at 12 starters.
- For persistence testing, create a **private test experience**, save the place there, and enable **Studio Access to API Services** in the test experience. Play, earn coins, stop, and rejoin to confirm totals, records, and loadout. Keep test DataStore data separate from production.
- Set permitted sound asset IDs for the experience in `src/Shared/Config.luau` under `audio`. Entries at `0` are silent. Confirm playback and music/effects settings in both Studio and the private client.
- To configure premium cosmetics after approval, create each game pass in the target experience and copy its pass ID into `Config.passes`. The suggested prices are Golden 49, Rainbow 79, Galaxy 99, Royal 149, and VIP 199 Robux. Set the actual prices in Roblox. The shop directs players to Roblox’s price confirmation, and the server verifies pass ownership and handles purchase completion. VIP grants an egg, name tag, and trail. Leave each ID at `0` to disable that offer. Permanent cosmetics use passes. Developer products and receipt processing are outside this build.

## Verification and publishing checklist

- [ ] In Studio, clear unexpected Output errors during solo, practice, and multi-client rounds. Test mid-race joins and departures, back-to-back rounds, checkpoint order, reset recovery, and races that time out.
- [ ] In a 12-client or private server test, confirm finish order, temporary shove protection, moving bridge riders, and egg visibility for other players.
- [ ] Test a narrow phone and controller. Check the race timer, results, scrolling shop, device controls, and sustained frame rate.
- [ ] Confirm save and rejoin behavior in a separate private experience. Check that ending a round and immediately leaving retains the reward.
- [ ] With authorized IDs configured, confirm preview, cancel, purchase, leave, and rejoin for each enabled pass. Verify currency, movement, and durability remain independent of pass ownership.
- [ ] Complete Roblox’s required audience, content, and experience metadata. Publish or enable paid products only after approval.

Executed in this workspace: Luau compilation for every script, the gate/reward/progression tests in `tests/RaceRules.test.luau`, and a Rojo place build with script placement and source verification. Roblox Studio and a Roblox client were unavailable here. In-engine play, physics, mobile/controller layout, live DataStore calls, and purchase flows still need verification.

## Files created

| File | Responsibility |
| --- | --- |
| `default.project.json` | Rojo source tree and place settings |
| `src/Shared/Config.luau` | Race settings, audio, cosmetic catalog, pass IDs, and titles |
| `src/Shared/Levels.luau` | Five course definitions and the three future worlds |
| `src/Shared/EggModel.luau` | Egg construction, marks, and crack visuals |
| `src/Shared/RaceRules.luau` | Shared gate geometry and reward calculations |
| `src/Server/Main.server.luau` | Round state, race validation, shoves, and networking |
| `src/Server/World.luau` | Procedural lobby and course construction |
| `src/Server/Obstacles.luau` | Obstacle registry, movement, damage, and rider handling |
| `src/Server/Data.luau` | Profile sessions, persistence, records, and reward updates |
| `src/Server/Eggs.luau` | Egg attachment, title tags, trails, and shell fragments |
| `src/Server/Shop.luau` | Coin cosmetics and Marketplace game passes |
| `src/Client/Main.client.luau` | Menus, HUD, controller/mobile input, camera fades, and effects |
| `src/Client/Audio.luau` | Optional music and sound cue playback |
| `tests/RaceRules.test.luau` | Standalone Luau rule and course configuration tests |
| `DontCrackTheEgg.rbxlx` | Generated, standalone Studio place |
| `README.md` | Setup, verification, release checklist, and roadmap |

## Remaining scope and first update

The MVP ships a live server leaderboard and podium. Persistent global leaderboards, a dedicated VIP victory animation, paid finish effects, egg accessories, and dances are still open. The last three worlds have configuration entries only. The obstacle registry includes conveyor, disappearing and cycling bridge, ice, launch, door, snowball, and low-gravity behaviors for future courses. Those behaviors need a course integration pass and Studio testing.

For the first update, playtest checkpoints and the narrow moving bridges with mixed device groups, then release **The Egg Cooker** starting with **Lava Leap** and **Conveyor Chaos**. Use separate visual cues for active conveyors and disappearing decks. Confirm Level 5 graduates can access the new courses and that existing records and unlocks survive the update.
