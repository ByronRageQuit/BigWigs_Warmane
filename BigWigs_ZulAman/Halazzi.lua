------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Halazzi"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local UnitName = UnitName
local UnitHealth = UnitHealth
local one = nil
local two = nil
local three = nil
local count = 1
local db = nil
local pName = UnitName("player")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Halazzi",

	engage_trigger = "Get on ya knees and bow.... to da fang and claw!",

	totem = "Totem",
	totem_desc = "Warn when Halazzi casts a Lightning Totem.",
	totem_message = "Incoming Lightning Totem!",

	phase = "Phases",
	phase_desc = "Warn for phase changes.",
	phase_spirit = "I fight wit' untamed spirit....",
	phase_normal = "Spirit, come back to me!",
	normal_message = "Normal Phase!",
	spirit_message = "%d%% HP! - Spirit Phase!",
	spirit_soon = "Spirit Phase soon!",
	spirit_bar = "~Possible Normal Phase",

	frenzy = "Frenzy",
	frenzy_desc = "Frenzy alert.",
	frenzy_trigger = "%s goes into a killing frenzy!",
	frenzy_message = "Frenzy!",

	flame = "Flame Shock",
	flame_desc = "Warn for players with Flame Shock.",
	flame_message = "Flame Shock: %s",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Target Icon on the player with Flame Shock. (requires promoted or higher)",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Zul'Aman"]
mod.enabletrigger = boss
mod.guid = 23577
mod.toggleoptions = {"totem", "phase", "frenzy", -1, "flame", "icon", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision: 4706 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_START", "Totem", 43302)
	self:AddCombatListener("SPELL_AURA_APPLIED", "FlameShock", 43303)
	self:AddCombatListener("SPELL_AURA_REMOVED", "FlameShockRemoved", 43303)
	self:AddCombatListener("SPELL_DISPEL", "FlameShockRemoved", 43303)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Totem()
	if db.totem then
		self:IfMessage(L["totem_message"], "Attention", 43302)
	end
end

function mod:FlameShock(player, spellID)
	if db.flame then
		local warn = L["flame_message"]:format(player)
		self:IfMessage(warn, "Attention", spellID)
		self:Bar(warn, 12, spellID)
	end
	self:Icon(player, "icon")
end

function mod:FlameShockRemoved(player)
	self:TriggerEvent("BigWigs_StopBar", self, L["flame_message"]:format(player))
	self:TriggerEvent("BigWigs_RemoveRaidIcon")
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg == L["frenzy_trigger"] and db.frenzy then
		self:Message(L["frenzy_message"], "Important")
		self:Bar(L["frenzy_message"], 6, "Ability_GhoulFrenzy")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if not db.phase then return end

	if msg == L["phase_spirit"] then
		if count == 1 then
			self:Message(L["spirit_message"]:format(75), "Urgent")
			count = count + 1
		elseif count == 2 then
			self:Message(L["spirit_message"]:format(50), "Urgent")
			count = count + 1
		elseif count == 3 then
			self:Message(L["spirit_message"]:format(25), "Urgent")
		end
		self:Bar(L["spirit_bar"], 50, "Spell_Nature_Regenerate")
	elseif msg == L["phase_normal"] then
		self:Message(L["normal_message"], "Attention")
	elseif msg == L["engage_trigger"] then
		count = 1
		one = nil
		two = nil
		three = nil
		if db.enrage then
			self:Enrage(600)
		end
	end
end

function mod:UNIT_HEALTH(msg)
	if not db.phase then return end

	if UnitName(msg) == boss then
		local health = UnitHealth(msg)
		if not one and health > 77 and health <= 80 then
			one = true
			self:Message(L["spirit_soon"], "Positive")
		elseif not two and health > 52 and health <= 55 then
			two = true
			self:Message(L["spirit_soon"], "Positive")
		elseif not three and health > 27 and health <= 30 then
			three = true
			self:Message(L["spirit_soon"], "Positive")
		end
	end
end

