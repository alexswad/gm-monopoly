AccessorFunc(ENT, "Turn", "Turn")
AccessorFunc(ENT, "State", "State")

function ENT:InitBoard()
	self.Players = {}
	self.State = 1
	self.Turn = 0
	self:GenerateProperties()
end

function ENT:GenerateProperties()
	self.Properties = {}
	self.PropGroups = {}
	for k, v in pairs(self.BoardData) do
		if not istable(v) then continue end
		local prop = self:CreateProperty(v)
		prop.Index = k
		self.Properties[k] = prop
		if v.group then
			self.PropGroups[v.group] = self.PropGroups[v.group] or {}
			table.insert(self.PropGroups[v.group], prop)
		end
	end
end

-- function ENT:GetState()
-- 	return self.ST_ENUM.ROLL_FOR_ORDER
-- end

function ENT:GetStateName()
	return self.ST_STRING[self:GetState()] or "nil"
end

function ENT:GetStateString()
	return self.ST_STRING[self:GetState()] or false
end

ENT.STATES = {}

ENT.ST_ENUM = {
	WAITING = 1,
	ROLL_FOR_ORDER = 2, // 10000 -> 10004, 2000 -> 206....
	TURN = 3,
	MOVE = 4,
	OWE_RENT = 5,
	CHANCE = 6,
	COMMUNITY = 7,
	ROLL = 8,
	GO_TO_JAIL = 9,
	FREE_PARKING = 10,
	ROLL_UTILITY = 11,
	ROLL_JAIL = 12,
	TRADE = 13,
	BID = 14,
}

ENT.ST_STRING = {}
for k, v in pairs(ENT.ST_ENUM) do
	ENT.ST_STRING[v] = k
end

if SERVER then
	function ENT:HandleInput(ply, command)

	end

	function ENT.STATES:WAITING(cturn_ply, players, properties)
		for k, v in pairs(players) do
			if not IsValid(v.Entity) and not v.AI then self:RemovePlayer(k) end
		end

		if #players == 8 then
			self:SetTurn(self:GetTurn() + 1)
			self:SetState(self.ST_ENUM.ROLL_FOR_ORDER)
		end

		self:NextThink(CurTime() + 1)
		return true
	end

	function ENT.STATES:ROLL_FOR_ORDER(ply, players, properties)
		if ply then
			ply:RollDice(2)
		end

		if not ply or self:GetTurn() == 8 then
			table.SortByMember(players, "RollTotal")
			self:ReloadPlayerList()
			self:SetTurn(1)
			self:SetState(self.ST_ENUM.TURN)
		else
			self:SetTurn(self:GetTurn() + 1)
		end

		self:NextThink(CurTime() + 2)
		return true
	end
end

//IDEA:  23 End Time?? | 3 Player #'s Turn | 5 State
if CLIENT then
	function ENT:RebuildStateCache(_, old, new)
		if old == new then return end
		self.State = bit.band(new, 0x1F)
		self.Turn = bit.band(new, 0xE0) + 1
	end
elseif SERVER then
	function ENT:UpdateStateInfo()
		local int = 0
		int = int + (self.State or 1)
		int = int + bit.lshift(math.max((self.Turn or 0) - 1, 0), 5)
		self:SetStateData(int)
	end

	function ENT:SetState(state)
		self.State = state
		self:UpdateStateInfo()
	end

	function ENT:SetTurn(turn)
		self.Turn = math.Clamp(1, 8, turn)
		self:UpdateStateInfo()
	end
end
