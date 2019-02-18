------------------------------
--      Are you local?      --
------------------------------

local zone = BZ["Arathi Basin"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..zone)

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(zone)
mod.zonename = "Battlegrounds"
mod.revision = tonumber(("$Revision: 4722 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
	--db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:CHAT_MSG_BG_SYSTEM_NEUTRAL(msg)
	self:keule(msg,"Neutral")
end

function mod:CHAT_MSG_BG_SYSTEM_HORDE(msg)
	self:keule(msg,"Horde")
end


function mod:CHAT_MSG_BG_SYSTEM_ALLIANCE(msg)
	self:keule(msg,"Alliance")
end

local capturetime = 60
local attacks = " attacks "

function mod:keule(msg,faction)
	local color, icon, base
	if msg:find("wins") then 
		BigWigs:ToggleModuleActive(self, false)
		return
	end
	
	if faction == "Horde" then
		color = "red"
		icon = "INV_BannerPVP_01"
	elseif faction == "Alliance" then
		color = "blue"
		icon = "INV_BannerPVP_02"
	else color = "yellow" end
	
	if msg:find("farm") then base = "Farm"
	elseif msg:find("stables") then base = "Stables"
	elseif msg:find("blacksmith") then base = "Blacksmith"
	elseif msg:find("lumber mill") then base = "Lumber Mill"
	elseif msg:find("mine") then base = "Gold Mine" end
	
	if base then
		if msg:find("assaulted") or msg:find("claims") then
			self:Bar(faction..attacks..base, capturetime, icon, true, color)
		elseif msg:find("defended") then
			if faction == "Horde" then faction = "Alliance"
			else faction = "Horde" end
			self:TriggerEvent("BigWigs_StopBar", self, faction..attacks..base)
		end
	end
end