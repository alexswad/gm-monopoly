local PANEL = {}
ENT.PLAYER_PANEL = vgui.RegisterTable(PANEL, "Panel")

local porder = {
	"brown",
	"cyan",
	"pink",
	"orange",
	"railroad",
	"red",
	"yellow",
	"utility",
	"green",
	"blue",
}

function PANEL:Init()
	local icon = vgui.Create("AvatarImage", self)
	self.Icon = icon
end

function PANEL:SetPlayer(ply)
	self.PObj = ply
	self.Icon:SetPlayer(ply.Entity)
end

PANEL.BackgroundColor = Color(0, 0, 0, 30)
function PANEL:Paint(w, h)
	draw.RoundedBox(4, 0, 0, w, h, self.BackgroundColor)
end

function PANEL:GetHoveredProp()

end

function PANEL:PerformLayout(w, h)

end