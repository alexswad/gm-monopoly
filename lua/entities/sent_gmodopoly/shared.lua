ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Monopoly Board"
ENT.Author = "Jenga"
ENT.Model = "models/props/de_tides/restaurant_table.mdl"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Fun + Games"


AddCSLuaFile("board_spaces.lua")
AddCSLuaFile("meta/flags.lua")
AddCSLuaFile("meta/board.lua")
AddCSLuaFile("meta/property.lua")
AddCSLuaFile("meta/player.lua")
AddCSLuaFile("meta/states.lua")
AddCSLuaFile("cards.lua")

AccessorFlags = include("meta/flags.lua")
include("board_spaces.lua")
include("meta/board.lua")
include("meta/states.lua")
include("meta/property.lua")
include("meta/player.lua")
include("cards.lua")

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

	self:SetupCache("Int", 0, "StateData", self.RebuildStateCache)
	self:SetupCache("Int", 9, "StartTime")
end

function ENT:Think()
	if #self.Players == 0 and self:GetState() ~= self.ST.WAITING then
		self:InitBoard()
		self:NextThink(CurTime() + 1)
		return true
	end

	if IsValid(self) and not self:CallState(self:GetState()) then
		self:NextThink(CurTime() + 3)
		if CLIENT then self:SetNextClientThink(CurTime() + 3) end
	end
	return true
end

// ONLY CALCULATES FORWARD DISTANCE
function ENT:SpaceDistance(start, final)
	if start < final then
		return final - start
	else
		return final + 40 - start
	end
end