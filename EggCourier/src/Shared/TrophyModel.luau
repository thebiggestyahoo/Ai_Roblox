local Trophy = {}
local gold = Color3.fromHex("ffd15e")
local trim = Color3.fromHex("ffa63f")
local base = Color3.fromHex("402357")

function Trophy.build()
	local trophy = Instance.new("Model")
	trophy.Name = "Egg Royale Cup"
	local function part(name, size, pivot, color, shape)
		local t = Instance.new("Part")
		t.Name = name
		t.Size = size
		t.CFrame = pivot
		t.Color = color
		t.Material = if color == base then Enum.Material.SmoothPlastic else Enum.Material.Metal
		t.Shape = shape or Enum.PartType.Block
		t.Anchored = true
		t.CanCollide = false
		t.CanTouch = false
		t.CanQuery = false
		t.Parent = trophy
		return t
	end
	local stem = part("Cup pedestal",Vector3.new(1.5,0.31,1.11),CFrame.new(0,0.15,0),base)
	trophy.PrimaryPart = stem
	part("Gold nameplate",Vector3.new(1.17,0.14,0.05),CFrame.new(0,0.17,-0.56),gold)
	part("Stem",Vector3.new(0.31,0.49,0.33),CFrame.new(0,0.55,0),trim)
	part("Cup",Vector3.new(1.36,1.12,1.12),CFrame.new(0,1.29,0),gold,Enum.PartType.Ball)
	part("Cup lip",Vector3.new(0.18,1.42,1.42),CFrame.new(0,1.64,0)*CFrame.Angles(0,0,math.pi/2),trim,Enum.PartType.Cylinder)
	for _, side in {-1,1} do
		for index=0,6 do
			local a = index*math.pi/6-math.pi/2
			part("Looped handle",Vector3.new(0.19,0.19,0.19),
				CFrame.new(side*(0.51+math.cos(a)*0.49),1.38+math.sin(a)*0.37,0),trim,Enum.PartType.Ball)
		end
	end
	return trophy
end

return Trophy
