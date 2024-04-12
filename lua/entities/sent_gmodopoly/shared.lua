ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Monopoly Board"
ENT.Author = "Axel"
ENT.Model = "models/props_c17/FurnitureTable001a.mdl"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Fun + Games"

AddCSLuaFile("board_spaces.lua")
AddCSLuaFile("cards_cfg.lua")
AddCSLuaFile("meta/flags.lua")
AddCSLuaFile("meta/board.lua")
AddCSLuaFile("meta/property.lua")
AddCSLuaFile("meta/player.lua")
AddCSLuaFile("meta/states.lua")
AddCSLuaFile("meta/cards.lua")

AddCSLuaFile("vgui/panel.lua")

AccessorFlags = include("meta/flags.lua")
include("board_spaces.lua")
include("cards_cfg.lua")
include("meta/board.lua")
include("meta/states.lua")
include("meta/property.lua")
include("meta/player.lua")
include("meta/cards.lua")
AccessorFlags = nil

function ENT:EZNetworkVar(type, slot, name, func)
	self:NetworkVar(type, slot, name)
	if CLIENT and func then
		self:NetworkVarNotify(name, func)
	end
end

function ENT:SetupDataTables()
	for i = 1, 8 do
		self:EZNetworkVar("Entity", i, "Player" .. i, self.RebuildPlayerCache)
		self:EZNetworkVar("Int", i, "PlayerFlags" .. i)
	end

	self:EZNetworkVar("String", 0, "PropData", self.RebuildPropertyCache)

	self:EZNetworkVar("Int", 0, "StateData", self.RebuildStateCache)
	self:EZNetworkVar("Int", 9, "StartTime")
end


function ENT:Think()
	if CLIENT and not IsValid(CMONPANEL) then
		CMONPANEL = vgui.CreateFromTable(MONPANEL)
		CMONPANEL.Board = self
	end

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