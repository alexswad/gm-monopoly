
for k, v in ipairs(ENT.ChanceCards) do
	v._index = k
end

for k, v in ipairs(ENT.CommunityCards) do
	v._index = bit.bor(k, 2 ^ 6)
end

if SERVER then
	function ENT:InitCards()
		self:BuildChanceDeck()
		self:BuildCommunityDeck()
	end

	function ENT:BuildChanceDeck()
		self.ChanceDeck = table.Copy(self.ChanceCards)
	end

	function ENT:BuildCommunityDeck()
		self.CommunityDeck = table.Copy(self.CommunityCards)
	end

	function ENT:CardEffect(ply, tbl)
		if tbl.space then
			self:StartMove(ply, tbl.space)
			return true
		elseif tbl.money then
			ply:AddMoney(tbl.money)
		elseif tbl.goj then
			ply:AddGOJCard()
		elseif tbl.repairs then
			
		elseif tbl.jail then
			self:SetState("GO_TO_JAIL")
			return true
		elseif tbl.birthday then
			for k, v in pairs(self.Players) do
				if v ~= ply then
					v:AddMoney(-tbl.birthday)
					ply:AddMoney(tbl.birthday)
				end
			end
		elseif tbl.payeach then
			
		end
	end
end

function ENT:GetCurrentCard()
	local c = self:GetCCard()
	return self.Cards[bit.band(c, 2 ^ 6) ~= 0 and 2 or 1][bit.band(c, bit.bnot(2 ^ 6))]
end

function ENT:DrawCommunityCard()
	if #self.CommunityDeck == 0 then self:BuildCommunityDeck() end
	local card, index = table.Random(self.CommunityDeck)
	table.remove(self.CommunityDeck, index)
	return card
end

function ENT:DrawChanceCard()
	if #self.ChanceDeck == 0 then self:BuildChanceDeck() end
	local card, index = table.Random(self.ChanceDeck)
	table.remove(self.ChanceDeck, index)
	return card
end