local rshift = bit.rshift
local lshift = bit.lshift
local band = bit.band
local bor = bit.bor

-- AccessorFlags(table target, string flagvar, table input, int roff, bool network)
-- Adds functions to edit flags stored in an integer for easier networking
-- target - table to be add meta functions to
-- flagvar - variable to store flag to
-- input - table in the form of {{"var", # of bits}, {"var", # of bits}} ex. {{"Length", 5}, {"Width", 4}, {"Height", 6}}
-- roff - bit offset for overloading functions
-- network - if true will execute Set[[flagvar]] serverside and Get[[flagvar]] clientside
local function AccessorFlags(target, flagvar, tab, roff, network)
	local bc = roff or 0
	target[flagvar] = 0

	for a, b in ipairs(tab) do
		local k, v = b[1], b[2]
		local sb = bc
		local flb = 2 ^ v - 1

		target["Get" .. k] = function(self)
			return rshift(band(network and CLIENT and self["Get" .. flagvar](self) or self[flagvar], lshift(flb, sb)), sb) or 0
		end

		target["Set" .. k] = function(self, val)
			assert(val <= flb, "SetFlag " .. k .. " out of range (" .. val .. " > " .. flb .. ")")
			local res = bor(band(self[flagvar], 2 ^ 30 - 1 - lshift(flb, sb)), lshift(val, sb))
			self[flagvar] = res
			if network and SERVER then self["Set" .. flagvar](self, res) end
		end

		bc = bc + v
		assert(bc <= 30, "Number of bits exceeds flag maximum of 30")
	end
end

return AccessorFlags