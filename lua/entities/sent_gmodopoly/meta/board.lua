AccessorFunc(ENT, "Turn", "Turn")
AccessorFunc(ENT, "State", "State")

function ENT:InitBoard()
	self.Players = {}
	self.State = 1
	self.StateVars = {}
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

if SERVER then
	ENT.Commands = {
		["start"] = function(self, ply, command, data)
			if ply:GetIndex() == 1 and self:GetState() == self.ST_EN.WAITING then
				for k, v in pairs(self.Players) do
					if not IsValid(v.Entity) then self:RemovePlayer(k) end
				end
				self:SetState(self.ST_EN.ROLL_FOR_ORDER, true)
			end
		end,
		["settings"] = function(self, ply, command, data)

		end,
		["leave"] = function(self, ply, command, data)
			self:RemovePly(ply)
		end,
		["roll"] = function(self, ply, command, data)
			if ply:IsRolling() then
				ply:RollDice(ply.Roll[2] == 7 and 2 or 1)
			end
		end,
		["start_roll"] = function(self, ply, command, data)
			if self:GetState() == self.ST_EN.TURN and ply:IsTurn() and self.StateVars.CanRoll then
				ply:StartRoll(2)
				ply.CanRoll = false
			end
		end,
		["start_trade"] = function(self, ply, command, data)

		end,
		["buy"] = function(self, ply, command, data)

		end,
		["mortage"] = function(self, ply, command, data)

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
		if not self.Commands[command] then return end
		self.Commands[command](self, self:GetPlayer(ply), command, data)
	end

	function ENT:SetTurn(turn)
		assert(isnumber(turn), "invalid input type (should be number)")
		self.Turn = turn
		self:UpdateStateData()
	end

	function ENT:NextTurn()
		self.Turn = self.Turn + 1
		if not self.Players[self.Turn] then self.Turn = 1 end
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
