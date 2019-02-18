------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Nalorakk"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local db = nil

local timer = {
	enrage = 600,
	bear = 30,
	normal = 45,
}

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Nalorakk",

	engage_trigger = "You be dead soon enough!",
	engage_message = "%s Engaged - Bear Form in 45sec!",

	phase = "Phases",
	phase_desc = "Warn for phase changes.",
	phase_bear = "You call on da beast, you gonna get more dan you bargain for!",
	phase_normal = "Make way for Nalorakk!",
	normal_message = "Normal Phase!",
	normal_bar = "Next Bear Phase",
	normal_soon = "Normal Phase in 10sec",
	normal_warning = "Normal Phase in 5sec",
	bear_message = "Bear Phase!",
	bear_bar = "Next Normal Phase",
	bear_soon = "Bear Phase in 10sec",
	bear_warning = "Bear Phase in 5sec",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Zul'Aman"]
mod.enabletrigger = boss
mod.guid = 23576
mod.toggleoptions = {"phase", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision: 4722 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if db.phase and msg == L["phase_bear"] then
		self:Message(L["bear_message"], "Attention")
		self:DelayedMessage(timer.bear-5, L["normal_warning"], "Attention")
		self:DelayedMessage(timer.bear-10, L["normal_soon"], "Urgent")
		self:Bar(L["bear_bar"], timer.bear, "Ability_Racial_BearForm")
		
	elseif db.phase and msg == L["phase_normal"] then
		self:Message(L["normal_message"], "Positive")
		self:DelayedMessage(timer.normal-5, L["bear_warning"], "Attention")
		self:DelayedMessage(timer.normal-10, L["bear_soon"], "Urgent")
		self:Bar(L["normal_bar"], timer.normal, "INV_Misc_Head_Troll_01")
		
	elseif msg == L["engage_trigger"] then
		if db.enrage then
			self:Enrage(timer.enrage, nil, true)
		end
		if db.phase then
			self:Message(L["engage_message"]:format(boss), "Positive")
			self:DelayedMessage(timer.normal-5, L["bear_warning"], "Attention")
			self:DelayedMessage(timer.normal-10, L["bear_soon"], "Urgent")
			self:Bar(L["normal_bar"], timer.normal, "INV_Misc_Head_Troll_01")
		end
	end
end

