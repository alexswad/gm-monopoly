local PROP = {}
PROP.__index = PROP

AccessorFunc(PROP, "RentTable", "RentTable")
AccessorFunc(PROP, "Name", "Name")
AccessorFunc(PROP, "Group", "Group")
AccessorFunc(PROP, "Cost", "Cost")
AccessorFunc(PROP, "RentLevel", "RentLevel")

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
	prop.Cost = tab.cost
	prop.Name = tab.name
	prop.Group = tab.group
	prop.Board = self

	return prop
end

function PROP:GetRent()

end

function PROP:GetMortaged()
	return self:GetRentLevel() == -1
end

function PROP:GetMortagePrice()
	return self.Cost / 2
end

function PROP:GetUnmortageCost()
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