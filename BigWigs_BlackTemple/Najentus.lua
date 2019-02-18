------------------------------
--      Are you local?    --
------------------------------

local boss = BB["High Warlord Naj'entus"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local db = nil
local CheckInteractDistance = CheckInteractDistance
local fmt = string.format

----------------------------
--      Localization     --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Naj'entus",

	start_trigger = "You will die in the name of Lady Vashj!",

	spine = "Impaling Spine",
	spine_desc = "Tells you who gets impaled.",
	spine_message = "Impaling Spine on %s!",

	spinesay = "Spine Say",
	spinesay_desc = "Print in say when you have a Spine, can help nearby members with speech bubbles on.",
	spinesay_message = "Spine on me!",

	shield = "Tidal Shield",
	shield_desc = "Timers for when Naj'entus will gain tidal shield.",
	shield_nextbar = "Next Tidal Shield",
	shield_warn = "Tidal Shield!",
	shield_soon_warn = "Tidal Shield in ~10sec!",
	shield_fade = "Shield Faded!",

	icon = "Icon",
	icon_desc = "Put an icon on players with Impaling Spine.",
} end )

----------------------------------
--    Module Declaration   --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = boss
mod.guid = 22887
mod.toggleoptions = {"enrage", "shield", -1, "spine", "spinesay", "icon", "proximity", "bosskill"}
mod.revision = tonumber(("$Revision: 4720 $"):sub(12, -3))
mod.proximityCheck = function( unit ) return CheckInteractDistance( unit, 3 ) end
mod.proximitySilent = true

local timer = {
	shield = 60,
	spine = 20,
}
local icon = {
	shield = 39872,
	spine = 39837,
}
local syncName = {}

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "ShieldOn", 39872)
	self:AddCombatListener("SPELL_AURA_REMOVED", "ShieldOff", 39872)
	self:AddCombatListener("SPELL_AURA_APPLIED", "ImpalingSpine", 39837)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
end

------------------------------
--    Event Handlers     --
------------------------------

function mod:ShieldOn()
	if db.shield then
		self:IfMessage(L["shield_warn"], "Important", icon.shield, "Alert")
		self:DelayedMessage(timer.shield-10, L["shield_soon_warn"], "Positive")
		self:Bar(L["shield_nextbar"], timer.shield, icon.shield)
	end
end

function mod:ShieldOff()
	if db.shield then
		self:IfMessage(L["shield_fade"], "Positive", icon.shield)
	end
end

function mod:ImpalingSpine(player)
	if db.spine then
		if UnitIsUnit(player, "player") and db.spinesay then
			SendChatMessage(L["spinesay_message"], "SAY")
		end
		self:IfMessage(fmt(L["spine_message"], player), "Important", icon.spine, "Alert")
		self:Icon(player)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["start_trigger"] then
		if db.shield then
			self:DelayedMessage(timer.shield-10, L["shield_soon_warn"], "Positive")
			self:Bar(L["shield_nextbar"], timer.shield, icon.shield)
		end
		if db.enrage then
			self:Enrage(480)
		end
		self:TriggerEvent("BigWigs_ShowProximity", self)
	end
end

