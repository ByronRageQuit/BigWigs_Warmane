----------------------------------
--    Module Declaration   --
----------------------------------
local boss = BB["High Warlord Naj'entus"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Black Temple"]
mod.enabletrigger = boss
mod.guid = 22887
mod.toggleoptions = {"shield", "shieldkill", -1, "spine", "spinesay", "spineicon", -1, "proximity", "enrage", "bosskill"}
mod.revision = 1000
--use IsSpellInRange with auto attack?
mod.proximityCheck = function( unit ) return CheckInteractDistance( unit, 3 ) end --Interact distance type 3 is 9.9 yrds, smallest that the api can check
mod.proximitySilent = true
local CheckInteractDistance = CheckInteractDistance
local db = nil
local started = nil
local shield_dmg = 8500

local timer = {
	shield = 60,
}
local icon = {
	shield = 39872,
	shieldkill = "ability_creature_cursed_02",
	spine = 39837,
}
local syncName = {}

----------------------------
--      Localization     --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Naj'entus",
	engage_trigger = "You will die in the name of Lady Vashj!",
	
	spine = "Impaling Spine",
	spine_desc = "Alerts who is impaled.",
	spine_msg = "Impaling Spine on %s!",
	
	spinesay = "Spine Say",
	spinesay_desc = "Alerts in say when you are spined.",
	spinesay_msg = "Spine on ME!",
	
	spineicon = "Spine Icon",
	spineicon_desc = "Puts an icon on the person with spine",
	
	shield = "Tidal Shield",
	shield_desc = "Timer & Alerts for Tidal Shield.",
	shield_msg = "Shield Active!",
	shield_soon = "Shield in 10 sec",
	shield_bar = "Next Shield",
	
	shieldkill = "Shield Kill Count",
	shieldkill_desc = "Show counter bar for # of players below hp threshold.",
	shieldkill_bar = "Shield Deaths",
	
} end )

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "ShieldOn", 39872)
	self:AddCombatListener("SPELL_AURA_REMOVED", "ShieldOff", 39872)
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

function mod:ImpalingSpine(player)
	if db.spine then --Alert msg
		self:Message(L["spine_msg"]:format(player), "Important", icon.spine, "Alert")
	end
	if db.spinesay and UnitIsUnit(player, "player") then --Say Alert
		SendChatMessage(L["spinesay_msg"], "SAY")
	end
	if db.spineicon then --Icon
		self:Icon(player)
	end
end

function mod:ShieldOn()
	if db.shield then --the timer might start after pop
		self:Message(L["shield_msg"], "Important", icon.sheild, "Alert")
		self:DelayedMessage(timer.shield-10, L["shield_soon"], "Positive")
		self:Bar(L["shield_bar"], timer.shield, icon.shield)
	end
	if db.shieldkill then
		--Start Counter bar
		self:TriggerEvent("BigWigs_StartCounterBar", self, L["shieldkill_bar"], 25)
		--self:TriggerEvent("BigWigs_SetCounterBar", self, L["shieldkill_bar"], 5)
		--start hp check/set bar event
		self:ScheduleRepeatingEvent("RaidHpCheck", self.hpCheck, 1, self)
	end
end
function mod:ShieldOff()
	if shieldkill then
		--stop counter bar
		self:TriggerEvent("BigWigs_StopCounterBar", self, L["shieldkill_bar"])
		--stop hp check event
		self:CancelScheduledEvent("RaidHpCheck")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["engage_trigger"] then
		started = true
		shieldkill_count = 0
		if db.enrage then
			self:Enrage(300)
		end
		if db.shield then
			self:DelayedMessage(timer.shield-10, L["shield_soon"], "Positive")
			self:Bar(L["shield_bar"], timer.shield, icon.shield)
		end
		if db.proximity then
			self:TriggerEvent("BigWigs_ShowProximity", self)
		end
	end
end

function mod:hpCheck()
	local shieldkill_count = 0
	for i = 1, GetNumRaidMembers() do
		local raid_member = "raid"..i
		if UnitHealth(raid_member) <= shield_dmg then
			shieldkill_count = shieldkill_count + 1
		end
	end
	--ChatFrame1:AddMessage(shieldkill_count)
	if shieldkill_count ~= 0 then
		self:TriggerEvent("BigWigs_SetCounterBar", self, L["shieldkill_bar"], shieldkill_count)
	else
		self:TriggerEvent("BigWigs_StartCounterBar", self, L["shieldkill_bar"], 25)
	end
end