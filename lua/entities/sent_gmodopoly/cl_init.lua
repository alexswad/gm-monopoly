include("shared.lua")
include("vgui/player.lua")
include("vgui/panel.lua")

function ENT:Initialize()
	self:InitBoard()
end

//debug
hook.Add("OnPlayerChat", "MN_TestInput", function(ply, text)
	if not IsValid(board) or not text:StartsWith("!") or ply ~= LocalPlayer() then return end
	text = string.Explode(" ", text)
	board:SendCommand(text[1]:sub(2):lower(), text)
end)