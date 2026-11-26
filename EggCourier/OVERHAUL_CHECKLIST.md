# EggCourier overhaul checklist

The economy brief takes precedence over older coin awards, egg purchases, tournament round counts, and carton acquisition rules. The cinematic brief sets the course identity. The references guide pacing and style. The Roblox geometry, names, eggs, packaging, music, and interface art are original to this project.

## Implementation

- [x] Preserve the existing Roblox place, server/client module layout, carry mechanics, and profile store.
- [x] Author an eight-world adventure catalog with 24 selectable routes and a dedicated championship route.
- [x] Use readable timing windows, alternate lanes, marked recovery points, original set pieces, and collectible side routes.
- [x] Keep the cosmetic egg's competitive envelope and the two-handed chest carry on R15 and R6.
- [x] Add original 3D world previews in the Adventure Atlas plus short pre-race establishing shots and a skip control.
- [x] Add three race modes and a five-round Royale target cut of 15 → 12 → 9 → 6 → 3 → 1.
- [x] Pay one final Royale placement reward per entrant and give Quick Race its own smaller table.
- [x] Separate gameplay-earned Egg Coins from balances whose purchase provenance is unknown.
- [x] Disclose current unowned carton content and actual probabilities. Keep randomized openings server-side and payable through gameplay earnings or achievement claims.
- [x] Use one-time Roblox pass ownership for configured fixed-content collector offers and season premium access.
- [x] Build a new egg catalog and 3D carton presentation, egg journal, dual-track 50-tier season screen, and quest claims.
- [x] Implement same-server parties, private local Quick Races, friend spectating, and visitor/owner museum previews.
- [x] Compose and render original lobby/world music and gameplay cues. Asset IDs are creator-configured.

## Verification and rollout

- [x] Compile the client, shared, and server Luau. Deserialize the Rojo place with Lune and compare each embedded source with its file.
- [x] Exercise all 25 course builders and timed obstacle updates with headless Roblox mocks. Check ordered checkpoints, camera anchors, and relic IDs.
- [x] Simulate a 15-player Royale, final placement payouts, Adventure checkpoint recovery, and isolation of private Quick Races.
- [x] Verify earned-only carton spending, displayed odds, collection reachability, premium entitlement idempotency, legacy receipt migration, and social authorization using mocks.
- [x] Build and crack all 103 egg variants with Roblox datatypes. Check the shared shell envelope and collision settings.

- [ ] Verify the full roster tournament, smaller rosters, simultaneous finishes, late disconnects, and team joins in Roblox Studio with multiple clients.
- [ ] Time successful clean and imperfect runs on each of the 24 routes in Studio. Tune the 120–180 second target, required jumps, hidden relic detours, and hazard avoidance with actual avatar physics.
- [ ] Check R15 and R6 grip positions, private Quick Race exits, spectate recovery, museum access, controller focus, touch layouts, and reduced-motion behavior.
- [ ] Test profile transfer, real pass acquisition and restored ownership, reward retries, DataStore failures, and the legacy receipt migration in a private published experience.
- [ ] Upload original audio assets, configure approved asset/pass IDs, and verify prices, permissions, and audio playback in the published test experience.

## Implementation boundaries

Party membership and private Quick Races are scoped to the active Roblox server. Cross-server parties, reserved servers, and invite routing need a separate TeleportService and MemoryStore rollout. The course library has 23 low-level obstacle types and 24 composable encounter builders. A broader 40-type primitive library, bespoke uploaded course poster art, and authored lobby emote animation assets remain content work. World layouts, art, audio, and content pacing still require an in-engine playtest. A successful source build does not establish device performance or actual course clear times.
