AccessorFunc(ENT, "Turn", "Turn")
AccessorFunc(ENT, "State", "State")

function ENT:InitBoard()
	self.Players = {}
	self.StateVars = {}
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

// function ENT:GetState()
// 	return self.ST_ENUM.ROLL_FOR_ORDER
// end

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
	ENT.Commands = {
		["start"] = function(self, ply, command, data)
			if ply:GetIndex() == 1 and self:GetState() == self.ST_ENUM.WAITING then
				for k, v in pairs(self.Players) do
					if not IsValid(v.Entity) then self:RemovePlayer(k) end
				end
				self:SetState(self.ST_ENUM.ROLL_FOR_ORDER)
			end
		end,
		["settings"] = function(self, ply, command, data)

		end,
		["leave"] = function(self, ply, command, data)

		end,
		["roll"] = function(self, ply, command, data)
			if ply.Roll[1] == 7 then
				ply:RollDice(ply.Roll[2] == 7 and 2 or 1)
			end
		end,
		["buy"] = function(self, ply, command, data)

		end,
		["mortage"] = function(self, ply, command, data)

		end,
		["start_trade"] = function(self, ply, command, data)

		end,
		["offer_trade"] = function(self, ply, command, data)

		end,
		["houses"] = function(self, ply, command, data)

		end,
		["bid"] = function(self, ply, command, data)

		end,
	}

	util.AddNetworkString("Monopoly_Command")

	net.Receive("Monopoly_Command", function(_, ply)
		if ply.MN_LastCommand and CurTime() - ply.MN_LastCommand < .3 then return end
		local ent = net.ReadEntity()
		if not (IsValid(ent) and ent:GetClass() == "sent_gmodopoly" and ent:GetPlayer(ply)) then return end

		local command = net.ReadString()
		local data = net.ReadTable()
		ent:HandleInput(ply, command, data)

		ply.MN_LastCommand = (ply.MN_LastCommand or 0) + 1
	end)

	function ENT:HandleInput(ply, command, data)
		if not self.Commands[command] then return print("fucK") end
		self.Commands[command](self, self:GetPlayer(ply), command, data)
	end

	//STATES
	function ENT.STATES:WAITING(ent, ply, players, properties)
		for k, v in pairs(players) do
			if not IsValid(v.Entity) then self:RemovePlayer(k) end
		end

		ent:NextThink(CurTime() + 0.5)
		return true
	end

	function ENT.STATES:ROLL_FOR_ORDER(ent, ply, players, properties)
		if not self.FirstRoll then
			for k, v in pairs(players) do
				v:StartRoll(2)
			end
			self.FirstRoll = true
		else
			local proceed = true
			for k, v in pairs(players) do
				if v:IsRolling() then
					proceed = false
					v.TRollTotal = v:GetRollTotal()
				end
			end
			if proceed then
				table.SortByMember(players, "TRollTotal")
				ent:ReloadPlayerList()
				ent:SetTurn(1)
				ent:SetState(ent.ST_ENUM.TURN)
			end
		end

		ent:NextThink(CurTime() + 1)
		return true
	end
	//

elseif CLIENT then
	function ENT:SendCommand(command, data)
		if not command or self.LastCommand and CurTime() - self.LastCommand < .3 then return false end
		net.Start("Monopoly_Command")
			net.WriteEntity(self)
			net.WriteString(command)
			net.WriteTable(data or {})
		net.SendToServer()
		self.LastCommand = CurTime()
	end
end

//IDEA:  23 End Time?? | 3 Player #'s Turn | 5 State
if CLIENT then
	function ENT:GetLocalPlayer()
		return self:GetPlayer(LocalPlayer())
	end

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
