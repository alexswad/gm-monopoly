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
	self:CreateBoardModel()
end

function ENT:Use(ent)
	if self:GetPlayer(ent) then
		self:RemovePlayer(ent)
	else
		self:AddPlayer(ent)
	end
end

ENT.BoardModel = "models/props_phx/games/chess/board.mdl"
ENT.BoardPos = Vector(0, 0, 29)
ENT.BoardScale = 0.17
ENT.BoardAngle = Angle(-90, 0, 0)

function ENT:CreateBoardModel()
	if IsValid(self.BoardEntity) then
		self.BoardEntity:Remove()
	end

	local b = ents.Create("prop_dynamic")
	b:SetModel(self.BoardModel)
	b:SetModelScale(self.BoardScale)
	b:SetPos(self:LocalToWorld(self.BoardPos))
	b:SetAngles(self:LocalToWorldAngles(self.BoardAngle))
	b:SetParent(self)
	b:Spawn()
	b:DeleteOnRemove(self)
	b:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	self:DeleteOnRemove(b)
	self.BoardEntity = b
end