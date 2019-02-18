----------------------------------
--      Module Declaration      --
----------------------------------
local boss = BB["Al'ar"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Tempest Keep"]
mod.otherMenu = "The Eye"
mod.enabletrigger = boss
mod.wipemobs = {"Ember of Al'ar"}
mod.guid = 19514
mod.toggleoptions = {"voidAlert", -1, "meteortimer", -1, "armortimer", "armoralert", "enrage", "bosskill"}
mod.revision = 1000

local db = nil
local pName = UnitName("player")
local fmt = string.format
local started = nil
local submerged = nil
local phaseTwoAnnounced = nil

local timer = {
	meteor = 45,
	armor = {75,60}, --First is late due to meteor
	emerge = {16,11.7},
}
local icon = {
	meteor = 35181,
	armor = 35410,
	emerge = "Spell_Fire_Burnout",
}
local syncName = {
	submerged = "Submerged"..mod.revision,
	emerged = "Emerged"..mod.revision,
}

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Alar",
	
	armortimer = "Melt Armor",
	armortimer_bar = "Next Melt Armor",
	armortimer_desc = "Timer for Melt Armor",
	armoralert = "Melt Armor Alert",
	armoralert_desc = "Alert when tank get Melt Armor",
	armoralert_msg = "Melt Armor on %s",
	
	meteortimer = "Meteor",
	meteortimer_bar = "Next Meteor",
	meteortimer_desc = "Timer for Meteor",
	
	voidAlert = "Flame Patch",
	voidAlert_desc = "Alert for Flame Patch",
	voidAlert_msg = "Flame Patch on YOU!",
} end)
------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_AURA_APPLIED", "meltArmor", 35410)
	self:AddCombatListener("SPELL_AURA_APPLIED", "voidAlert", 35383)
	self:AddCombatListener("UNIT_DIED", "BossDeath")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("BigWigs_RecvSync")

	db = self.db.profile
	started = nil
	submerged = nil
	phaseTwoAnnounced = nil
end

------------------------------
--     Utility Functions    --
------------------------------
local function findBoss()
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i.."target") == boss then
			return "raid"..i
		end
	end
	return false
end
local function resetFight()
	mod:CheckForWipe()
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:meltArmor(player)
	if db.armortimer then
		self:Bar(L["armortimer_bar"], timer.armor[2], icon.armor)
	end
	if db.armoralert then
		self:Message(L["armoralert_msg"]:format(player), "Urgent")
	end
end

function mod:voidAlert(player)
	if db.voidAlert and player == pName then
		self:Message(L["voidAlert_msg"], "Urgent", false, "Alarm")
	end
end

--This allows for normal wipe detection and handling in p1
function mod:UNIT_HEALTH(unit)
	if UnitName(unit) == boss then
		local hp = UnitHealth(unit)
		if hp <= 1 and not phaseTwoAnnounced then
			--unload normal wipe trigger
			if self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
				self:UnregisterEvent("PLAYER_REGEN_ENABLED")
			end
			--start state check event
			self:ScheduleRepeatingEvent("CheckBossState", self.BossCheck, 0.3, self)
		end
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.submerged then
		submerged = true
		self:ScheduleEvent("AlarReset", resetFight, 90) --If a meteor has not happend in 90 sec then its a wipe
		if not phaseTwoAnnounced then
			phaseTwoAnnounced = true
			self:Bar(L["armortimer"], timer.armor[1], icon.armor)
			self:Bar(L["meteortimer"], timer.meteor, icon.meteor)
			self:Bar("Emerge", timer.emerge[1], icon.emerge)
			self:Enrage(600)
		else
			self:Bar(L["meteortimer"], timer.meteor, icon.meteor)
			self:Bar("Emerge", timer.emerge[2], icon.emerge)
		end
	elseif sync == syncName.emerged then
		submerged = false
	end
	
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		submerged = false --Done so that I dont need to keep a meteor count
		phaseTwoAnnounced = false
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
	end
end

function mod:BossCheck()
	if not findBoss() and not submerged then --This triggers once boss transitions from up to down
		self:Sync(syncName.submerged)
	elseif findBoss() and submerged then --This is triggers once boss returns
		self:Sync(syncName.emerged)
	end
end