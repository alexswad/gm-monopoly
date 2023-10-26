function ENT:GetStateName()
	return self.ST_STR[self:GetState()] or "nil"
end

function ENT:GetStateString()
	return self.ST_STR[self:GetState()] or "nil"
end

ENT.STATES = {}

ENT.ST_EN = {
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

ENT.ST_STR = {}
for k, v in pairs(ENT.ST_EN) do
	ENT.ST_STR[v] = k
end

function ENT:CallState(state)
	if isnumber(state) then
		state = self.ST_STR[state]
	end

	local f = self.STATES[state or ""]
	return not f and false or f and f(self.StateVars, self, self:GetPlayerByIndex(self:GetTurn()), self.Players or {}, self.Properties or {})
end

if CLIENT then
	function ENT:RebuildStateCache(_, old, new)
		if old == new then return end
		local ostate, nstate = self.State, bit.band(new, 0x1F)
		if ostate ~= nstate then
			self:CallState(self:GetStateString(ostate) .. "_END")
			self.State = nstate
			self:CallState(self:GetStateString(nstate) .. "_START")
		end

		self.Turn = bit.band(new, 0xE0) + 1
		self.StateVars = {}
		self:CallState(self:GetStateString() .. "_BUILDCACHE")
	end

	// STATES
	function ENT.STATES:MOVE_BUILDCACHE(ent, ply, players, properties)
		//self.MoveEndTime = bit.band(ent.StateInfo, )
		//self.MoveSpace =
	end
elseif SERVER then
	//IDEA:  23 End Time?? | 3 Player #'s Turn | 5 State
	function ENT:UpdateStateData()
		local int = 0
		int = int + (self.State or 1)
		int = int + bit.lshift(math.max((self.Turn or 0) - 1, 0), 5)
		print(self:GetStateString())
		int = int + bit.lshift(self:CallState(self:GetStateString() .. "_UPDATEDATA") or 0, 8)
		self:SetStateData(int)
	end

	function ENT:SetState(state, clear)
		if self:GetState() == state then return end

		if clear then self.StateVars = {} end

		self.State = state
		if self:GetStateString() then
			self:CallState(self:GetStateString() .. "_START")
		end

		self:UpdateStateData()
	end

	function ENT:StartMove(index, newspace)
		if not index or not newspace then return end
		self:SetTurn(index)
		self.StateVars.MoveSpace = newspace
		self.StateVars.MoveEndTime = endtime or 0 // TODO
		self:SetState(self.ST_EN.MOVE)
	end

	// STATES
	function ENT.STATES:WAITING(ent, ply, players, properties)
		for k, v in pairs(players) do
			if not IsValid(v.Entity) then self:RemovePlayer(k) end
		end

		ent:NextThink(CurTime() + 0.5)
		return true
	end

	function ENT.STATES:ROLL_FOR_ORDER_START(ent, ply, players, properties)
		for k, v in pairs(players) do
			v:StartRoll(2)
		end
	end

	function ENT.STATES:ROLL_FOR_ORDER(ent, ply, players, properties)
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
			timer.Simple(2, function()
				ent:SetTurn(1)
				ent:SetState(ent.ST_EN.TURN, true)
			end)
		end

		ent:NextThink(CurTime() + 1)
		return true
	end

	function ENT.STATES:TURN_START(ent, ply, players, properties)
		self.CanRoll = true
		ply:SetRoll(0)
	end

	function ENT.STATES:TURN(ent, ply, players, properties)
		if ply:GetRollTotal() ~= 0 then
			ent:StartMove(ply.Index, ply:GetSpace() + ply:GetRollTotal())
		end
		ent:NextThink(CurTime() + 1)
		return true
	end

	function ENT.STATES:MOVE_UPDATEDATA(ent, ply, players, properties)
		return self.MoveSpace + bit.rshift(self.MoveEndTime, 6)
	end
end

