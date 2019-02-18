------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Jan'alai"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local fmt = string.format
local UnitName = UnitName
local db = nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Jan'alai",

	engage_trigger = "Spirits of da wind be your doom!",

	flame = "Flame Breath",
	flame_desc = "Warn who Jan'alai casts Flame Strike on.",
	flame_message = "Flame Breath on %s!",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Target Icon on the player targetted by Flame Breath. (requires promoted or higher)",

	bomb = "Fire Bomb",
	bomb_desc = "Show timers for Fire Bomb.",
	bomb_trigger = "I burn ya now!",
	bomb_message = "Incoming Fire Bombs!",

	adds = "Adds",
	adds_desc = "Warn for Incoming Adds.",
	adds_trigger = "Where ma hatcha? Get to work on dem eggs!",
	adds_message = "Incoming Adds!",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Zul'Aman"]
mod.enabletrigger = boss
mod.guid = 23578
mod.toggleoptions = {"bomb", "adds", -1, "flame", "icon", "enrage", "berserk", "bosskill"}
mod.revision = tonumber(("$Revision: 4706 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_START", "FlameBreath", 43140)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

local function ScanTarget()
	local target
	if UnitName("target") == boss then
		target = UnitName("targettarget")
	elseif UnitName("focus") == boss then
		target = UnitName("focustarget")
	else
		local num = GetNumRaidMembers()
		for i = 1, num do
			if UnitName(fmt("%s%d%s", "raid", i, "target")) == boss then
				target = UnitName(fmt("%s%d%s", "raid", i, "targettarget"))
				break
			end
		end
	end
	if target then
		mod:IfMessage(fmt(L["flame_message"], target), "Important", 23461)
		if mod.db.profile.icon then
			mod:Icon(target)
		end
	end
end

function mod:FlameBreath()
	if db.flame then
		self:ScheduleEvent("BWFlameToTScan", ScanTarget, 0.2)
		self:ScheduleEvent("BWRemoveJanIcon", "BigWigs_RemoveRaidIcon", 4, self)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if db.bomb and msg == L["bomb_trigger"] then
		self:Message(L["bomb_message"], "Urgent")
		self:Bar(L["bomb"], 12, "Spell_Fire_Fire")
	elseif db.adds and msg == L["adds_trigger"] then
		self:Message(L["adds_message"], "Positive")
		self:Bar(L["adds"], 92, "INV_Misc_Head_Troll_01")
	elseif msg == L["engage_trigger"] then
		if db.enrage then
			self:Enrage(300, nil, true)
		end
		if db.berserk then
			self:Enrage(600, true)
		end
		if db.adds then
			self:Bar(L["adds"], 12, "INV_Misc_Head_Troll_01")
		end
	end
end

