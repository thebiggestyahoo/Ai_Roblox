local Levels = {}

Levels.worlds = {
	{key="temple", name="The Lost Temple", color="356950", accent="ffdb73", hook="An expedition unlocks a living mountain.", icon="idol", relic="Sun idol"},
	{key="pirate", name="The Pirate's Secret", color="216985", accent="ffbe7a", hook="Follow a flooded cave to a ship that should not exist.", icon="ship", relic="Compass piece"},
	{key="prehistoric", name="Prehistoric Panic", color="3d693e", accent="ffd084", hook="A research station races a creature migration.", icon="fossil", relic="Amber fossil"},
	{key="factory", name="The Impossible Factory", color="8a4e85", accent="ffd787", hook="An impossible candy workshop has a delivery deadline.", icon="gear", relic="Candy recipe stamp"},
	{key="frozen", name="Frostbite Peaks", color="40658e", accent="b4f3ff", hook="The last mountain lift leaves before the storm.", icon="crystal", relic="Frost crystal"},
	{key="cloud", name="Cloud Kingdom", color="614c96", accent="ffe19a", hook="Chase the sky fleet through a city on the wind.", icon="cloud", relic="Sky seal"},
	{key="neon", name="Neon Metropolis", color="523982", accent="8effec", hook="Beat the last train across a city that never dims.", icon="tower", relic="Signal chip"},
	{key="galactic", name="Galactic Escape", color="3b3b79", accent="f2a9ff", hook="Evacuate a station while its gravity reboots.", icon="planet", relic="Star fragment"},
}
Levels.worldByKey = {}
for _, world in ipairs(Levels.worlds) do
	Levels.worldByKey[world.key] = world
end

local rating = {"Beginner", "Easy", "Moderate", "Hard", "Expert"}

local function course(worldKey,key,name,stars,hook,sections,championship)
	local world = Levels.worldByKey[worldKey]
	local limit = 185 + stars*4
	local index = #Levels+1
	Levels[index] = {
		key=key, worldKey=worldKey, island=world.name, name=name, stars=stars,
		rating=rating[stars], hook=hook, sections=sections, time=limit,
		medal={gold=115+stars*4, silver=142+stars*4, bronze=limit},
		pace=0.86+stars*0.03, championship=championship == true,
	}
	return index
end

-- Chapters use consecutive playable encounters. A course's order determines
-- where its optional relic can be found and where Adventure restores the player.
course("temple","sun-vault","The Sun Vault",2,"Open the jungle vault, outrun the idol's stone guard, and catch a minecart.",
	{"expedition","idolRoom","boulderRun","cartTracks","waterfall","sunExit"})
course("temple","broken-aqueduct","The Broken Aqueduct",3,"Follow the dry canal into a flooded temple and reopen its sky bridge.",
	{"rootway","floodgates","relicGallery","crackBridge","waterfall","cartTracks"})
course("temple","echoes-below","Echoes Below",4,"Find a route through the mountain's rotating rooms before the lanterns go dark.",
	{"relicGallery","turningDoors","rootway","cartTracks","boulderRun","sunExit"})
course("pirate","tideglass-grotto","Tideglass Grotto",2,"Find the village trapdoor, ride the spillway, and board a hidden ship.",
	{"harbor","seaSlide","rigging","ghostShip","floodgates","reefExit"})
course("pirate","moon-tide-run","Moon Tide Run",3,"Cross flooded docks and sail a rocking ferry to the smuggler's rope bridge.",
	{"smuggler","tidePools","ghostShip","crackBridge","seaSlide","reefExit"})
course("pirate","captains-last-call","Captain's Last Call",4,"Race the returning tide from the captain's hold to an open-water escape.",
	{"ghostShip","smuggler","seaSlide","rigging","tidePools","reefExit"})
course("prehistoric","amber-outpost","Amber Outpost",2,"Power the research lifts and guide your egg through a giant creature migration.",
	{"fieldStation","rootway","migration","researchLift","fossilBasin","canopyExit"})
course("prehistoric","raptor-ridge","Raptor Ridge",3,"Escape a ridge-side dig by climbing fossil terraces and crossing the nest trails.",
	{"fossilBasin","migration","canopyLift","crackBridge","fieldStation","canopyExit"})
course("prehistoric","last-tram-out","Last Tram Out",4,"Keep up with the supply tram as the forest breaks through the research base.",
	{"researchLift","fieldStation","cartTracks","migration","canopyLift","canopyExit"})
course("factory","midnight-delivery","Midnight Delivery",1,"Take the candy line through frosting rollers before the packing bell.",
	{"candyWorks","chocolateRiver","mixingRoom","frostingLine","crackBridge","sugarExit"})
course("factory","runaway-recipe","Runaway Recipe",3,"Chase a runaway batch between giant mixers and the furnace belts.",
	{"mixingRoom","candyWorks","furnace","caramelLift","frostingLine","sugarExit"})
course("factory","clockwork-cocoa","Clockwork Cocoa",4,"Read the boiler signals and ride a transforming assembly line out of the factory.",
	{"furnace","chocolateRiver","caramelLift","candyWorks","mixingRoom","sugarExit"})
course("frozen","glacier-express","Glacier Express",2,"Catch the mountain gondola after braving a snowball slalom.",
	{"skiVillage","avalanche","iceCaves","gondola","frostSpan","summitExit"})
course("frozen","crystal-underpass","Crystal Underpass",3,"Cut through a crystal cave and a frozen sluice to reach the summit.",
	{"iceCaves","frostSpan","floodgates","skiVillage","avalanche","gondola"})
course("frozen","whiteout-relay","Whiteout Relay",4,"Chain sheltered snowbanks and low-visibility bridge crossings above the valley.",
	{"gondola","avalanche","skiVillage","iceCaves","crackBridge","summitExit"})
course("cloud","windward-courier","Windward Courier",2,"Deliver to the sky fleet through floating gardens and gust gates.",
	{"skyGarden","gustGates","cloudSteps","airships","ringway","skyExit"})
course("cloud","floating-bell","The Floating Bell",3,"Cross drifting airships and climb a tower of cloud stairs to ring the harbor bell.",
	{"airships","skyGarden","ringway","cloudSteps","crackBridge","skyExit"})
course("cloud","thunder-mail","Thunder Mail",4,"Race a storm along sky bridges while wind switches the faster lanes.",
	{"gustGates","airships","ringway","frostSpan","cloudSteps","skyExit"})
course("neon","last-light-express","Last Light Express",2,"Catch the city's final elevated train by following its glowing signals.",
	{"rooftop","signalYard","maglev","arcade","overpass","neonExit"})
course("neon","signal-chase","Signal Chase",3,"Navigate the switchyard, climb a billboard spine, and race the night tram.",
	{"signalYard","rooftop","overpass","maglev","arcade","neonExit"})
course("neon","midnight-switch","Midnight Switch",4,"Use neon shortcuts and the slower service walkways to beat a power surge.",
	{"arcade","overpass","signalYard","crackBridge","maglev","neonExit"})
course("galactic","station-sunrise","Station Sunrise",3,"Leave the crew ring and leap onto the emergency shuttle.",
	{"orbitalDock","gravityLab","airlock","cargoSpin","satellites","launchExit"})
course("galactic","out-of-orbit","Out of Orbit",4,"Race a spin-up test through satellite arrays and a fractured cargo ring.",
	{"satellites","cargoSpin","orbitalDock","crackBridge","gravityLab","launchExit"})
course("galactic","ring-rescue","Ring Rescue",5,"Use the station's emergency doors, shifting cargo decks, and rescue thrusters.",
	{"airlock","orbitalDock","ringway","gravityLab","satellites","launchExit"})
Levels.final = course("galactic","championship","The Crown Launch",5,"Three finalists chase one golden capsule through a championship-only course.",
	{"crownEntry","cargoSpin","crownFerry","crackBridge","crownTower","crownFinish"},true)

return Levels
