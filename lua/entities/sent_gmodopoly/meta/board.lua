AccessorFlags(ENT, "StateData", {{"Turn", 4}, {"State", 4}}, nil, 0)

function ENT:InitBoard()
	self.Players = {}
	if SERVER then
		self:SetState(1)
		self:SetFreeParking(0)
		self:InitCards()
	end
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

if SERVER then
	AccessorFunc(ENT, "FreeParking", "FreeParking")
	ENT.Commands = {
		["start"] = function(ent, ply, command, data)
			if ply:GetIndex() == 1 and ent:GetState() == ent.ST.WAITING then
				for k, v in pairs(ent.Players) do
					if not IsValid(v.Entity) then ent:RemovePlayer(k) end
				end
				ent:SetState("ROLL_FOR_ORDER", true)
			end
		end,
		["settings"] = function(ent, ply, command, data)

		end,
		["kick"] = function(ent, ply, command, data)
			ent:RemovePly(ply)
		end,
		["roll"] = function(ent, ply, command, data)
			if ply:IsRolling() then
				ply:RollDice(ply:IsRolling())
			end
		end,
		["start_roll"] = function(ent, ply, command, data)
			if ent:GetState() == ent.ST.TURN and ply:IsTurn() and ply:GetDiceTotal() == 0 and ent.CanRoll then
				ply:StartRoll(2)
				ent.CanRoll = false
			end
		end,
		//debug
		["move"] = function(ent, ply, command, data)
			print(data[2])
			if ply:IsTurn() and ply:GetDiceTotal() == 0 then
				ply:SetDiceTotal(tonumber(data[2]) or 0)
			end
		end,
		["start_trade"] = function(ent, ply, command, data)

		end,
		// temp basic implementation without auctioning for prototyping
		["buy"] = function(ent, ply, command, data)
			if ent:GetState() == ent.ST.TURN and ply:IsTurn() and ent.HasGone then
				local p = ent.Properties[ply:GetSpace()]
				if not p or not ply:CanAfford(p:GetPrice()) or p:GetOwner() then return end
				ply:AddMoney(-p:GetPrice())
				ply:AddProperty(p.Index)
			end
		end,
		["mortage"] = function(ent, ply, command, data)

		end,
		["offer_trade"] = function(ent, ply, command, data)

		end,
		["sethouses"] = function(ent, ply, command, data)

		end,
		["bid"] = function(ent, ply, command, data)

		end,
		["end"] = function(ent, ply, command, data)
			if not ply:IsTurn() or ent.CanRoll or ent:GetState() ~= ent.ST.TURN then print("cant_end") return end
			ent:SetTurn((ent:GetTurn() % #ent.Players) + 1)
			ent:SetState("TURN", true)
			print("end_turn")
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
		if not self.Commands[command] then return end
		self.Commands[command](self, self:GetPlayer(ply), command, data)
	end

	function ENT:NextTurn()
		self:SetTurn(self:GetTurn() + 1)
		if not self.Players[self:GetTurn()] then self:SetTurn(1) end
	end

	function ENT:AddParking(money)
		self:SetFreeParking(self:GetFreeParking() + money)
	end
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

	function ENT:GetLocalPlayer()
		return self:GetPlayer(LocalPlayer())
	end
end
