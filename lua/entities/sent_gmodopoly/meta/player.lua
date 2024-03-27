local PLAYER = {}
PLAYER.__index = PLAYER

AccessorFunc(PLAYER, "Entity", "Entity")
AccessorFunc(PLAYER, "DrawSpace", "DrawSpace")
AccessorFunc(PLAYER, "FlagInt", "FlagInt")
AccessorFlags(PLAYER, "FlagInt", {{"Valid", 1}, {"Money", 15}, {"Space", 6}, {"GOJCards", 2}, {"Jailed", 1}, {"Dice1", 3}, {"Dice2", 3}}, nil, -1)

function ENT:CreatePlayer(entity)
	local ply = {}
	setmetatable(ply, PLAYER)
	ply.Entity = entity
	ply.Board = self
	ply.Properties = {}

	return ply
end

if SERVER then
	function ENT:AddPlayer(entity)
		//if self:GetState() ~= self.ST.WAITING then return false end
		// self:GetPlayer(entity) or
		if not IsValid(entity) or table.Count(self.Players) >= 8 then return false end
		local ply = self:CreatePlayer(entity)
		local index = table.insert(self.Players, ply)
		ply.Index = index
		ply:SetValid(true)
		ply:SetSpace(1)

		self:ReloadPlayerList()

		return index
	end

	function ENT:RemovePlayer(entity)
		local ply = isnumber(entity) and entity or self:GetPlayerIndex(entity)
		//if not ply or self:GetState() ~= self.ST.WAITING then return false end

		// this needs some work
		if self:GetTurn() == ply then
			self:NextTurn()
			if ply ~= 8 then
				self:SetTurn(self:GetTurn() - 1)
			end
		elseif self:GetTurn() > ply then
			self:SetTurn(self:GetTurn() - 1)
		end
		//

		table.remove(self.Players, ply)

		self:ReloadPlayerList()

		return true
	end

	function ENT:ReloadPlayerList()
		local hostfound
		for i = 1, 8 do
			if self.Players[i] then
				if self.Players[i].Host then
					hostfound = true
				end
				self.Players[i].Index = i
				self:SetDTInt(i, self.Players[i]:GetFlagInt())
				self:SetDTEntity(i, self.Players[i].Entity)
			else
				self:SetDTInt(i, 0)
				self:SetDTEntity(i, NULL)
			end
		end
		if not hostfound and self.Players[1] then self.Players[1].Host = true end
		self:UpdatePropData()
	end
end

if CLIENT then
	function ENT:RebuildPlayerCache()
		print("help")
		timer.Create("MN_RebuildPlayerCache", 0.1, 1, function()
			self:BuildPlayerCache()
		end)
	end

	function ENT:BuildPlayerCache()
		self.Players = {}
		for i = 1, 8 do
			print(self:GetDTInt(i))
			if bit.band(self:GetDTInt(i), 1) == 1 then
				self.Players[i] = self:CreatePlayer(self:GetDTEntity(i))
			end
		end
		self:BuildPropertyCache()
	end
end

function ENT:GetPlayerIndex(entity)
	for k, v in pairs(self.Players) do
		if v.Entity == entity then
			return k
		end
	end
	return false
end

function ENT:GetPlayerByIndex(i)
	return self.Players[i] or false
end

function ENT:GetPlayer(entity)
	local found
	for k, v in pairs(self.Players) do
		if v.Entity == entity and (not found or v:IsTurn()) then
			found = v
		end
	end
	return found or false
end

function ENT:IsTurn(ply)
	return self:GetTurn() == (isnumber(ply) and ply or self:GetPlayerIndex(ply))
end

function ENT:GetTurnPlayer()
	return self:GetPlayerByIndex(self:GetTurn())
end

function PLAYER:IsValid()
	return self:GetValid() and IsValid(self.Board)
end

function PLAYER:IsTurn()
	if not IsValid(self.Board) then return false end
	return self.Board:GetTurn() == self.Index
end

function PLAYER:GetIndex()
	if self.Index or not IsValid(self.Board) then return self.Index end
	self.Index = table.KeyFromValue(self.Board.Players, self)
	return self.Index or false
end

function PLAYER:GetRoll()
	if self:GetDice1() == 7 then return 0, 0 end
	return self:GetDice1(), self:GetDice2()
end

function PLAYER:IsRolling()
	if self:GetDice1() == 7 then
		return self:GetDice2() == 7 and 2 or 1
	end
	return false
end

function PLAYER:GetDiceTotal()
	local d1, d2 = self:GetDice1(), self:GetDice2()
	return d1 ~= 7 and ((d1 and d2) and d1 + d2 or d1) or 0
end

function PLAYER:SetDTInt(_, val)
	if not IsValid(self.Board) or not self.Index then return end
	self.Board:SetDTInt(self.Index, val)
end

function PLAYER:GetDTInt(_)
	if not IsValid(self.Board) or not self.Index then return 0 end
	return self.Board:GetDTInt(self.Index, val) or 0
end

if SERVER then

	function PLAYER:SetSpace(space)
		if space > 40 then // make looping easier
			space = space % 40
		end
		self:SetSpaceVar(space)
	end

	function PLAYER:AddMoney(money)
		self:SetMoney(math.Clamp(self:GetMoney() + money, 1, 32000))
	end

	function PLAYER:CanAfford(money)
		return self:GetMoney() >= money
	end

	function PLAYER:SetDice(dice1, dice2)
		self:SetDice1(dice1 or 0)
		self:SetDice2(dice2 or 0)
	end

	// DEBUG
	function PLAYER:SetDiceTotal(total)
		self:SetDice1(math.min(6, total))
		self:SetDice2(math.Clamp(total - 6, 0, 6))
	end

	function PLAYER:StartRoll(n)
		if n == 1 then
			self:SetDice(7, 0)
		else
			self:SetDice(7, 7)
		end
	end

	function PLAYER:RollDice(n)
		if n == 2 then
			self:SetDice(math.random(6), math.random(6))
		else
			self:SetDice(math.random(6))
		end
		return self:GetDiceTotal()
	end

	function PLAYER:AddProperty(propid, noupdate)
		local prop = self.Board.Properties[propid]
		if not prop or prop:GetOwner() then return false end

		self.Properties[propid] = prop
		if not noupdate then self.Board:UpdatePropData() end
		return true
	end

	function PLAYER:RemoveProperty(propid, noupdate)
		self.Properties[propid] = nil
		if not noupdate then self.Board:UpdatePropData() end
	end

end

function PLAYER:GetProperties()
	return self.Properties
end

function PLAYER:HasProperty(index)
	return self.Properties[index]
end

function PLAYER:GetName()
	if self.Name then return self.Name end
	self.Name = IsValid(self.Entity) and self.Entity:Name()
	return self.Name or "NULL"
end

function PLAYER:StartMove(newspace)
	self.Board:StartMove(self, newspace)
end

function PLAYER:GetPropDataString()
	local str = ""
	for a, b in pairs(self.Properties) do
		str = str .. a .. (self.Board.PROP_HL[b] or "a") .. ":"
	end
	str = str:sub(1, -2)
	return str
end

// planned to be remade in 3D
if CLIENT then

	local d = 1080
	local x, y = ScrW() / 2 - d / 2, 0

	// this math is all garbage but it works for TESTING!!!!
	local function calcspace(space, i)
		if space > 0 and space <= 11 then
			local nx, ny = x + d - 18 * 3 - 13, y + d - 32
			nx = nx - (140 / 2) - 89 * (space - 1)

			nx = nx + 30 * math.floor((i - 1) / 3)
			ny = ny - 34 * (i - 1) % (34 * 3)

			return nx, ny
		elseif space <= 21 then
			local nx, ny = x + 2 , y + d - 18 * 3 - 13
			ny = ny - (140 / 2) - 89 * (space % 11)

			ny = ny + 30 * math.floor((i - 1) / 3)
			nx = nx + 34 * (i - 1) % (34 * 3)

			return nx, ny
		elseif space <= 31 then
			local nx, ny = x - 16, y + 5
			nx = nx + 140 / 2 + 89 * ((space + 1) % 11)

			nx = nx + 30 * math.floor((i - 1) / 3)
			ny = ny + 34 * (i - 1) % (34 * 3)

			return nx, ny
		elseif space <= 40 then
			local nx, ny = x + d - 32 , y - 27
			ny = ny + 140 + 89 * ((space + 2) % 11)

			ny = ny - 30 * math.floor((i - 1) / 3)
			nx = nx - 34 * (i - 1) % (34 * 3)

			return nx, ny
		end
		return x + d / 2 + i, y + d / 2 + i
	end

	function PLAYER:Draw()
		local i = self:GetIndex()
		local space = self.DrawSpace or self:GetSpace()
		local nx, ny = calcspace(space, i)
		surface.SetDrawColor(Color(10, 10, 10))
		surface.DrawRect(nx, ny, 24, 24)
		surface.SetDrawColor(self:GetColor())
		surface.DrawRect(nx + 3, ny + 3, 18, 18)
		draw.DrawText(self:GetDiceTotal() or 0, "TargetIDSmall", nx + 5, ny + 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	function PLAYER:DrawPos(nx, ny)
		nx, ny = nx - 12, ny - 12
		surface.SetDrawColor(Color(10, 10, 10))
		surface.DrawRect(nx, ny, 24, 24)
		surface.SetDrawColor(self:GetColor())
		surface.DrawRect(nx + 3, ny + 3, 18, 18)
		draw.DrawText(self:GetDiceTotal() or 0, "TargetIDSmall", nx + 5, ny + 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	function PLAYER:GetColor()
		local i = self:GetIndex() - 1
		return HSVToColor(i / 8 * 360, 1 - 0.60 * math.Clamp(i - 2, 0, 1), 1 - 0.20 * math.Clamp(i - 2, 0, 1))
	end
end
