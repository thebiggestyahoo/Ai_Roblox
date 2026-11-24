-- Each row builds a 46-stud station with a 14-stud checkpoint approach.
return {
	{name = "Big Ball Boulevard", time = 75, stations = {
		{"ball", "sweep"}, {"foam", "ball"}, {"sweep", "ball"}, {"beam", "sweep"}, {"ball", "sweep"},
	}},
	{name = "Spinner Showdown", time = 85, stations = {
		{"sweep", "sweep"}, {"moving", "sweep"}, {"zone", "ball"}, {"moving", "sweep"}, {"sweep", "sweep"},
	}},
	{name = "Punch Wall Panic", time = 90, stations = {
		{"foam", "foam"}, {"moving", "foam"}, {"foam", "sweep"}, {"zone", "foam"}, {"moving", "foam"},
	}},
	{name = "The Wobbly Bridge", time = 100, stations = {
		{"tilt", "beam"}, {"roller", "sweep"}, {"moving", "tilt"}, {"beam", "pendulum"}, {"zone", "sweep"},
	}},
	{name = "Meadow Mayhem", time = 110, stations = {
		{"ball", "foam"}, {"moving", "sweep"}, {"zone", "pendulum"}, {"tilt", "roller"}, {"pendulum", "pendulum"}, {"beam", "sweep"},
	}},
	future = {
		{name = "The Egg Cooker", difficulty = "Medium", palette = {0xf96335, 0x343046}, mechanics = {"conveyor", "vanish", "lava"}, levels = {"Lava Leap", "Conveyor Chaos", "Volcano Rush", "The Melting Bridge", "The Giant Egg Cooker"}},
		{name = "Frozen Eggs", difficulty = "Hard", palette = {0x83dcff, 0x435dc7}, mechanics = {"ice", "moving", "snowball", "wind"}, levels = {"Slippery Slopes", "Snowball Speedway", "Iceberg Islands", "Frozen Spinner", "Blizzard Mountain"}},
		{name = "Eggstraterrestrial", difficulty = "Extreme", palette = {0x9d54ff, 0x272251}, mechanics = {"gravity", "vanish", "roller"}, levels = {"Zero Gravity Jump", "Planet Hopper", "Cosmic Conveyor", "Galaxy Gauntlet", "The Final Egg"}, reward = "Cosmic"},
	},
}
