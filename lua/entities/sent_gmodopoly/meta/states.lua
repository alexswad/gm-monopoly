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
AccessorFlags(ENT, "StateData", {{"MVSpace", 4}, {"MVStartSpace", 4}, {"MVEndTime", 6}}, boff, true)

if CLIENT then
	function ENT:RebuildStateCache(_, old, new)
		if old == new then return end
		local ostate, nstate = self.State, bit.band(new, 0x1F)
		if ostate ~= nstate then
			self:CallState(self:GetStateString(ostate) .. "_END")
			timer.Create("MN_StartState", 0, 0, function()
				if not IsValid(self) then return end
				self:CallState(self:GetStateString(nstate) .. "_START")
			end)
		end
	end
elseif SERVER then
	ENT.SetStateVar = ENT.SetState
	function ENT:SetState(state)
		if isstring(state) then
			state = self.ST[state]
		end

		self:CallState(self:GetStateString() .. "_END")

		self:ClearCustomStateData()

		timer.Create("MN_SetState", 0.1, 1, function()
			if not IsValid(self) then return end
			self:SetStateVar(state)
			self:CallState(self:GetStateString() .. "_START")
		end)
	end

	function ENT:ClearCustomStateData()
		self:SetStateData(bit.band(self.StateData, 2 ^ boff - 1))
	end

	function ENT:StartMove(ply, newspace)
		ply = isnumber(ply) and self:GetPlayerByIndex(ply) or ply
		if not ply or not newspace then return end
		self:SetTurn(ply.Index)
		self:SetStartTime(CurTime())
		self:SetState("MOVE")
		self:SetMVSpace(newspace)
		self:SetMVStartSpace(ply:GetSpace())
		self:SetMVEndTime(self:SpaceDistance(self:GetMVStartSpace(), newspace) * movetime + startmovewait)
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
			v.TRollTotal = v:GetRollTotal()
		end
		if proceed then
			table.SortByMember(players, "TRollTotal")
			self:ReloadPlayerList()
			timer.Simple(1, function()
				if not IsValid(self) then return end
				for k, v in pairs(players) do
					v:SetMoney(1500)
				end
				self:SetTurn(1)
				self:SetState("TURN", true)
			end)
		end

		self:NextThink(CurTime() + 1)
		return true
	end

	// TURN
	function ENT.STATES:TURN_START(ply, players, properties)
		self.CanRoll = self.CanRoll == nil or self.CanRoll
		ply:SetRoll(0)
	end

	function ENT.STATES:TURN(ply, players, properties)
		if ply:GetRollTotal() ~= 0 and ply then
			ply:StartMove(ply:GetSpace() + ply:GetRollTotal())
		end
		self:NextThink(CurTime() + 1)
		return true
	end

	// MOVE
	function ENT.STATES:MOVE_START(ply, players, properties)
		self:SetMVEndTime(self:SpaceDistance(self:GetMVStartSpace(), self:GetMVSpace()) * movetime + startmovewait)
		ply:SetSpace(self:GetMVSpace())
	end

	function ENT.STATES:MOVE(ply, players, properties)
		if IsValid(ply) and self:GetMVEndTime() + self:GetStartTime() < CurTime() then
			local p = properties[ply:GetSpace()] or self.BoardData[ply:GetSpace()]
			local pe = ply:GetEntity()
			if istable(p) and not p:GetOwner() then
				pe:ChatPrint("You can buy this!!! type !buy!!!")
			elseif istable(p) and not p:GetMortaged() and not ply:HasProperty(p.index) then
				if p.group == "utility" then
					self:SetState("ROLL_UTILITY")
				else
					local rent = p:GetRent()
					pe:ChatPrint("You OWE!!!! $" .. rent)

					if ply:CanAfford(rent) then
						ply:AddMoney(-rent)
						self:SetState("TURN")
					else
						self:StartDebt(ply, rent, p:GetOwner())
					end
				end
			end

			if ply:GetRoll()[1] == ply:GetRoll()[2] then
				pe:ChatPrint("Doubles!!")
				self.CanRoll = true
			end
			self.HasGone = true

			if p == "chance" then
				self:SetState("CHANCE")
			elseif p == "community" then
				self:SetState("COMMUNITY")
			elseif p == "income" then
				if ply:CanAfford(200) then
					ply:AddMoney(-200)
					self:AddParking(200)
					self:SetState("TURN")
				else
					self:StartDebt(ply, 200)
				end
			elseif p == "luxury" then
				if ply:CanAfford(100, true) then
					ply:AddMoney(-100)
					self:AddParking(100)
					self:SetState("TURN")
				else
					self:StartDebt(ply, 100)
				end
			elseif p == "freeparking" then
				if self:GetFreeParking() > 0 then
					ply:AddMoney(self:GetFreeParking())
					self:SetFreeParking(0)
				end
			else
				self:SetState("TURN")
			end
		end
	end

	function ENT.STATES:MOVE_END(ply, players, properties)
		if IsValid(ply) then
			ply:SetSpace(self:GetMVSpace())
		end
	end
end

