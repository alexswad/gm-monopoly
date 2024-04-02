function ENT:GetStateName()
	return self.ST_STR[self:GetState()] or "nil"
end

function ENT:GetStateString()
	return self.ST_STR[self:GetState()] or "nil"
end

ENT.STATES = {}

ENT.ST = {
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
for k, v in pairs(ENT.ST) do
	ENT.ST_STR[v] = k
end

function ENT:CallState(state, data)
	if isnumber(state) then
		state = self.ST_STR[state]
	end

	local f = self.STATES[state or ""]
	return not f and false or f and f(self, self:GetPlayerByIndex(self:GetTurn()), self.Players or {}, self.Properties or {}, data)
end

local movetime = 0.3
local startmovewait = 1

local boff = 8
AccessorFlags(ENT, "StateData", {{"MVSpace", 6}, {"MVStartSpace", 6}, {"MVEndTime", 6}}, boff, 0) // MOVE
AccessorFlags(ENT, "StateData", {{"CCard", 7}}, boff, 0) // CHANCE/COMMUNITY

if CLIENT then
	function ENT:RebuildStateCache(_, old, new)
		if old == new then return end
		local ostate, nstate = self.State, bit.band(new, 0xFF)
		if ostate ~= nstate then
			self:CallState(self:GetStateString(ostate) .. "_END")
			timer.Create("MN_StartState", 0.01, 1, function()
				if not IsValid(self) then return end
				self:CallState(self:GetStateString(nstate) .. "_START")
			end)
		end
	end

	function ENT.STATES:CHANCE_START(ply, players, properties)
		PrintTable(self:GetCurrentCard())
	end

elseif SERVER then
	function ENT:SetState(state, cleanup)
		if isstring(state) then
			state = self.ST[state]
		end

		self:CallState(self:GetStateString() .. "_END", cleanup)

		self:SetStartTime(CurTime())
		self:ClearCustomStateData()
		self:NextThink(CurTime() + 1)
		if CLIENT then self:SetNextClientThink(CurTime() + 1) end

		timer.Create("MN_SetState", 0.1, 1, function()
			if not IsValid(self) then return end
			self:SetStateVar(state)
			self:CallState(self:GetStateString() .. "_START")
		end)
	end

	function ENT:ClearCustomStateData()
		self:SetStateData(bit.band(self.StateData, 2 ^ boff - 1))
	end

	// STATES
	// WAITING
	function ENT.STATES:WAITING(ply, players, properties)
		for k, v in pairs(players) do
			if not IsValid(v.Entity) then self:RemovePlayer(k) end
		end

		self:NextThink(CurTime() + 0.5)
		return true
	end

	// START / RFO
	function ENT.STATES:ROLL_FOR_ORDER_START(ply, players, properties)
		for k, v in pairs(players) do
			v:StartRoll(2)
		end
	end

	function ENT.STATES:ROLL_FOR_ORDER(ply, players, properties)
		local proceed = true
		for k, v in pairs(players) do
			if v:IsRolling() then
				proceed = false
			end
			v.TRollTotal = v:GetDiceTotal()
		end
		if proceed then
			table.SortByMember(players, "TRollTotal")
			self:ReloadPlayerList()
			timer.Simple(0.9, function()
				if not IsValid(self) then return end
				for k, v in pairs(players) do
					v:SetMoney(1500)
				end
				self:SetTurn(1)
				self:SetState("TURN", true)
			end)
		end

		self:NextThink(CurTime() + 1.1)
		return true
	end

	// TURN
	function ENT.STATES:TURN_START(ply, players, properties)
		self.CanRoll = self.CanRoll == nil or self.CanRoll
		ply:SetDice(0)
	end

	function ENT.STATES:TURN(ply, players, properties)
		if ply:GetDiceTotal() ~= 0 and ply then
			ply:StartMove(ply:GetSpace() + ply:GetDiceTotal())
		end
		self:NextThink(CurTime() + 1)
		return true
	end

	function ENT.STATES:TURN_END(ply, players, properties, clean)
		if clean then
			self.CanRoll = nil
			self.HasGone = nil
		end
	end

	// MOVE
	function ENT:StartMove(ply, newspace)
		ply = isnumber(ply) and self:GetPlayerByIndex(ply) or ply
		if not ply or not newspace then return end
		self:SetTurn(ply.Index)
		self:SetState("MOVE")
		self:SetMVSpace(newspace)
		self:SetMVStartSpace(ply:GetSpace())
		self:SetMVEndTime(self:SpaceDistance(self:GetMVStartSpace(), newspace) * movetime + startmovewait)
	end

	function ENT.STATES:MOVE_START(ply, players, properties)
		ply:SetSpace(self:GetMVSpace())
	end

	function ENT.STATES:MOVE(ply, players, properties)
		if IsValid(ply) and self:GetMVEndTime() + self:GetStartTime() < CurTime() then
			local p = properties[ply:GetSpace()] or self.BoardData[ply:GetSpace()]
			local pe = ply:GetEntity()
			if istable(p) and not p:GetOwner() then
				pe:ChatPrint("You can buy this!!! type !buy!!!")
			elseif istable(p) and not p:GetMortaged() and not ply:HasProperty(p.Index) then
				if p.group == "utility" then
					self:SetState("ROLL_UTILITY")
				else
					local rent = p:GetRent()
					pe:ChatPrint("You OWE!!!! $" .. rent)

					ply:AddMoney(-rent)
					self:SetState("TURN")
				end
			end

			if ply:GetDice1() == ply:GetDice2() then
				pe:ChatPrint("Doubles!!")
				self.CanRoll = true
			end
			self.HasGone = true

			if p == "chance" then
				self:SetState("CHANCE")
				return
			elseif p == "community" then
				self:SetState("COMMUNITY")
				return
			elseif p == "income" then
				ply:AddMoney(-200)
				self:AddParking(200)
				self:SetState("TURN")
				return
			elseif p == "luxury" then
				ply:AddMoney(-100)
				self:AddParking(100)
				self:SetState("TURN")
				return
			elseif p == "freeparking" then
				if self:GetFreeParking() > 0 then
					ply:AddMoney(self:GetFreeParking())
					self:SetFreeParking(0)
				end
			end

			self:SetState("TURN")
		end
	end

	function ENT.STATES:MOVE_END(ply, players, properties, clean)
		if IsValid(ply) then
			ply:SetSpace(self:GetMVSpace())
		end
	end

	function ENT.STATES:COMMUNITY_START(ply, players, properties)
		local card = self:DrawCommunityCard()
		self:SetCCard(card._index)
	end

	function ENT.STATES:CHANCE_START(ply, players, properties)
		local card = self:DrawChanceCard()
		self:SetCCard(card._index)
	end

	function ENT.STATES:COMMUNITY(ply, players, properties)
		self:CardEffect(ply, self:GetCurrentCard())
		self:NextThink(CurTime() + 100)
		return true
	end
	ENT.STATES.CHANCE = COMMUNITY

	function ENT.STATES:GO_TO_JAIL_START(ply, players, properties)
		if IsValid(ply) then
			ply:SetSpace(10)
			ply:SetJailed(true)
		end
	end
end
