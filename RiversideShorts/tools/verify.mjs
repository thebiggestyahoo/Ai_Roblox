import assert from "node:assert/strict";
import {readFileSync, readdirSync, writeFileSync} from "node:fs";
import {createRequire} from "node:module";
import {pathToFileURL} from "node:url";
import {resolve} from "node:path";

const modules = resolve(process.argv[2]);
const {LuauState} = await import(pathToFileURL(resolve(modules,"luau-web/src/index.js")));
const reader = createRequire(import.meta.url)(resolve(modules,"rbx-reader"));
const state = await LuauState.createAsync();
const sources = Object.fromEntries(readdirSync("src").map(name=>[name,readFileSync("src/"+name,"utf8")]));
const {instances} = reader.parseBuffer(readFileSync(process.argv[3]));
for (const [file,source] of Object.entries(sources)) {
    state.loadstring(source,file,true);
    const name=file.split(".")[0];
    const node=instances.find(node=>node.Name===name && node.Source);
    assert(node);
    assert.equal(Buffer.from(node.Source,"latin1").toString("utf8"),source,file);
}
assert.equal(instances.find(node=>node.Name==="hide_playeravatar").Disabled,true);
const result = await state.loadstring(`
local vm={}
local function V(x,y,z) return setmetatable({x=x,y=y,z=z},vm) end
vm.__add=function(a,b) return V(a.x+b.x,a.y+b.y,a.z+b.z) end
vm.__sub=function(a,b) return V(a.x-b.x,a.y-b.y,a.z-b.z) end
vm.__mul=function(a,b) return V(a.x*b,a.y*b,a.z*b) end
vm.__unm=function(a) return a*-1 end
vm.__index=vm
function vm:Lerp(b,t) return self+(b-self)*t end
local Vector3={new=V}
local clock=(function()
${sources["NarrationTiming.luau"]}
end)()
local plot=(function()
${sources["StoryData.luau"]}
end)()
local cfg=(function()
${sources["Config.luau"]}
end)()
local ctx={}
local shots={}
local sceneSamples={}
local function valid(p) for _,n in p do assert(n==n and math.abs(n)<250) end end
function ctx:actor(role,p,dir,pose)
	assert(self.allowed[role] and not self.onstage[role],role)
	assert(math.abs(dir.x)+math.abs(dir.z)>.001)
	valid(p) valid(dir)
	self.onstage[role]=p
	for _,n in pose do assert(n==n) end
end
function ctx:path(role,a,b,t,i,j,mode,pose,face)
	assert(i<j and (mode=="walk" or mode=="run"))
	valid(b)
	local u=math.clamp((t-i)/(j-i),0,1)
	local r=.14
	local v=u-r/2
	if u<r then v=u*u/(2*r)
	elseif u>1-r then v=1-r-(1-u)^2/(2*r) end
	self:actor(role,a:Lerp(b,v/(1-r)),face or b-a,pose)
end
local props={bus=true,bag=true,cake=true,ticket=true,ball=true,plug=true,phone=true}
function ctx:prop(name,p) assert(props[name],name) valid(p) end
function ctx:hand(name,role) assert(props[name] and self.onstage[role],role) end
function ctx:transfer(name,a,b,t)
	self:hand(name,a) self:hand(name,b)
	assert(t>=0 and t<=1)
	self.transfers[name]=true
end
function ctx:toss(name,a,b,t) self:transfer(name,a,b,t) end
function ctx:shot(p,t,fov)
	assert(not self.camera and fov>=48)
	valid(p) valid(t)
	local d=p-t
	assert(d.x*d.x+d.y*d.y+d.z*d.z>=80,"Expected a full-figure wide shot")
	self.camera={p,t,fov}
	local row=table.concat({p.x,p.y,p.z,t.x,t.y,t.z},",")
	shots[row]=true
end
function ctx:tone(look) assert(look=="memory" or look=="next day") end
function ctx:lights(b) assert(type(b)=="boolean") end
function ctx:busState(o,b) assert(o>=0 and o<=1 and type(b)=="boolean") end
local films,beats,frames=0,0,0
local closest=math.huge
local closestAt=""
local tight={}
for key,film in plot do
	films+=1
	local track=clock[key]
	assert(track.finish>=90 and track.finish<=120 and #track.cues==#film.scenes)
	ctx.allowed,ctx.transfers={},{}
	for _,name in film.roles do assert(cfg.Cast[name]) ctx.allowed[name]=true end
	for i,scene in film.scenes do
		local cue=track.cues[i]
		assert(cue[2]>cue[1])
		if i>1 then assert(cue[1]==track.cues[i-1][2]) end
		beats+=1
		for frame=0,math.ceil((cue[2]-cue[1])*30) do
			ctx.onstage,ctx.camera={},false
			scene(ctx,math.clamp(frame/30/(cue[2]-cue[1]),0,1))
			assert(ctx.camera)
			if frame%15==0 or frame==math.ceil((cue[2]-cue[1])*30) then
				local camera,target,fov=table.unpack(ctx.camera)
				local row={key,i,frame,camera.x,camera.y,camera.z,target.x,target.y,target.z,fov}
				for role,mark in ctx.onstage do
					if role~="Driver" then row[#row+1]=role row[#row+1]=mark.x row[#row+1]=mark.y row[#row+1]=mark.z end
				end
				table.insert(sceneSamples,table.concat(row,","))
			end
			for role,a in ctx.onstage do
				for other,b in ctx.onstage do
					if role<other and role~="Driver" and other~="Driver" and math.abs(a.y-b.y)<1.85 then
						local d=math.sqrt((a.x-b.x)^2+(a.z-b.z)^2)
						local label=key..":"..i..":"..role.."+"..other
						if d<closest then closest,closestAt=d,label end
						if d<3.3 then tight[label]=math.min(tight[label] or math.huge,d) end
					end
				end
			end
			frames+=1
		end
	end
	if key=="last-bus" then assert(ctx.transfers.cake and ctx.transfers.bag)
	else assert(ctx.transfers.ball) end
end
local reports={}
for key,d in tight do table.insert(reports,key.."="..string.format("%.2f",d)) end
local marks={}
for row in shots do table.insert(marks,row) end
return films,beats,frames,closest,closestAt,table.concat(reports,", "),table.concat(marks,";"),table.concat(sceneSamples,";")
`,"riverside scene simulation",true)();
assert.equal(result[0],2);
assert.equal(result[1],40);
console.log(`Verified 8 embedded sources and simulated ${result[2]} frames across ${result[0]} shorts.`);
console.log(`Minimum authored actor spacing: ${result[3].toFixed(2)} studs at ${result[4]}.`);
assert(result[3]>=3, result[5]);
const timing=JSON.parse(readFileSync("media/timings.json","utf8"));
for(const film of Object.values(timing)) {
    assert(film.finish>=90 && film.finish<=120);
    for(const cue of film.cues) {
        assert.equal(cue.captions.map(s=>s[2]).join(" "),cue.line);
        let last=cue.start;
        for(const [a,b,line] of cue.captions) {
            assert(a===last && b>a && line.length<=29 && b<=cue.finish);
            last=b;
        }
        assert.equal(last,cue.finish);
    }
}
const geometry=await state.loadstring(`
local vec={}
local function V(x,y,z) return setmetatable({x=x,y=y,z=z},vec) end
vec.__mul=function(a,b) return V(a.x*b,a.y*b,a.z*b) end
vec.__add=function(a,b) return V(a.x+b.x,a.y+b.y,a.z+b.z) end
local Vector3={new=V}
local cf={}
local function C(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},cf) end
cf.__mul=function(a,b) return C(a.x+b.x,a.y+b.y,a.z+b.z) end
local CFrame={new=C,Angles=function() return C() end}
local Color3={fromRGB=V}
local UDim2={fromScale=function() return {} end}
local Enum=setmetatable({},{__index=function() return setmetatable({},{__index=function(_,key) return key end}) end})
local nodes={}
local function new(class)
	local node={ClassName=class}
	function node:FindFirstChild(key)
		for _,part in nodes do if part.Parent==self and part.Name==key then return part end end
	end
	function node:Destroy() self.destroyed=true end
	table.insert(nodes,node)
	return node
end
local Instance={new=new}
local workspace=new("Workspace")
local base=new("Part")
base.Name,base.Parent="Baseplate",workspace
local world=(function()
${sources["WorldBuilder.luau"]}
end)().build()
assert(workspace:FindFirstChild("Riverside")==world)
assert(base.destroyed)
for _,name in {"Riverfront and town square","Mixed-use blocks","Riverside Park","Riverside transit","Streets and crossings","Town entrance"} do
	assert(world:FindFirstChild(name),name)
end
local built=0
local boxes={}
local appearance={}
for _,node in nodes do
	if node.ClassName=="Part" and not node.destroyed then
		assert(math.min(node.Size.x,node.Size.y,node.Size.z)>0,node.Name)
		built+=1
		local cf,size,color=node.CFrame,node.Size,node.Color
		table.insert(appearance,table.concat({cf.x,cf.y,cf.z,size.x,size.y,size.z,color.x,color.y,color.z,node.Shape or "Block",node.Transparency or 0},","))
		if node.CanCollide~=false and (node.Transparency or 0)<.48 then
			local c,d=node.CFrame,node.Size
			table.insert(boxes, table.concat({c.x,c.y,c.z,d.x,d.y,d.z},","))
		end
	end
end
return built,table.concat(boxes,";"),table.concat(appearance,";")
`,"town geometry",true)();
assert(geometry[0]>1000);
console.log(`Built ${geometry[0]} town parts in a headless Roblox-instance mock.`);
const boxes=geometry[1].split(";").map(row=>row.split(",").map(Number));
if(process.argv[4]) writeFileSync(process.argv[4], JSON.stringify({boxes, town:geometry[2].split(";").map(row=>row.split(",")), samples:result[7].split(";").map(row=>row.split(","))}));
for(const row of result[7].split(";")){
    const [film,beat,frame,...parts]=row.split(",");
    for(let i=7;i<parts.length;i+=4){
        const point=parts.slice(i+1,i+4).map(Number);
        point[1]+=2.25;
        const inScenery=boxes.some(([x,y,z,a,b,c])=>Math.abs(point[0]-x)<a/2-.01
            && Math.abs(point[1]-y)<b/2-.01 && Math.abs(point[2]-z)<c/2-.01);
        assert(!inScenery,`Torso mark in scenery: ${film} beat ${beat} frame ${frame} ${parts[i]}`);
    }
}
const shotMarks=result[6].split(";").map(row=>row.split(",").map(Number));
function available(position,target){
    return boxes.every(([x,y,z,w,h,d])=>{
        const ctr=[x,y,z], half=[w/2,h/2,d/2];
        if(position.every((v,i)=>Math.abs(v-ctr[i])<=half[i]+.56)) return false;
        let first=0,last=1;
        for(let i=0;i<3;i++){
            const delta=target[i]-position[i];
            if(Math.abs(delta)<1e-7){
                if(Math.abs(position[i]-ctr[i])>half[i]) return true;
                continue;
            }
            const t1=(ctr[i]-half[i]-position[i])/delta;
            const t2=(ctr[i]+half[i]-position[i])/delta;
            first=Math.max(first,Math.min(t1,t2));
            last=Math.min(last,Math.max(t1,t2));
            if(first>last) return true;
        }
        return false;
    });
}
let neededAlternate=0;
for (const [x,y,z,tx,ty,tz] of shotMarks) {
    const target=[tx,ty,tz], pos=[x,y,z], travel=Math.hypot(x-tx,y-ty,z-tz);
    const horiz=Math.hypot(x-tx,z-tz), ax=(tz-z)/horiz, az=(x-tx)/horiz;
    const move=(lateral,up)=>[x+lateral*ax,y+up,z+lateral*az];
    if (available(pos,target)) continue;
    neededAlternate++;
    const alternate=[move(2.7,.7),move(-2.7,.7),move(0,2.8),move(5.3,1.8),move(-5.3,1.8),
        [x+(x-tx)*3.5/travel,y+(y-ty)*3.5/travel+3.3,z+(z-tz)*3.5/travel],
        [tx+2,ty+14,tz-10],[tx-10,ty+11,tz-5]];
    assert(alternate.some(p=>available(p,target)),`No clear candidate for ${pos} → ${target}`);
}
console.log(`Checked ${shotMarks.length} distinct camera marks against approximate town bounds. ${neededAlternate} needed an alternate.`);
state.destroy();
