# Don’t Crack the Egg!

A Roblox knockout obstacle racer. Queue at **Shell Yard Terminal**, carry your egg across the islands, and take one of the available finish slots. A fall or a shattered shell ends your scored run.

## Play in Roblox Studio

1. Open **`DontCrackTheEgg.rbxlx`** in desktop Roblox Studio and press **Play**. The file contains the spawn, floor, and scripts that build the hub and courses.
2. To see any island immediately, open **Worlds** in the bottom dock and click **Practice** next to its course. This works even while the course is locked for competitive play.
3. For a scored run, click **Queue** or use the hangar prompt. The queue starts when it fills to 15 or the 15-second lobby timer expires. One player gets a solo time trial. Two or more players get a tournament with cuts sized to the starting field.
4. To test against other players, use **Test → Server & Clients** with at least two clients and queue both. In the marked red **Crack Zones**, face a nearby rival and use **E**, controller **X**, or the touch **Shove** button. A missed shove still costs the five-second cooldown.

Practice is reward-free. A failed practice attempt sends you back to the starting line with a fresh egg. Use **Leave practice** to head back to the terminal. In scored heats, racers who fall, break their eggs, or miss the last finish slot return to the terminal and see an elimination scorecard.

## Tournament

The map reel draws five different courses in ascending difficulty. In a full field, the five heats cut **15 → 12 → 9 → 6 → 3 → 2**. The final two start a fresh head-to-head heat on the fifth map. The first to finish or the last racer standing wins. If both finalists are active at the time limit, course distance breaks the tie, followed by remaining shell HP. If both values match, the final is tied. A preliminary qualifier wins by default if every other contender has been eliminated or left.

The HUD shows finish slots filled and open during the heat. The raised **FINISH** board also shows the count from both sides. R15 avatars cradle the egg at chest height with both hands. R6 avatars use a two-arm carry pose.

Qualified finishes earn coins and XP. Finishing the next locked course unlocks it for solo selection. Tournament wins earn the red-outline and red-trail **Winner Aura**, which can be toggled in **Stats**. The meter shows progress toward the first win. Existing wins also count.

## Islands

| Island | Trials | Hazards |
| --- | --- | --- |
| Green Meadows | Big Ball Boulevard, Spinner Showdown, Punch Wall Panic, The Wobbly Bridge, Meadow Mayhem | Pinball lanes, carnival carousels, foam-fist stunt sets, river rafts, and mushroom jumps |
| The Egg Cooker | Lava Leap | Foundry rollers, warning lights on heat plates, and a timed ferry |
| Frozen Eggs | Snowball Speedway | Snowbank slalom, snowball lanes, and packed snow refuges |
| Eggstraterrestrial | Planet Hopper | Low-gravity jumps, blinking bridges, and crater platforms |
| Sunken Ruins | The Relic Run | A temple boulder corridor with refuge alcoves, pressure traps, and broken bridge jumps |

Moving rafts, ferries, and tilting decks use solid driven parts so players can ride them. Marked waiting bays separate bouncers and moving walls. Existing unlocks, coins, and cosmetics carry forward. The rebuilt routes start a new set of personal bests. Older records remain in the profile.

## Egg locker and Robux

Preview 13 egg designs in the locker. Eggs and trails are cosmetic, and tournament wins earn the Winner Aura. In **Locker → Coin packs**, there are three optional fixed-amount offers configured in `src/Shared/Config.luau`.

| Pack | Coins | Suggested Roblox price |
| --- | ---: | ---: |
| Starter | 400 | 29 Robux |
| Courier | 1,000 | 59 Robux |
| Collector | 2,400 | 119 Robux |

To enable a pack in a published Roblox experience, create the matching **Developer Product** in Creator Dashboard, set its actual price there, and fill in the product's numeric `productId` in the matching pack. Zero IDs keep packs unavailable. Rebuild the place and verify a purchase in a private test experience with data storage enabled. The Roblox prompt shows the actual price. Receipts are credited server-side with duplicate protection. Coins buy cosmetic trails. The first race finish unlocks a free cosmetic egg box. The Locker lists all three tiers and the remaining finish milestones.

## Source and configuration

- Rojo 7 maps `src/Shared`, `src/Server`, and `src/Client` into the place. Run `rojo build -o DontCrackTheEgg.rbxlx` from this directory to rebuild.
- `src/Server/World.luau` builds the terminal. `Courses.luau` and `Obstacles.luau` build the islands and course mechanics. `Main.server.luau` runs the heat and validates route traversal, placement, shoves, and rewards.
- `src/Shared/Levels.luau` defines island and course order. `Config.luau` holds race settings, permitted audio asset IDs, and cosmetic game-pass IDs. Entries at zero disable the corresponding asset or offer.
- Set max server size to **15** and the avatar type to **R15** in the experience settings. Unpublished Studio sessions use temporary profiles. For persistence tests, use a private test experience and enable **Studio Access to API Services** there.
- Before a release, test in Studio with solo and multiple clients. Walk, land, stand, and jump near the edges of rafts and tilting decks with multiple clients. Check mobile controls, the carry pose, the full and short tournament paths, and the final-slot elimination. Test purchase flows and audio separately if those IDs are enabled.

The project has no Roblox publication step in this repository. The Studio verification above is required for in-engine feel and device layout.
