include("shared.lua")

function ENT:Initialize()
	self:InitBoard()
end

local mat = Material("monopoly/default_board"):GetTexture("$basetexture")
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
			if v:GetPlayer(LocalPlayer()) then
				board = v
				return
			end
		end
		return
	end

	if not board:GetPlayer(LocalPlayer()) then board = nil return end
	render.DrawTextureToScreenRect(mat, x, y, d, d)

	// board info
	draw.RoundedBox(0, x - 150, 0, 150, ScrH(), Color(30, 30, 30, 200))

	draw.DrawText(board:GetStateName(), "CloseCaption_Bold", x - 150 / 2, 2, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

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


	if board.ST_ENUM.ROLL_FOR_ORDER == board:GetState() then
		local c = table.Count(board.Players)
		for k, v in pairs(board.Players) do
			v:DrawPos(x + d / 2 - c * 30 + k * 30, y + d / 2)
		end
	else
		// players
		for k, v in pairs(board.Players) do
			v:Draw()
		end
	end
end)

function curve(evalTime, p0, p1, p2, p3)
	local c3 = p3 + 3.0 * (p1 - p2) - p0
	local c2 = 3.0 * (p2 - 2.0 * p1 + p0)
	local c1 = 3.0 * (p1 - p0)
	local c0 = p0 - evalTime

	local a = c2 / c3
	local b = c1 / c3
	local c = c0 / c3

	local aDiv3 = a / 3.0
	local Q = (aDiv3 * aDiv3) - b / 3.0
	local R = ((2 * aDiv3 * aDiv3 * aDiv3) - (aDiv3 * b) + c) / 2.0

	local RR = R * R
	local QQQ = Q * Q * Q
	if RR < QQQ then
		local sqrt_Q = math.sqrt(Q)
		local theta = math.acos(R / math.sqrt(QQQ))
		local t1 = -2.0 * sqrt_Q * math.cos(theta / 3.0) - aDiv3
		local t2 = -2.0 * sqrt_Q * math.cos((theta + 2.0 * math.pi) / 3.0) - aDiv3
		local t3 = -2.0 * sqrt_Q * math.cos((theta - 2.0 * math.pi) / 3.0) - aDiv3
		return (t1 >= 0.0 and t1 <= 1.0) and t1 or nil,
			   (t2 >= 0.0 and t2 <= 1.0) and t2 or nil,
			   (t3 >= 0.0 and t3 <= 1.0) and t3 or nil
	else
		local A = (
			(R > 0.0 and -mathPow(R + math.sqrt(RR-QQQ), 1.0 / 3.0)) or
			 mathPow(-R + math.sqrt(RR-QQQ), 1.0 / 3.0)
		)
		local t1 = A + (A == 0.0 and 0.0 or Q / A) - aDiv3
		return (t1 >= 0.0 and t1 <= 1.0) and t1 or nil, nil, nil
	end
end