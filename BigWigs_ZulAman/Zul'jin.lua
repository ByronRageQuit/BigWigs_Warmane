------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Zul'jin"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local pName = UnitName("player")
local db = nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Zul'jin",

	engage_trigger = "Nobody badduh dan me!",
	engage_message = "Phase 1 - Human Phase",

	form = "Form Shift",
	form_desc = "Warn when Zul'jin changes form.",
	form_bear_trigger = "Got me some new tricks... like me brudda bear....",
	form_bear_message = "80% Phase 2 - Bear Form!",
	form_eagle_trigger = "Dere be no hidin' from da eagle!",
	form_eagle_message = "60% Phase 3 - Eagle Form!",
	form_lynx_trigger = "Let me introduce you to me new bruddas: fang and claw!",
	form_lynx_message = "40% Phase 4 - Lynx Form!",
	form_dragonhawk_trigger = "Ya don' have to look to da sky to see da dragonhawk!",
	form_dragonhawk_message = "20% Phase 5 - Dragonhawk Form!",

	throw = "Grievous Throw",
	throw_desc = "Warn who is afflicted by Grievous Throw.",
	throw_message = "%s has Grievous Throw",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Target Icon on the player afflicted by Grievous Throw or Claw Rage. (requires promoted or higher)",

	paralyze = "Paralyze",
	paralyze_desc = "Warn for Creeping Paralysis and the impending Paralyze after effect.",
	paralyze_warning = "Creeping Paralysis - Paralyze in 5 sec!",
	paralyze_message = "Paralyzed!",
	paralyze_bar = "Inc Paralyze",
	paralyze_warnbar = "Next Paralyze",
	paralyze_soon = "Creeping Paralysis in 5 sec",

	claw = "Claw Rage",
	claw_desc = "Warn for who gets Claw Rage.",
	claw_message = "Claw Rage on %s",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Zul'Aman"]
mod.enabletrigger = boss
mod.guid = 23863
mod.toggleoptions = {"form", "paralyze", -1, "throw", "claw", "icon", "bosskill"}
mod.revision = tonumber(("$Revision: 4722 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "Throw", 43093)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Paralyze", 43095)
	self:AddCombatListener("SPELL_AURA_APPLIED", "ClawRage", 43150)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Throw(player, spellID)
	if db.throw then
		self:IfMessage(L["throw_message"]:format(player), "Attention", spellID)
		self:Icon(player, "icon")
	end
end

function mod:Paralyze(_, spellID)
	if db.paralyze then
		self:IfMessage(L["paralyze_warning"], "Urgent", spellID)
		self:DelayedMessage(5, L["paralyze_message"], "Positive")
		self:ScheduleEvent("BWZulParaInc", "BigWigs_Message", 22, L["paralyze_soon"], "Urgent")
		self:Bar(L["paralyze_bar"], 5, spellID)
		self:Bar(L["paralyze_warnbar"], 27, spellID)
	end
end

function mod:ClawRage(player, spellID)
	if db.claw then
		self:IfMessage(L["claw_message"]:format(player), "Urgent", spellID)
		self:Icon(player, "icon")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if not db.form then return end

	if msg == L["form_bear_trigger"] then
		self:Message(L["form_bear_message"], "Urgent")
		self:TriggerEvent("BigWigs_RemoveRaidIcon")
	elseif msg == L["form_eagle_trigger"] then
		self:Message(L["form_eagle_message"], "Important")
		self:CancelScheduledEvent("BWZulParaInc")
		self:TriggerEvent("BigWigs_StopBar", self, L["paralyze_warnbar"])
	elseif msg == L["form_lynx_trigger"] then
		self:Message(L["form_lynx_message"], "Positive")
	elseif msg == L["form_dragonhawk_trigger"] then
		self:Message(L["form_dragonhawk_message"], "Attention")
		self:TriggerEvent("BigWigs_RemoveRaidIcon")
	elseif msg == L["engage_trigger"] then
		self:Message(L["engage_message"], "Attention")
	end
end

