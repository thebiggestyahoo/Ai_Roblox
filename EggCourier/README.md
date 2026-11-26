# Don’t Crack the Egg!

An original multiplayer adventure racer built around carrying and protecting a cosmetic egg. The server runs race state, rewards, inventory changes, and hazard outcomes. The Rojo project and the built Roblox place are both in this directory.

## Play and test

1. Open **DontCrackTheEgg.rbxlx** in Roblox Studio and press **Play**. The place builds the hub and active courses in code.
2. Choose **Play** to enter **Egg Royale**, **Quick Race**, or **Adventure**. Use **Worlds** to explore the atlas, choose a course, and see difficulty, relics, medals, and personal bests.
3. Solo Studio sessions can run Adventure and Quick Race. Use **Test → Server & Clients** with multiple clients for qualification, parties, spectating, and finishes. Set the published experience’s server capacity to **15**.
4. Jump or move into the marked safe lanes to avoid hazards. In a **Crack Zone**, use **E**, controller **X**, or the onscreen **Shove** button to shove a nearby rival. Adventure routes have checkpoint recovery and let you look for relics.
5. Open **Cartons** to see the remaining reward pool and live odds. Visit **Pass** and **Quests** to claim earned rewards. The egg journal shows model previews, acquisition sources, and favorites.

## Race modes

- **Egg Royale** uses four qualifying heats and a dedicated championship course. A full 15-racer field cuts to 12, 9, 6, 3, then 1. Finals are ranked by finish, then by course progress as needed. A disconnect or a shattered shell can leave fewer racers in a heat.
- **Quick Race** runs a single shorter competitive session with a separate reward table.
- **Adventure** supports individual course selection, checkpoint recovery, timed medals, route exploration, and permanent relic collection.

Coin awards for Royale are final placement awards. A champion earns 150 Egg Coins, followed by 100 for second, 75 for third, 50 for fourth through sixth, 40 for seventh through ninth, 30 for tenth through twelfth, and 20 for thirteenth through fifteenth.

## Progression and purchases

The experience keeps Egg Coins earned through gameplay separate from legacy purchased or mixed-source coins. Existing cosmetics and profile history carry forward. The redesigned course keys start fresh records.

Earned **Classic**, **Adventure**, **Enchanted**, **Royal**, and **Galactic** cartons cost 500, 750, 1,250, 2,000, and 2,500 Egg Coins. Champion and other achievement cartons come from play. The server rolls among eligible unowned eggs. Players can skip the opening animation after receiving the grant.

The **Great Eggscape** season has 50 tiers, free and premium tracks, and Claim All. Premium collector cartons show their cosmetic contents before purchase. Configured Roblox game passes are one-time entitlements and actual pricing comes from Roblox. Commerce has no effect on race movement, egg durability, rankings, or obstacle behavior.

### Creator Dashboard setup

- Configure fixed-content collector pass IDs in **src/Shared/EconomyConfig.luau** and the premium season pass ID in **src/Shared/SeasonConfig.luau**. Confirm the Dashboard prices and test each configured offer. A zero ID keeps an offer unavailable.
- Keep optional legacy coin-pack product IDs in **src/Shared/Config.luau** only to honor past receipts. Legacy coin balances cannot purchase mystery cartons.
- Complete eligible purchase tests in a private published experience using Roblox’s official purchase prompts. Use **Studio Access to API Services** only in the test place when verifying persistence.
- Unpublished Studio sessions use temporary profiles. The production place uses the existing profile store and normalizes older saves when loading.

## Audio

**assets/EggCourier-Audio.zip** contains original Ogg Vorbis loops for the lobby and eight worlds, plus race and UI cues. To regenerate it locally, run **python tools/compose_audio.py audio-output** with Python and FFmpeg installed. Upload the individual tracks to Roblox and grant use to the destination experience. Put the assigned asset IDs in **Config.audio** and **Config.worldMusic**. Zero placeholders keep the game playable silently.

## Build and verification

Run **rojo build -o DontCrackTheEgg.rbxlx** in this directory. Compile all Luau files and run the standalone race tests in **tests/**. See [OVERHAUL_CHECKLIST.md](OVERHAUL_CHECKLIST.md) for implementation decisions and the remaining Studio validation.
