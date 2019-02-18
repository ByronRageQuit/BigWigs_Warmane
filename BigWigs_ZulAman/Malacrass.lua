------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Hex Lord Malacrass"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local pName = UnitName("player")
local db = nil

local bolts = {
	duration = 10,
	cd = 30,
}

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Malacrass",

	engage_trigger = "Da shadow gonna fall on you....",

	bolts = "Spirit Bolts",
	bolts_desc = "Warn when Malacrass starts channelling Spirit Bolts.",
	bolts_message = "Incoming Spirit Bolts!",
	bolts_warning = "Spirit Bolts in 5 sec!",
	bolts_nextbar = "Next Spirit Bolts",

	soul = "Siphon Soul",
	soul_desc = "Warn who is afflicted by Siphon Soul.",
	soul_message = "Siphon: %s",

	totem = "Totem",
	totem_desc = "Warn when a Fire Nova Totem is casted.",
	totem_message = "Fire Nova Totem!",

	heal = "Heal",
	heal_desc = "Warn when Malacrass casts a heal.",
	heal_message = "Casting Heal!",

	consecration = "Consecration",
	consecration_desc = "Warn when Consecration is cast.",
	consecration_bar = "Consecration (%d)",
	consecration_warn = "Casted Consecration!",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Zul'Aman"]
mod.enabletrigger = boss
mod.guid = 24239
mod.toggleoptions = {"bolts", "soul", "totem", "heal", "consecration", "bosskill"}
mod.revision = tonumber(("$Revision: 4722 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "SoulSiphon", 43501)
	self:AddCombatListener("SPELL_CAST_START", "Heal", 43548, 43451, 43431) --Healing Wave, Holy Light, Flash Heal
	self:AddCombatListener("SPELL_SUMMON", "Totem", 43436)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Bolts", 43383)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Consecration", 43429)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:SoulSiphon(player, spellID)
	if db.soul then
		self:IfMessage(L["soul_message"]:format(player), "Urgent", spellID)
	end
end

function mod:Heal(_, spellID)
	if db.heal then
		local show = L["heal_message"]
		self:IfMessage(show, "Positive", spellID)
		self:Bar(show, 2, spellID)
	end
end

function mod:Totem()
	if db.totem then
		self:IfMessage(L["totem_message"], "Urgent", 43436)
	end
end

function mod:Bolts(_, spellID)
	if db.bolts then
		self:IfMessage(L["bolts_message"], "Important", spellID)
		self:Bar(L["bolts"], bolts.duration, spellID)
		self:Bar(L["bolts_nextbar"], bolts.duration+bolts.cd, spellID)
		self:DelayedMessage(bolts.duration+bolts.cd-5, L["bolts_warning"], "Attention")
	end
end

local count = 0
function mod:Consecration(_, spellID)
	if self.db.profile.consecration then
		self:IfMessage(L["consecration_warn"], "Positive", spellID)
		count = count + 1
		self:Bar(L["consecration_bar"]:format(count), 20, spellID)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["engage_trigger"] and db.bolts then
		self:Bar(L["bolts_nextbar"], bolts.cd, 43383)
		self:DelayedMessage(bolts.cd-5, L["bolts_warning"], "Attention")
	end
end

