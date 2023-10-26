AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:SpawnFunction(ply, tr, cl)
	if not tr.Hit then return end
	local pos = tr.HitPos
	local ent = ents.Create(cl)

	ent:SetPos(pos)
	ent:Spawn()
	ent:Activate()
	if IsValid(ent:GetPhysicsObject()) then
		ent:GetPhysicsObject():EnableMotion(false)
	end
	//DEBUG
	mono = ent
	return ent
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:InitBoard()
end

function ENT:Use(ent)
	if self:GetPlayer(ent) then
		self:RemovePlayer(ent)
	else
		self:AddPlayer(ent)
	end
end