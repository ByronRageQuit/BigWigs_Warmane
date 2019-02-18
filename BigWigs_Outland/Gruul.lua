------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Gruul the Dragonkiller"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local growcount = 1
local silence = nil
local IsItemInRange = IsItemInRange
local pName = UnitName("player")
local db = nil

local bandages = {
	[21991] = true, -- Heavy Netherweave Bandage
	[21990] = true, -- Netherweave Bandage
	[14530] = true, -- Heavy Runecloth Bandage
	[14529] = true, -- Runecloth Bandage
	[8545] = true, -- Heavy Mageweave Bandage
	[8544] = true, -- Mageweave Bandage
	[6451] = true, -- Heavy Silk Bandage
	[6450] = true, -- Silk Bandage
	[3531] = true, -- Heavy Wool Bandage
	[3530] = true, -- Wool Bandage
	[2581] = true, -- Heavy Linen Bandage
	[1251] = true, -- Linen Bandage
}

local timer = {
	grow = {39,30}, --Hilariously seems like which one is based on the white/black key pattern of a piano. OEIS:A059620
	silence = {19.7,31,22,75,84,22,75,84,22,75,84} --Just a guess on the looping 22,75,84
}
----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Gruul",

	engage_trigger = "Come.... and die.",
	engage_message = "%s Engaged!",

	grow = "Grow",
	grow_desc = "Count and warn for Gruul's grow.",
	grow_message = "Grows: (%d)",
	grow_bar = "Grow (%d)",

	grasp = "Grasp",
	grasp_desc = "Grasp warnings and timers.",
	grasp_message = "Ground Slam - Shatter in ~10sec!",
	grasp_warning = "Ground Slam Soon",
	grasp_bar = "~Ground Slam Cooldown",

	cavein = "Cave In on You",
	cavein_desc = "Warn for a Cave In on You.",
	cavein_message = "Cave In on YOU!",

	silence = "Silence",
	silence_desc = "Warn when Gruul casts AOE Silence (Reverberation).",
	silence_message = "AOE Silence",
	silence_warning = "AOE Silence soon!",
	silence_bar = "~Silence Cooldown",

	shatter_message = "Shatter!",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Gruul's Lair"]
mod.otherMenu = "Outland"
mod.enabletrigger = boss
mod.guid = 19044
mod.toggleoptions = {"grasp", "grow", -1, "cavein", "silence", "proximity", "bosskill"}
mod.revision = tonumber(("$Revision: 4722 $"):sub(12, -3))
mod.proximityCheck = function(unit)
	for k, v in pairs(bandages) do
		if IsItemInRange(k, unit) == 1 then
			return true
		end
	end
	return false
end
mod.proximitySilent = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "CaveIn", 36240)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Grow", 36300)
	self:AddCombatListener("SPELL_AURA_APPLIED_DOSE", "Grow", 36300)
	self:AddCombatListener("SPELL_AURA_APPLIED", "Silence", 36297)
	self:AddCombatListener("SPELL_CAST_START", "Shatter", 33654)
	self:AddCombatListener("SPELL_CAST_START", "Slam", 33525)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	db = self.db.profile
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:CaveIn(player)
	if player == pName and db.cavein then
		self:LocalMessage(L["cavein_message"], "Personal", 36240, "Alarm")
	end
end

function mod:growPattern(count)
	return math.floor((5*count+7)/12)-math.floor((5*count+2)/12)
end
function mod:Grow()
	if db.grow then
		if growcount > 0 then
			self:Message(L["grow_message"]:format(growcount), "Attention", 36300, "None") --If not on pull then alert, no sound
		end
		growcount = growcount + 1 --Interate count
		local color = self:growPattern(growcount)+1 --get grow color
		self:Bar(L["grow_bar"]:format(growcount), timer.grow[color], 36300)
	end
end

function mod:Silence()
	if db.silence then
		if silencecount > 0 then
			self:Message(L["silence_message"], "Attention", 36297)
		end
		silencecount = silencecount + 1
		self:DelayedMessage(timer.silence[silencecount]-5, L["silence_warning"], "Attention")
		self:Bar(L["silence_bar"], timer.silence[silencecount], 36297)
	end
end

function mod:Shatter()
	self.proximitySilent = true

	if db.grasp then
		self:IfMessage(L["shatter_message"], "Positive", 33654)
		self:DelayedMessage(48, L["grasp_warning"], "Urgent")
		self:Bar(L["grasp_bar"], 52, 33525)
	end
end

function mod:Slam(_, spellID)
	self.proximitySilent = nil

	if db.grasp then
		self:IfMessage(L["grasp_message"], "Attention", spellID)
		self:Bar(L["shatter_message"], 9, 33654)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["engage_trigger"] then
		silence = nil
		growcount = 0
		silencecount = 0
		self.proximitySilent = true
		self:TriggerEvent("BigWigs_ShowProximity", self)

		self:Message(L["engage_message"]:format(boss), "Attention")

		if db.grasp then
			self:DelayedMessage(30, L["grasp_warning"], "Urgent")
			self:Bar(L["grasp_bar"], 35, 33525)
		end
		self:Silence()
		self:Grow()
	end
end

