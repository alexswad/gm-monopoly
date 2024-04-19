function ENT:InvalidatePlayerPanels()
	if not IsValid(CMONPANEL) then return end
	CMONPANEL:ValidatePlayerPanels()
end

local PANEL = {}
local PLAYER = ENT.PLAYER_PANEL
PANEL.CameraPos = vector_origin
PANEL.CameraAngle = angle_zero

function PANEL:Init()
	self:SetFocusTopLevel(true)
	self.PPanels = {}
end

function PANEL:Think()
	local b = self.Board
	if not IsValid(b) then
		self:Remove()
		return
	end
	self:SetSize(ScrW(), ScrH())
	self:Center()
	if self.NextThink and self.NextThink < CurTime() then return end

	self.NextThink = CurTime() + 0.5
end

function PANEL:ValidatePlayerPanels()
	local b = self.Board
	if not IsValid(b) then return end

	local mply = math.max(0, #self.Board.Players - table.Count(self.PPanels))

	if mply ~= 0 then
		for i = 1, mply do
			self:CreatePlayerPanel()
		end
	end

	local sort
	for k, v in pairs(self.PPanels) do
		local ply = b:GetPlayerByIndex(k)
		if not ply then
			sort = true
			v:Remove()
			self.PPanels[v] = nil
			continue
		end
		v:SetPlayer(ply)
	end

	if sort then table.SortByMember(self.PPanels, "Index", true) end
	self:InvalidateLayout()
end

function PANEL:Center()
	self:CenterVertical()
	self:CenterHorizontal()
end

function PANEL:FaceVector(pos, angle, dist)
	local npos = angle:Forward() * dist + pos
	self.CameraPos = self.Board:LocalToWorld(npos)
	self.CameraAngle = self.Board:LocalToWorldAngles((pos - npos):Angle())
end

function PANEL:CreatePlayerPanel()
	local np = vgui.CreateFromTable(PLAYER, self)
	self.PPanels[#self.PPanels + 1] = np
	return np
end

local spin = 0
function PANEL:Paint(w, h)
	local x, y = self:GetPos()
	local b = self.Board

	if b:GetState() == b.ST.WAITING then
		spin = spin + 0.1
		self:FaceVector(Vector(0, 0, 30), Angle(-30, spin % 360, 0), 100)
	end

	local e = ents.FindInSphere(b:GetPos(), 40)
	local t = {}

	for k, v in pairs(e) do
		if v.GetNoDraw and v ~= b and v:GetClass() ~= "prop_dynamic" then
			t[v] = v:GetNoDraw()
			v:SetNoDraw(true)
		end
	end

	local old = DisableClipping( false ) -- Avoid issues introduced by the natural clipping of Panel rendering
	render.RenderView( {
		origin = self.CameraPos,
		angles = self.CameraAngle,
		x = x, y = y,
		w = w, h = h,
		drawviewmodel = false,

	} )
	DisableClipping( old )

	for k, v in pairs(t) do
		k:SetNoDraw(v)
	end

end

function PANEL:PerformLayout(w, h)
	for k, v in pairs(self.PPanels) do
		v:SetSize(300, 100)
		v:SetPos(10, -50 + 100 * k)
	end
end


ENT.MONPANEL = vgui.RegisterTable(PANEL)