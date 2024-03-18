local PLAYER = {}
PLAYER.__index = PLAYER

AccessorFunc(PLAYER, "Entity", "Entity")
AccessorFunc(PLAYER, "Money", "Money")
AccessorFunc(PLAYER, "Jailed", "Jailed")
AccessorFunc(PLAYER, "JailCards", "JailCards")
AccessorFunc(PLAYER, "Space", "Space")


function ENT:CreatePlayer(entity)
	local ply = {}
	setmetatable(ply, PLAYER)
	ply.Entity = entity
	ply.Board = self
	ply.Properties = {}
	ply.Valid = true
	ply.Jailed = false
	ply.Money = 0
	ply.Space = 1
	ply.JailCards = 0
	ply.Roll = {0, 0}

	return ply
end

if SERVER then
	function ENT:AddPlayer(entity)
		//if self:GetState() ~= self.ST_EN.WAITING then return false end
		// self:GetPlayer(entity) or
		if not IsValid(entity) or table.Count(self.Players) >= 8 then return false end
		local index = table.insert(self.Players, self:CreatePlayer(entity))
		self.Players[index].Index = index

		self:ReloadPlayerList()

		return index
	end

	function ENT:RemovePlayer(entity)
		local ply = isnumber(entity) and entity or self:GetPlayerIndex(entity)
		//if not ply or self:GetState() ~= self.ST_EN.WAITING then return false end

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
				self:SetDTInt(i, self.Players[i]:GetFlagInteger())
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
		timer.Create("MN_RebuildPlayerCache", 0.1, 1, function()
			self:BuildPlayerCache()
		end)
	end

	function ENT:BuildPlayerCache()
		self.Players = {}
		for i = 1, 8 do
			if bit.band(self:GetDTInt(i), 1) == 1 then
				self.Players[i] = self:CreatePlayer(self:GetDTEntity(i))
				self:BuildPlayerInfoCache(i)
			end
		end
		self:BuildPropertyCache()
	end

	// 32bits >>roll(6)|injail(1)|goj(2|3)|pos(6|63)|money(15|32,767)|Alive/Valid(1)
	function ENT:RebuildPlayerInfoCache(ply)
		ply = tonumber(ply:sub(#ply))
		if not ply then return end

		timer.Create("MN_RebuildPlayerInfoCache" .. ply, 0.1, 1, function()
			self:BuildPlayerInfoCache(ply)
		end)
	end

	function ENT:BuildPlayerInfoCache(ply)
		local plyobj = self.Players[ply]
		if not plyobj then return end
		local flags = self:GetDTInt(ply)

		plyobj.Valid = tobool(bit.band(flags, 0x1))
		if not plyobj.Valid then return end

		plyobj.Money = bit.rshift(bit.band(flags, 0xFFFE), 1)
		plyobj.Space = math.max(bit.rshift(bit.band(flags, 0x3F0000), 16), 1)
		plyobj.JailCards = bit.rshift(bit.band(flags, 0xC00000), 22)
		plyobj.Jailed = tobool(bit.rshift(bit.band(flags, 0x1000000), 24))
		plyobj.Roll = {bit.rshift(bit.band(flags, 0xE000000), 25), bit.rshift(bit.band(flags, 0x70000000), 28)}

		timer.Remove("MN_RebuildPlayerInfoCache" .. ply)
	end

elseif SERVER then
	// server networking update stuff
	function ENT:UpdatePlayerFlags(plyind)
		local plytbl = self.Players[plyind]
		if not plytbl then return end

		self:SetDTInt(plyind, plytbl:GetFlagInteger())
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
	return self.Valid and IsValid(self.Board)
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

local empty = {0, 0}
function PLAYER:GetRoll()
	if self.Roll[1] == 7 then return empty end
	return self.Roll
end

function PLAYER:IsRolling()
	if self.Roll[1] == 7 then
		return true, self.Roll[2] == 7 and 2 or 1
	end
	return false
end

function PLAYER:GetRollTotal()
	local d1, d2 = self.Roll[1], self.Roll[2]
	return d1 ~= 7 and ((d1 and d2) and d1 + d2 or d1) or 0
end

// 32bits >>|injail(1)|goj(2|3)|pos(6|63)|money(15|32,767)|Alive/Valid(1)

function PLAYER:GetFlagInteger()
	local int = 0
	int = int + (self.Valid and 1 or 0)
	int = int + bit.lshift(self.Money or 0, 1)
	int = int + bit.lshift(self.Space or 0, 16)
	int = int + bit.lshift(self.JailCards or 0, 22)
	int = int + bit.lshift(self.Jailed and 1 or 0, 24)
	int = int + bit.lshift(self.Roll[1] or 0, 25)
	int = int + bit.lshift(self.Roll[2] or 0, 28)
	return int
end

if SERVER then
	function PLAYER:UpdateFlags()
		if not IsValid(self.Board) then return end
		self.Board:UpdatePlayerFlags(self:GetIndex())
	end

	function PLAYER:SetSpace(space)
		if space > 40 then // make looping easier
			space = space % 40
		end
		self.Space = space
		self:UpdateFlags()
	end

	function PLAYER:SetMoney(money)
		self.Money = math.Clamp(money, 1, 32000)
		self:UpdateFlags()
	end

	function PLAYER:AddMoney(money)
		self.Money = math.Clamp(self.Money + money, 1, 32000)
		self:UpdateFlags()
	end

	function PLAYER:CanAfford(money)
		return self.Money >= money
	end

	function PLAYER:SetJailCards(jc)
		self.JailCards = jc
		self:UpdateFlags()
	end

	function PLAYER:SetRoll(roll)
		self.Roll = istable(roll) and roll or {bit.band(roll, 0x7), bit.rshift(bit.band(roll, 0x38), 3)}
		self:UpdateFlags()
	end

	function PLAYER:StartRoll(n)
		if n == 1 then
			self.Roll = {7, 0}
		else
			self.Roll = {7, 7}
		end
		self:UpdateFlags()
	end

	function PLAYER:RollDice(n)
		n = n or 1
		local out, tab = 0, {0, 0}
		for i = 1, n do
			local b = math.random(6)
			out = out + b
			tab[i] = b
		end
		self.Roll = tab
		self:UpdateFlags()
		return tab, out
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
		local space = self:GetSpace()
		local nx, ny = calcspace(space, i)
		surface.SetDrawColor(Color(10, 10, 10))
		surface.DrawRect(nx, ny, 24, 24)
		surface.SetDrawColor(self:GetColor())
		surface.DrawRect(nx + 3, ny + 3, 18, 18)
		draw.DrawText(self:GetRollTotal() or 0, "TargetIDSmall", nx + 5, ny + 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	function PLAYER:DrawPos(nx, ny)
		nx, ny = nx - 12, ny - 12
		surface.SetDrawColor(Color(10, 10, 10))
		surface.DrawRect(nx, ny, 24, 24)
		surface.SetDrawColor(self:GetColor())
		surface.DrawRect(nx + 3, ny + 3, 18, 18)
		draw.DrawText(self:GetRollTotal() or 0, "TargetIDSmall", nx + 5, ny + 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	function PLAYER:GetColor()
		local i = self:GetIndex() - 1
		return HSVToColor(i / 8 * 360, 1 - 0.60 * math.Clamp(i - 2, 0, 1), 1 - 0.20 * math.Clamp(i - 2, 0, 1))
	end
end
