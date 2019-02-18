------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Kalecgos"]
local sath = BB["Sathrovarr the Corruptor"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local db = nil
local enrageWarn = nil
local wipe = nil
local counter = 1

local fmt = string.format
local GetNumRaidMembers = GetNumRaidMembers
local CheckInteractDistance = CheckInteractDistance
local pName = UnitName("player")
local UnitBuff = UnitBuff
local UnitPowerType = UnitPowerType
local UnitClass = UnitClass

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Kalecgos",

	engage_trigger = "Aggh!! No longer will I be a slave to Malygos! Challenge me and you will be destroyed!",
	wipe_bar = "Respawn",

	portal = "Portal",
	portal_desc = "Warn when the Spectral Blast cooldown is up.",
	portal_bar = "Next portal (%d)",
	portal_message = "Possible portal in 5sec!",

	realm = "Spectral Realm",
	realm_desc = "Tells you who is in the Spectral Realm.",
	realm_message = "Spectral Realm: %s (Group %d)",

	curse = "Curse of Boundless Agony",
	curse_desc = "Tells you who is afflicted by Curse of Boundless Agony.",
	curse_bar = "Curse: %s",

	magichealing = "Wild Magic (Increased healing)",
	magichealing_desc = "Tells you when you get increased healing from Wild Magic.",
	magichealing_you = "Wild Magic - Healing effects increased!",

	magiccast = "Wild Magic (Increased cast time)",
	magiccast_desc = "Tells you when a healer gets incrased cast time from Wild Magic.",
	magiccast_you = "Wild Magic - Increased casting time on YOU!",
	magiccast_other = "Wild Magic - Increased casting time on %s!",

	magichit = "Wild Magic (Decreased chance to hit)",
	magichit_desc = "Tells you when a tank's chance to hit is reduced by Wild Magic.",
	magichit_you = "Wild Magic - Decreased chance to hit on YOU!",
	magichit_other = "Wild Magic - Decreased chance to hit on %s!",

	magicthreat = "Wild Magic (Increased threat)",
	magicthreat_desc = "Tells you when you get increased threat from Wild Magic.",
	magicthreat_you = "Wild Magic - Threat generation increased!",

	buffet = "Arcane Buffet",
	buffet_desc = "Show the Arcane Buffet timer bar.",

	enrage_warning = "Enrage soon!",
	enrage_message = "10% - Enraged!",
	enrage_trigger = "Sathrovarr drives Kalecgos into a crazed rage!",

	strike = "Corrupting Strike",
	strike_desc = "Warn who gets Corrupting Strike.",
	strike_message = "Corrupting Strike: %s",
	
	enrage_bar = "Enrage",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Sunwell Plateau"]
mod.enabletrigger = { boss, sath }
mod.guid = 24892
mod.toggleoptions = {"portal", "buffet", "realm", "curse", "strike", -1, "magichealing", "magiccast", "magichit", "magicthreat", "enrage", "proximity", "bosskill"}
mod.revision = tonumber(("$Revision: 4740 $"):sub(12, -3))
mod.proximityCheck = function(unit) return CheckInteractDistance(unit, 3) end
mod.proximitySilent = true

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	self:AddSyncListener("SPELL_AURA_APPLIED", 46021, "KalecgosRealm", 1)
	self:AddSyncListener("SPELL_CAST_SUCCESS", 45029, "KalecgosStrike", 1)
	self:AddSyncListener("SPELL_AURA_APPLIED", 45032, 45034, "KalecgosCurse", 1)
	self:AddSyncListener("SPELL_AURA_APPLIED", 45018, "KaleBuffet", 1)
	self:AddSyncListener("SPELL_AURA_APPLIED_DOSE", 45018, "KaleBuffet", 1)
	self:AddSyncListener("SPELL_AURA_REMOVED", 45032, 45034, "KaleCurseRemv", 1)

	self:AddCombatListener("SPELL_AURA_APPLIED", "WildMagic", 44978, 45001, 45002, 45006)
	self:AddCombatListener("UNIT_DIED", "BossDeath")

	self:RegisterEvent("BigWigs_RecvSync")
	self:Throttle(3, "KalecgosMagicCast", "KalecgosMagicHit", "KaleBuffet", "KalecgosStrike")
	self:Throttle(0, "KalecgosCurse", "KaleCurseRemv")
	self:Throttle(19, "KalecgosRealm")

	db = self.db.profile
	if wipe and BigWigs:IsModuleActive(boss) then
		self:Bar(L["wipe_bar"], 30, 44670)
		wipe = nil
		
		self:TriggerEvent("BigWigs_StopBar", self, L["enrage_bar"])
	end
	counter = 1
end

------------------------------
--      Event Handlers      --
------------------------------


function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L["engage_trigger"] then
		wipe = true
		counter = 1
		if db.portal then
			self:Bar(L["portal_bar"]:format(counter), 20, 46021)
			self:DelayedMessage(15, L["portal_message"], "Urgent", nil, "Alert")
		end
		self:TriggerEvent("BigWigs_ShowProximity", self)
		
		--
		self:Bar(L["enrage_bar"], 300, 5229)
	end
end

function mod:WildMagic(player, spellId)
	if spellId == 44978 and player == pName and db.magichealing then -- Wild Magic - Healing done by spells and effects increased by 100%.
		self:LocalMessage(L["magichealing_you"], "Attention", spellId, "Long")
	elseif spellId == 45001 then -- Wild Magic - Casting time increased by 100%.
		if self:IsPlayerHealer(player) then
			self:Sync("KalecgosMagicCast", player)
		end
	elseif spellId == 45002 then -- Wild Magic - Chance to hit with melee and ranged attacks reduced by 50%.
		if self:IsPlayerTank(player) then
			self:Sync("KalecgosMagicHit", player)
		end
	elseif spellId == 45006 and player == pName and db.magicthreat then -- Wild Magic - Increases threat generated by 100%.
		self:LocalMessage(L["magicthreat_you"], "Personal", spellId, "Long")
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == "KalecgosRealm" and rest then
		if db.portal then
			counter = counter + 1
			self:Bar(L["portal_bar"]:format(counter), 20, 46021)
			self:DelayedMessage(15, L["portal_message"], "Urgent", nil, "Alert")
		end
		if db.realm then
			local groupNo = self:GetGroupNumber(rest) or 0
			self:IfMessage(fmt(L["realm_message"], rest, groupNo), "Urgent", 44866, "Alert")
		end
	elseif sync == "KalecgosCurse" and rest and db.curse then
		self:Bar(fmt(L["curse_bar"], rest), 30, 45032)
	elseif sync == "KaleBuffet" and db.buffet then
		self:Bar(L["buffet"], 8, 45018)
	elseif sync == "KaleCurseRemv" and rest and db.curse then
		self:TriggerEvent("BigWigs_StopBar", self, fmt(L["curse_bar"], rest))
	elseif sync == "KalecgosMagicCast" and rest and db.magiccast then
		local other = fmt(L["magiccast_other"], rest)
		if rest == pName then
			self:LocalMessage(L["magiccast_you"], "Positive", 45001, "Long")
			self:WideMessage(other)
		else
			self:IfMessage(other, "Attention", 45001)
		end
	elseif sync == "KalecgosMagicHit" and rest and db.magichit then
		local other = fmt(L["magichit_other"], rest)
		if rest == pName then
			self:LocalMessage(L["magichit_you"], "Personal", 45002, "Long")
			self:WideMessage(other)
		else
			self:IfMessage(other, "Attention", 45002)
		end
	elseif sync == "KalecgosStrike" and rest and db.strike then
		local msg = fmt(L["strike_message"], rest)
		if rest == boss then
			self:IfMessage(msg, "Urgent", 45029)
		else
			self:IfMessage(msg, "Urgent", 45029)
			self:Bar(msg, 3, 45029)
		end
	end
end

function mod:UNIT_HEALTH(msg)
	if db.enrage then
		if msg == sath then
			local health = UnitHealth(msg)
			if health > 12 and health <= 14 and not enrageWarn then
				self:Message(L["enrage_warning"], "Positive")
				enrageWarn = true
			elseif health > 50 and enrageWarn then
				enrageWarn = false
			end
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if db.enrage and msg == L["enrage_trigger"] then
		self:IfMessage(L["enrage_message"], "Important", 44806)
	end
end

-- Assumptions made:
--	Shaman are always counted as healers
--	Paladins without Righteous Fury are healers
--	Druids are counted as healers if they have a mana bar and are not Moonkin
--	Priests are counted as healers if they aren't in Shadowform
local sfID = GetSpellInfo(15473) --Shadowform
local mkID = GetSpellInfo(24905) --Moonkin
local rfID = GetSpellInfo(25780) --Righteous Fury

local function hasBuff(player, buff)
	local i = 1
	local name = UnitBuff(player, i)
	while name do
		if name == buff then return true end
		i = i + 1
		name = UnitBuff(player, i)
	end
	return false
end

function mod:IsPlayerHealer(player)
	local _, class = UnitClass(player)
	if class == "SHAMAN" then
		return true
	end
	if class == "DRUID" and UnitPowerType(player) == 0 then
		return not hasBuff(player, mkID)
	end
	if class == "PALADIN" then
		return not hasBuff(player, rfID)
	end
	if class == "PRIEST" then
		return not hasBuff(player, sfID)
	end
	return false
end

-- Assumptions made:
--	Anyone with a rage bar is counted as a tank
--	Paladins with Righteous Fury are counted as tanks
function mod:IsPlayerTank(player)
	local _, class = UnitClass(player)
	if UnitPowerType(player) == 1 then --has rage
		return true
	end
	if class == "PALADIN" and hasBuff(player, rfID) then
		return true
	end
	return false
end

function mod:GetGroupNumber(player)
	for i = 1, GetNumRaidMembers() do
		local name, _, subGroup = GetRaidRosterInfo(i)
		if name == player then return subGroup end
	end
end

