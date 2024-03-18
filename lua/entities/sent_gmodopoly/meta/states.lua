function ENT:GetStateName()
	return self.ST_STR[self:GetState()] or "nil"
end

function ENT:GetStateString()
	return self.ST_STR[self:GetState()] or "nil"
end

ENT.STATES = {}

ENT.ST_EN = {
	WAITING = 1,
	ROLL_FOR_ORDER = 2,
	TURN = 3,
	MOVE = 4,
	BID = 5,
	CHANCE = 6,
	COMMUNITY = 7,
	DEBT = 8,
	GO_TO_JAIL = 9,
	TRADE = 10,
	ROLL_UTILITY = 11,
	ROLL_JAIL = 12,
}

ENT.ST_STR = {}
for k, v in pairs(ENT.ST_EN) do
	ENT.ST_STR[v] = k
end

function ENT:CallState(state, data)
	if isnumber(state) then
		state = self.ST_STR[state]
	end

	local f = self.STATES[state or ""]
	return not f and false or f and f(self.StateVars, self, self:GetPlayerByIndex(self:GetTurn()), self.Players or {}, self.Properties or {}, data)
end

local movetime = 0.3
local startmovewait = 1

if CLIENT then
	function ENT:RebuildStateCache(_, old, new)
		if old == new then return end
		local ostate, nstate = self.State, bit.band(new, 0x1F)
		if ostate ~= nstate then
			self:CallState(self:GetStateString(ostate) .. "_END")
			self.State = nstate
		end

		self.Turn = bit.band(new, 0xE0) + 1

		timer.Create("MN_RebuildStateCache", 0, 1, function()
			self.StateVars = {}
			self:CallState(self:GetStateString() .. "_BUILDCACHE", bit.rshift(new - bit.band(new, 255), 8))
			self:CallState(self:GetStateString(nstate) .. "_START")
		end)
	end

	function ENT:BuildStateCache()
		self:RebuildStateCache(nil, nil, self:GetStateData())
	end

	// STATES
	function ENT.STATES:MOVE_BUILDCACHE(ent, ply, players, properties, data)
		self.MoveSpace = bit.band(data, 0x3F)
		self.MoveEndTime = bit.rshift(bit.band(data, 0xFFFFFFC0), 6)
		self.MoveStartSpace = self.MoveStartSpace or ply and ply:GetSpace()
	end
elseif SERVER then
	//IDEA:  23 End Time?? | 3 Player #'s Turn | 5 State
	function ENT:UpdateStateData()
		local int = 0
		int = int + (self.State or 1)
		int = int + bit.lshift(math.max((self.Turn or 0) - 1, 0), 5)
		local updatedata = self:CallState(self:GetStateString() .. "_UPDATEDATA")
		int = int + bit.lshift(updatedata or 0, 8)
		self:SetStateData(int)
	end

	function ENT:SetState(state, clear)
		if isstring(state) then
			state = self.ST_EN[state]
		end

		timer.Create("MN_SetState", 0.1, 1, function()
			self:CallState(self:GetStateString() .. "_END")

			if clear then self:ClearStateVars() end

			self.State = state
			self:CallState(self:GetStateString() .. "_START")

			self:UpdateStateData()
		end)
	end

	function ENT:ClearStateVars()
		self.StateVars = {}
	end

	function ENT:StartMove(ply, newspace)
		ply = isnumber(ply) and self:GetPlayerByIndex(ply) or ply
		if not ply or not newspace then return end
		self:SetTurn(ply.Index)
		self:SetStartTime(CurTime())
		self.StateVars.MoveSpace = newspace
		self.StateVars.MoveStartSpace = ply:GetSpace()
		self.StateVars.MoveEndTime = self:SpaceDistance(self.StateVars.MoveStartSpace, newspace) * movetime + startmovewait
		self:SetState("MOVE")
	end

	// STATES
	// WAITING
	function ENT.STATES:WAITING(ent, ply, players, properties)
		for k, v in pairs(players) do
			if not IsValid(v.Entity) then self:RemovePlayer(k) end
		end

		ent:NextThink(CurTime() + 0.5)
		return true
	end

	// START / RFO
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
			end
			v.TRollTotal = v:GetRollTotal()
		end
		if proceed then
			table.SortByMember(players, "TRollTotal")
			ent:ReloadPlayerList()
			timer.Simple(1, function()
				if not IsValid(ent) then return end
				for k, v in pairs(players) do
					v:SetMoney(1500)
				end
				ent:SetTurn(1)
				ent:SetState("TURN", true)
			end)
		end

		ent:NextThink(CurTime() + 1)
		return true
	end

	// TURN
	function ENT.STATES:TURN_START(ent, ply, players, properties)
		self.CanRoll = self.CanRoll == nil or self.CanRoll
		ply:SetRoll(0)
	end

	function ENT.STATES:TURN(ent, ply, players, properties)
		if ply:GetRollTotal() ~= 0 and ply then
			ply:StartMove(ply:GetSpace() + ply:GetRollTotal())
		end
		ent:NextThink(CurTime() + 1)
		return true
	end



	// MOVE
	function ENT.STATES:MOVE_UPDATEDATA(ent, ply, players, properties)
		return self.MoveSpace + bit.lshift(math.ceil(self.MoveEndTime), 6)
	end

	function ENT.STATES:MOVE_START(ent, ply, players, properties)
		ply:SetSpace(self.MoveSpace)
	end

	function ENT.STATES:MOVE(ent, ply, players, properties)
		if IsValid(ply) and self.MoveEndTime + ent:GetStartTime() < CurTime() then
			local p = properties[ply:GetSpace()] or ent.BoardData[ply:GetSpace()]
			local pe = ply:GetEntity()
			if istable(p) and not p:GetOwner() then
				pe:ChatPrint("You can buy this!!! type !buy!!!")
			elseif istable(p) and not p:GetMortaged() and not ply:HasProperty(p.index) then
				if p.group == "utility" then
					ent:SetState("ROLL_UTILITY")
				else
					local rent = p:GetRent()
					pe:ChatPrint("You OWE!!!! $" .. rent)

					if ply:CanAfford(rent) then
						ply:AddMoney(-rent)
						ent:SetState("TURN")
					else
						ent:StartDebt(ply, rent, p:GetOwner())
					end
				end
			end

			if ply:GetRoll()[1] == ply:GetRoll()[2] then
				pe:ChatPrint("Doubles!!")
				self.CanRoll = true
			end
			self.HasGone = true

			if p == "chance" then
				ent:SetState("CHANCE")
			elseif p == "community" then
				ent:SetState("COMMUNITY")
			elseif p == "income" then
				if ply:CanAfford(200) then
					ply:AddMoney(-200)
					ent:AddParking(200)
					ent:SetState("TURN")
				else
					ent:StartDebt(ply, 200)
				end
			elseif p == "luxury" then
				if ply:CanAfford(100, true) then
					ply:AddMoney(-100)
					ent:AddParking(100)
					ent:SetState("TURN")
				else
					ent:StartDebt(ply, 100)
				end
			elseif p == "freeparking" then
				if ent.FreeParking > 0 then
					ply:AddMoney(self.FreeParking)
					ent.FreeParking = 0
				end
			else
				ent:SetState("TURN")
			end
		end
	end

	function ENT.STATES:MOVE_END(ent, ply, players, properties)
		if IsValid(ply) then
			ply:SetSpace(self.MoveSpace)
		end
		self.MoveSpace = nil
		self.MoveEndTime = nil
		self.MoveStartSpace = nil
	end
end

