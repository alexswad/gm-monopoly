local PROP = {}
PROP.__index = PROP

AccessorFunc(PROP, "RentTable", "RentTable")
AccessorFunc(PROP, "Name", "Name")
AccessorFunc(PROP, "Group", "Group")
AccessorFunc(PROP, "Price", "Price")
AccessorFunc(PROP, "RentLevel", "RentLevel")

local housestoletter = {
	[0] = "a",
	[1] = "b",
	[2] = "c",
	[3] = "d",
	[4] = "e",
	[5] = "f",
	[-1] = "m",
}
ENT.PROP_HL = housestoletter

local lettertohouses = {}
ENT.PROP_LH = lettertohouses
for k, v in pairs(housestoletter) do
	lettertohouses[v] = k
end

local colors = {
	brown = Color(149, 84, 54),
	cyan = Color(173, 224, 251),
	pink = Color(217, 58, 150),
	orange = Color(247, 148, 29),
	red = Color(255, 0, 0),
	yellow = Color(254, 242, 0),
	green = Color(32, 179, 91),
	blue = Color(0, 114, 187),
	railroad = Color(30, 30, 30),
	utility = Color(230, 230, 230),
}

function ENT:CreateProperty(tab)
	local prop = {}
	setmetatable(prop, PROP)
	prop.RentTable = tab.rent
	prop.Price = tab.price
	prop.Name = tab.name
	prop.Group = tab.group
	prop.Board = self

	return prop
end

function PROP:GetRent()
	return self.RentTable[self:GetRentLevel()] or self.RentTable[#self.RentTable]
end

function PROP:GetMortaged()
	return self:GetRentLevel() == -1
end

function PROP:GetMortagePrice()
	return self.Price / 2
end

function PROP:GetUnmortagePrice()
	return self:GetMortagePrice() * 1.1
end

function PROP:GetOwner()
	if self.owner ~= nil and (not IsValid(self.owner) or not self.owner.Properties[self.Index]) then
		self.owner = nil
	elseif self.owner then
		return self.owner
	end

	for k, v in pairs(self.Board.Players) do
		if v.Properties[self.Index] then
			self.owner = v
			return self.owner
		end
	end

	return false
end

function PROP:SetOwner(ply)
	for k, v in pairs(self.Board.Players) do
		v:RemoveProperty(self.Index, true)
	end
	ply.Properties[self.Index] = self
end

function PROP:GetColor()
	return colors[self.Group]
end

function PROP:Draw()

end

if CLIENT then
	function ENT:RebuildPropertyCache()
		timer.Create("MN_RebuildPropCache", 0.1, 1, function()
			self:BuildPropertyCache()
		end)
	end

	function ENT:BuildPropertyCache()
		for k, v in pairs(string.Explode("|", self:GetPropData())) do
			local ply = self.Players[k]
			if not ply then continue end

			ply.Properties = {}
			if not ply:IsValid() then continue end

			for a, b in pairs (string.Explode(":", v)) do
				local propid = tonumber(b:sub(1, -2))
				if not propid then continue end
				ply.Properties[propid] = self.Properties[propid]
				self.Properties[propid].owner = ply
				ply.Properties[propid]:SetRentLevel(lettertohouses[b:sub(#b)] or 0)
			end
		end
		timer.Remove("MN_RebuildPropCache")
	end
else
	function ENT:UpdatePropData()
		local str = ""
		for i = 1, 8 do
			local ply = self.Players[i]
			if not IsValid(ply) then
				if i < 8 then str = str .. "|" end
				continue
			end
			str = str .. ply:GetPropDataString()
			if i < 8 then str = str .. "|" end
		end
		self:SetPropData(str)
	end
end