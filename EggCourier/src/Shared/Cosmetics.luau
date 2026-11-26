-- Carton IDs are acquisition identifiers. These cosmetic definitions confer
-- no movement, durability, collision, qualification, or reward advantages.
local Cosmetics = {}
Cosmetics.rarities = {
	Common = {mark = "●", color = "e4dced", weight = 40},
	Uncommon = {mark = "▲", color = "a4e1aa", weight = 27},
	Rare = {mark = "◆", color = "a9d8ff", weight = 17},
	Epic = {mark = "✦", color = "d6b9fa", weight = 10},
	Legendary = {mark = "★", color = "ffd27e", weight = 5},
	Mythic = {mark = "✸", color = "ffa6cb", weight = 1},
}
Cosmetics.rarityOrder = {"Common","Uncommon","Rare","Epic","Legendary","Mythic"}
Cosmetics.sources = {
	starter = "Granted to every courier",
	legacy = "Legacy locker cosmetic",
	classic = "Classic Carton",
	adventure = "Adventure Carton",
	enchanted = "Enchanted Carton",
	royal = "Royal Carton",
	galactic = "Galactic Carton",
	champion = "Champion Carton",
	starterCollector = "Starter Collector Carton",
	pirateCollector = "Pirate Collector Carton",
	relicCollector = "Ancient Relic Collector Carton",
	dragonCollector = "Dragon Collector Carton",
	galacticCollector = "Galactic Collector Carton",
	deluxeCollector = "Deluxe Collector Collection",
	season = "The Great Eggscape season track",
}
Cosmetics.collections = {
	{"Farmstand", "Farmstand"}, {"Expedition", "Expedition"}, {"Pirate", "Pirate"},
	{"Prehistoric", "Prehistoric"}, {"Magical", "Magical"}, {"Royal", "Royal"},
	{"Galactic", "Galactic"}, {"Championship", "Championship"}, {"Skyline", "Skyline"},
	{"Glacier", "Glacier"}, {"Foundry", "Foundry"},
}
local raw = {
	-- ID, display name, rarity rank, collection, shell/accent, model motifs, observation.
	starter = {
		{"Classic","Classic Egg",1,"Farmstand","fff0d2","ffb978","","The original, dependable delivery shell."},
	},
	legacy = {
		{"Chocolate","Chocolate Egg",1,"Farmstand","71392a","eb9a62","","Caramel icing and a handful of sugar sprinkles."},
		{"Watermelon","Watermelon Egg",1,"Farmstand","41b85c","ff6177","","A hand-striped shell with a juicy melon badge."},
		{"Ninja","Ninja Egg",3,"Skyline","2a2e48","f45362","","A scarlet headband for the quiet route."},
		{"Dinosaur","Dinosaur Egg",3,"Prehistoric","87db4b","287b62","","Soft ridges from a very tiny thunder lizard."},
		{"Frozen","Frozen Egg",4,"Glacier","93e1ff","3d8aff","","Ice shards catch the light on every turn."},
		{"Lava","Lava Egg",5,"Foundry","241d27","ff672b","","Warm magma glows between the cooled basalt plates."},
		{"Cosmic","Cosmic Champion",6,"Championship","8d4be2","52ffdd","","A comet halo for an old league champion."},
		{"Golden","Golden Egg",5,"Royal","ffc436","fff58c","","Polished gold with diamond-cut badges."},
		{"Rainbow","Animated Rainbow Egg",4,"Magical","fa78c2","5dd7ff","","A prism ribbon curves around the shell."},
		{"Galaxy","Galaxy Egg",5,"Galactic","4d33a1","fa76ed","","A little planet with a dusty ring."},
		{"Royal","Royal Egg",5,"Royal","9d36b2","ffd44a","","A jeweled crown belongs on top."},
		{"VIP","VIP Egg Courier",5,"Skyline","4beadd","ffdd63","","A retired aviator with gold-rimmed goggles."},
	},
	classic = {
		{"DaisyDip","Daisy Dip",1,"Farmstand","ffefad","f6ad62","bloom seed","Three daisies and a pollen-yellow shell."},
		{"CiderChick","Cider Chick",1,"Farmstand","f6cb6d","ed824f","beak tuft","A downy orchard chick with a crooked feather."},
		{"HoneyHush","Honey Hush",2,"Farmstand","f2aa4d","442842","stripe antenna","A striped worker bee with springy feelers."},
		{"BlueberryBasket","Blueberry Basket",2,"Farmstand","556cbc","b4df79","basket leaf","A painted berry perched in a woven basket."},
		{"PuddlePup","Puddle Pup",2,"Farmstand","dcbda8","694635","ear snout","A floppy-eared farm dog with a very muddy nose."},
		{"MoonMoth","Moon Moth",3,"Farmstand","9da3cc","f8dfb1","wing antenna","Night wings unfurl under a pair of bright feelers."},
		{"CactusSprout","Cactus Sprout",3,"Farmstand","6ab278","f48b98","cactus bloom","Round cactus pads sprout a pink flower."},
		{"PicnicParade","Picnic Parade",4,"Farmstand","f8bcc5","58b5aa","basket bow seed","A gingham bow dresses up a basket of berries."},
	},
	adventure = {
		{"Explorer","Explorer Egg",1,"Expedition","ce9a62","a74b53","hat scarf","A sun hat and handkerchief from the expedition camp."},
		{"AncientRelic","Ancient Relic Egg",2,"Expedition","b78d65","527969","panel glyph","Weathered stone with an old trail symbol."},
		{"GoldenIdol","Golden Idol Egg",3,"Expedition","b7832c","ffe294","totem bead","A hollow idol from a forgotten trail marker."},
		{"EmeraldGuardian","Emerald Guardian Egg",4,"Expedition","338771","adedad","armor crystal","A green crystal guarded by ceremonial armor."},
		{"CrystalSkull","Crystal Skull Egg",4,"Expedition","aacfe1","f1f9ff","skull shard","Deep eye sockets cut into blue crystal."},
		{"Captain","Captain Egg",2,"Pirate","653b58","f4bf70","tricorn anchor","A ship captain's hat with a brass anchor."},
		{"Treasure","Treasure Egg",3,"Pirate","926443","f2cc71","lock coins","A strapped specimen pocket jingles with spare coins."},
		{"Fossil","Fossil Egg",2,"Prehistoric","b68664","edd9ad","fossil ridge","The fossil of a curled little creature shows through."},
	},
	enchanted = {
		{"Sorcerer","Sorcerer Egg",2,"Magical","7956b7","f5beea","wizard glyph","A crooked felt hat and charcoal chalk charms."},
		{"Potion","Potion Egg",2,"Magical","64b6b7","c7ee88","bottle bubble","A corked flask full of peppermint bubbles."},
		{"EnchantedBook","Enchanted Book Egg",3,"Magical","8c4866","eac26f","book lock","A very small field guide with oversized clasps."},
		{"Phoenix","Phoenix Egg",4,"Magical","e87449","ffe397","flame wing","Swept flame feathers shaped like sunrise."},
		{"CelestialWizard","Celestial Wizard Egg",5,"Magical","4d478d","edd7ff","wizard orbit star","A constellation and orbiting moons crown a tall hat."},
		{"Nimbus","Nimbus Egg",2,"Skyline","a8c6df","fff4df","cloud bolt","Cloud puffs keep the little lightning stripe company."},
		{"CrystalWisp","Crystal Wisp",3,"Glacier","6cafc4","c9fbff","crystal halo","Frozen lanterns hang around a crystal plume."},
		{"SugarSpell","Sugar Spell",3,"Magical","e79dbd","9edace","candy bow","Sugared ribbons decorate a wizard's favorite treat."},
	},
	royal = {
		{"SilkRibbon","Silk Ribbon Egg",2,"Royal","d66388","ffc3bb","bow fringe","Silk loops and tiny tassels cover a parade shell."},
		{"MarbleCrest","Marble Crest Egg",3,"Royal","c9bdbe","76618e","crest panel","A sculpted coat of arms is inset into carved marble."},
		{"PearlKnight","Pearl Knight Egg",3,"Royal","bab7cf","6b89ac","armor visor","Rounded pearl armor with a blue visor."},
		{"RoseCourt","Rose Court Egg",4,"Royal","974968","ffbdcc","bloom crown","A crown threaded with three roses."},
		{"VelvetOrb","Velvet Orb Egg",4,"Royal","623869","df9946","crown orb","The court orb sits under a tiny coronet."},
		{"SovereignSwan","Sovereign Swan",5,"Royal","e0d6d8","e3b15e","wing beak halo","Pale fanned wings and a gold circlet."},
		{"PalaceMirror","Palace Mirror",3,"Royal","9794bb","f4be73","mirror fringe","A mirror set in quilted velvet and brass."},
		{"SunsetDuchess","Sunset Duchess",5,"Royal","a34765","ffdb92","crest flare crown","The rays of the sun frame a royal insignia."},
	},
	galactic = {
		{"SpaceExplorer","Space Explorer Egg",2,"Galactic","e5dfdb","6196b6","helmet pack","A hand-me-down pressure helmet and oxygen pack."},
		{"Alien","Alien Egg",2,"Galactic","78b581","9369d0","antenna visor","A wide-eyed explorer from a neighboring moon."},
		{"Meteor","Meteor Egg",3,"Galactic","74566b","f9a269","crater flame","Fresh impact craters and glowing reentry fins."},
		{"Nebula","Nebula Egg",4,"Galactic","7257a6","f0a9ec","cloud star","Clusters of dust and neon points form a nebula."},
		{"GalacticEmperor","Galactic Emperor",5,"Galactic","443d79","a9e8e0","crown orbit planet","Three little satellites circle a celestial crown."},
		{"PulseDrive","Pulse Drive",3,"Galactic","445c72","6be7da","panel bolt pack","A frame of coolant lines powers this little rocket."},
		{"MoonCourier","Moon Courier",3,"Galactic","8e9eae","efe2a6","crater antenna helmet","An ancient rover with a sun-faded helmet."},
		{"RingBeacon","Ring Beacon",4,"Galactic","576d94","e6b4ff","planet halo orb","A double ring guards an ice-blue navigation beacon."},
	},
	champion = {
		{"CheckeredChamp","Checkered Champ",3,"Championship","dad1dd","e47766","checker visor","A racing visor meets the checkered finish line."},
		{"BronzeBolt","Bronze Bolt",3,"Championship","925a47","ffb575","bolt medal","A sprint medal cast in burnished bronze."},
		{"SilverFeather","Silver Feather",4,"Championship","b6bad2","69a8b8","medal wing","Silver wings celebrate a comeback finish."},
		{"ArenaTorch","Arena Torch",4,"Championship","c77854","ffde9a","torch crest","The arena torch is reborn as a parade egg."},
		{"VictoryLaurels","Victory Laurels",5,"Championship","d3aa53","c7edb1","leaf medal crown","Laurels frame a champion's hanging medal."},
		{"GoldPodium","Gold Podium",5,"Championship","f3c158","8f536a","trophy checker","The winner's cup and two finish-line stripes."},
		{"CloudTrophy","Cloud Trophy",5,"Championship","bba5e3","ffed8f","trophy cloud halo","A trophy rising from a celebratory cloud."},
		{"GrandFinale","Grand Finale",6,"Championship","3f4c83","ffd7a0","trophy flare orbit","A luminous winner's cup framed in dancing lights."},
	},
	starterCollector = {
		{"RainCoat","Rain Coat Egg",2,"Farmstand","f4d678","69b8c7","hood boot","A rain slicker built for very small puddle jumps."},
		{"BerryBaker","Berry Baker Egg",2,"Farmstand","e0a6b6","f5e2cb","chef apron","An apron and baker's cap with a dusting of flour."},
		{"PumpkinCart","Pumpkin Cart Egg",3,"Farmstand","ec9654","4c8f68","leaf wheel","A lacquered autumn cart with its harvest on top."},
		{"RoseBeetle","Rose Beetle Egg",3,"Farmstand","bc5c74","e5ac80","stripe wing","A rose-colored beetle with bronze wing cases."},
	},
	pirateCollector = {
		{"GhostShip","Ghost Ship Egg",4,"Pirate","52878c","b9f6ea","ship sail halo","A stern lantern glows through ghostly sails."},
		{"Kraken","Kraken Egg",4,"Pirate","965686","6acbad","tentacle orb","Four tentacles guard a sea-glass pearl."},
		{"GoldenCompass","Golden Compass Egg",5,"Pirate","ba884c","ffe094","compass fringe","A compass framed in hanging brass markers."},
		{"Saltwind","Saltwind Egg",3,"Pirate","89725e","b2d8d4","tricorn sail","An old captain's hat beneath a painted canvas sail."},
	},
	relicCollector = {
		{"JadeSentinel","Jade Sentinel Egg",4,"Expedition","4e8773","e5c18b","totem armor","A jade guide carved with protective armor."},
		{"CavernLens","Cavern Lens Egg",3,"Expedition","516d76","f3d99f","mirror pack","An expedition lantern and a storage pack."},
		{"SandOracle","Sand Oracle Egg",4,"Expedition","bc8257","8de2d3","hood orb glyph","A copper oracle keeps an aquamarine pearl."},
		{"AncientGuardian","Ancient Guardian",6,"Expedition","295c59","efbd64","totem crown orbit","A crown and orbiting stones animate this old guardian."},
	},
	dragonCollector = {
		{"AncientDragon","Ancient Dragon Egg",5,"Prehistoric","995485","f5a365","ridge flame wing","A cave dragon with feather-shaped flames."},
		{"StormWyvern","Storm Wyvern Egg",5,"Magical","49548d","a7f2f1","horn bolt wing","A lightning stripe splits two folded wings."},
		{"FrostWyrm","Frost Wyrm Egg",4,"Glacier","7eafd0","e4fcff","horn shard tentacle","The icy horns of a glacier-dwelling wyrm."},
		{"AmberDrake","Amber Drake Egg",4,"Prehistoric","ae7843","ffc46b","fossil horn wing","A fossil drake caught in sunlit amber."},
	},
	galacticCollector = {
		{"IonNavigator","Ion Navigator",4,"Galactic","41818a","b4f5f2","visor compass panel","An ion compass glows behind tinted glass."},
		{"SatelliteScout","Satellite Scout",4,"Galactic","6870a2","ffc06e","antenna solar orbit","A solar-powered scout with three small satellites."},
		{"RedDwarf","Red Dwarf Egg",5,"Galactic","914d67","ffa666","flare planet crater","A glowing stellar rim marks these old craters."},
		{"EventHorizon","Event Horizon",6,"Galactic","382d5b","f6c4f9","planet orbit flare","A shifting ring circles a dark stellar core."},
	},
	deluxeCollector = {
		{"CloudConductor","Cloud Conductor",5,"Skyline","7da2ca","fae198","cloud hat bolt","A weather conductor keeps lightning tucked under a hat."},
		{"PalaceArtisan","Palace Artisan",5,"Royal","94668b","f1c985","apron crest fringe","A royal artisan's apron made from parade ribbons."},
		{"SugarEngine","Sugar Engine",5,"Foundry","dd8da2","9de5de","candy wheel pack","An elaborate clockwork wagon delivers sugar drops."},
		{"DaydreamBeacon","Daydream Beacon",6,"Magical","7566b9","ffdda2","flame mirror orbit","A magical mirror scatters dancing lights."},
	},
	season = {
		{"CampLantern","Camp Lantern",2,"Expedition","87724b","ffcd76","torch pack","An expedition lantern with a comfortable back strap."},
		{"IndigoFieldNote","Indigo Field Note",3,"Expedition","6a6193","e0b87b","book compass","A field notebook cataloging mountain paths."},
		{"TideChart","Tide Chart Egg",3,"Pirate","518e9b","e7d7a3","compass book","A chart pitched at the angle of a passing swell."},
		{"CannonPearl","Cannon Pearl",4,"Pirate","52516b","a9dfd3","ship orb lock","A ship's bow frames a rare pearl."},
		{"Raptor","Raptor Egg",2,"Prehistoric","6e9859","e2b382","ridge beak","A chirpy hatchling with a serrated spine."},
		{"Triceratops","Triceratops Egg",3,"Prehistoric","7a8e6d","ead59f","horn crest","A broad frill and three short horns."},
		{"Amber","Amber Egg",3,"Prehistoric","b47142","f9bf58","fossil bubble","Tiny bubbles surround a perfectly preserved fossil."},
		{"LavaCourier","Lava Courier",3,"Foundry","8a4f58","ffb562","boot flame","Heat-resistant boots and smoldering fins."},
		{"ConveyorCaptain","Conveyor Captain",4,"Foundry","65516e","eeb57e","wheel helmet","A factory captain's round helmet and two spoked wheels."},
		{"IceSignal","Ice Signal",3,"Glacier","6ebbce","ebd4fc","shard antenna bolt","A radio signal trapped in a field of ice."},
		{"CrystalLift","Crystal Lift",4,"Glacier","6894b9","d2f3eb","crystal pack orbit","A counterweight set suspends ice crystals in midair."},
		{"SkyGlider","Sky Glider Egg",3,"Skyline","a5a5d9","ffca92","wing visor","Rounded wings fold under a pilot visor."},
		{"CrownVoyager","Crown Voyager",4,"Royal","a3698f","edca73","crown sail","A little sailboat ferries a palace crown."},
		{"CometShuttle","Comet Shuttle",4,"Galactic","6f5895","a2e4ef","solar flame pack","Solar panels flare around a comet-chasing shuttle."},
		{"MeteorChaser","Meteor Chaser",5,"Galactic","645977","fdbf8c","crater helmet orbit","A meteor helmet with three trailing navigation lights."},
		{"MedalMaker","Medal Maker",4,"Championship","b9836c","fee194","apron medal wheel","The maker who cuts and stamps every race medal."},
		{"RelicPathfinder","Relic Pathfinder",5,"Expedition","897653","a5e9a6","totem compass halo","A trail-finding spirit with an illuminated dial."},
		{"EggscapeBeacon","Eggscape Beacon",6,"Championship","4b628b","ffe9a2","trophy orb orbit","The season's gold beacon inside a winner's trophy."},
	},
}
local order = {"starter","legacy","classic","adventure","enchanted","royal","galactic","champion",
	"starterCollector","pirateCollector","relicCollector","dragonCollector","galacticCollector","deluxeCollector","season"}
Cosmetics.entries, Cosmetics.byId = {}, {}
for _, source in ipairs(order) do
	for _, egg in ipairs(raw[source]) do
		local id,name,rank,collection,shell,accent,style,description = table.unpack(egg)
		local entry = {
			id=id, name=name, rarity=Cosmetics.rarityOrder[rank], rank=rank,
			collection=collection, shell=shell, accent=accent, style=style,
			description=description, source=source,
		}
		assert(not Cosmetics.byId[id],id)
		Cosmetics.byId[id] = entry
		table.insert(Cosmetics.entries, entry)
	end
end
return Cosmetics
