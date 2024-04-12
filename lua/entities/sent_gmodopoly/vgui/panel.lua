local PANEL = {}
PANEL.CameraPos = vector_origin
PANEL.CameraAngle = angle_zero

function PANEL:Init()
	self:SetFocusTopLevel(true)
end

function PANEL:Think()
	local b = self.Board
	if not IsValid(b) then
		self:Remove()
		return
	end
	self:SetSize(ScrW(), ScrH())
	self:Center()
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

end


MONPANEL = vgui.RegisterTable(PANEL)