include("shared.lua")

function ENT:Initialize()
	self:InitBoard()
end

local mat
local board

local d = 1080
local x, y = ScrW() / 2 - d / 2, 0

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


// TESTING PURPOSES WILL NOT BE FINAL PRODUCT
hook.Add("HUDPaint", "DrawMon", function()
	if not IsValid(board) then
		for k, v in pairs(ents.FindByClass("sent_gmodopoly")) do
			if v:GetLocalPlayer() then
				board = v
				return
			end
		end
		return
	end
	mat = mat or Material("monopoly/default_board"):GetTexture("$basetexture")


	if not board:GetLocalPlayer() then board = nil return end
	render.DrawTextureToScreenRect(mat, x, y, d, d)

	if board:GetState() == board.ST.WAITING then
		draw.SimpleTextOutlined("PLAYER 1 PRESS SPACE TO START", "CloseCaption_Bold", x + d / 2, y + d / 2 - 50, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 4, Color(0, 0, 0))
	elseif board:GetLocalPlayer():IsRolling() then
		draw.SimpleTextOutlined("PRESS SPACE TO ROLL!!!", "CloseCaption_Bold", x + d / 2, y + d / 2 - 50, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 4, Color(0, 0, 0))
	end

	// board info
	draw.RoundedBox(0, x - 150, 0, 150, ScrH(), Color(30, 30, 30, 200))

	draw.DrawText(board:GetStateName() .. "(" .. board:GetTurn() .. ")", "CloseCaption_Bold", x - 150 / 2, 2, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	for k, v in pairs(board.Players) do
		local nx, ny = x - 150, 40 + 80 * (k - 1)
		draw.RoundedBox(0, nx, ny, 150, 80, k % 2 ~= 0 and Color(180, 180, 180, 50) or Color(120, 120, 120, 60))
		draw.DrawText(v:GetName(), "TargetIDSmall", nx + 5, ny + 2, v:GetColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.DrawText("$" .. v:GetMoney(), "TargetIDSmall", nx + 145, ny + 2, nil, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		for gnum, gname in pairs(porder) do
			for pnum, prop in pairs(board.PropGroups[gname]) do
				if prop:GetOwner() == v then
					draw.RoundedBox(0, nx + 8 + 14 * (gnum - 1), ny + 25 + 12 * (pnum - 1), 8, 7, prop:GetColor())
				else
					draw.RoundedBox(0, nx + 8 + 14 * (gnum - 1), ny + 25 + 12 * (pnum - 1), 8, 7, Color(0, 0, 0, 90))
				end
			end
		end
	end


	if board:GetState() == board.ST.ROLL_FOR_ORDER then
		local c = table.Count(board.Players)
		for k, v in pairs(board.Players) do
			v:DrawPos(x + d / 2 - c * 30 + k * 30, y + d / 2)
		end
	elseif board:GetState() == board.ST.MOVE then
		local ply = board:GetTurnPlayer()
		if board:GetMVEndTime() ~= 0 and ply then
			local dr, ms, mss, t = board:GetMVEndTime(), board:GetMVSpace(), board:GetMVStartSpace(), CurTime() - board:GetStartTime() - 1
			ply:SetDrawSpace(mss + math.ceil(board:SpaceDistance(mss, ms) * math.Clamp(t / dr, 0, 1)))
		end

		for k, v in pairs(board.Players) do
			v:Draw()
		end
	else
		// players
		for k, v in pairs(board.Players) do
			v:SetDrawSpace(nil)
			v:Draw()
		end
	end
end)

hook.Add("PlayerButtonDown", "MN_TestInput", function(ply, key)
	if not IsValid(board) or not board:GetLocalPlayer() then return end
	local bply = board:GetLocalPlayer()
	if board:GetState() == board.ST.WAITING and key == KEY_SPACE then
		board:SendCommand("start")
	end

	if bply:IsRolling() and key == KEY_SPACE  then
		board:SendCommand("roll")
	end
end)

//debug
hook.Add("OnPlayerChat", "MN_TestInput", function(ply, text)
	if not IsValid(board) or not text:StartsWith("!") or ply ~= LocalPlayer() then return end
	text = string.Explode(" ", text)
	board:SendCommand(text[1]:sub(2):lower(), text)
end)