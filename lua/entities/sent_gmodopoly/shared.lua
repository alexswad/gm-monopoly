ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Monopoly Board"
ENT.Author = "Jenga"
ENT.Model = "models/props/de_tides/restaurant_table.mdl"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Fun + Games"


AddCSLuaFile("board_spaces.lua")
AddCSLuaFile("meta/board.lua")
AddCSLuaFile("meta/property.lua")
AddCSLuaFile("meta/player.lua")
include("board_spaces.lua")
include("meta/board.lua")
include("meta/property.lua")
include("meta/player.lua")

function ENT:SetupCache(type, slot, name, func)
	self:NetworkVar(type, slot, name)
	if CLIENT and func then
		self:NetworkVarNotify(name, func)
	end
end

function ENT:SetupDataTables()
	for i = 1, 8 do
		self:SetupCache("Entity", i, "Player" .. i, self.RebuildPlayerCache)
		self:SetupCache("Int", i, "PlayerFlags" .. i, self.RebuildPlayerInfoCache)
	end

	self:SetupCache("String", 0, "PropData", self.RebuildPropertyCache)

	//IDEA:  23 End Time | 3 Player #'s Turn | 5 State
	self:SetupCache("Int", 0, "StateData", self.RebuildStateCache)
end

function ENT:Think()
	local f = self.STATES[self:GetStateString()]
	if not f or f and not f(self, self:GetPlayerByIndex(self:GetTurn()), self.Players, self.Properties) then
		self:NextThink(CurTime() + 3)
		if CLIENT then self:SetNextClientThink(CurTime() + 3) end
	end
	return true
end