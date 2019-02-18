------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Brutallus"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local pName = UnitName("player")
local db = nil
local meteorCounter = 1

local timer = {
	burn = 20,
	burn_duration = 60,
	stomp = 30,
	meteor = 12, -- in  trinity core base it says 11 (metoer slash)
	enrage = 300,
	
}
----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Brutallus",

	engage_trigger = "Ah, more lambs to the slaughter!",

	burn = "Burn",
	burn_desc = "Tells you who has been hit by Burn and when the next Burn is coming.",
	burn_you = "Burn on YOU!",
	burn_other = "Burn on %s!",
	burn_me = "Burn on me!",
	burn_bar = "Burn",
	burn_message = "Burn in ~5sec!",

	burnresist = "Burn Resist",
	burnresist_desc = "Warn who resists burn.",
	burn_resist = "%s resisted Burn",

	meteor = "Meteor Slash",
	meteor_desc = "Show a Meteor Slash timer bar.",
	meteor_bar = "Meteor Slash #%d",

	stomp = "Stomp",
	stomp_desc = "Warn for Stomp and show a bar.",
	stomp_warning = "Stomp in 5sec!",
	stomp_message = "Stomp: %s",
	stomp_bar = "Stomp",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Sunwell Plateau"]
mod.enabletrigger = boss
mod.guid = 24882
mod.toggleoptions = {"burn", "burnresist", "meteor", "stomp", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision: 4740 $"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_MISSED", "BurnResist", 45141)
	self:AddCombatListener("SPELL_CAST_START", "Meteor", 45150)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Burn", 46394)
	self:AddCombatListener("SPELL_AURA_REMOVED", "BurnRemove", 46394)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Stomp", 45185)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
	meteorCounter = 1
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Burn(player, spellID)
	if db.burn then
		local other = L["burn_other"]:format(player)
		if player == pName then
			self:Message(L["burn_you"], "Personal", true, "Alert", nil, spellID)
			self:Message(other, "Attention", nil, nil, true)
			SendChatMessage(L["burn_me"], "SAY")
		else
			self:Message(other, "Attention", nil, nil, nil, spellID)
			self:Whisper(player, L["burn_you"])
		end
		self:Icon(player, "icon")
		self:Bar(other, timer.burn_duration, spellID)
		self:Bar(L["burn_bar"], timer.burn, spellID)
		self:DelayedMessage(timer.burn-5, L["burn_message"], "Attention")
	end
end

function mod:Meteor()
	meteorCounter = meteorCounter + 1
	if db.meteor then
		self:Bar(L["meteor_bar"]:format(meteorCounter), timer.meteor, 45150)
	end
end

function mod:BurnRemove(player)
	if db.burn then
		self:TriggerEvent("BigWigs_StopBar", self, L["burn_other"]:format(player))
	end
end

function mod:BurnResist(player)
	if db.burnresist then
		self:Message(L["burn_resist"]:format(player), "Positive", nil, nil, nil, 45141)
	end
end

function mod:Stomp(player, spellID)
	if db.stomp then
		self:Message(L["stomp_message"]:format(player), "Urgent", nil, nil, nil, spellID)
		self:DelayedMessage(timer.stomp-5, L["stomp_warning"], "Attention")
		self:Bar(L["stomp_bar"], timer.stomp, spellID)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["engage_trigger"] then
		meteorCounter = 1
		if db.burn then
			self:Bar(L["burn_bar"], timer.burn, 45141)
			self:DelayedMessage(timer.burn-5, L["burn_message"], "Attention")
		end
		if db.enrage then
			self:Enrage(timer.enrage)
		end
		if db.stomp then
			self:Bar(L["stomp_bar"], timer.stomp, 45185)
		end
	end
end

