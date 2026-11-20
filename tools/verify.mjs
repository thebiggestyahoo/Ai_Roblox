// Usage: node tools/verify.mjs /path/to/node_modules /path/to/uncompressed-place.rbxl
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { createRequire } from "node:module";
import { pathToFileURL, fileURLToPath } from "node:url";
import { resolve } from "node:path";
const repo = fileURLToPath(new URL("../", import.meta.url));
const modules = resolve(process.argv[2]);
const { LuauState } = await import(pathToFileURL(resolve(modules,"luau-web/src/index.js")));
const require = createRequire(import.meta.url);
const reader = require(resolve(modules,"rbx-reader"));
const sources = new Map(readdirSync(resolve(repo,"src")).map(name=>[name,readFileSync(resolve(repo,"src",name),"utf8")]));
const state=await LuauState.createAsync();
for (const [file,source] of sources) state.loadstring(source,file,true);
const {instances}=reader.parseBuffer(readFileSync(process.argv[3]));
const classes={".client.luau":"LocalScript",".server.luau":"Script",".luau":"ModuleScript"};
for (const [file,source] of sources) {
    const [name,ext]=file.match(/^([^.]+)(.*)$/).slice(1);
    const found=instances.find(el=>el.Name===name && el.ClassName===classes[ext]);
    assert.equal(found && Buffer.from(found.Source,"latin1").toString("utf8"),source,file);
    if(ext!==".luau") assert.equal(found.Disabled,false,file);
}
assert.equal(instances.find(el=>el.Name==="hide_playeravatar").Disabled,true);
assert.equal(instances.find(el=>el.ClassName==="Workspace").StreamingEnabled,false);
const timeline=JSON.parse(readFileSync(resolve(repo,"media/STORY_TIMELINE.json")));
assert.equal(timeline.scenes.length,12);
assert.equal(timeline.duration,174);
const narration=readFileSync(resolve(repo,"media/NARRATION_FIRST_PERSON.txt"),"utf8").trim().split(/\r?\n\r?\n/);
for (const [i,scene] of timeline.scenes.entries()) {
    assert.equal(scene.narration,narration[i]);
    assert.equal(scene.captions.map(c=>c[2]).join(" "),narration[i]);
    for(const [j, [a,b]] of scene.captions.entries()){
        assert(a>=scene.start && a<b && b<=scene.end);
        if(j>0) assert(scene.captions[j-1][1]<=a);
    }
}
const smoke=state.loadstring(`
local vector = {}
local function V(x,y,z) return setmetatable({x=x,y=y,z=z},vector) end
vector.__add=function(a,b) return V(a.x+b.x,a.y+b.y,a.z+b.z) end
vector.__sub=function(a,b) return V(a.x-b.x,a.y-b.y,a.z-b.z) end
vector.__mul=function(a,b) return V(a.x*b,a.y*b,a.z*b) end
local Vector3={new=V}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<10000 end
local function vec(v) assert(finite(v.x) and finite(v.y) and finite(v.z)) end
local story=(function()
${sources.get("StoryData.luau")}
end)()
local timing=(function()
${sources.get("NarrationTiming.luau")}
end)()
local cast={Noah=true,Lucas=true,Keeper=true,Rumor=true,Teacher=true,Student=true,Extra=true,YoungNoah=true,YoungLucas=true}
local props={watch=true,photo=true,phone=true,ledger=true}
local sets={School=true,Yard=true,Shop=true,Street=true,Home=true,River=true}
local covered, ledger, transfer, replace = {},{}, {},0
local c = {}
function c:set(set,look) assert(sets[set] and type(look)=="string") self.scene=set covered[set]=true end
function c:actor(role,pos,dir,data)
	assert(cast[role] and self.scene and not self.roles[role],role)
	self.roles[role]=true
	vec(pos) vec(dir)
	assert(math.abs(dir.x)+math.abs(dir.z)>0)
	for _,n in data do assert(finite(n)) end
end
function c:walk(role,a,b,t,start,finish,mode,pose)
	assert(start<finish and (mode=="run" or mode=="walk"))
	vec(b)
	self:actor(role,a,b-a,pose)
end
function c:prop(key,p) assert(props[key]) vec(p) self.seen[key]=true end
function c:hand(key,role,p) assert(self.roles[role]) self:prop(key,p) end
function c:transfer(key,a,b,u,p)
	assert(self.roles[a] and self.roles[b] and u>=0 and u<=1)
	self:prop(key,p)
	transfer[key]=true
end
function c:pocket(key,role) self:hand(key,role,V(0,0,0)) end
function c:ledger(open,text)
	assert(open>=0 and open<=1 and self.seen.ledger)
	ledger[text]=true
end
function c:shot(f,t,fov,d,key)
	vec(f) vec(t) vec(d)
	assert(fov>20 and fov<70 and self.scene)
	if key then assert(self.seen[key],key) end
	self.shots+=1
end
function c:door(n) assert(finite(n)) end
function c:houseDoor(n) self:door(n) end
function c:shopLight(n) self:door(n) end
function c:mist(n) self:door(n) end
function c:rewind(n) self:door(n) replace+=1 end
function c:glow(n) self:door(n) end
local frames=0
assert(#story==12 and timing.finish<180)
for i,scene in story do
	local seconds=(timing.starts[i+1] or timing.finish)-timing.starts[i]
	for frame=0,seconds*30-1 do
		c.scene,c.shots,c.roles,c.seen=nil,0,{},{}
		scene(c,frame/30*timing.rate)
		assert(c.shots==1,"Expected one authored camera per frame")
		frames+=1
	end
end
for name in sets do assert(covered[name],name) end
assert(ledger["LUCAS — ALL MEMORIES\\nOF NOAH"])
assert(transfer.watch and transfer.photo and replace>0)
return frames
`,"story smoke",true);
assert.deepEqual(await smoke(),[5220]);
console.log("Compiled 8 Luau scripts, verified 8 embedded sources, simulated 5,220 frames across 12 scenes, and checked verbatim timed captions.");
const build=state.loadstring(`
local V
local vector={}
V=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vector) end
vector.__add=function(a,b) return V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vector.__mul=function(a,b) return V(a.X*b,a.Y*b,a.Z*b) end
local frame={}
local function cf(a,b,c) return setmetatable({Position=type(a)=="table" and a or V(a or 0,b or 0,c or 0)},frame) end
frame.__mul=function(a,b) return cf(a.Position+b.Position) end
local CFrame={new=cf,Angles=function() return cf() end}
local Vector3={new=V}
local Color3={fromRGB=V}
local UDim2={fromScale=function() return {} end}
local Enum=setmetatable({},{__index=function() return setmetatable({},{__index=function(_,key) return key end}) end})
local records={}
local function new(class)
	local node={ClassName=class,destroyed=false}
	function node:FindFirstChild(name)
		for _,other in records do if other.Parent==self and other.Name==name and not other.destroyed then return other end end
	end
	function node:Destroy() self.destroyed=true end
	table.insert(records,node)
	return node
end
local Instance={new=new}
local workspace=new("Workspace")
local base=new("Part")
base.Name,base.Parent="Baseplate",workspace
local World=(function()
${sources.get("WorldBuilder.luau")}
end)()
local root=World.build()
assert(root.Parent==workspace and base.destroyed)
for name in World.origins do assert(root:FindFirstChild(name),name) end
local shop=root:FindFirstChild("Shop")
assert(shop:FindFirstChild("Door") and shop:FindFirstChild("Shop title") and shop:FindFirstChild("Counter warning"))
for i=1,12 do assert(shop:FindFirstChild("Clock"..i)) end
assert(root:FindFirstChild("Home"):FindFirstChild("HouseDoor"))
assert(root:FindFirstChild("River"):FindFirstChild("Climbable ladder"))
assert(root:FindFirstChild("School"):FindFirstChild("Chalkboard"))
local parts=0
for _,node in records do
	if node.ClassName=="Part" and not node.destroyed then
		assert(node.Parent and node.Anchored and node.Size.X>0 and node.Size.Y>0 and node.Size.Z>0,node.Name)
		parts+=1
	end
end
assert(parts>500 and parts<1600)
return parts
`, "world geometry smoke", true);
const [parts]=await build();
console.log(`Constructed ${parts} anchored set parts with mocked Roblox instances and checked set landmarks.`);
state.destroy();
