------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Magtheridon"]
local channeler = BB["Hellfire Channeler"]

local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local abycount = 0
local debwarn = nil
local pName = UnitName("player")
local db = nil
local started = nil
local deaths = 0

----------------------------
-- Encounter Information  --
----------------------------
--[[
Feenix timers are different to retail!
Time between casts of Blast Nova seems to be 69 second with a deviation of 0.5 seconds
The time for the first nova after the last channeler died looks like to be blizzlike 58s
]]--

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Magtheridon",

	escape = "Escape",
	escape_desc = "Countdown until Magtheridon breaks free.",
	escape_trigger1 = "%%s's bonds begin to weaken!",
	escape_trigger2 = "I... am... unleashed!",
	escape_trigger3 = "Thank you for releasing me. Now... die!",
	escape_warning1 = "%s Engaged - Breaks free in 2min!",
	escape_warning2 = "Breaks free in 1min!",
	escape_warning3 = "Breaks free in 30sec!",
	escape_warning4 = "Breaks free in 10sec!",
	escape_warning5 = "Breaks free in 3sec!",
	escape_bar = "Released...",
	escape_message = "%s Released!",

	abyssal = "Burning Abyssal",
	abyssal_desc = "Warn when a Burning Abyssal is created.",
	abyssal_message = "Burning Abyssal Created (%d)",

	heal = "Heal",
	heal_desc = "Warn when a Hellfire Channeler starts to heal.",
	heal_message = "Healing!",

	nova = "Blast Nova",
	nova_desc = "Estimated Blast Nova timers.",
	nova_ = "Blast Nova!", -- String to search for in emote
	nova_bar = "~Blast Nova Cooldown",
	nova_warning = "Blast Nova Soon",
	nova_cast = "Casting Blast Nova!",
	
	-- Added Feenix specific Nova
	cast_nova = "Blast Nova Casting",
	cast_nova_desc = "Estimating next Blast Nova cast.",
	cast_nova_ = "Blast Nova Cast!", -- Not happening, since we do not listen to the emote
	cast_nova_bar = "~Blast Nova Cast Cooldown",
	cast_nova_warning = "Nova in 9 seconds",
	cast_nova_cast = "Doing Blast Nova Cast!",

	banish = "Banish",
	banish_desc = "Warn when you Banish Magtheridon.",
	banish_trigger = "Not again! Not again...",
	banish_message = "Banished for ~10sec",
	banish_over_message = "Banish Fades!",
	banish_bar = "Banished",

	exhaust = "Disable Exhaustion Bars",
	exhaust_desc = "Timer bars for Mind Exhaustion on players.",
	exhaust_bar = "[%s] Exhausted",

	debris = "Debris on You",
	debris_desc = "Warn for Debris on You.",
	debris_message = "Debris on YOU!",

	debrisinc = "Debris",
	debrisinc_desc = "Warn for incoming debris at 30%.",
	debrisinc_trigger = "Let the walls of this prison tremble",
	debrisinc_message = "30% - Incoming Debris!",
	debrisinc_warning = "Debris Soon!",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Magtheridon's Lair"]
mod.otherMenu = "Outland"
mod.enabletrigger = {channeler, boss}
mod.guid = 17257
-- Added cast_nova to options
mod.toggleoptions = {"escape", "abyssal", "heal", -1, "nova", "cast_nova", "banish", -1, "debris", "debrisinc", -1, "exhaust", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision: 5706 $"):sub(12, -3)) -- Revision changed 21.01.2014

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "Exhaustion", 44032)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Debris", 36449)
	self:AddCombatListener("SPELL_SUMMON", "Abyssal", 30511)
	self:AddCombatListener("SPELL_CAST_START", "Heal", 30528)
	self:AddCombatListener("SPELL_AURA_REMOVED", "BanishRemoved", 30168)
	self:AddCombatListener("SPELL_CAST_START", "BlastNovaCasting", 30616) -- Magtheridon casts BlastNova
	self:AddCombatListener("UNIT_DIED", "Deaths")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	started = nil
	abycount = 1
	debwarn = nil
	deaths = 0
	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Exhaustion(player)
	if not db.exhaust then
		self:Bar(L["exhaust_bar"]:format(player), 30, 44032)
	end
end

function mod:Debris(player)
	if player == pName and db.debris then
		self:LocalMessage(L["debris_message"], "Important", 30632, "Alert")
	end
end

function mod:Abyssal()
	if db.abyssal then
		self:IfMessage(L["abyssal_message"]:format(abycount), "Attention", 30511)
		abycount = abycount + 1
	end
end

function mod:Heal(_, spellID)
	if db.heal then
		self:IfMessage(L["heal_message"], "Urgent", spellID, "Alarm")
		self:Bar(L["heal_message"], 2, spellID)
	end
end

function mod:BanishRemoved()
	if db.banish then
		self:IfMessage(L["banish_over_message"], "Attention", 30168)
		self:TriggerEvent("BigWigs_StopBar", self, L["banish_bar"])
	end
end

function mod:Deaths(unit, guid)
	if unit == channeler then
		deaths = deaths + 1
		if deaths == 5 then
			self:Start()
		end
	else
		self:BossDeath(nil, guid)
	end
end

function mod:Start()
	if started then return end
	started = true
	if db.escape then
		self:Message(L["escape_message"]:format(boss), "Important", nil, "Alert")
	end
	if db.nova then
		self:Bar(L["cast_nova_bar"], 61, "Spell_Fire_SealOfFire")
		self:DelayedMessage(56, L["nova_warning"], "Urgent")
	end
	if db.enrage then
		self:Enrage(1200, nil, true)
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg:find(L["escape_trigger1"]) then
		abycount = 1
		debwarn = nil

		if db.escape then
			self:Message(L["escape_warning1"]:format(boss), "Attention")
			self:Bar(L["escape_bar"], 120, "Ability_Rogue_Trip")
			self:DelayedMessage(60, L["escape_warning2"], "Positive")
			self:DelayedMessage(90, L["escape_warning3"], "Attention")
			self:DelayedMessage(110, L["escape_warning4"], "Urgent")
			self:DelayedMessage(117, L["escape_warning5"], "Urgent", nil, "Long")
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if (msg == L["escape_trigger2"]) or (msg == L["escape_trigger3"]) then
		--self:Print("calling self:Start")
		self:Start()
	elseif msg == L["banish_trigger"] then
		if db.banish then
			self:Message(L["banish_message"], "Important", nil, "Info", nil, 30168)
			self:Bar(L["banish_bar"], 10, "Spell_Shadow_Cripple")
		end
		self:TriggerEvent("BigWigs_StopBar", self, L["nova_cast"])
		self:TriggerEvent("BigWigs_StopBar", self, L["cast_nova_cast"])
	elseif db.debrisinc and msg:find(L["debrisinc_trigger"]) then
		self:Message(L["debrisinc_message"], "Positive")
		--Fanofdough - Encore reset on blast nova fix
		self:TriggerEvent("BigWigs _StopBar", self, L["cast_nova_bar"])
		self:Bar("Possible Blast Nova", 68, "Spell_Fire_SealOfFire")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	DEFAULT_CHAT_FRAME:AddMessage("BOSS EMOTE "..msg)
	if db.nova and msg:find(L["nova_"]) then
		DEFAULT_CHAT_FRAME:AddMessage("Got BOSS EMOTE and am inside bar starting")
		self:Message(L["nova_"], "Positive")
		self:Bar(L["nova_bar"], 51, "Spell_Fire_SealOfFire")
		self:Bar(L["nova_cast"], 12, "Spell_Fire_SealOfFire")
		self:DelayedMessage(48, L["nova_warning"], "Urgent")
	else
		DEFAULT_CHAT_FRAME:AddMessage("BOSS EMOTE, But did not trigger........")
	end
end

-- Magtheridon is starting to cast Blast Nova
function mod:BlastNovaCasting(_, spellID, arg2)
	-- Message with that text and the priority
	self:Message(L["cast_nova_"], "Positive")
	-- Bar with given name, 60s duration and icon
	self:Bar(L["cast_nova_bar"], 60, "Spell_Fire_SealOfFire")
	-- Bar with given name, 12s duration and icon
	self:Bar(L["cast_nova_cast"], 12, "Spell_Fire_SealOfFire")
	-- Sends a message in 55 seconds with the given text and priority
	self:DelayedMessage(55, L["cast_nova_warning"], "Urgent")
end

function mod:UNIT_HEALTH(msg)
	if not db.debrisinc then return end
	if UnitName(msg) == boss then
		local health = UnitHealth(msg)
		if health > 31 and health <= 35 and not debwarn then
			self:Message(L["debrisinc_warning"], "Positive")
			debwarn = true
		elseif health > 60 and debwarn then
			debwarn = false
		end
	end
end

