# Don’t Crack the Egg!

A Roblox knockout obstacle racer. Pick a heat at **Shell Yard Terminal**, carry your egg across the island, and take one of the available finish slots. A fall or a shattered shell ends your run.

## Play in Roblox Studio

1. Open **`DontCrackTheEgg.rbxlx`** in desktop Roblox Studio and press **Play**. The file contains the spawn, floor, and scripts that build the hub and courses.
2. To see any island immediately, open **Islands** in the bottom dock and click **Practice** next to its course. This works even while the course is locked for competitive play.
3. For a scored run, click **Race** or use the hangar prompt. One player starts a solo time trial. Two or more players get a knockout heat with limited finish slots.
4. To test against other players, use **Test → Server & Clients** with at least two clients and queue both. In the marked red **Crack Zones**, face a nearby rival and use **E**, controller **X**, or the touch **Shove** button. A missed shove still costs the five-second cooldown.

Practice is reward-free. A failed practice attempt sends you back to the starting line with a fresh egg. Use **Leave practice** to head back to the terminal. In scored heats, racers who fall, break their eggs, or miss the last finish slot return to the terminal and see an elimination scorecard.

## Islands

| Island | Trials | Hazards |
| --- | --- | --- |
| Green Meadows | Big Ball Boulevard, Spinner Showdown, Punch Wall Panic, The Wobbly Bridge, Meadow Mayhem | Jump chains, narrow moving rafts, spinners, punch walls, and Crack Zones |
| The Egg Cooker | Lava Leap | Foundry rollers, cycling heat plates, disappearing tiles, and a timed ferry |
| Frozen Eggs | Snowball Speedway | Snowball lanes, slick ice, tilting perches, and moving platforms |
| Eggstraterrestrial | Planet Hopper | Disappearing bridges, small orbital platforms, and shutters |
| Sunken Ruins | The Relic Run | A temple boulder corridor with refuge alcoves, pressure traps, and broken bridge jumps |

In a two-player heat only the first finisher qualifies. Larger heats accept up to 60% of starters, rounded up and capped at one fewer than the starting field. First place earns the win. Accepted finishes still grant coins, XP, and level progression. Existing unlocks, coins, and cosmetics carry forward. Personal bests for the rebuilt routes use separate records.

## Source and configuration

- Rojo 7 maps `src/Shared`, `src/Server`, and `src/Client` into the place. Run `rojo build -o DontCrackTheEgg.rbxlx` from this directory to rebuild.
- `src/Server/World.luau` builds the terminal. `Courses.luau` and `Obstacles.luau` build the islands and course mechanics. `Main.server.luau` runs the heat and validates route traversal, placement, shoves, and rewards.
- `src/Shared/Levels.luau` defines island and course order. `Config.luau` holds race settings, permitted audio asset IDs, and cosmetic game-pass IDs. Entries at zero disable the corresponding asset or offer.
- Set max server size to **12** and the avatar type to **R15** in the experience settings. Unpublished Studio sessions use temporary profiles. For persistence tests, use a private test experience and enable **Studio Access to API Services** there.
- Before a release, test in Studio with solo and multiple clients. Check mobile jump and shove controls. Verify timing on the orbit jumps and moving ferries, the boulder alcoves, both the hit and miss sides of shove cooldown, and the final-slot elimination. Test purchase flows and audio separately if those IDs are enabled.

The project has no Roblox publication step in this repository. The Studio verification above is required for in-engine feel and device layout.
