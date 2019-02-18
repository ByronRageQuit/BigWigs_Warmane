------------------------------
--      Are you local?      --
------------------------------

local zone = BZ["Alterac Valley"]
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
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	--db = self.db.profile
end

local graveyards = {
	"Aid Station",
	"Stormpike Graveyard",
	"Stonehearth Graveyard",
	"Snowfall Graveyard",
	"Iceblood Graveyard",
	"Frostwolf Graveyard",
	"Relief Hut",
}

local bases = {
	Alliance = {
		"Stonehearth Bunker",
		"Icewing Bunker",
		"Dun Baldar North Bunker",
		"Dun Baldar South Bunker",
	},
	Horde = {
		"Iceblood Tower",
		"Tower Point",
		"East Frostwolf Tower",
		"West Frostwolf Tower",
	}
}

local capturetime = 240

------------------------------
--      Event Handlers      --
------------------------------
function mod:CHAT_MSG_MONSTER_YELL(msg)
	local color, icon, graveyard, base
	if msg == "The Stormpike General is Dead!" or msg == "The Frostwolf General is Dead!" then 
		BigWigs:ToggleModuleActive(self, false)
		return
	end
	
	if msg:find("Horde") then
		color = "red"
		icon = "INV_BannerPVP_01"
	elseif msg:find("Alliance") then
		color = "blue"
		icon = "INV_BannerPVP_02"
	else color = "yellow" end
	
	for i,b in pairs(graveyards) do
		if msg:find(b) then graveyard = b end
	end
	for faction,baselist in pairs(bases) do
		for i,b in pairs(baselist) do
			if msg:find(b) then base = b end
		end
	end
	
	if graveyard or base then
		if msg:find("under attack") then
			self:Bar(graveyard or base, capturetime, icon, true, color)
		elseif msg:find("was taken") then
			self:TriggerEvent("BigWigs_StopBar", self, graveyard or base)
		end
	elseif msg:find("Mine") then
			return
	else
		--if we land here, there is something missing/wrong in this module
		--DEFAULT_CHAT_FRAME:AddMessage("Alterac Valley Module: Unhandled Event")
		--DEFAULT_CHAT_FRAME:AddMessage(msg)
	end
end